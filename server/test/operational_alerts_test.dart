import 'package:test/test.dart';

import '../lib/operational_alerts.dart';

void main() {
  group('operational alerts', () {
    test('keeps a healthy low-error snapshot green', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: {
          'totals': {'request_count': 100, 'error_rate': 0.01},
          'endpoints': {
            'GET /decks': {'request_count': 100, 'p95_latency_ms': 250},
          },
        },
        aiJobs: {
          'status': 'ok',
          'active_total': 0,
          'completed_24h': 20,
          'failed_24h': 0,
          'oldest_active_seconds': 0,
        },
        aiCost: {'status': 'ok', 'total_calls': 20, 'errors': 0},
      );

      expect(result['status'], equals('ok'));
      expect(result['alert_count'], equals(0));
      expect(result['thresholds_version'], operationalAlertThresholdsVersion);
    });

    test('raises critical HTTP and endpoint latency alerts', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: {
          'totals': {'request_count': 100, 'error_rate': 0.20},
          'endpoints': {
            'GET /decks': {'request_count': 25, 'p95_latency_ms': 15000},
          },
        },
        aiJobs: const {'status': 'not_initialized'},
        aiCost: const {'status': 'not_initialized'},
      );
      final alerts = result['alerts'] as List<Object?>;
      final codes =
          alerts
              .cast<Map<String, Object>>()
              .map((alert) => alert['code'])
              .toSet();

      expect(result['status'], equals('critical'));
      expect(codes, contains('http_5xx_rate_critical'));
      expect(codes, contains('endpoint_p95_critical:GET /decks'));
    });

    test('raises actionable AI heartbeat and provider alerts', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: const {
          'totals': {'request_count': 0, 'error_rate': 0.0},
          'endpoints': <String, Object?>{},
        },
        aiJobs: const {
          'status': 'ok',
          'active_total': 1,
          'completed_24h': 8,
          'failed_24h': 2,
          'oldest_active_seconds': 200,
        },
        aiCost: const {'status': 'ok', 'total_calls': 10, 'errors': 2},
      );
      final alerts =
          (result['alerts'] as List<Object?>).cast<Map<String, Object>>();
      final codes = alerts.map((alert) => alert['code']).toSet();

      expect(result['status'], equals('warning'));
      expect(codes, contains('ai_job_stalled_warning'));
      expect(codes, contains('ai_job_failure_rate_warning'));
      expect(codes, contains('ai_provider_error_rate_warning'));
      expect(
        alerts.every((alert) => (alert['action'] as String).isNotEmpty),
        isTrue,
      );
    });

    test('does not alert on samples below the noise floor', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: const {
          'totals': {'request_count': 2, 'error_rate': 1.0},
          'endpoints': {
            'GET /decks': {'request_count': 2, 'p95_latency_ms': 30000},
          },
        },
        aiJobs: const {
          'status': 'ok',
          'active_total': 0,
          'completed_24h': 0,
          'failed_24h': 2,
          'oldest_active_seconds': 0,
        },
        aiCost: const {'status': 'ok', 'total_calls': 2, 'errors': 2},
      );

      expect(result['status'], equals('ok'));
      expect(result['alert_count'], equals(0));
    });
  });
}
