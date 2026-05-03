import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart' show AccumulatorSink;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const GokrazyManagerApp());
}

class GokrazyManagerApp extends StatelessWidget {
  const GokrazyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff0f4f67);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final panel = const Color(0xff101a2d).withValues(alpha: 0.82);
    const layer = Color(0xff1b2842);
    const border = Color(0xff243858);
    return MaterialApp(
      title: 'Gokrazy Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          surfaceTintColor: colorScheme.primary.withValues(alpha: 0.08),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          centerTitle: false,
          scrolledUnderElevation: 0,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            minimumSize: const Size(0, 46),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            minimumSize: const Size(0, 46),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
          ),
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          fillColor: layer,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          color: WidgetStateProperty.resolveWith((_) => panel),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          side: BorderSide.none,
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: border.withValues(alpha: 0.7),
          space: 0,
          thickness: 1,
        ),
        textTheme: TextTheme(
          titleLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          bodyMedium: TextStyle(
            fontSize: 14.5,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          bodyLarge: const TextStyle(height: 1.4),
          labelLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class GokrazyInstance {
  const GokrazyInstance({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    this.pinnedFingerprint,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final String? pinnedFingerprint;
  final DateTime? lastSeen;

  GokrazyInstance copyWith({
    String? name,
    String? baseUrl,
    String? username,
    Object? pinnedFingerprint = _sentinel,
    DateTime? lastSeen,
  }) {
    return GokrazyInstance(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      pinnedFingerprint: identical(pinnedFingerprint, _sentinel)
          ? this.pinnedFingerprint
          : pinnedFingerprint as String?,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'username': username,
        'pinnedFingerprint': pinnedFingerprint,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  factory GokrazyInstance.fromJson(Map<String, Object?> json) {
    final lastSeenRaw = json['lastSeen'] as String?;
    return GokrazyInstance(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      username: json['username'] as String,
      pinnedFingerprint: json['pinnedFingerprint'] as String?,
      lastSeen: lastSeenRaw == null ? null : DateTime.tryParse(lastSeenRaw),
    );
  }

  static const _sentinel = Object();
}

class GokrazyStatus {
  const GokrazyStatus({
    required this.services,
    this.hostname,
    this.model,
    this.kernel,
    this.buildTimestamp,
    this.sbomHash,
    this.permUsed,
    this.permAvail,
    this.permTotal,
    this.privateAddrs = const [],
    this.publicAddrs = const [],
    this.memTotal,
    this.memAvailable,
  });

  final List<GokrazyService> services;
  final String? hostname;
  final String? model;
  final String? kernel;
  final String? buildTimestamp;
  final String? sbomHash;
  final int? permUsed;
  final int? permAvail;
  final int? permTotal;
  final List<String> privateAddrs;
  final List<String> publicAddrs;
  final int? memTotal;
  final int? memAvailable;

  int get runningServices => services.where((svc) => svc.running).length;

  factory GokrazyStatus.fromJson(Map<String, Object?> json) {
    final meminfo = _asMap(json['Meminfo']);
    return GokrazyStatus(
      services: _asList(json['Services'])
          .map((entry) => GokrazyService.fromJson(_asMap(entry)))
          .toList(),
      hostname: json['Hostname'] as String?,
      model: json['Model'] as String?,
      kernel: json['Kernel'] as String?,
      buildTimestamp: json['BuildTimestamp'] as String?,
      sbomHash: json['SBOMHash'] as String?,
      permUsed: _asInt(json['PermUsed']),
      permAvail: _asInt(json['PermAvail']),
      permTotal: _asInt(json['PermTotal']),
      privateAddrs: _asList(json['PrivateAddrs']).map((e) => '$e').toList(),
      publicAddrs: _asList(json['PublicAddrs']).map((e) => '$e').toList(),
      memTotal: _asInt(meminfo['MemTotal']),
      memAvailable: _asInt(meminfo['MemAvailable']),
    );
  }
}

class GokrazyService {
  const GokrazyService({
    required this.path,
    required this.stopped,
    this.pid,
    this.startTime,
    this.args = const [],
  });

  final String path;
  final bool stopped;
  final int? pid;
  final String? startTime;
  final List<String> args;

  bool get running => !stopped && (pid ?? 0) > 0;
  String get name => path.split('/').where((part) => part.isNotEmpty).lastOrNull ?? path;

  factory GokrazyService.fromJson(Map<String, Object?> json) {
    return GokrazyService(
      path: json['Path'] as String? ?? 'unknown',
      stopped: json['Stopped'] == true,
      pid: _asInt(json['Pid']),
      startTime: json['StartTime'] as String?,
      args: _asList(json['Args']).map((e) => '$e').toList(),
    );
  }
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
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

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

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
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      final response = await request.close();
      final body = response.transform(utf8.decoder).transform(const LineSplitter());

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

  Future<void> uploadRoot({
    required Stream<List<int>> stream,
    required int size,
    required void Function(int sent, int total) onProgress,
  }) async {
    String? untrustedFingerprint;
    final client = _httpClient(
      onBadCertificate: (fingerprint) => untrustedFingerprint = fingerprint,
    );
    try {
      final request = await client.putUrl(_uri('update/root'));
      _setHeaders(request);

      var sent = 0;
      final output = AccumulatorSink<Digest>();
      final input = sha256.startChunkedConversion(output);
      final hashingStream = stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            input.add(chunk);
            onProgress(sent, size);
            sink.add(chunk);
          },
          handleDone: (sink) {
            input.close();
            sink.close();
          },
        ),
      );

      await request.addStream(hashingStream);
      final response = await request.close();
      final body = (await response.transform(utf8.decoder).join()).trim();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }
      final localHash = output.events.single.toString();
      if (body != localHash) {
        throw StateError('Checksum mismatch: device returned $body, sent $localHash');
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
      final request = await client.postUrl(_uri(endpoint).replace(queryParameters: params));
      request.headers.set(HttpHeaders.cookieHeader, 'gokrazy_xsrf=$xsrf');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      _setHeaders(request, keepJsonAccept: false);
      final response = await request.close();
      final body = (await response.transform(utf8.decoder).join()).trim();
      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.seeOther) {
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
    final request = await client.getUrl(_uri('status').replace(queryParameters: {'path': path}));
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
          .firstWhere((entry) => entry.startsWith('gokrazy_xsrf='), orElse: () => '');
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InstanceRepository? _repo;
  List<GokrazyInstance> _instances = [];
  final Map<String, GokrazyStatus> _statuses = {};
  final Map<String, String> _errors = {};
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await InstanceRepository.open();
    final instances = repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _repo = repo;
      _instances = instances;
      _selectedId = instances.isEmpty ? null : instances.first.id;
      _loading = false;
    });
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    for (final instance in _instances) {
      unawaited(_refresh(instance));
    }
  }

  Future<void> _refresh(GokrazyInstance instance) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      setState(() => _errors[instance.id] = 'Missing password');
      return;
    }
    try {
      final status = await GokrazyClient(
        instance: instance,
        password: password,
      ).fetchStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _statuses[instance.id] = status;
        _errors.remove(instance.id);
      });
      await _markSeen(instance);
    } on CertificatePinRequired catch (error) {
      if (!mounted) {
        return;
      }
      final accepted = await _confirmCertificate(error.fingerprint);
      if (accepted) {
        await _saveInstance(
          instance.copyWith(pinnedFingerprint: error.fingerprint),
          password: password,
          stayOnPage: true,
        );
      } else if (mounted) {
        setState(() => _errors[instance.id] = 'Certificate not trusted');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errors[instance.id] = error.toString());
    }
  }

  Future<void> _markSeen(GokrazyInstance instance) async {
    final updated = instance.copyWith(lastSeen: DateTime.now());
    final next = _instances
        .map((entry) => entry.id == updated.id ? updated : entry)
        .toList();
    await _repo?.saveAll(next);
    if (mounted) {
      setState(() => _instances = next);
    }
  }

  Future<void> _saveInstance(
    GokrazyInstance instance, {
    required String password,
    bool stayOnPage = false,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    final exists = _instances.any((entry) => entry.id == instance.id);
    final next = exists
        ? _instances.map((entry) => entry.id == instance.id ? instance : entry).toList()
        : [..._instances, instance];
    await repo.saveAll(next);
    await repo.upsertPassword(instance.id, password);
    if (!mounted) {
      return;
    }
    setState(() {
      _instances = next;
      if (!stayOnPage) {
        _selectedId = instance.id;
      }
    });
    await _refresh(instance);
  }

  Future<void> _deleteInstance(GokrazyInstance instance) async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${instance.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final next = _instances.where((entry) => entry.id != instance.id).toList();
    await repo.saveAll(next);
    await repo.deletePassword(instance.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _instances = next;
      _statuses.remove(instance.id);
      _errors.remove(instance.id);
      _selectedId = next.isEmpty ? null : next.first.id;
    });
  }

  Future<bool> _confirmCertificate(String fingerprint) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trust certificate?'),
        content: SelectableText(fingerprint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Trust'),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  Future<void> _openEditor([GokrazyInstance? instance]) async {
    final password = instance == null
        ? ''
        : await _repo?.passwordFor(instance.id) ?? '';
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => InstanceEditor(
        instance: instance,
        password: password,
        onSave: (next, password) => _saveInstance(next, password: password),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _instances
        .where((entry) => entry.id == _selectedId)
        .firstOrNull;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff081226),
            Color(0xff0f1d38),
            Color(0xff0b1224),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add instance'),
          tooltip: 'Add instance',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBar: AppBar(
          title: const Text('Gokrazy Manager'),
          leading: _instances.isNotEmpty
              ? IconButton(
                  tooltip: 'Refresh selected',
                  onPressed: selected == null ? null : () => _refresh(selected),
                  icon: const Icon(Icons.refresh_rounded),
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Refresh all',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : _instances.isEmpty
                  ? EmptyState(onAdd: () => _openEditor())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        final list = Card(
                          margin: const EdgeInsets.only(
                            left: 14,
                            right: 12,
                            top: 12,
                            bottom: 12,
                          ),
                          child: InstanceList(
                            instances: _instances,
                            statuses: _statuses,
                            errors: _errors,
                            selectedId: _selectedId,
                            onSelect: (id) => setState(() => _selectedId = id),
                            onRefresh: _refresh,
                          ),
                        );
                        final detail = selected == null
                            ? const SizedBox.shrink()
                            : InstanceDetail(
                                instance: selected,
                                status: _statuses[selected.id],
                                error: _errors[selected.id],
                                onEdit: () => _openEditor(selected),
                                onDelete: () => _deleteInstance(selected),
                                onRefresh: () => _refresh(selected),
                                onPinned: (fingerprint) async {
                                  final password = await _repo?.passwordFor(selected.id) ?? '';
                                  await _saveInstance(
                                    selected.copyWith(pinnedFingerprint: fingerprint),
                                    password: password,
                                    stayOnPage: true,
                                  );
                                },
                              );
                        if (!wide) {
                          return Column(
                            children: [
                              SizedBox(height: 226, child: list),
                              const Divider(height: 1),
                              Expanded(child: detail),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 360, child: list),
                            const VerticalDivider(width: 1),
                            Expanded(child: detail),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class InstanceEditor extends StatefulWidget {
  const InstanceEditor({
    required this.instance,
    required this.password,
    required this.onSave,
    super.key,
  });

  final GokrazyInstance? instance;
  final String password;
  final Future<void> Function(GokrazyInstance instance, String password) onSave;

  @override
  State<InstanceEditor> createState() => _InstanceEditorState();
}

class _InstanceEditorState extends State<InstanceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _saving = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.instance?.name ?? '');
    _url = TextEditingController(text: widget.instance?.baseUrl ?? 'https://');
    _username = TextEditingController(text: widget.instance?.username ?? 'gokrazy');
    _password = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final current = widget.instance;
    final instance = GokrazyInstance(
      id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      baseUrl: normalizeUrl(_url.text),
      username: _username.text.trim(),
      pinnedFingerprint: current?.pinnedFingerprint,
      lastSeen: current?.lastSeen,
    );
    try {
      await widget.onSave(instance, _password.text);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, inset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.instance == null ? 'Add instance' : 'Edit instance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'URL',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                final uri = Uri.tryParse(normalizeUrl(value));
                if (uri == null || !uri.hasAuthority) {
                  return 'Invalid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              obscureText: !_showPassword,
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Credentials are encrypted by platform secure storage.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.cloud_queue_rounded, size: 48),
                ),
                const SizedBox(height: 18),
                Text(
                  'No Gokrazy instances yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add an appliance URL and credentials to monitor services, logs, and updates in one place.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Create first instance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InstanceList extends StatelessWidget {
  const InstanceList({
    required this.instances,
    required this.statuses,
    required this.errors,
    required this.selectedId,
    required this.onSelect,
    required this.onRefresh,
    super.key,
  });

  final List<GokrazyInstance> instances;
  final Map<String, GokrazyStatus> statuses;
  final Map<String, String> errors;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<GokrazyInstance> onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            'Instances',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            itemCount: instances.length,
            itemBuilder: (context, index) {
              final instance = instances[index];
              final status = statuses[instance.id];
              final error = errors[instance.id];
              final selected = selectedId == instance.id;
              final isHealthy = status != null && error == null;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
                  ),
                ),
                child: ListTile(
                  onTap: () => onSelect(instance.id),
                  selected: selected,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  leading: StatusDot(ok: isHealthy),
                  title: Text(
                    instance.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: status == null
                      ? Text(instance.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : Text(
                          '${status.runningServices}/${status.services.length} services running',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => onRefresh(instance),
                    icon: const Icon(Icons.sync_rounded, size: 20),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class InstanceDetail extends StatefulWidget {
  const InstanceDetail({
    required this.instance,
    required this.status,
    required this.error,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onPinned,
    super.key,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final String? error;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final Future<void> Function(String fingerprint) onPinned;

  @override
  State<InstanceDetail> createState() => _InstanceDetailState();
}

class _InstanceDetailState extends State<InstanceDetail> {
  double? _uploadProgress;
  bool _busy = false;
  String? _uploadMessage;

  Future<void> _uploadSquashfs() async {
    final repo = await InstanceRepository.open();
    final password = await repo.passwordFor(widget.instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['squashfs', 'img', 'bin'],
      withReadStream: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return;
    }
    final stream = file.readStream ?? (file.path == null ? null : File(file.path!).openRead());
    if (stream == null) {
      _showSnack('Cannot read selected file');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flash root squashfs?'),
        content: Text(file.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Flash'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _busy = true;
      _uploadProgress = 0;
      _uploadMessage = 'Uploading ${file.name}';
    });
    try {
      await GokrazyClient(instance: widget.instance, password: password).uploadRoot(
        stream: stream,
        size: file.size,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
      if (mounted) {
        setState(() => _uploadMessage = 'Upload verified');
      }
    } on CertificatePinRequired catch (error) {
      await widget.onPinned(error.fingerprint);
      _showSnack('Certificate pinned. Try upload again.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _runAction(String label, Future<void> Function(GokrazyClient client) action) async {
    final repo = await InstanceRepository.open();
    final password = await repo.passwordFor(widget.instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    setState(() => _busy = true);
    try {
      await action(GokrazyClient(instance: widget.instance, password: password));
      _showSnack(label);
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _runServiceAction(
    String label,
    GokrazyService service,
    Future<void> Function(GokrazyClient client) action,
  ) async {
    await _runAction(label, (client) => action(client));
    if (mounted) {
      widget.onRefresh();
    }
  }

  Future<void> _openServiceLogs(GokrazyService service) async {
    final repo = await InstanceRepository.open();
    final password = await repo.passwordFor(widget.instance.id);
    if (password == null) {
      _showSnack('Missing password');
      return;
    }
    if (!mounted) {
      return;
    }
    final stream = GokrazyClient(instance: widget.instance, password: password)
        .serviceLogStream(path: service.path, stream: 'both');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
                builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<String>(
                stream: stream,
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('${service.name} logs',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xff0b1021),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              controller: controller,
                              child: SelectableText(
                                snapshot.data ?? 'Connecting...',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _InstanceHeaderCard(
            instance: widget.instance,
            status: status,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onRefresh: () => widget.onRefresh(),
            hasError: widget.error != null,
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: widget.error!),
          ],
          const SizedBox(height: 16),
          if (status == null)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else ...[
            OverviewCard(status: status),
            const SizedBox(height: 12),
            ResourceCard(status: status),
            const SizedBox(height: 12),
            FlashCard(
              busy: _busy,
              progress: _uploadProgress,
              message: _uploadMessage,
              onUpload: _uploadSquashfs,
              onTestboot: () => _runAction('Test boot marked', (client) => client.testboot()),
              onSwitch: () => _runAction('Root switched', (client) => client.switchRoot()),
              onReboot: () => _runAction('Reboot requested', (client) => client.reboot()),
            ),
            const SizedBox(height: 12),
            ServicesCard(
              services: status.services,
              onStart: (service) => _runServiceAction(
                'Service started',
                service,
                (client) => client.startService(service.path),
              ),
              onStop: (service) => _runServiceAction(
                'Service stopped',
                service,
                (client) => client.stopService(service.path),
              ),
              onRestart: (service) => _runServiceAction(
                'Service restarted',
                service,
                (client) => client.restartService(service.path),
              ),
              onLogs: _openServiceLogs,
            ),
          ],
        ],
      ),
    );
  }
}

class _InstanceHeaderCard extends StatelessWidget {
  const _InstanceHeaderCard({
    required this.instance,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.hasError,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final runningServices = status?.services.where((service) => service.running).length ?? 0;
    final totalServices = status?.services.length ?? 0;
    final stopped = hasError || status == null;
    final lastSeenText = instance.lastSeen == null
        ? 'Never checked'
        : 'Last checked ${_timeAgo(instance.lastSeen!)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(instance.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(instance.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(lastSeenText, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync_rounded),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: stopped ? Icons.wifi_off : Icons.wifi,
                  label: stopped ? 'Connection issue' : 'Connected',
                  color: stopped ? Colors.red : Colors.green,
                ),
                if (status != null)
                  _StatusChip(
                  icon: Icons.miscellaneous_services,
                  label: 'Services $runningServices/$totalServices',
                  color: Colors.blueGrey,
                ),
                if (status?.hostname != null && status!.hostname!.isNotEmpty)
                  _StatusChip(
                    icon: Icons.computer,
                    label: status!.hostname!,
                    color: Colors.indigo,
                  ),
                if (status?.kernel != null && status!.kernel!.isNotEmpty)
                  _StatusChip(
                    icon: Icons.memory_outlined,
                    label: status!.kernel!,
                    color: Colors.orange.shade700,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(color: color.withValues(alpha: 0.95), fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}

String _timeAgo(DateTime value) {
  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inSeconds < 60) {
    return '${diff.inSeconds}s ago';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({required this.status, super.key});

  final GokrazyStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (status.publicAddrs.isNotEmpty || status.privateAddrs.isNotEmpty)
                  const Icon(Icons.route_outlined, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(icon: Icons.memory, label: 'Model', value: status.model ?? 'Unknown'),
            InfoRow(icon: Icons.terminal, label: 'Kernel', value: status.kernel ?? 'Unknown'),
            InfoRow(icon: Icons.badge_outlined, label: 'Host', value: status.hostname ?? 'Unknown'),
            if (status.buildTimestamp != null)
              InfoRow(
                icon: Icons.schedule,
                label: 'Build',
                value: status.buildTimestamp!,
              ),
            if (status.sbomHash != null)
              InfoRow(icon: Icons.fingerprint, label: 'SBOM', value: status.sbomHash!),
            if (status.privateAddrs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Private addresses', style: Theme.of(context).textTheme.labelLarge),
            ],
            if (status.privateAddrs.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...status.privateAddrs.map(
                    (addr) => Chip(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      avatar: const Icon(Icons.lan, size: 16),
                      label: Text(addr),
                    ),
                  ),
                ],
              ),
            if (status.publicAddrs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Public addresses', style: Theme.of(context).textTheme.labelLarge),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...status.publicAddrs.map(
                  (addr) => Chip(
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    label: Text(addr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResourceCard extends StatelessWidget {
  const ResourceCard({required this.status, super.key});

  final GokrazyStatus status;

  @override
  Widget build(BuildContext context) {
    final permTotal = status.permTotal ?? 0;
    final permUsed = status.permUsed ?? 0;
    final memTotal = status.memTotal ?? 0;
    final memUsed = memTotal - (status.memAvailable ?? 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resources', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (permTotal > 0)
              Text('Persistent data ${_percent(permUsed, permTotal)}', style: Theme.of(context).textTheme.bodySmall),
            Meter(
              label: 'Persistent data',
              used: permUsed,
              total: permTotal,
            ),
            const SizedBox(height: 14),
            if (memTotal > 0)
              Text('Memory ${_percent(memUsed, memTotal)}', style: Theme.of(context).textTheme.bodySmall),
            Meter(
              label: 'Memory',
              used: memUsed,
              total: memTotal,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usage is computed from available memory + persistent volume and updates every status refresh.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FlashCard extends StatelessWidget {
  const FlashCard({
    required this.busy,
    required this.progress,
    required this.message,
    required this.onUpload,
    required this.onTestboot,
    required this.onSwitch,
    required this.onReboot,
    super.key,
  });

  final bool busy;
  final double? progress;
  final String? message;
  final VoidCallback onUpload;
  final VoidCallback onTestboot;
  final VoidCallback onSwitch;
  final VoidCallback onReboot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(value: progress),
              ),
              const SizedBox(height: 8),
              Text(message ?? 'Uploading'),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Squashfs'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : onTestboot,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Test boot',
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : onSwitch,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Switch',
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : onReboot,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reboot',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('Advanced actions', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ServicesCard extends StatelessWidget {
  const ServicesCard({
    required this.services,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onLogs,
    super.key,
  });

  final List<GokrazyService> services;
  final ValueChanged<GokrazyService> onStart;
  final ValueChanged<GokrazyService> onStop;
  final ValueChanged<GokrazyService> onRestart;
  final ValueChanged<GokrazyService> onLogs;

  @override
  Widget build(BuildContext context) {
    final serviceCount = services.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Services', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (serviceCount > 0)
                  Text(
                    '$serviceCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (services.isEmpty) ...[
              const SizedBox(height: 4),
              Text('No services found', style: Theme.of(context).textTheme.bodyMedium),
            ],
            ...services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: StatusDot(ok: service.running),
                          title: Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(service.stopped
                              ? 'Stopped'
                              : 'PID ${service.pid ?? '-'} • started ${service.startTime ?? 'unknown'}'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Tooltip(
                              message: service.stopped ? 'Start' : 'Stop',
                              child: FilledButton.tonal(
                                onPressed: () => service.stopped ? onStart(service) : onStop(service),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  minimumSize: const Size(0, 38),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(service.stopped ? Icons.play_arrow : Icons.stop, size: 18),
                                    const SizedBox(width: 6),
                                    Text(service.stopped ? 'Start' : 'Stop'),
                                  ],
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Restart',
                              child: FilledButton.tonal(
                                onPressed: () => onRestart(service),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  minimumSize: const Size(0, 38),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 18),
                                    SizedBox(width: 6),
                                    Text('Restart'),
                                  ],
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Logs',
                              child: FilledButton.tonal(
                                onPressed: () => onLogs(service),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  minimumSize: const Size(0, 38),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.terminal, size: 18),
                                    SizedBox(width: 6),
                                    Text('Logs'),
                                  ],
                                ),
                              ),
                            ),
                            if (service.args.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _showServiceArgs(context, service),
                                icon: const Icon(Icons.tune, size: 16),
                                label: Text('Args ${service.args.length}'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showServiceArgs(BuildContext context, GokrazyService service) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('${service.name} args'),
        content: SelectableText(service.args.join('\n')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class Meter extends StatelessWidget {
  const Meter({
    required this.label,
    required this.used,
    required this.total,
    super.key,
  });

  final String label;
  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
            Text('${_bytes(used)} / ${_bytes(total)}'),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 450),
              tween: Tween<double>(begin: 0, end: value),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => LinearProgressIndicator(
                value: animatedValue,
                minHeight: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.34),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              SizedBox(width: 90, child: Text(label)),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({required this.ok, super.key});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: ok ? const Color(0xff10b981) : const Color(0xffef4444),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (ok ? const Color(0xff10b981) : const Color(0xffef4444)).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

String _bytes(int bytes) {
  if (bytes <= 0) {
    return '-';
  }
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
}

String _percent(int used, int total) {
  if (total <= 0) {
    return '0%';
  }
  final value = (used / total * 100).clamp(0.0, 100.0);
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}%';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
