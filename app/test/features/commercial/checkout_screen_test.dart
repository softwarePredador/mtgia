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

  testWidgets('external checkout exposes and opens the payment action', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          startCheckout:
              () async => const CommercialCheckoutResult(
                activated: false,
                requiresExternalPayment: true,
                message: 'Finalize o pagamento para ativar o Pro.',
                checkoutUrl: 'https://pay.example.com/session/123',
              ),
          externalCheckoutLauncher: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('checkout-confirm-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('checkout-open-payment-button')),
      findsOneWidget,
    );
    expect(find.text('Continuar para pagamento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkout-open-payment-button')));
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://pay.example.com/session/123'));
  });

  testWidgets('invalid payment URL is not exposed as an action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          startCheckout:
              () async => const CommercialCheckoutResult(
                activated: false,
                requiresExternalPayment: true,
                message: 'Finalize o pagamento para ativar o Pro.',
                checkoutUrl: 'javascript:alert(1)',
              ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('checkout-confirm-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('O link de pagamento recebido não é seguro. Tente novamente.'),
      findsWidgets,
    );
    expect(find.byKey(const Key('checkout-open-payment-button')), findsNothing);
  });
}
