import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/features/home/life_counter_route.dart';

void main() {
  group('lifeCounterRouteLocation', () {
    test('keeps the canonical route without empty context', () {
      expect(lifeCounterRouteLocation(), lifeCounterRoutePath);
      expect(
        lifeCounterRouteLocation(deckId: '  ', deckName: ''),
        lifeCounterRoutePath,
      );
    });

    test('encodes deck context as URL-safe query parameters', () {
      final location = lifeCounterRouteLocation(
        deckId: 'deck/42',
        deckName: 'Atraxa + marcadores',
        deckSnapshotHash:
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        deckVersionAtEpochMs: 1784714400000,
      );
      final uri = Uri.parse(location);

      expect(uri.path, lifeCounterRoutePath);
      expect(uri.queryParameters['deckId'], 'deck/42');
      expect(uri.queryParameters['deckName'], 'Atraxa + marcadores');
      expect(
        uri.queryParameters['deckSnapshotHash'],
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      expect(uri.queryParameters['deckVersionAt'], '1784714400000');
    });

    test('omits incomplete or invalid deck version metadata', () {
      final incomplete = Uri.parse(
        lifeCounterRouteLocation(
          deckId: 'deck-42',
          deckSnapshotHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      );
      final invalid = Uri.parse(
        lifeCounterRouteLocation(
          deckId: 'deck-42',
          deckSnapshotHash: 'not-a-sha256',
          deckVersionAtEpochMs: 1784714400000,
        ),
      );

      expect(incomplete.queryParameters['deckId'], 'deck-42');
      expect(incomplete.queryParameters, isNot(contains('deckSnapshotHash')));
      expect(incomplete.queryParameters, isNot(contains('deckVersionAt')));
      expect(invalid.queryParameters, isNot(contains('deckSnapshotHash')));
      expect(invalid.queryParameters, isNot(contains('deckVersionAt')));
    });
  });

  test('exit result only exposes a valid non-negative duration', () {
    const completed = LifeCounterExitResult(
      hadGameActivity: true,
      storageFlushed: true,
      startedAtEpochMs: 1000,
      deckSnapshotHash:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      deckVersionAtEpochMs: 500,
      endedAtEpochMs: 61000,
    );
    const invalid = LifeCounterExitResult(
      hadGameActivity: false,
      storageFlushed: false,
      startedAtEpochMs: 2000,
      endedAtEpochMs: 1000,
    );

    expect(completed.duration, const Duration(minutes: 1));
    expect(completed.deckVersionAtEpochMs, 500);
    expect(invalid.duration, isNull);
  });

  testWidgets(
    'opening the life counter removes the active snackbar and its queue',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  FilledButton(
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          duration: const Duration(days: 1),
                          content: const Text('Otimização em andamento'),
                          action: SnackBarAction(
                            label: 'Retomar',
                            onPressed: () {},
                          ),
                        ),
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          duration: Duration(days: 1),
                          content: Text('Mensagem enfileirada'),
                        ),
                      );
                    },
                    child: const Text('mostrar-feedback'),
                  ),
                  FilledButton(
                    onPressed: () => openLifeCounterRoute(context),
                    child: const Text('jogar-agora'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: lifeCounterRoutePath,
            builder: (context, state) =>
                const Scaffold(body: Text('mesa-life-counter')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('mostrar-feedback'));
      await tester.pump();
      expect(find.text('Otimização em andamento'), findsOneWidget);

      await tester.tap(find.text('jogar-agora'));
      await tester.pumpAndSettle();

      expect(find.text('mesa-life-counter'), findsOneWidget);
      expect(find.text('Otimização em andamento'), findsNothing);
      expect(find.text('Mensagem enfileirada'), findsNothing);
      expect(find.text('Retomar'), findsNothing);
    },
  );
}
