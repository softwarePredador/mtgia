import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/commercial/screens/checkout_screen.dart';

void main() {
  testWidgets('free beta exposes no payment or activation action', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CheckoutScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout-beta-notice')), findsOneWidget);
    expect(find.text('Checkout não está disponível'), findsOneWidget);
    expect(find.textContaining('não aceita pagamentos'), findsOneWidget);
    expect(find.byKey(const Key('checkout-confirm-button')), findsNothing);
    expect(find.byKey(const Key('checkout-open-payment-button')), findsNothing);
    expect(find.textContaining('R\$'), findsNothing);
  });
}
