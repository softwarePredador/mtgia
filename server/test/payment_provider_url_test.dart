import 'dart:io';

import 'package:server/billing/payment_provider.dart';
import 'package:test/test.dart';

void main() {
  test('free beta has no configurable checkout URL surface', () {
    final source = File('lib/billing/payment_provider.dart').readAsStringSync();

    expect(source, isNot(contains('checkout_url')));
    expect(source, isNot(contains('MANALOOM_PRO_CHECKOUT_URL')));
    expect(source, contains("'purchase_available': false"));
  });

  test('checkout and webhook fail closed at runtime', () async {
    const provider = ManaLoomPaymentProvider();

    final checkout = await provider.createCheckout(
      const BillingCheckoutRequest(planName: 'pro'),
    );
    expect(checkout.statusCode, HttpStatus.forbidden);
    expect(checkout.body['checkout_status'], 'beta_free_only');
    expect(checkout.body['billing_enabled'], isFalse);
    expect(checkout.body['purchase_available'], isFalse);

    final webhook = provider.verifyWebhook();
    expect(webhook.statusCode, HttpStatus.gone);
    expect(webhook.body['webhook_status'], 'beta_free_only');
    expect(webhook.body['billing_enabled'], isFalse);
  });
}
