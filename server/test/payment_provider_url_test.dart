import 'package:server/billing/payment_provider.dart';
import 'package:test/test.dart';

void main() {
  test('billing checkout accepts only absolute HTTPS URLs', () {
    expect(
      secureBillingCheckoutUri('https://pay.example.com/session/123'),
      Uri.parse('https://pay.example.com/session/123'),
    );
    expect(secureBillingCheckoutUri('http://pay.example.com/session'), isNull);
    expect(secureBillingCheckoutUri('javascript:alert(1)'), isNull);
    expect(secureBillingCheckoutUri('/relative/checkout'), isNull);
  });
}
