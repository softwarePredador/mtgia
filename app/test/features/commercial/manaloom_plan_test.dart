import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/models/commercial_launch_policy.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';

void main() {
  test('free tier is presented as the no-cost public beta', () {
    expect(CommercialLaunchPolicy.paidCheckoutEnabled, isFalse);
    expect(CommercialLaunchPolicy.isFreeBeta, isTrue);
    expect(ManaLoomPlanTier.free.label, 'Beta gratuita');
    expect(ManaLoomPlan.free.priceLabel, 'Sem custo');
    expect(ManaLoomPlan.free.billingTerms.recurrenceLabel, 'Sem cobrança');
    expect(
      ManaLoomPlan.free.billingTerms.checkoutGuardrail,
      contains('não exige checkout'),
    );
  });

  test(
    'Pro reflects the real quota entitlement without gating open features',
    () {
      final freeFeatures = ManaLoomPlan.free.features.join(' ').toLowerCase();
      final proFeatures = ManaLoomPlan.pro.features.join(' ').toLowerCase();

      expect(ManaLoomPlan.free.monthlyAiLimit, 120);
      expect(ManaLoomPlan.pro.monthlyAiLimit, 2500);
      expect(freeFeatures, contains('pós-jogo'));
      expect(freeFeatures, contains('comunidade'));
      expect(proFeatures, isNot(contains('pós-jogo')));
      expect(proFeatures, isNot(contains('social')));
      expect(
        ManaLoomPlan.pro.limits.join(' '),
        contains('continuam disponíveis'),
      );
    },
  );

  test('Pro billing copy is centralized and explicit before checkout', () {
    final terms = ManaLoomPlan.pro.billingTerms;

    expect(ManaLoomPlan.pro.priceLabel, 'R\$ 19,90/mês');
    expect(terms.recurrenceLabel, 'Assinatura mensal recorrente');
    expect(terms.renewalDisclosure.toLowerCase(), contains('renovação'));
    expect(terms.cancellationDisclosure, startsWith('Cancelamento:'));
    expect(terms.refundDisclosure, startsWith('Reembolso:'));
    expect(terms.checkoutGuardrail, contains('não conclua'));
  });
}
