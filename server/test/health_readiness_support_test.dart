import 'package:test/test.dart';

import '../lib/health_readiness_support.dart';

void main() {
  group('health_readiness_support', () {
    test('builds ready response body', () {
      final body = buildReadinessResponseBody(
        checks: const {
          'database': {'status': 'healthy'},
        },
        allHealthy: true,
        now: DateTime.parse('2026-03-24T00:00:00.000Z'),
        environment: 'staging',
      );

      expect(body['status'], equals('ready'));
      expect(body['service'], equals('mtgia-server'));
      expect(body['environment'], equals('staging'));
      expect(body['checks'], isA<Map<String, dynamic>>());
    });

    test('maps unhealthy readiness to 503', () {
      expect(readinessStatusCode(false), equals(503));
      expect(readinessStatusCode(true), equals(200));
    });
  });
}
