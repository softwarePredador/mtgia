import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/life_counter_route.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  _FakeLotusHost({required this.onShellMessageRequested, this.onLoadBundle});

  final LotusShellMessageCallback onShellMessageRequested;
  final Future<void> Function(_FakeLotusHost host)? onLoadBundle;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  int loadBundleCallCount = 0;
  bool isDisposed = false;

  @override
  Widget buildView(BuildContext context) {
    return const ColoredBox(
      key: Key('fake-lotus-host-view'),
      color: Colors.black,
    );
  }

  @override
  Future<void> loadBundle() async {
    loadBundleCallCount += 1;
    await onLoadBundle?.call(this);
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
  group('LotusLifeCounterScreen', () {
    String? clipboardText;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      clipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              final arguments = call.arguments;
              if (arguments is Map) {
                clipboardText = arguments['text']?.toString();
              }
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('shows the owned loading overlay on boot', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
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
      expect(find.text('Preparing the life counter'), findsOneWidget);
      expect(host.loadBundleCallCount, 1);
    });

    testWidgets('shows error state and retries bundle load', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
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

      expect(find.text('Life counter unavailable'), findsOneWidget);
      expect(find.text('Test bundle load failure'), findsOneWidget);
      expect(host.loadBundleCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(host.loadBundleCallCount, 2);
      expect(find.text('Life counter unavailable'), findsNothing);
      expect(find.text('Test bundle load failure'), findsNothing);
    });

    testWidgets(
      'opens native settings from shell shortcut and applies changes',
      (tester) async {
        late _FakeLotusHost host;

        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory: ({
                required onAppReviewRequested,
                required onShellMessageRequested,
              }) {
                host = _FakeLotusHost(
                  onShellMessageRequested: onShellMessageRequested,
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-settings","source":"settings_shortcut_pressed"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Life Counter Settings'), findsOneWidget);

        await tester.tap(find.text('Auto-kill'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-settings-save')),
        );
        await tester.pumpAndSettle();

        final settings = await LifeCounterSettingsStore().load();
        expect(settings, isNotNull);
        expect(settings!.autoKill, isFalse);
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets('opens native history from shell shortcut', (tester) async {
      late _FakeLotusHost host;

      final session = LifeCounterSession.tryFromJson({
        ...LifeCounterSession.initial(playerCount: 4).toJson(),
        'last_table_event': 'Player 1 lost 3 life',
      });
      expect(session, isNotNull);
      await LifeCounterSessionStore().save(session!);
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'currentGameMeta': '{"name":"Game #12"}',
            'gameHistory':
                '[{"message":"Player 2 gained 2 life","timestamp":1711800000000}]',
            'allGamesHistory':
                '[{"name":"Game #11","history":[{"message":"Player 3 was eliminated"}]}]',
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-history","source":"history_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Life Counter History'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-native-history-last-event')),
        findsOneWidget,
      );
      expect(find.text('Player 1 lost 3 life'), findsOneWidget);
      expect(find.text('Player 2 gained 2 life'), findsOneWidget);
      expect(
        find.text('Player 3 was eliminated', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('exports native history to clipboard', (tester) async {
      late _FakeLotusHost host;

      final session = LifeCounterSession.tryFromJson({
        ...LifeCounterSession.initial(playerCount: 4).toJson(),
        'last_table_event': 'Player 1 lost 3 life',
      });
      expect(session, isNotNull);
      await LifeCounterSessionStore().save(session!);
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'currentGameMeta': '{"name":"Game #12"}',
            'gameHistory':
                '[{"message":"Player 2 gained 2 life","timestamp":1711800000000}]',
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-history","source":"history_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-history-export')),
      );
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('Player 2 gained 2 life'));
      expect(clipboardText, contains('Game #12'));
    });

    testWidgets('opens native card search from shell shortcut', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-card-search","source":"card_search_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Search'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-native-card-search-input')),
        findsOneWidget,
      );
      expect(find.text('SOL RING'), findsOneWidget);
    });

    testWidgets('opens native turn tracker from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;

      await LifeCounterSessionStore().save(
        LifeCounterSession.initial(playerCount: 4),
      );
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'layoutType': '"portrait-portrait-portrait-portrait"',
            'turnTracker':
                '{"isActive":false,"ongoingGame":false,"autoHighroll":false,"turnTimer":{"isActive":false,"duration":0,"countDown":[]},"currentPlayerIndex":0,"startingPlayerIndex":null,"currentTurn":1}',
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-turn-tracker","source":"turn_tracker_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Turn Tracker'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Start Game'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-apply')),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.turnTrackerActive, isTrue);
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('shows ManaLoom-owned feedback for blocked external links', (
      tester,
    ) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        'ManaLoom blocked an external link: https://play.google.com/store/apps/details?id=com.vanilla.mtgcounter',
      );
      await tester.pump();

      expect(
        find.text(
          'External shortcut disabled while ManaLoom owns the life counter shell.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('resolves the live /life-counter route', (tester) async {
      late _FakeLotusHost host;
      final router = GoRouter(
        initialLocation: lifeCounterRoutePath,
        routes: [
          GoRoute(
            path: lifeCounterRoutePath,
            builder:
                (context, state) => LotusLifeCounterScreen(
                  hostFactory: ({
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
  });
}
