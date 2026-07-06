import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('plan checkout route does not activate Pro without explicit config', () {
    final route = File(
      'routes/users/me/plan/checkout/index.dart',
    ).readAsStringSync();

    expect(route, contains('MANALOOM_INTERNAL_CHECKOUT_ENABLED'));
    expect(route, contains('ALLOW_INTERNAL_PRO_ACTIVATION'));
    expect(route, contains('MANALOOM_PRO_CHECKOUT_URL'));
    expect(route, contains('payment_provider_not_configured'));
    expect(route, contains('PlanService(pool).activatePro(userId)'));
  });

  test('plan service persists Pro with renewal window', () {
    final service = File('lib/plan_service.dart').readAsStringSync();

    expect(service, contains('Future<UserPlanSnapshot> activatePro'));
    expect(service, contains("plan_name = 'pro'"));
    expect(service, contains("renews_at = NOW() + INTERVAL '30 days'"));
    expect(service, contains('ON CONFLICT (user_id) DO UPDATE'));
  });
}
