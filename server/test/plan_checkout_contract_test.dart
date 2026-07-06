import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('plan checkout route does not activate Pro without explicit config', () {
    final route = File(
      'routes/users/me/plan/checkout/index.dart',
    ).readAsStringSync();
    final provider =
        File('lib/billing/payment_provider.dart').readAsStringSync();
    final webhook =
        File('routes/billing/webhook/index.dart').readAsStringSync();

    expect(route, contains('ManaLoomPaymentProvider(pool: pool)'));
    expect(route, isNot(contains('activatePro(userId)')));
    expect(provider, contains('MANALOOM_INTERNAL_CHECKOUT_ENABLED'));
    expect(provider, contains('ALLOW_INTERNAL_PRO_ACTIVATION'));
    expect(provider, contains('MANALOOM_PRO_CHECKOUT_URL'));
    expect(provider, contains('payment_provider_not_configured'));
    expect(provider, contains('_verifyHmacSha256'));
    expect(provider, contains('provider_adapter_not_implemented'));
    expect(webhook, contains('verifyWebhook'));
    expect(webhook, contains('context.request.body()'));
  });

  test('plan service persists Pro with renewal window', () {
    final service = File('lib/plan_service.dart').readAsStringSync();

    expect(service, contains('Future<UserPlanSnapshot> activatePro'));
    expect(service, contains("plan_name = 'pro'"));
    expect(service, contains("renews_at = NOW() + INTERVAL '30 days'"));
    expect(service, contains('ON CONFLICT (user_id) DO UPDATE'));
  });
}
