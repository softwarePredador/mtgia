import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/screens/checkout_screen.dart';
import 'package:manaloom/features/commercial/screens/legal_screen.dart';
import 'package:manaloom/features/commercial/screens/plan_screen.dart';
import 'package:manaloom/features/commercial/screens/upgrade_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('free beta is clear and purchase-free at 390px', (tester) async {
    final provider = await _commercialProvider();
    await _pumpAt(
      tester,
      const Size(390, 900),
      ChangeNotifierProvider.value(value: provider, child: const PlanScreen()),
    );

    expect(find.byKey(const Key('beta-free-access-panel')), findsOneWidget);
    expect(find.byKey(const Key('free-beta-status-badge')), findsOneWidget);
    expect(find.byKey(const Key('plans-mobile-stack')), findsNothing);
    expect(find.byKey(const Key('plans-desktop-grid')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('beta-free-access-panel'))).width,
      greaterThan(340),
    );
    expect(find.byKey(const Key('plan-pro-upgrade-button')), findsNothing);
    expect(find.textContaining('R\$'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('ai-usage-open-plans-button')))
          .height,
      greaterThanOrEqualTo(AppTheme.touchTargetMin),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('free beta stays in a readable column at 1280px', (tester) async {
    final provider = await _commercialProvider();
    await _pumpAt(
      tester,
      const Size(1280, 900),
      ChangeNotifierProvider.value(value: provider, child: const PlanScreen()),
    );

    expect(find.byKey(const Key('beta-free-access-panel')), findsOneWidget);
    expect(find.byKey(const Key('plans-desktop-grid')), findsNothing);
    expect(find.byKey(const Key('plans-mobile-stack')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('beta-free-access-panel'))).width,
      lessThanOrEqualTo(AppTheme.readingMaxWidth),
    );
    expect(find.byKey(const Key('plan-pro-upgrade-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legal content respects compact gutters at 390px', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 900), const CommercialLegalScreen());

    final content = tester.getRect(find.byKey(const Key('legal-content')));
    expect(content.left, greaterThanOrEqualTo(16));
    expect(content.right, lessThanOrEqualTo(374));
    expect(tester.takeException(), isNull);
  });

  testWidgets('legal content stays in a readable column at 1280px', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1280, 900), const CommercialLegalScreen());

    final content = tester.getSize(find.byKey(const Key('legal-content')));
    expect(content.width, lessThanOrEqualTo(712));
    expect(tester.takeException(), isNull);
  });

  testWidgets('free beta checkout fallback is full-width at 390px', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 900), const CheckoutScreen());

    expect(find.byKey(const Key('checkout-beta-notice')), findsOneWidget);
    expect(find.text('Checkout não é necessário'), findsOneWidget);
    expect(find.byKey(const Key('checkout-confirm-button')), findsNothing);
    expect(find.textContaining('R\$'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('checkout-back-to-beta-button')))
          .width,
      greaterThan(340),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('checkout-back-to-beta-button')))
          .height,
      greaterThanOrEqualTo(AppTheme.touchTargetMin),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('free beta checkout stays readable at 1280px', (tester) async {
    await _pumpAt(tester, const Size(1280, 900), const CheckoutScreen());

    expect(
      tester.getSize(find.byKey(const Key('checkout-beta-notice'))).width,
      lessThanOrEqualTo(712),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('checkout-back-to-beta-button')))
          .width,
      closeTo(220, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('free beta upgrade fallback is full-width at 390px', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 1000), const UpgradeScreen());

    expect(find.byKey(const Key('upgrade-beta-notice')), findsOneWidget);
    expect(find.text('Você já está na versão disponível'), findsOneWidget);
    expect(
      find.byKey(const Key('upgrade-start-checkout-button')),
      findsNothing,
    );
    expect(find.textContaining('R\$'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('upgrade-back-to-beta-button')))
          .width,
      greaterThan(340),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('upgrade-back-to-beta-button')))
          .height,
      greaterThanOrEqualTo(AppTheme.touchTargetMin),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('free beta upgrade stays readable at 1280px', (tester) async {
    await _pumpAt(tester, const Size(1280, 1000), const UpgradeScreen());

    expect(
      tester.getSize(find.byKey(const Key('upgrade-beta-notice'))).width,
      lessThanOrEqualTo(712),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('upgrade-back-to-beta-button')))
          .width,
      closeTo(280, 0.1),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<CommercialProvider> _commercialProvider() async {
  SharedPreferences.setMockInitialValues({});
  final provider = CommercialProvider();
  await provider.load();
  return provider;
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget home) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: home));
  await tester.pumpAndSettle();
}
