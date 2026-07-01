import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Free plan blocks AI after monthly limit', () async {
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();

    expect(provider.tier, ManaLoomPlanTier.free);
    expect(provider.monthlyAiLimit, 5);

    for (var i = 0; i < 5; i++) {
      expect(
        await provider.consumeAiAction(AiUsageKind.deckGeneration),
        isTrue,
      );
    }

    expect(provider.remainingAiActions, 0);
    expect(
      await provider.consumeAiAction(AiUsageKind.deckOptimization),
      isFalse,
    );
  });

  test('Pro plan raises AI usage limit and persists tier', () async {
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();
    await provider.setPlan(ManaLoomPlanTier.pro);

    expect(provider.tier, ManaLoomPlanTier.pro);
    expect(provider.monthlyAiLimit, 200);
    expect(
      await provider.consumeAiAction(AiUsageKind.deckOptimization),
      isTrue,
    );

    final reloaded = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await reloaded.load();
    expect(reloaded.tier, ManaLoomPlanTier.pro);
    expect(reloaded.usedAiActions, 1);
  });

  test('monthly usage rolls over into a new period', () async {
    var currentDate = DateTime(2026, 7, 31);
    final provider = CommercialProvider(now: () => currentDate);
    await provider.load();
    expect(await provider.consumeAiAction(AiUsageKind.deckGeneration), isTrue);
    expect(provider.usedAiActions, 1);

    currentDate = DateTime(2026, 8, 1);
    expect(await provider.consumeAiAction(AiUsageKind.deckGeneration), isTrue);

    expect(provider.periodKey, '2026-08');
    expect(provider.usedAiActions, 1);
    expect(provider.remainingAiActions, 4);
  });
}
