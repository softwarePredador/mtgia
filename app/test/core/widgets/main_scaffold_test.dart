import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/main_scaffold.dart';

import '../../ui/support/manaloom_ui_audit_harness.dart';

GoRouter _routerFor(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          for (final path in [
            '/home',
            '/decks',
            '/collection',
            '/community',
            '/profile',
          ])
            GoRoute(
              path: path,
              builder: (context, state) => ColoredBox(
                color: AppTheme.backgroundAbyss,
                child: Text(
                  path,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            ),
          GoRoute(
            path: '/decks/:id',
            builder: (context, state) =>
                Text('deck ${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const Text('messages'),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpAt(
  WidgetTester tester, {
  required Size size,
  required String location,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = _routerFor(location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses bottom navigation on compact primary screens', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAt(tester, size: const Size(390, 844), location: '/home');

    expect(find.byKey(const Key('main-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('main-navigation-rail')), findsNothing);
    await expectManaLoomBaselineAccessibility(tester);
    semantics.dispose();
  });

  testWidgets('uses navigation rail on wide primary screens', (tester) async {
    await _pumpAt(tester, size: const Size(1280, 900), location: '/decks');

    expect(find.byKey(const Key('main-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-navigation')), findsNothing);
  });

  testWidgets('hides primary navigation on nested deck screens', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      size: const Size(390, 844),
      location: '/decks/deck-1',
    );

    expect(find.byKey(const Key('main-navigation-rail')), findsNothing);
    expect(find.byKey(const Key('main-bottom-navigation')), findsNothing);
  });

  testWidgets('keeps the deck section rail on wide nested screens', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      size: const Size(1280, 900),
      location: '/decks/deck-1',
    );

    expect(find.byKey(const Key('main-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-navigation')), findsNothing);
  });

  testWidgets('keeps an unselected rail on wide auxiliary screens', (
    tester,
  ) async {
    await _pumpAt(tester, size: const Size(1280, 900), location: '/messages');

    final rail = tester.widget<NavigationRail>(
      find.byKey(const Key('main-navigation-rail')),
    );
    expect(rail.selectedIndex, isNull);
    expect(find.byKey(const Key('main-bottom-navigation')), findsNothing);
  });
}
