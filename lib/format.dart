import 'package:flutter/material.dart';

String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '–';
  }
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
}

String formatPercent(num used, num total) {
  if (total <= 0) {
    return '0%';
  }
  final value = (used / total * 100).clamp(0.0, 100.0);
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}%';
}

String formatTimeAgo(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.isNegative) {
    return 'just now';
  }
  if (diff.inSeconds < 5) {
    return 'just now';
  }
  if (diff.inSeconds < 60) {
    return '${diff.inSeconds}s ago';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()}w ago';
  }
  return '${(diff.inDays / 30).floor()}mo ago';
}

String formatDurationCompact(Duration value) {
  final totalSeconds = value.inSeconds;
  if (totalSeconds < 60) {
    return '${totalSeconds}s';
  }

  final days = value.inDays;
  final hours = value.inHours.remainder(24);
  final minutes = value.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  return '${minutes}m';
}

/// Deterministic accent color derived from a string (instance id, hostname).
/// Returns a hue in [0, 360) so the surrounding theme can shape saturation.
double hueFromString(String value) {
  if (value.isEmpty) {
    return 220;
  }
  var hash = 0;
  for (final code in value.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}

/// Two-letter monogram for an instance name, e.g. "ws" -> "WS".
String monogramFor(String name) {
  final cleaned = name.trim();
  if (cleaned.isEmpty) {
    return '?';
  }
  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  if (cleaned.length == 1) {
    return cleaned.toUpperCase();
  }
  return cleaned.substring(0, 2).toUpperCase();
}

Color lerpAlpha(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}
