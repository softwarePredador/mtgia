import 'dart:io';

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

  group('ready route contract', () {
    test('/ready delegates to /health/ready handler', () {
      final route = File('routes/ready/index.dart').readAsStringSync();
      final contract =
          File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();

      expect(route, contains("import '../health/ready/index.dart'"));
      expect(route, contains('health_ready.onRequest(context)'));
      expect(
        contract,
        contains('| `GET /ready` | internal/stable ops alias |'),
      );
      expect(
        contract,
        isNot(contains('| `GET /ready` | internal/deprecated |')),
      );
    });

    test('readiness reports latency without leaking dependency exceptions', () {
      final route = File('routes/health/ready/index.dart').readAsStringSync();

      expect(route, contains('databaseStopwatch.elapsedMilliseconds'));
      expect(route, contains('cardsStopwatch.elapsedMilliseconds'));
      expect(route, contains("'error_code': 'database_check_failed'"));
      expect(route, contains("'error_code': 'cards_data_check_failed'"));
      expect(route, isNot(contains("'error': e.toString()")));
      expect(route, isNot(contains("'latency_ms': null")));
    });
  });
}
