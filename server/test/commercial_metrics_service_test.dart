import 'dart:io';

import 'package:server/analytics/activation_kpi.dart';
import 'package:server/commercial_metrics_service.dart';
import 'package:test/test.dart';

void main() {
  group('CommercialMetricsService', () {
    // BT-KPI-001: o funil antigo somava eventos e dividia por cadastros (um
    // usuário com 10 decks valia 10). As métricas de ativação contam usuários
    // distintos; o comportamento está em activation_kpi_db_live_test.dart.
    test('activation metrics count users, never event totals', () {
      final source =
          File('lib/commercial_metrics_service.dart').readAsStringSync();
      expect(source, isNot(contains('countAiActivationEvents')));
      expect(source, isNot(contains('_per_signup')));
      expect(source, isNot(contains("'activation_funnel'")));
      expect(source, contains('activationKpiCohortSql(existing)'));
      expect(source, contains('activationKpiFunnelSql()'));
      expect(activationKpiFunnelSql(), contains('COUNT(DISTINCT e.user_id)'));
      final cohort = activationKpiCohortSql(activationKpiOptionalTables());
      expect(cohort, isNot(contains('COUNT(DISTINCT')));
      expect(cohort, contains('GROUP BY cohort_week'));
      expect(
        cohort,
        contains("d.created_at < c.signup_at + INTERVAL '24 hours'"),
      );
      expect(cohort, contains("a.at >= c.signup_at + INTERVAL '7 days'"));
      expect(cohort, contains("a.at < c.signup_at + INTERVAL '14 days'"));
    });

    test('KPI rates are null without a denominator and keep 4 decimals', () {
      expect(activationKpiRate(0, 0), isNull);
      expect(activationKpiRate(3, 0), isNull);
      expect(activationKpiRate(0, 5), 0.0);
      expect(activationKpiRate(2, 3), 0.6667);
      expect(activationKpiRate(3, 3), 1.0);
    });

    test('guardrails compare against versioned D-47 limits', () {
      Map<String, Object?> errorRate(double? observed, int sample) =>
          evaluateActivationKpiGuardrail(
            id: 'ai_provider_error_rate',
            observed: observed,
            sample: sample,
            minimumSample: activationKpiErrorRateMinimumSample,
            warningAt: activationKpiErrorRateWarning,
            criticalAt: activationKpiErrorRateCritical,
          );
      expect(activationKpiGuardrailsVersion, 1);
      expect(activationKpiErrorRateWarning, 0.20);
      expect(activationKpiErrorRateCritical, 0.50);
      expect(activationKpiErrorRateMinimumSample, 5);
      expect(activationKpiAiActionsWarningAt(), 60);
      expect(activationKpiAiActionsCriticalAt(), 96);

      expect(errorRate(0.19, 5)['status'], 'ok');
      expect(errorRate(0.20, 5)['status'], 'warning');
      expect(errorRate(0.49, 5)['status'], 'warning');
      expect(errorRate(0.50, 5)['status'], 'critical');
      expect(errorRate(0.90, 4)['status'], 'insufficient_data');
      expect(errorRate(null, 50)['status'], 'insufficient_data');
      expect(errorRate(0.2, 5), {
        'id': 'ai_provider_error_rate',
        'status': 'warning',
        'observed': 0.2,
        'sample': 5,
        'minimum_sample': 5,
        'warning_at': 0.2,
        'critical_at': 0.5,
      });

      expect(activationKpiGuardrailsStatus([]), 'insufficient_data');
      expect(
        activationKpiGuardrailsStatus([
          {'status': 'insufficient_data'},
          {'status': 'ok'},
        ]),
        'ok',
      );
      expect(
        activationKpiGuardrailsStatus([
          {'status': 'ok'},
          {'status': 'warning'},
        ]),
        'warning',
      );
      expect(
        activationKpiGuardrailsStatus([
          {'status': 'warning'},
          {'status': 'critical'},
          {'status': 'insufficient_data'},
        ]),
        'critical',
      );
    });

    test('AI actions per AI user are brought to 30 days', () {
      expect(
        activationKpiAiActionsPer30Days(actions: 30, users: 3, windowDays: 30),
        10,
      );
      expect(
        activationKpiAiActionsPer30Days(actions: 30, users: 3, windowDays: 7),
        42.86,
      );
      expect(
        activationKpiAiActionsPer30Days(actions: 5, users: 0, windowDays: 30),
        isNull,
      );
    });

    test('normalizes reporting window into supported commercial range', () {
      expect(CommercialMetricsService.normalizeWindowDays(-10), equals(1));
      expect(CommercialMetricsService.normalizeWindowDays(0), equals(1));
      expect(CommercialMetricsService.normalizeWindowDays(30), equals(30));
      expect(CommercialMetricsService.normalizeWindowDays(180), equals(90));
    });

    test('normalizes AI history bucket and window range', () {
      expect(CommercialMetricsService.normalizeHistoryBucket('hour'), 'hour');
      expect(CommercialMetricsService.normalizeHistoryBucket('HOUR'), 'hour');
      expect(CommercialMetricsService.normalizeHistoryBucket('week'), 'day');
      expect(CommercialMetricsService.normalizeHistoryBucket(null), 'day');

      expect(
        CommercialMetricsService.normalizeHistoryWindowDays(30, bucket: 'hour'),
        7,
      );
      expect(
        CommercialMetricsService.normalizeHistoryWindowDays(-4, bucket: 'day'),
        1,
      );
      expect(
        CommercialMetricsService.normalizeHistoryWindowDays(120, bucket: 'day'),
        90,
      );
    });

    test('separates provider telemetry from plan quota telemetry', () {
      expect(
        CommercialMetricsService.isProviderTelemetryEndpoint(
          'provider:generate',
        ),
        isTrue,
      );
      expect(
        CommercialMetricsService.isProviderTelemetryEndpoint('optimize'),
        isTrue,
      );
      expect(
        CommercialMetricsService.isProviderTelemetryEndpoint('complete'),
        isTrue,
      );
      expect(
        CommercialMetricsService.isProviderTelemetryEndpoint(
          'plan:post:/ai/generate',
        ),
        isFalse,
      );
      expect(
        CommercialMetricsService.isProviderTelemetryEndpoint(
          'plan-reservation:post:/ai/optimize',
        ),
        isFalse,
      );
      expect(
        CommercialMetricsService.isPlanActionTelemetryEndpoint(
          'plan:post:/ai/generate',
        ),
        isTrue,
      );
    });

    test('dashboard and reports share one provider SQL predicate', () {
      final source =
          File('routes/health/dashboard/index.dart').readAsStringSync();
      final logServiceSource =
          File('lib/ai_log_service.dart').readAsStringSync();

      expect(
        CommercialMetricsService.providerTelemetrySqlPredicate,
        contains("endpoint LIKE 'provider:%'"),
      );
      expect(
        source,
        contains('CommercialMetricsService.providerTelemetrySqlPredicate'),
      );
      expect(logServiceSource, contains('aiProviderTelemetrySqlPredicate'));
    });
  });
}
