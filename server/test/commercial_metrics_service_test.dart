import 'dart:io';

import 'package:server/commercial_metrics_service.dart';
import 'package:test/test.dart';

void main() {
  group('CommercialMetricsService', () {
    test('AI activation totals include generate, optimize and rebuild', () {
      expect(
        CommercialMetricsService.countAiActivationEvents({
          'deck_generated': 3,
          'deck_optimized': 2,
          'deck_rebuild_created': 1,
          'deck_created': 8,
        }),
        6,
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
