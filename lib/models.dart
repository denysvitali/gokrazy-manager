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
    this.bootPart,
    this.upgradePart,
    this.uptime,
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
  final String? bootPart;
  final String? upgradePart;
  final Duration? uptime;

  int get runningServices => services.where((svc) => svc.running).length;
  int get totalServices => services.length;

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
      bootPart: json['BootPart'] as String?,
      upgradePart: json['UpgradePart'] as String?,
      uptime: _asDuration(json['Uptime']) ??
          _asDuration(json['UptimeSeconds']) ??
          _asDuration(json['UptimeNanos'], unit: _DurationUnit.nanoseconds),
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
  String get name =>
      path.split('/').where((part) => part.isNotEmpty).lastOrNull ?? path;

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

Duration? _asDuration(
  Object? value, {
  _DurationUnit unit = _DurationUnit.auto,
}) {
  final parsed = _asDouble(value);
  if (parsed == null || parsed < 0) {
    return null;
  }

  switch (unit) {
    case _DurationUnit.nanoseconds:
      return Duration(microseconds: (parsed / 1000).round());
    case _DurationUnit.auto:
      // Go's time.Duration marshals to nanoseconds. If gokrazy exposes uptime
      // as plain seconds instead, the value is small enough to keep as seconds.
      if (parsed > 1000000000) {
        return Duration(microseconds: (parsed / 1000).round());
      }
      return Duration(seconds: parsed.round());
  }
}

double? _asDouble(Object? value) {
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

enum _DurationUnit { auto, nanoseconds }
