import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('free beta checkout is fail-closed with no activation escape hatch', () {
    final route =
        File('routes/users/me/plan/checkout/index.dart').readAsStringSync();
    final provider =
        File('lib/billing/payment_provider.dart').readAsStringSync();
    final webhook =
        File('routes/billing/webhook/index.dart').readAsStringSync();
    final planRoute =
        File('routes/users/me/plan/index.dart').readAsStringSync();
    final planMiddleware = File('lib/plan_middleware.dart').readAsStringSync();

    expect(route, contains('const ManaLoomPaymentProvider()'));
    expect(route, isNot(contains('activatePro(userId)')));
    expect(provider, contains("'checkout_status': 'beta_free_only'"));
    expect(provider, contains("'billing_enabled': false"));
    expect(provider, contains("'purchase_available': false"));
    expect(provider, isNot(contains('MANALOOM_INTERNAL_CHECKOUT_ENABLED')));
    expect(provider, isNot(contains('ALLOW_INTERNAL_PRO_ACTIVATION')));
    expect(provider, isNot(contains('MANALOOM_PRO_CHECKOUT_URL')));
    expect(provider, isNot(contains('activatePro')));
    expect(provider, isNot(contains('checkout_url')));
    expect(webhook, contains('verifyWebhook'));
    expect(webhook, isNot(contains('context.request.body()')));
    expect(provider, contains("'webhook_status': 'beta_free_only'"));
    expect(planRoute, contains("'is_free': true"));
    expect(planRoute, contains("'purchase_available': false"));
    expect(planRoute, isNot(contains("'upgrade_offer'")));
    expect(planMiddleware, contains("'beta_mode': true"));
    expect(planMiddleware, contains("'purchase_available': false"));
    expect(planMiddleware, isNot(contains("'upgrade_hint'")));
    expect(planMiddleware, isNot(contains('Faça upgrade para continuar')));
  });

  test('plan service persists Pro with renewal window', () {
    final service = File('lib/plan_service.dart').readAsStringSync();

    expect(service, contains('Future<UserPlanSnapshot> activatePro'));
    expect(service, contains("plan_name = 'pro'"));
    expect(service, contains("renews_at = NOW() + INTERVAL '30 days'"));
    expect(service, contains('ON CONFLICT (user_id) DO UPDATE'));
  });

  test('commercial surfaces do not expose deployment instructions', () {
    final sources = [
      File(
        '../app/lib/features/commercial/screens/upgrade_screen.dart',
      ).readAsStringSync(),
      File(
        '../app/lib/features/commercial/screens/legal_screen.dart',
      ).readAsStringSync(),
      File(
        '../app/lib/features/commercial/providers/commercial_provider.dart',
      ).readAsStringSync(),
      File('lib/billing/payment_provider.dart').readAsStringSync(),
    ];

    for (final source in sources) {
      expect(source, isNot(contains('MVP de validação')));
      expect(source, isNot(contains('Stripe/Mercado Pago')));
      expect(source, isNot(contains('Configure MANALOOM')));
      expect(source, isNot(contains('adaptador do provedor')));
    }

    expect(sources.join('\n'), contains('O ManaLoom está em beta gratuita.'));
  });
}
