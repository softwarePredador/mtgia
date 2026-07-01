import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/platform_unavailable_screen.dart';

void main() {
  testWidgets('renders unavailable message and navigates to fallback', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/unavailable',
      routes: [
        GoRoute(
          path: '/unavailable',
          builder:
              (context, state) => const PlatformUnavailableScreen(
                title: 'Recurso indisponivel no navegador',
                message: 'Use o app mobile para este recurso.',
                fallbackRoutePath: '/home',
              ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home ready')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Recurso indisponivel no navegador'), findsOneWidget);
    expect(find.text('Use o app mobile para este recurso.'), findsOneWidget);

    await tester.tap(find.text('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Home ready'), findsOneWidget);
  });
}
