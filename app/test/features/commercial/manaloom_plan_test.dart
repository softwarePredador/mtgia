import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/models/commercial_launch_policy.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';

void main() {
  test('controlled beta exposes one free non-commercial offer', () {
    expect(CommercialLaunchPolicy.paidCheckoutEnabled, isFalse);
    expect(CommercialLaunchPolicy.isFreeBeta, isTrue);
    expect(ManaLoomPlanTier.values, [ManaLoomPlanTier.free]);
    expect(ManaLoomPlanTier.free.label, 'Beta gratuita');
    expect(ManaLoomPlan.free.priceLabel, 'Sem cobrança');
    expect(ManaLoomPlan.free.monthlyAiLimit, 120);

    final copy = <String>[
      ManaLoomPlan.free.description,
      ...ManaLoomPlan.free.features,
      ...ManaLoomPlan.free.limits,
    ].join(' ').toLowerCase();
    expect(copy, contains('teto operacional'));
    expect(copy, contains('não define preço'));
    expect(copy, contains('servidor'));
    expect(copy, isNot(contains('2.500')));
    expect(copy, isNot(contains('r\$')));
  });

  test('legacy plan identifiers normalize to the free beta', () {
    expect(ManaLoomPlanTierLabel.fromId('pro'), ManaLoomPlanTier.free);
    expect(ManaLoomPlanTierLabel.fromId('unknown'), ManaLoomPlanTier.free);
    expect(ManaLoomPlan.forTier(ManaLoomPlanTier.free), ManaLoomPlan.free);
  });
}
