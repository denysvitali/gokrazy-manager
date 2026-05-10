import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class InstanceRepository {
  InstanceRepository(this._prefs, this._secureStorage);

  static const _instancesKey = 'instances';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static Future<InstanceRepository> open() async {
    return InstanceRepository(
      await SharedPreferences.getInstance(),
      const FlutterSecureStorage(),
    );
  }

  List<GokrazyInstance> load() {
    final raw = _prefs.getString(_instancesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((entry) => GokrazyInstance.fromJson(_asMap(entry)))
        .toList();
  }

  Future<void> saveAll(List<GokrazyInstance> instances) async {
    await _prefs.setString(
      _instancesKey,
      jsonEncode(instances.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<String?> passwordFor(String id) {
    return _secureStorage.read(key: _passwordKey(id));
  }

  Future<void> upsertPassword(String id, String password) async {
    await _secureStorage.write(key: _passwordKey(id), value: password);
  }

  Future<void> deletePassword(String id) {
    return _secureStorage.delete(key: _passwordKey(id));
  }

  String _passwordKey(String id) => 'gokrazy_password_$id';
}

class CertificatePinRequired implements Exception {
  const CertificatePinRequired(this.fingerprint);

  final String fingerprint;

  @override
  String toString() => 'Certificate pin required: $fingerprint';
}

class GokrazyClient {
  GokrazyClient({
    required this.instance,
    required this.password,
  });

  static const _defaultConnectionTimeout = Duration(seconds: 12);

  final GokrazyInstance instance;
  final String password;

  Future<GokrazyStatus> fetchStatus() async {
    final body = await _requestText('GET', '');
    final decoded = jsonDecode(body) as Map<String, Object?>;
    return GokrazyStatus.fromJson(decoded);
  }

  Future<List<String>> fetchFeatures() async {
    final body = await _requestText('GET', 'update/features');
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return '${decoded['features'] ?? ''}'
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
      }
    } on FormatException {
      // Older gokrazy versions return a text/plain comma separated list.
    }
    return body
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  Future<void> testboot() => _requestText('POST', 'update/testboot').then((_) {});

  Future<void> switchRoot() => _requestText('POST', 'update/switch').then((_) {});

  Future<void> reboot({bool asyncReboot = true}) {
    final suffix = asyncReboot ? 'reboot?async=true' : 'reboot';
    return _requestText('POST', suffix).then((_) {});
  }

  Future<void> startService(String path) => _serviceAction(
        endpoint: 'restart',
        path: path,
        superviseMode: 'once',
      );

  // Restarting a service via gokrazy's POST /restart endpoint races with
  // the supervisor for services that handle SIGTERM cleanly: the
  // supervisor's "exited successfully, stopping" branch sets the service
  // back to stopped=true after /restart cleared it, leaving the service
  // down. Stop first, give the supervisor time to process the exit, then
  // re-arm via /restart and verify the service is back up — retrying if
  // we still lose the race (e.g. for slow shutdowns).
  Future<void> restartService(String path) async {
    await _serviceAction(endpoint: 'stop', path: path);
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    for (var attempt = 0; attempt < 4; attempt++) {
      await _serviceAction(
        endpoint: 'restart',
        path: path,
        superviseMode: 'loop',
      );
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        final status = await fetchStatus();
        final svc = status.services
            .where((service) => service.path == path)
            .firstOrNull;
        if (svc == null || !svc.stopped) {
          return;
        }
      } catch (_) {
        // Transient failure — retry the re-arm.
      }
    }
  }

  Future<void> stopService(String path) => _serviceAction(
        endpoint: 'stop',
        path: path,
      );

  Stream<String> serviceLogStream({
    required String path,
    String stream = 'both',
    int maxLines = 1200,
  }) async* {
    final lines = <String>[];
    final client = _httpClient();
    try {
      final request = await client.getUrl(
        _uri('log').replace(queryParameters: {'path': path, 'stream': stream}),
      );
      _setHeaders(request, keepJsonAccept: false);
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      final response = await request.close();
      final body =
          response.transform(utf8.decoder).transform(const LineSplitter());

      if (response.statusCode != HttpStatus.ok) {
        final text = await body.join();
        throw HttpException('HTTP ${response.statusCode}: ${text.trim()}');
      }

      await for (final line in body) {
        final trimmed = line.trim();
        if (trimmed.startsWith('event:')) {
          continue;
        }
        if (trimmed.startsWith('data:')) {
          final decoded = trimmed.substring(5).trimLeft();
          if (decoded.isNotEmpty) {
            lines.add(decoded);
            if (lines.length > maxLines) {
              lines.removeRange(0, lines.length - maxLines);
            }
            yield lines.join('\n');
          }
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Uploads a squashfs image to the gokrazy device's inactive root partition.
  ///
  /// The upload process:
  /// 1. Sends the image as a PUT request to /update/root
  /// 2. The device writes to the inactive partition while computing SHA-256
  /// 3. Device returns the computed hash as the response body
  /// 4. Client verifies the hash matches its local computation
  ///
  /// [total] is the expected size of the *uploaded* (post-decompression)
  /// payload, or null if unknown. [onProgress] reports bytes that have been
  /// accepted by the request stream sink — backpressure from the socket
  /// throttles this, so the count tracks actual transmission within the
  /// size of OS/TLS buffers.
  Future<void> uploadRoot({
    required Stream<List<int>> stream,
    required int? total,
    required void Function(int sent, int? total) onProgress,
    bool decompress = false,
  }) async {
    String formatBytesHex(List<int> bytes) {
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
    }

    String formatBytesAscii(List<int> bytes) {
      return bytes
          .map((byte) => byte >= 0x20 && byte <= 0x7e ? String.fromCharCode(byte) : '.')
          .join();
    }

    String? untrustedFingerprint;
    final client = _httpClient(
      // Flashing can spend a long time connected while the device writes
      // the root image and returns the verification hash.
      connectionTimeout: null,
      onBadCertificate: (fingerprint) => untrustedFingerprint = fingerprint,
    );
    try {
      final request = await client.putUrl(_uri('update/root'));
      _setHeaders(request);

      var sent = 0;
      final inputBytes = <int>[];
      final uploadedBytes = <int>[];
      var previewLogged = false;

      final hashAccumulator = AccumulatorSink<Digest>();
      final hashSink = sha256.startChunkedConversion(hashAccumulator);

      void logPreview({required bool fromInputTap, required bool fromOutputTap}) {
        if (previewLogged) {
          return;
        }
        final hasEnough = inputBytes.length >= 6 || uploadedBytes.length >= 6;
        if (!hasEnough) {
          return;
        }
        previewLogged = true;
        final isGzip = inputBytes.length >= 2 &&
            inputBytes[0] == 0x1F &&
            inputBytes[1] == 0x8B;
        debugPrint(
          'uploadRoot: decompress=$decompress input_gzip=$isGzip '
          'input_hex=${formatBytesHex(inputBytes)} '
          'input_ascii="${formatBytesAscii(inputBytes)}" '
          'uploaded_hex=${formatBytesHex(uploadedBytes)} '
          'uploaded_ascii="${formatBytesAscii(uploadedBytes)}"',
        );
      }

      // Capture preview bytes from the raw input (before decompression).
      final inputTap = StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          if (inputBytes.length < 6) {
            inputBytes.addAll(chunk.take(6 - inputBytes.length));
            logPreview(fromInputTap: true, fromOutputTap: false);
          }
          sink.add(chunk);
        },
      );

      // Track progress and hash on the post-decompression stream — these
      // are the bytes the device will actually receive and verify.
      // Counting here (rather than at the source) lets addStream's
      // backpressure throttle the read pipeline, so `sent` tracks actual
      // socket throughput instead of disk-read speed.
      final outputTap = StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          hashSink.add(chunk);
          onProgress(sent, total);
          if (uploadedBytes.length < 6) {
            uploadedBytes.addAll(chunk.take(6 - uploadedBytes.length));
            logPreview(fromInputTap: false, fromOutputTap: true);
          }
          sink.add(chunk);
        },
      );

      Stream<List<int>> uploadStream = stream.transform(inputTap);
      if (decompress) {
        uploadStream = uploadStream.transform(io.gzip.decoder);
      }
      uploadStream = uploadStream.transform(outputTap);

      debugPrint('uploadRoot: starting addStream (total=$total)');
      await request.addStream(uploadStream);
      hashSink.close();
      final localHash = hashAccumulator.events.single.toString();
      debugPrint('uploadRoot: addStream complete, local hash=$localHash');
      logPreview(fromInputTap: false, fromOutputTap: true);

      debugPrint('uploadRoot: closing request, waiting for response');
      final response = await request.close();
      debugPrint('uploadRoot: response status=${response.statusCode}');

      final body = (await response.transform(utf8.decoder).join()).trim();
      debugPrint('uploadRoot: response body=$body');

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }

      if (body != localHash) {
        throw StateError(
            'Checksum mismatch: device returned $body, sent $localHash');
      }

      debugPrint('uploadRoot: upload verified successfully');
    } on CertificatePinRequired {
      rethrow;
    } on HandshakeException {
      final fingerprint = untrustedFingerprint;
      if (fingerprint != null) {
        throw CertificatePinRequired(fingerprint);
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _serviceAction({
    required String endpoint,
    required String path,
    String? superviseMode,
    String? signal,
  }) async {
    String? untrustedFingerprint;
    final client = _httpClient(
      onBadCertificate: (fingerprint) => untrustedFingerprint = fingerprint,
    );
    try {
      final xsrf = await _fetchXsrfToken(client: client, path: path);
      final params = {
        'path': path,
        'xsrftoken': xsrf,
        if (superviseMode != null) 'supervise': superviseMode,
        if (signal != null) 'signal': signal,
      };
      final request =
          await client.postUrl(_uri(endpoint).replace(queryParameters: params));
      request.headers.set(HttpHeaders.cookieHeader, 'gokrazy_xsrf=$xsrf');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      _setHeaders(request, keepJsonAccept: false);
      final response = await request.close();
      final body = (await response.transform(utf8.decoder).join()).trim();
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.seeOther) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }
    } on CertificatePinRequired {
      rethrow;
    } on HandshakeException {
      final fingerprint = untrustedFingerprint;
      if (fingerprint != null) {
        throw CertificatePinRequired(fingerprint);
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _fetchXsrfToken({
    required HttpClient client,
    required String path,
  }) async {
    final request = await client
        .getUrl(_uri('status').replace(queryParameters: {'path': path}));
    _setHeaders(request, keepJsonAccept: false);
    final response = await request.close();
    final cookieHeaders = response.headers[HttpHeaders.setCookieHeader];
    final body = (await response.transform(utf8.decoder).join()).trim();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}: $body');
    }
    for (final cookie in cookieHeaders ?? const <String>[]) {
      final match = cookie
          .split(';')
          .map((entry) => entry.trim())
          .firstWhere((entry) => entry.startsWith('gokrazy_xsrf='),
              orElse: () => '');
      if (match.isNotEmpty) {
        return match.substring('gokrazy_xsrf='.length);
      }
    }
    throw StateError('XSRF token not found in /status response');
  }

  Future<String> _requestText(String method, String path) async {
    String? untrustedFingerprint;
    final client = _httpClient(
      onBadCertificate: (fingerprint) => untrustedFingerprint = fingerprint,
    );

    try {
      final request = await client.openUrl(method, _uri(path));
      _setHeaders(request);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: ${body.trim()}');
      }
      return body;
    } on HandshakeException {
      final fingerprint = untrustedFingerprint;
      if (fingerprint != null) {
        throw CertificatePinRequired(fingerprint);
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  HttpClient _httpClient({
    Duration? connectionTimeout = _defaultConnectionTimeout,
    void Function(String fingerprint)? onBadCertificate,
  }) {
    return HttpClient()
      ..connectionTimeout = connectionTimeout
      ..badCertificateCallback = (cert, host, port) {
        final fingerprint = certificateFingerprint(cert);
        onBadCertificate?.call(fingerprint);
        return _fingerprintsMatch(instance.pinnedFingerprint, fingerprint);
      };
  }

  Uri _uri(String path) {
    final base = instance.baseUrl.endsWith('/')
        ? instance.baseUrl
        : '${instance.baseUrl}/';
    return Uri.parse(base).resolve(path);
  }

  void _setHeaders(HttpClientRequest request, {bool keepJsonAccept = true}) {
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (!keepJsonAccept) {
      request.headers.remove(HttpHeaders.acceptHeader, 'application/json');
    }
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Basic ${base64Encode(utf8.encode('${instance.username}:$password'))}',
    );
  }
}

String certificateFingerprint(X509Certificate certificate) {
  final pem = certificate.pem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final der = base64Decode(pem);
  return sha256.convert(der).bytes.map((byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }).join(':');
}

bool _fingerprintsMatch(String? trusted, String? observed) {
  if (trusted == null || observed == null) {
    return false;
  }
  String normalize(String value) => value.replaceAll(':', '').toUpperCase();
  return normalize(trusted) == normalize(observed);
}

String normalizeUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry('$key', entry));
  }
  return const {};
}
