import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/screens/checkout_screen.dart';

void main() {
  test('checkout accepts only secure external payment URLs', () {
    expect(
      secureExternalCheckoutUri('https://pay.example.com/session/123'),
      Uri.parse('https://pay.example.com/session/123'),
    );
    expect(secureExternalCheckoutUri('http://pay.example.com/session'), isNull);
    expect(secureExternalCheckoutUri('javascript:alert(1)'), isNull);
    expect(secureExternalCheckoutUri('not a URL'), isNull);
  });

  testWidgets('free beta never starts or exposes a payment action', (
    tester,
  ) async {
    var checkoutStarts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          startCheckout: () async {
            checkoutStarts += 1;
            return const CommercialCheckoutResult(
              activated: true,
              requiresExternalPayment: false,
              message: 'should not run',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout-beta-notice')), findsOneWidget);
    expect(find.text('Checkout não é necessário'), findsOneWidget);
    expect(find.textContaining('Não há assinatura'), findsOneWidget);
    expect(find.byKey(const Key('checkout-confirm-button')), findsNothing);
    expect(find.byKey(const Key('checkout-open-payment-button')), findsNothing);
    expect(find.textContaining('R\$'), findsNothing);
    expect(checkoutStarts, 0);
  });
}
