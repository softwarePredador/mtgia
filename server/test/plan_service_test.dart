import 'dart:io';

import 'package:server/ai_telemetry_contract.dart';
import 'package:server/plan_service.dart';
import 'package:test/test.dart';

void main() {
  test('estimates supported provider models with separate token rates', () {
    final estimate = estimateAiProviderCost(const [
      AiProviderUsageTotals(
        model: 'gpt-4o-mini-2024-07-18',
        inputTokens: 1000000,
        outputTokens: 1000000,
      ),
      AiProviderUsageTotals(
        model: 'gpt-5.4-mini',
        inputTokens: 1000000,
        outputTokens: 1000000,
      ),
    ]);

    expect(estimate.usd, closeTo(6, 0.000001));
    expect(estimate.coverageRatio, 1);
  });

  test('reports cost coverage when a provider model is not priced', () {
    final estimate = estimateAiProviderCost(const [
      AiProviderUsageTotals(
        model: 'gpt-4o-mini',
        inputTokens: 500,
        outputTokens: 500,
      ),
      AiProviderUsageTotals(
        model: 'unknown-provider-model',
        inputTokens: 500,
        outputTokens: 500,
      ),
    ]);

    expect(estimate.usd, closeTo(0.000375, 0.0000001));
    expect(estimate.coverageRatio, 0.5);
    expect(PlanService.estimatedCostPricingVersion, 'openai-2026-07-16');
  });

  test(
    'uses one provider predicate and cleans stale reservations on reads',
    () {
      final source = File('lib/plan_service.dart').readAsStringSync();

      expect(
        PlanService.providerTelemetrySqlPredicate,
        aiProviderTelemetrySqlPredicate,
      );
      expect(
        source,
        contains('await _cleanupStaleReservations(session, userId)'),
      );
      expect(source, contains("endpoint LIKE 'plan-reservation:%'"));
      expect(source, contains('created_at <'));
    },
  );
}
