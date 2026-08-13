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

  test('free beta is the only entitlement exposed by plan snapshots', () {
    final source = File('lib/plan_service.dart').readAsStringSync();

    expect(PlanService.activeOfferName, 'free');
    expect(PlanService.activeOfferStatus, 'active');
    expect(PlanService.freeBetaAiMonthlyOperationalLimit, 120);
    expect(source, contains('const planName = activeOfferName'));
    expect(source, contains('const aiMonthlyLimit ='));
    expect(source, isNot(contains('_proLimit')));
    expect(source, isNot(contains("plan_name = 'pro'")));
    expect(
      source,
      isNot(contains("VALUES (\n          @userId,\n          'pro'")),
    );
  });

  test('legacy Pro activation API fails closed without a database write', () {
    final source = File('lib/plan_service.dart').readAsStringSync();
    final activationStart = source.indexOf(
      'Future<UserPlanSnapshot> activatePro',
    );
    final snapshotStart = source.indexOf(
      'Future<UserPlanSnapshot> getSnapshot',
    );
    final activationSource = source.substring(activationStart, snapshotStart);

    expect(activationStart, greaterThanOrEqualTo(0));
    expect(snapshotStart, greaterThan(activationStart));
    expect(activationSource, contains('PaidPlanActivationDisabled'));
    expect(activationSource, isNot(contains('pool.execute')));
    expect(activationSource, isNot(contains('INSERT INTO')));
    expect(activationSource, isNot(contains('UPDATE SET')));
  });
}
