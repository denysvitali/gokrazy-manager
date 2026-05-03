import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:convert/convert.dart' show AccumulatorSink;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 28.0;
}

class AppSeedColors {
  static const Color darkSurface = Color.fromARGB(255, 11, 16, 32);
  static const Color seed = Color.fromARGB(255, 15, 79, 103);
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 320);
}

class AppBreakpoints {
  static const double tablet = 700.0;
  static const double desktop = 1024.0;
}

enum AppThemeVariant {
  system,
  light,
  dark,
  amoledBlack,
}

const String _themePreferenceKey = 'theme_variant';
final ValueNotifier<AppThemeVariant> _themeVariant = ValueNotifier(AppThemeVariant.system);

Future<void> _loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_themePreferenceKey);
  if (raw == null) {
    return;
  }
  try {
    _themeVariant.value = AppThemeVariant.values.byName(raw);
  } catch (_) {
    // Ignore older or unknown preference values.
  }
}

Future<void> _saveThemePreference(AppThemeVariant value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themePreferenceKey, value.name);
}

ThemeData _buildTheme(Brightness brightness, {bool amoledBlack = false}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppSeedColors.seed,
    brightness: brightness,
  );
  final textTheme = ThemeData(brightness: brightness).textTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 57, fontWeight: FontWeight.w700),
        displayMedium: const TextStyle(fontSize: 45, fontWeight: FontWeight.w700),
        displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
        bodySmall: const TextStyle(fontSize: 12, height: 1.35),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      );
  final pageBg = (brightness == Brightness.dark && amoledBlack)
      ? Colors.black
      : brightness == Brightness.dark
          ? AppSeedColors.darkSurface
          : colorScheme.surface;
  final cardBg = colorScheme.surfaceContainerHighest.withOpacity(0.9);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: pageBg,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      surfaceTintColor: colorScheme.primary.withOpacity(0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: pageBg,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: AppSpacing.xxl,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.xs)),
        minimumSize: const WidgetStatePropertyAll(Size(AppSpacing.xxl, AppSpacing.xxl)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, AppSpacing.xxl),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, AppSpacing.xxl),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withOpacity(0.4),
      space: 0,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadThemePreference();
  runApp(const GokrazyManagerApp());
}

final _appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const HomePage(initialNavIndex: 1),
    ),
    GoRoute(
      path: '/instance/:instanceId',
      builder: (context, state) => HomePage(
        initialNavIndex: 0,
        initialInstanceId: state.pathParameters['instanceId'],
      ),
    ),
  ],
  errorBuilder: (context, state) => const HomePage(),
);

class GokrazyManagerApp extends StatelessWidget {
  const GokrazyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeVariant>(
      valueListenable: _themeVariant,
      builder: (context, value, child) {
        final dark = value == AppThemeVariant.dark || value == AppThemeVariant.amoledBlack;
        final amoled = value == AppThemeVariant.amoledBlack;
        final themeMode = value == AppThemeVariant.light
            ? ThemeMode.light
            : dark
                ? ThemeMode.dark
                : ThemeMode.system;
        return MaterialApp.router(
          title: 'Gokrazy Manager',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark, amoledBlack: amoled),
          themeMode: themeMode,
          routerConfig: _appRouter,
        );
      },
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
    bool decompress = false,
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

      Stream<List<int>> uploadStream = stream;
      if (decompress) {
        uploadStream = stream.transform(io.gzip.decoder);
      }

      final hashed = uploadStream.map((chunk) {
        sent += chunk.length;
        input.add(chunk);
        onProgress(sent, size);
        return chunk;
      });

      await request.addStream(hashed);
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
  const HomePage({
    this.initialNavIndex = 0,
    this.initialInstanceId,
    super.key,
  });

  final int initialNavIndex;
  final String? initialInstanceId;

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
  int _activeNavIndex = 0;
  final Set<String> _statusLoading = {};

  @override
  void initState() {
    super.initState();
    _activeNavIndex = widget.initialNavIndex;
    _load();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNavIndex != oldWidget.initialNavIndex ||
        widget.initialInstanceId != oldWidget.initialInstanceId) {
      setState(() {
        _activeNavIndex = widget.initialNavIndex;
      });
      final resolved = _resolveSelectedId(widget.initialInstanceId);
      if (_selectedId != resolved) {
        setState(() => _selectedId = resolved);
      }
    }
  }

  String? _resolveSelectedId(String? requestedId) {
    if (requestedId != null && _instances.any((entry) => entry.id == requestedId)) {
      return requestedId;
    }
    if (_selectedId != null && _instances.any((entry) => entry.id == _selectedId)) {
      return _selectedId;
    }
    if (_instances.isEmpty) {
      return null;
    }
    return _instances.first.id;
  }

  void _syncRouteTab(int index) {
    setState(() => _activeNavIndex = index);
    if (index == 1) {
      context.go('/settings');
    } else {
      context.go(_selectedId == null ? '/' : '/instance/$_selectedId');
    }
  }

  void _selectInstance(String id) {
    if (!mounted) {
      return;
    }
    if (!_instances.any((entry) => entry.id == id)) {
      return;
    }
    setState(() {
      _activeNavIndex = 0;
      _selectedId = id;
    });
    context.go('/instance/$id');
  }

  Future<void> _persistRouteForSelection() async {
    if (_activeNavIndex == 1) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (_selectedId == null) {
      context.go('/');
      return;
    }
    context.go('/instance/$_selectedId');
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
      _selectedId = _resolveSelectedId(widget.initialInstanceId);
      _loading = false;
    });
    await _refreshAll();
    await _persistRouteForSelection();
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
    setState(() => _statusLoading.add(instance.id));
    if (_errors[instance.id] != null) {
      _errors.remove(instance.id);
    }
    final password = await repo.passwordFor(instance.id);
    if (password == null) {
      setState(() => _errors[instance.id] = 'Missing password');
      setState(() => _statusLoading.remove(instance.id));
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
    } finally {
      if (mounted) {
        setState(() => _statusLoading.remove(instance.id));
      }
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
        _activeNavIndex = 0;
      }
    });
    if (!stayOnPage) {
      await _persistRouteForSelection();
    }
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
    if (_activeNavIndex == 0) {
      await _persistRouteForSelection();
    }
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
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final selected = _instances
        .where((entry) => entry.id == _selectedId)
        .firstOrNull;
    final rail = _instances.isNotEmpty
        ? MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop
        : false;

    final content = AnimatedSwitcher(
      duration: reducedMotion ? Duration.zero : AppMotion.normal,
      child: _loading
          ? const HomeSkeletonList()
          : _activeNavIndex == 1
              ? const _SettingsPanel()
              : _buildMainContent(context, selected),
    );

    if (rail) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            selectedIndex: _activeNavIndex,
            onDestinationSelected: _syncRouteTab,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: _appBar(selected),
              floatingActionButton: _activeNavIndex == 0
                  ? _buildAddButton()
                  : null,
              body: content,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: _appBar(selected),
      floatingActionButton: _activeNavIndex == 0 ? _buildAddButton() : null,
      body: content,
      bottomNavigationBar: Semantics(
        label: 'Main navigation',
        child: NavigationBar(
          selectedIndex: _activeNavIndex,
          onDestinationSelected: _syncRouteTab,
          destinations: [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(GokrazyInstance? selected) {
    return AppBar(
      title: const Text('Gokrazy Manager'),
      leading: _activeNavIndex == 0 && _instances.isNotEmpty
          ? Semantics(
              label: 'Refresh selected instance',
              button: true,
              child: IconButton(
                tooltip: 'Refresh selected',
                onPressed: selected == null ? null : () => _refresh(selected),
                icon: const Icon(Icons.refresh_rounded),
              ),
            )
          : null,
      actions: [
        if (_activeNavIndex == 0)
          Semantics(
            label: 'Refresh all instances',
            button: true,
            child: IconButton(
              tooltip: 'Refresh all',
              onPressed: _loading ? null : _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: () => _openEditor(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add instance'),
      tooltip: 'Add instance',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    );
  }

  Widget _buildMainContent(BuildContext context, GokrazyInstance? selected) {
    if (_instances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xxl,
          ),
          child: EmptyState(onAdd: () => _openEditor()),
        ),
      );
    }

    final list = InstanceList(
      instances: _instances,
      statuses: _statuses,
      errors: _errors,
      selectedId: _selectedId,
      loadingIds: _statusLoading,
      onSelect: _selectInstance,
      onRefresh: _refresh,
    );
    final detail = selected == null
        ? const _NoSelectionPlaceholder()
        : InstanceDetail(
            instance: selected,
            status: _statuses[selected.id],
            statusLoading: _statusLoading.contains(selected.id),
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

    if (_activeNavIndex != 0) {
      return const SizedBox.shrink();
    }

    if (MediaQuery.sizeOf(context).width < AppBreakpoints.tablet) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              height: 280,
              child: list,
            ),
            const SizedBox(height: AppSpacing.m),
            Expanded(child: detail),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: list),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: detail),
        ],
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
      padding: EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, inset + AppSpacing.m),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.instance == null ? 'Add instance' : 'Edit instance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.s),
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
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.s),
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
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Credentials are encrypted by platform secure storage.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Save instance',
                button: true,
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
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.xl,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: AppSpacing.l,
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurface,
                  child: const Icon(Icons.cloud_queue_rounded, size: 32),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'No instances yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add an appliance URL and credentials to monitor services, logs, and updates in one place.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.m),
                FilledButton(
                  onPressed: onAdd,
                  child: const Text('Create first instance'),
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
    required this.loadingIds,
    required this.onSelect,
    required this.onRefresh,
    super.key,
  });

  final List<GokrazyInstance> instances;
  final Map<String, GokrazyStatus> statuses;
  final Map<String, String> errors;
  final String? selectedId;
  final Set<String> loadingIds;
  final ValueChanged<String> onSelect;
  final ValueChanged<GokrazyInstance> onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Text(
            'Instances',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Expanded(
          child: Card(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              itemCount: instances.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (context, index) {
                final instance = instances[index];
                final status = statuses[instance.id];
                final error = errors[instance.id];
                final selected = selectedId == instance.id;
                final isLoading = loadingIds.contains(instance.id);
                final isHealthy = status != null && error == null;
                return Semantics(
                  label: '${instance.name}, open details',
                  selected: selected,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelect(instance.id),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected
                              ? colors.primary.withOpacity(0.55)
                              : colors.outline.withOpacity(0.28),
                        ),
                        color: selected
                            ? colors.primaryContainer.withOpacity(0.45)
                            : null,
                      ),
                      child: ListTile(
                        onTap: () => onSelect(instance.id),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xs,
                        ),
                        leading: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    error == null ? colors.primary : colors.error,
                                  ),
                                ),
                              )
                            : Hero(
                                tag: 'status-dot-${instance.id}',
                                child: StatusDot(ok: isHealthy),
                              ),
                        title: Hero(
                          tag: 'instance-${instance.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              instance.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                        subtitle: status == null
                            ? Text(
                                isLoading ? 'Refreshing...' : instance.baseUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                '${status.runningServices}/${status.services.length} services running',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Semantics(
                          label: 'Refresh ${instance.name}',
                          button: true,
                          child: IconButton(
                            tooltip: 'Refresh',
                            onPressed: () => onRefresh(instance),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
    required this.statusLoading,
    required this.error,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onPinned,
    super.key,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final bool statusLoading;
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
      allowedExtensions: const ['squashfs', 'squashfs.gz', 'img', 'bin'],
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
    final isGzipped = file.name.endsWith('.squashfs.gz') || file.name.endsWith('.img.gz') || file.name.endsWith('.bin.gz');
    setState(() {
      _busy = true;
      _uploadProgress = 0;
      _uploadMessage = 'Uploading ${file.name}${isGzipped ? ' (decompressing)' : ''}';
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
              padding: const EdgeInsets.all(AppSpacing.m),
              child: StreamBuilder<String>(
                stream: stream,
                builder: (context, snapshot) {
                  final colors = Theme.of(context).colorScheme;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${service.name} logs',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Semantics(
                            label: 'Close logs',
                            button: true,
                            child: IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            child: SingleChildScrollView(
                              controller: controller,
                              child: SelectableText(
                                snapshot.data ?? 'Connecting...',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
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
    final loading = widget.statusLoading && status == null;
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.xs,
          AppSpacing.m,
          AppSpacing.l,
        ),
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
          if (loading)
            const _DetailSkeleton()
          else if (status == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: NoDataState(message: 'No status available for this instance.'),
              ),
            )
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
    final colors = Theme.of(context).colorScheme;
    final lastSeenText = instance.lastSeen == null
        ? 'Never checked'
        : 'Last checked ${_timeAgo(instance.lastSeen!)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
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
                      const SizedBox(height: AppSpacing.xs),
                      Text(instance.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Text(lastSeenText, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync_rounded),
                  color: colors.onSurfaceVariant,
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: colors.onSurfaceVariant,
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: colors.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _StatusChip(
                  icon: stopped ? Icons.wifi_off : Icons.wifi,
                  label: stopped ? 'Connection issue' : 'Connected',
                  tone: stopped ? ConnectionTone.error : ConnectionTone.success,
                ),
                if (status != null)
                  _StatusChip(
                  icon: Icons.miscellaneous_services,
                  label: 'Services $runningServices/$totalServices',
                  tone: ConnectionTone.info,
                ),
                if (status?.hostname != null && status!.hostname!.isNotEmpty)
                  _StatusChip(
                    icon: Icons.computer,
                    label: status!.hostname!,
                    tone: ConnectionTone.primary,
                  ),
                if (status?.kernel != null && status!.kernel!.isNotEmpty)
                  _StatusChip(
                    icon: Icons.memory_outlined,
                    label: status!.kernel!,
                    tone: ConnectionTone.secondary,
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
    required this.tone,
  });

  final IconData icon;
  final String label;
  final ConnectionTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (tone) {
      ConnectionTone.success => (colors.tertiaryContainer, colors.onTertiaryContainer),
      ConnectionTone.error => (colors.errorContainer, colors.onErrorContainer),
      ConnectionTone.info => (colors.secondaryContainer, colors.onSecondaryContainer),
      ConnectionTone.primary => (colors.primaryContainer, colors.onPrimaryContainer),
      ConnectionTone.secondary => (colors.surfaceContainerHighest, colors.onSurface),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: foreground),
      label: Text(label),
      side: BorderSide(color: background),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      backgroundColor: background.withOpacity(0.4),
    );
  }
}

enum ConnectionTone { success, error, info, primary, secondary }

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
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (status.publicAddrs.isNotEmpty || status.privateAddrs.isNotEmpty)
                  Icon(Icons.route_outlined, size: 18, color: colors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
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
              const SizedBox(height: AppSpacing.s),
              Text('Private addresses', style: Theme.of(context).textTheme.labelLarge),
            ],
            if (status.privateAddrs.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ...status.privateAddrs.map(
                    (addr) => Chip(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      avatar: Icon(Icons.lan, size: 16, color: colors.onSecondaryContainer),
                      label: Text(
                        addr,
                        style: TextStyle(color: colors.onSecondaryContainer),
                      ),
                    ),
                  ),
                ],
              ),
            if (status.publicAddrs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              Text('Public addresses', style: Theme.of(context).textTheme.labelLarge),
            ],
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ...status.publicAddrs.map(
                  (addr) => Chip(
                    backgroundColor: colors.tertiaryContainer,
                    label: Text(
                      addr,
                      style: TextStyle(color: colors.onTertiaryContainer),
                    ),
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
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resources', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.m),
            if (permTotal > 0)
              Text(
                'Persistent data ${_percent(permUsed, permTotal)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Meter(
              label: 'Persistent data',
              used: permUsed,
              total: permTotal,
            ),
            const SizedBox(height: AppSpacing.m),
            if (memTotal > 0)
              Text('Memory ${_percent(memUsed, memTotal)}', style: Theme.of(context).textTheme.bodySmall),
            Meter(
              label: 'Memory',
              used: memUsed,
              total: memTotal,
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, size: 18),
                const SizedBox(width: AppSpacing.xs),
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
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: LinearProgressIndicator(value: progress),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message ?? 'Uploading'),
              const SizedBox(height: AppSpacing.s),
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
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: busy ? null : onTestboot,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Test boot',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: busy ? null : onSwitch,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Switch',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: busy ? null : onReboot,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reboot',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
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
        padding: const EdgeInsets.all(AppSpacing.m),
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
            const SizedBox(height: AppSpacing.s),
            if (services.isEmpty)
              const Text('No services found', style: TextStyle(fontWeight: FontWeight.w500))
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, index) => _ServiceItem(
                  service: services[index],
                  onStart: onStart,
                  onStop: onStop,
                  onRestart: onRestart,
                  onLogs: onLogs,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.service,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onLogs,
  });

  final GokrazyService service;
  final ValueChanged<GokrazyService> onStart;
  final ValueChanged<GokrazyService> onStop;
  final ValueChanged<GokrazyService> onRestart;
  final ValueChanged<GokrazyService> onLogs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Hero(
                tag: 'service-${service.name}',
                child: StatusDot(ok: service.running),
              ),
              title: Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(service.stopped
                  ? 'Stopped'
                  : 'PID ${service.pid ?? '-'} • started ${service.startTime ?? 'unknown'}'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              alignment: WrapAlignment.start,
              children: [
                FilledButton.tonal(
                  onPressed: () => service.stopped ? onStart(service) : onStop(service),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: const Size(0, 38),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(service.stopped ? Icons.play_arrow : Icons.stop, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(service.stopped ? 'Start' : 'Stop'),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => onRestart(service),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: const Size(0, 38),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text('Restart'),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => onLogs(service),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: const Size(0, 38),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text('Logs'),
                    ],
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
    );
  }
}

class _NoSelectionPlaceholder extends StatelessWidget {
  const _NoSelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_rounded, size: 42),
              SizedBox(height: AppSpacing.s),
              Text('Select an instance to view details'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Adaptive navigation is enabled. Use this section for app preferences, diagnostics, or export tools.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.m),
              Text('Theme', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              ValueListenableBuilder<AppThemeVariant>(
                valueListenable: _themeVariant,
                builder: (context, selected, _) {
                  return SegmentedButton<AppThemeVariant>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeVariant.system,
                        icon: Icon(Icons.devices_other),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: AppThemeVariant.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: AppThemeVariant.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: AppThemeVariant.amoledBlack,
                        icon: Icon(Icons.nightlight_round),
                        label: Text('AMOLED'),
                      ),
                    ],
                    selected: {selected},
                    onSelectionChanged: (values) {
                      if (values.isNotEmpty) {
                        _themeVariant.value = values.first;
                        unawaited(_saveThemePreference(values.first));
                      }
                    },
                    showSelectedIcon: false,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.m),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: cs.onSurface),
                title: const Text('Data'),
                subtitle: const Text('Instances are stored locally'),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.storage, color: cs.onSurface),
                title: const Text('Storage'),
                subtitle: const Text('Credentials are kept in secure storage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSkeletonList extends StatelessWidget {
  const HomeSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          const SkeletonRow(height: 24, width: 130),
          const SizedBox(height: AppSpacing.s),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (_, __) => const Card(
                child: SkeletonRow(height: 72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Card(child: SkeletonRow(height: 138)),
        SizedBox(height: AppSpacing.s),
        Card(child: SkeletonRow(height: 140)),
        SizedBox(height: AppSpacing.s),
        Card(child: SkeletonRow(height: 120)),
        SizedBox(height: AppSpacing.s),
        Card(child: SkeletonRow(height: 120)),
      ],
    );
  }
}

class NoDataState extends StatelessWidget {
  const NoDataState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class SkeletonRow extends StatelessWidget {
  const SkeletonRow({required this.height, this.width = double.infinity, super.key});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      height: height,
      width: width,
      margin: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
            Text('${_bytes(used)} / ${_bytes(total)}'),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: AppSpacing.xs,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: colors.surface.withOpacity(0.35),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: TweenAnimationBuilder<double>(
              duration: AppMotion.normal,
              tween: Tween<double>(begin: 0, end: value),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => LinearProgressIndicator(
                value: animatedValue,
                minHeight: AppSpacing.xs,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.34),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.s,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 90,
                child: Text(label, style: Theme.of(context).textTheme.labelSmall),
              ),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.s),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: AppSpacing.xs,
      height: AppSpacing.xs,
      decoration: BoxDecoration(
        color: ok ? colors.primary : colors.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (ok ? colors.primary : colors.error).withOpacity(0.4),
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
