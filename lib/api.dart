import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

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

  Future<void> restartService(String path) => _serviceAction(
        endpoint: 'restart',
        path: path,
        superviseMode: 'loop',
      );

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
  /// Note: The [onProgress] callback fires when chunks are buffered locally,
  /// not when data is transmitted. For large images, the server may still
  /// be writing to disk after the client sees 100% progress.
  Future<void> uploadRoot({
    required Stream<List<int>> stream,
    required int size,
    required void Function(int sent, int total) onProgress,
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
      onBadCertificate: (fingerprint) => untrustedFingerprint = fingerprint,
    );
    try {
      final request = await client.putUrl(_uri('update/root'));
      _setHeaders(request);

      var sent = 0;
      // Track first 6 bytes of the original input (before any decompression)
      final inputBytes = <int>[];
      // Track first 6 bytes of what will be sent (after decompression if any)
      final uploadedBytes = <int>[];
      var previewLogged = false;

      void logPreview({required bool fromInputTap, required bool fromOutputTap}) {
        if (previewLogged) {
          return;
        }
        // Log preview once we have enough bytes from either source
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

      // First transformer: track progress and capture input bytes
      final inputTap = StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          onProgress(sent, size);
          if (inputBytes.length < 6) {
            inputBytes.addAll(chunk.take(6 - inputBytes.length));
            logPreview(fromInputTap: true, fromOutputTap: false);
          }
          sink.add(chunk);
        },
      );

      // Second transformer: capture uploaded bytes and log preview
      final outputTap = StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
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

      // Create broadcast stream for simultaneous hash computation and upload
      final sharedStream = uploadStream.asBroadcastStream();

      // Compute local hash while uploading
      final localHashFuture = sha256.bind(sharedStream).first.then(
            (digest) => digest.toString(),
          );

      // Add stream to request and wait for it to complete
      // This ensures all data has been read from the stream
      debugPrint('uploadRoot: starting addStream (size=$size)');
      await request.addStream(sharedStream);
      debugPrint('uploadRoot: addStream complete, waiting for hash');

      // After addStream completes, log preview again in case output tap
      // received data after the input tap finished
      logPreview(fromInputTap: false, fromOutputTap: true);

      // Wait for hash computation to complete
      final localHash = await localHashFuture;
      debugPrint('uploadRoot: local hash=$localHash');

      // Close request and get response
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

  HttpClient _httpClient({void Function(String fingerprint)? onBadCertificate}) {
    return HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
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
