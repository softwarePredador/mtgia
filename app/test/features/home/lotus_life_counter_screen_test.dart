import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/features/home/life_counter_route.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost, LotusStorageFlushBarrier {
  _FakeLotusHost({
    required this.onShellMessageRequested,
    this.onLoadBundle,
    this.onFlushStorageSnapshot,
  });

  final LotusShellMessageCallback onShellMessageRequested;
  final Future<void> Function(_FakeLotusHost host)? onLoadBundle;
  final Future<bool> Function()? onFlushStorageSnapshot;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  int loadBundleCallCount = 0;
  int flushStorageSnapshotCallCount = 0;
  bool isDisposed = false;
  final List<String> executedScripts = <String>[];

  @override
  Widget buildView(BuildContext context) {
    return const ColoredBox(
      key: Key('fake-lotus-host-view'),
      color: Colors.black,
    );
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {}

  @override
  Future<void> loadBundle() async {
    loadBundleCallCount += 1;
    await onLoadBundle?.call(this);
  }

  @override
  Future<void> runJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    if (script.contains('.planechase-overlay')) {
      return jsonEncode(<String, Object>{
        'planechaseAvailable': true,
        'planechaseActive': true,
        'planechaseCardPoolActive': false,
        'archenemyAvailable': true,
        'archenemyActive': false,
        'archenemyCardPoolActive': false,
        'bountyAvailable': true,
        'bountyActive': false,
        'bountyCardPoolActive': false,
        'maxActiveModes': 2,
      });
    }

    return jsonEncode(<String, Object>{
      'planechaseAvailable': true,
      'planechaseActive': false,
      'planechaseCardPoolActive': false,
      'archenemyAvailable': true,
      'archenemyActive': false,
      'archenemyCardPoolActive': false,
      'bountyAvailable': true,
      'bountyActive': false,
      'bountyCardPoolActive': false,
      'maxActiveModes': 2,
    });
  }

  @override
  Future<bool> flushStorageSnapshot({String reason = 'flutter_exit'}) async {
    flushStorageSnapshotCallCount += 1;
    return await onFlushStorageSnapshot?.call() ?? true;
  }

  void completeSuccessfulLoad() {
    errorMessage.value = null;
    isLoading.value = false;
  }

  void failLoad(String message) {
    errorMessage.value = message;
    isLoading.value = false;
  }

  void emitShellMessage(String message) {
    onShellMessageRequested(message);
  }

  @override
  void dispose() {
    isDisposed = true;
    isLoading.dispose();
    errorMessage.dispose();
  }
}

void main() {
  group('LotusLifeCounterScreen host and backend behavior', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows the owned loading overlay on boot', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory:
                ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) {
                  host = _FakeLotusHost(
                    onShellMessageRequested: onShellMessageRequested,
                  );
                  return host;
                },
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('fake-lotus-host-view')), findsOneWidget);
      expect(find.text('Preparando o contador de vida'), findsOneWidget);
      expect(host.loadBundleCallCount, 1);
    });

    testWidgets('shows error state and retries bundle load', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory:
                ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) {
                  host = _FakeLotusHost(
                    onShellMessageRequested: onShellMessageRequested,
                    onLoadBundle: (host) async {
                      if (host.loadBundleCallCount == 1) {
                        host.failLoad('Test bundle load failure');
                        return;
                      }

                      host.completeSuccessfulLoad();
                    },
                  );
                  return host;
                },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Contador de vida indisponível'), findsOneWidget);
      expect(
        find.text(
          'Não foi possível carregar o contador de vida. Tente novamente em instantes.',
        ),
        findsOneWidget,
      );
      expect(host.loadBundleCallCount, 1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(host.loadBundleCallCount, 2);
      expect(find.text('Contador de vida indisponível'), findsNothing);
      expect(find.text('Test bundle load failure'), findsNothing);
    });

    testWidgets('resolves the live /life-counter route', (tester) async {
      late _FakeLotusHost host;
      final router = GoRouter(
        initialLocation: lifeCounterRoutePath,
        routes: [
          GoRoute(
            path: lifeCounterRoutePath,
            builder: (context, state) => LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    host = _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                    );
                    return host;
                  },
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('fake-lotus-host-view')), findsOneWidget);
      expect(host.loadBundleCallCount, 1);
    });

    testWidgets('binds deck context before loading the Lotus bundle', (
      tester,
    ) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            deckId: 'deck-607',
            deckName: 'Lorehold reconstruído',
            deckSnapshotHash:
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            deckVersionAtEpochMs: 1784714400000,
            hostFactory:
                ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) {
                  host = _FakeLotusHost(
                    onShellMessageRequested: onShellMessageRequested,
                    onLoadBundle: (host) async => host.completeSuccessfulLoad(),
                  );
                  return host;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      final history = await LifeCounterHistoryStore().load();

      expect(host.loadBundleCallCount, 1);
      expect(session, isNotNull);
      expect(session!.deckId, 'deck-607');
      expect(session.deckName, 'Lorehold reconstruído');
      expect(
        session.deckSnapshotHash,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      expect(session.deckVersionAtEpochMs, 1784714400000);
      expect(session.playSessionId, startsWith('play-'));
      expect(session.startedAtEpochMs, isNotNull);
      expect(history?.currentGameMeta?['deckId'], 'deck-607');
      expect(history?.currentGameMeta?['playSessionId'], session.playSessionId);
      expect(
        history?.currentGameMeta?['deckSnapshotHash'],
        session.deckSnapshotHash,
      );
    });

    testWidgets('a changed version of the same deck starts a clean game session', (
      tester,
    ) async {
      final previousSession = LifeCounterSession.initial(
        playerCount: 4,
        playSessionId: 'play-deck-v1',
        deckId: 'deck-607',
        deckName: 'Lorehold',
        deckSnapshotHash:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        deckVersionAtEpochMs: 1000,
        startedAtEpochMs: 2000,
      ).copyWith(lives: const <int>[12, 40, 40, 40]);
      await LifeCounterSessionStore().save(previousSession);
      await LifeCounterHistoryStore().save(
        const LifeCounterHistoryState(
          currentGameName: 'Partida Lorehold v1',
          currentGameMeta: <String, Object?>{
            'id': 'game-v1',
            'startDate': 2000,
            'deckId': 'deck-607',
            'playSessionId': 'play-deck-v1',
          },
          currentGameEntries: <LifeCounterHistoryEntry>[
            LifeCounterHistoryEntry(message: 'Jogador 1 perdeu 28 de vida'),
          ],
          archiveEntries: <LifeCounterHistoryEntry>[],
          archivedGameCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            deckId: 'deck-607',
            deckName: 'Lorehold',
            deckSnapshotHash:
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            deckVersionAtEpochMs: 3000,
            hostFactory:
                ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) => _FakeLotusHost(
                  onShellMessageRequested: onShellMessageRequested,
                  onLoadBundle: (host) async => host.completeSuccessfulLoad(),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      final history = await LifeCounterHistoryStore().load();
      expect(session?.deckId, 'deck-607');
      expect(
        session?.deckSnapshotHash,
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      );
      expect(session?.playSessionId, isNot('play-deck-v1'));
      expect(session?.lives, everyElement(40));
      expect(history?.currentGameEntries, isEmpty);
      expect(history?.archivedGames, hasLength(1));
    });

    testWidgets(
      'switching decks starts a clean board and archives the previous game',
      (tester) async {
        final previousSession =
            LifeCounterSession.initial(
              playerCount: 4,
              playSessionId: 'play-deck-a',
              deckId: 'deck-a',
              deckName: 'Deck A',
              startedAtEpochMs: 1000,
            ).copyWith(
              lives: const <int>[17, 40, 40, 40],
              poison: const <int>[4, 0, 0, 0],
            );
        await LifeCounterSessionStore().save(previousSession);
        await LifeCounterHistoryStore().save(
          const LifeCounterHistoryState(
            currentGameName: 'Partida do deck A',
            currentGameMeta: <String, Object?>{
              'id': 'game-a',
              'startDate': 1000,
              'deckId': 'deck-a',
              'playSessionId': 'play-deck-a',
            },
            currentGameEntries: <LifeCounterHistoryEntry>[
              LifeCounterHistoryEntry(message: 'Jogador 1 perdeu 23 de vida'),
            ],
            archiveEntries: <LifeCounterHistoryEntry>[],
            archivedGameCount: 0,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              deckId: 'deck-b',
              deckName: 'Deck B',
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    return _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                      onLoadBundle: (host) async =>
                          host.completeSuccessfulLoad(),
                    );
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        final history = await LifeCounterHistoryStore().load();
        expect(session?.deckId, 'deck-b');
        expect(session?.lives, everyElement(40));
        expect(session?.poison, everyElement(0));
        expect(history?.currentGameEntries, isEmpty);
        expect(history?.currentGameMeta?['deckId'], 'deck-b');
        expect(history?.archivedGames, hasLength(1));
        expect(history?.archivedGames.single.metadata['deckId'], 'deck-a');
        expect(
          history?.archivedGames.single.entries.single.message,
          'Jogador 1 perdeu 23 de vida',
        );
      },
    );

    testWidgets(
      'close shell message returns to home when life counter is stacked',
      (tester) async {
        late _FakeLotusHost host;
        LifeCounterExitResult? routeResult;
        final flushBarrier = Completer<bool>();
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    routeResult =
                        await openLifeCounterRoute<LifeCounterExitResult>(
                          context,
                        );
                  },
                  child: const Text('open-life-counter'),
                ),
              ),
            ),
            GoRoute(
              path: lifeCounterRoutePath,
              builder: (context, state) => LotusLifeCounterScreen(
                hostFactory:
                    ({
                      required onAppReviewRequested,
                      required onShellMessageRequested,
                    }) {
                      host = _FakeLotusHost(
                        onShellMessageRequested: onShellMessageRequested,
                        onFlushStorageSnapshot: () => flushBarrier.future,
                        onLoadBundle: (host) async =>
                            host.completeSuccessfulLoad(),
                      );
                      return host;
                    },
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('open-life-counter'));
        await tester.pumpAndSettle();

        host.emitShellMessage(
          '{"type":"close-life-counter","source":"test_shell"}',
        );
        await tester.pump();

        expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
        expect(find.text('open-life-counter'), findsNothing);
        expect(host.flushStorageSnapshotCallCount, 1);
        expect(host.isDisposed, isFalse);

        flushBarrier.complete(true);
        await tester.pumpAndSettle();

        expect(find.text('open-life-counter'), findsOneWidget);
        expect(host.isDisposed, isTrue);
        expect(routeResult, isNotNull);
        expect(routeResult!.hadGameActivity, isFalse);
        expect(routeResult!.storageFlushed, isTrue);
      },
    );

    testWidgets(
      'close reports activity and keeps the play session context after a life change',
      (tester) async {
        late _FakeLotusHost host;
        LifeCounterExitResult? routeResult;
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    routeResult = await openLifeCounterRoute<LifeCounterExitResult>(
                      context,
                      deckId: 'deck-607',
                      deckName: 'Lorehold',
                      deckSnapshotHash:
                          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                      deckVersionAtEpochMs: 1784714400000,
                    );
                  },
                  child: const Text('open-life-counter'),
                ),
              ),
            ),
            GoRoute(
              path: lifeCounterRoutePath,
              builder: (context, state) => LotusLifeCounterScreen(
                deckId: state.uri.queryParameters['deckId'],
                deckName: state.uri.queryParameters['deckName'],
                deckSnapshotHash: state.uri.queryParameters['deckSnapshotHash'],
                deckVersionAtEpochMs: int.tryParse(
                  state.uri.queryParameters['deckVersionAt'] ?? '',
                ),
                hostFactory:
                    ({
                      required onAppReviewRequested,
                      required onShellMessageRequested,
                    }) {
                      host = _FakeLotusHost(
                        onShellMessageRequested: onShellMessageRequested,
                        onFlushStorageSnapshot: () async {
                          final store = LifeCounterSessionStore();
                          final session = await store.load();
                          await store.save(
                            session!.copyWith(
                              lives: <int>[
                                session.lives.first - 1,
                                ...session.lives.skip(1),
                              ],
                            ),
                          );
                          return true;
                        },
                        onLoadBundle: (host) async =>
                            host.completeSuccessfulLoad(),
                      );
                      return host;
                    },
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        await tester.tap(find.text('open-life-counter'));
        await tester.pumpAndSettle();

        host.emitShellMessage(
          '{"type":"close-life-counter","source":"activity_test"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('open-life-counter'), findsOneWidget);
        expect(routeResult, isNotNull);
        expect(routeResult!.hadGameActivity, isTrue);
        expect(routeResult!.storageFlushed, isTrue);
        expect(routeResult!.deckId, 'deck-607');
        expect(
          routeResult!.deckSnapshotHash,
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );
        expect(routeResult!.deckVersionAtEpochMs, 1784714400000);
        expect(routeResult!.playSessionId, startsWith('play-'));
        expect(routeResult!.duration, isNotNull);
      },
    );

    testWidgets('exit storage barrier has a bounded timeout', (tester) async {
      late _FakeLotusHost host;
      final neverCompletes = Completer<bool>();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => openLifeCounterRoute(context),
                child: const Text('open-life-counter'),
              ),
            ),
          ),
          GoRoute(
            path: lifeCounterRoutePath,
            builder: (context, state) => LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    host = _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                      onFlushStorageSnapshot: () => neverCompletes.future,
                      onLoadBundle: (host) async =>
                          host.completeSuccessfulLoad(),
                    );
                    return host;
                  },
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-life-counter'));
      await tester.pumpAndSettle();

      host.emitShellMessage(
        '{"type":"close-life-counter","source":"timeout_test"}',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 899));

      expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
      expect(host.flushStorageSnapshotCallCount, 1);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('open-life-counter'), findsOneWidget);
      expect(host.isDisposed, isTrue);
    });

    testWidgets('close shell message falls back to home when route is direct', (
      tester,
    ) async {
      late _FakeLotusHost host;
      final router = GoRouter(
        initialLocation: lifeCounterRoutePath,
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('home-screen')),
          ),
          GoRoute(
            path: lifeCounterRoutePath,
            builder: (context, state) => LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    host = _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                      onLoadBundle: (host) async =>
                          host.completeSuccessfulLoad(),
                    );
                    return host;
                  },
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      host.emitShellMessage(
        '{"type":"close-life-counter","source":"direct_route_shell"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('home-screen'), findsOneWidget);
    });

    testWidgets('system back falls back to home on direct route', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: lifeCounterRoutePath,
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('home-screen')),
          ),
          GoRoute(
            path: lifeCounterRoutePath,
            builder: (context, state) => LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    return _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                      onLoadBundle: (host) async =>
                          host.completeSuccessfulLoad(),
                    );
                  },
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('home-screen'), findsOneWidget);
    });

    testWidgets('records Flutter lifecycle pause diagnostics', (tester) async {
      final debugLogs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          debugLogs.add(message);
        }
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    return _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                    );
                  },
            ),
          ),
        );

        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(
          debugLogs.any(
            (log) =>
                log.contains('category=life_counter.lifecycle') &&
                log.contains('message=lifecycle_changed') &&
                log.contains('state: paused'),
          ),
          isTrue,
        );
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    testWidgets('records native user leave hint diagnostics', (tester) async {
      const channel = MethodChannel('manaloom/life_counter_lifecycle');
      const codec = StandardMethodCodec();
      final debugLogs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          debugLogs.add(message);
        }
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory:
                  ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    return _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                    );
                  },
            ),
          ),
        );

        await tester.pump();
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(
            const MethodCall('userLeaveHint', <String, Object?>{
              'timestampMs': 1,
            }),
          ),
          (_) {},
        );
        await tester.pump();

        expect(
          debugLogs.any(
            (log) =>
                log.contains('category=life_counter.lifecycle') &&
                log.contains('message=native_lifecycle_signal') &&
                log.contains('method: userLeaveHint'),
          ),
          isTrue,
        );
      } finally {
        debugPrint = originalDebugPrint;
      }
    });
  });
}
