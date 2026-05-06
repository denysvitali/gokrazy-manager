import 'package:flutter_test/flutter_test.dart';
import 'package:gokrazy_manager/main.dart';

void main() {
  test('normalizes URLs to HTTPS', () {
    expect(normalizeUrl('gokrazy.local'), 'https://gokrazy.local');
    expect(normalizeUrl('http://gokrazy.local'), 'http://gokrazy.local');
  });

  test('parses gokrazy status JSON', () {
    final status = GokrazyStatus.fromJson({
      'Hostname': 'gokrazy',
      'Model': 'Raspberry Pi 5',
      'Kernel': 'Linux 6.12',
      'Uptime': 90000000000,
      'Services': [
        {'Path': '/user/hello', 'Pid': 42, 'Stopped': false},
        {'Path': '/user/off', 'Stopped': true},
      ],
      'Meminfo': {'MemTotal': 100, 'MemAvailable': 25},
    });

    expect(status.hostname, 'gokrazy');
    expect(status.services, hasLength(2));
    expect(status.runningServices, 1);
    expect(status.memAvailable, 25);
    expect(status.uptime, const Duration(seconds: 90));
  });

  test('parses uptime seconds', () {
    final status = GokrazyStatus.fromJson({
      'Services': [],
      'UptimeSeconds': '3661',
    });

    expect(status.uptime, const Duration(hours: 1, minutes: 1, seconds: 1));
  });
}
