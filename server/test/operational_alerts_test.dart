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

    test('connects Battle job queue, lifecycle, and persistence alerts', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: const {
          'totals': {'request_count': 0, 'error_rate': 0.0},
          'endpoints': <String, Object?>{},
        },
        aiJobs: const {'status': 'not_initialized'},
        aiCost: const {'status': 'not_initialized'},
        battleJobs: const {
          'status': 'ok',
          'jobs': {
            'active': 2,
            'oldest_active_seconds': 400,
            'completed': 3,
            'censored': 1,
            'timeout': 2,
            'coverage_error': 1,
            'engine_error': 1,
            'persistence_error': 1,
          },
          'queue': {'depth': 2, 'oldest_wait_seconds': 301},
          'persistence': {'failures': 1},
        },
      );
      final alerts =
          (result['alerts'] as List<Object?>).cast<Map<String, Object>>();
      final codes = alerts.map((alert) => alert['code']).toSet();

      expect(result['status'], 'critical');
      expect(codes, contains('battle_job_stalled_critical'));
      expect(codes, contains('battle_job_queue_stalled_critical'));
      expect(codes, contains('battle_job_persistence_error_critical'));
      expect(codes, contains('battle_job_failure_rate_critical'));
    });

    test('alerts on stuck and failed Battle Coach aggregate states', () {
      final result = evaluateOperationalAlerts(
        requestMetrics: const {
          'totals': {'request_count': 0, 'error_rate': 0.0},
          'endpoints': <String, Object?>{},
        },
        aiJobs: const {'status': 'not_initialized'},
        aiCost: const {'status': 'not_initialized'},
        interactiveBattle: const {
          'status': 'ok',
          'user_id': 'must-not-leak',
          'active': {
            'total': 4,
            'session_id': 'must-not-leak',
            'waiting_for_action': 2,
            'waiting_past_prompt_deadline': 1,
            'ttl_expired_non_terminal': 1,
            'max_age_seconds': 900,
            'max_prompt_overdue_seconds': 45,
          },
          'terminals_24h': {
            'total': 8,
            'process_lost': 1,
            'timeout': 3,
            'persistence_error': 1,
          },
        },
      );
      final alerts =
          (result['alerts'] as List<Object?>).cast<Map<String, Object>>();
      final codes = alerts.map((alert) => alert['code']).toSet();

      expect(result['status'], 'critical');
      expect(codes, contains('battle_coach_prompt_overdue_critical'));
      expect(codes, contains('battle_coach_ttl_expired_active_critical'));
      expect(codes, contains('battle_coach_process_lost_warning'));
      expect(codes, contains('battle_coach_timeout_critical'));
      expect(codes, contains('battle_coach_persistence_error_critical'));
      expect(
        alerts.expand((alert) => alert.values).join(' '),
        isNot(contains('must-not-leak')),
      );
    });

    // BT-OBS-001: os valores andam junto com a versão. Mudar um limite sem
    // subir operationalAlertThresholdsVersion quebra este teste.
    test('thresholds are pinned to their version', () {
      expect(operationalAlertThresholdsVersion, 3);
      expect(operationalAlertThresholds, {
        'minimum_request_sample': 20,
        'minimum_endpoint_sample': 10,
        'minimum_ai_sample': 5,
        'warning_error_rate': 0.05,
        'critical_error_rate': 0.15,
        'warning_endpoint_p95_ms': 3000,
        'critical_endpoint_p95_ms': 10000,
        'warning_oldest_ai_job_seconds': 180,
        'critical_oldest_ai_job_seconds': 360,
        'warning_ai_failure_rate': 0.20,
        'critical_ai_failure_rate': 0.50,
        'warning_oldest_battle_job_seconds': 180,
        'critical_oldest_battle_job_seconds': 360,
        'warning_battle_queue_seconds': 120,
        'critical_battle_queue_seconds': 300,
        'minimum_battle_terminal_sample': 5,
        'warning_battle_failure_rate': 0.20,
        'critical_battle_failure_rate': 0.50,
        'critical_coach_terminal_count': 3,
      });
    });

    test('the 5xx rate comes from the 5-minute window when present', () {
      Set<Object?> codes(Map<String, dynamic> requestMetrics) {
        final result = evaluateOperationalAlerts(
          requestMetrics: requestMetrics,
          aiJobs: const {'status': 'not_initialized'},
          aiCost: const {'status': 'not_initialized'},
        );
        return (result['alerts'] as List<Object?>)
            .cast<Map<String, Object>>()
            .map((alert) => alert['code'])
            .toSet();
      }

      // Uma semana no ar dilui o apagão no total; a janela mostra.
      expect(
        codes({
          'totals': {'request_count': 1000000, 'error_rate': 0.011},
          'windows': {
            '5m': {'request_count': 400, 'error_rate': 0.5},
          },
          'endpoints': <String, Object?>{},
        }),
        contains('http_5xx_rate_critical'),
      );
      // Janela sem amostra suficiente não alerta, nem com o total alto.
      expect(
        codes({
          'totals': {'request_count': 1000, 'error_rate': 0.9},
          'windows': {
            '5m': {'request_count': 3, 'error_rate': 1.0},
          },
          'endpoints': <String, Object?>{},
        }),
        isEmpty,
      );
    });
  });
}
