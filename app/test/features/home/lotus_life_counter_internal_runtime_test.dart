import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  _FakeLotusHost({required this.onShellMessageRequested});

  final LotusShellMessageCallback onShellMessageRequested;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  int loadBundleCallCount = 0;
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
  }

  @override
  Future<void> runJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    if (script.contains('receivePatch')) {
      return jsonEncode(<String, Object>{'ok': true});
    }

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

  void completeSuccessfulLoad() {
    errorMessage.value = null;
    isLoading.value = false;
  }

  void emitShellMessage(String message) {
    onShellMessageRequested(message);
  }

  @override
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}

void main() {
  group('LotusLifeCounterScreen internal runtime fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
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

    testWidgets('advances active turn tracker without reloading the Lotus bundle', (
      tester,
    ) async {
      late _FakeLotusHost host;

      await LifeCounterSessionStore().save(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 40, 40, 40],
          poison: [0, 0, 0, 0],
          energy: [0, 0, 0, 0],
          experience: [0, 0, 0, 0],
          commanderCasts: [0, 0, 0, 0],
          partnerCommanders: [false, false, false, false],
          playerSpecialStates: [
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
            LifeCounterPlayerSpecialState.none,
          ],
          lastPlayerRolls: [null, null, null, null],
          lastHighRolls: [null, null, null, null],
          commanderDamage: [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          stormCount: 0,
          monarchPlayer: null,
          initiativePlayer: null,
          firstPlayerIndex: 0,
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: false,
          currentTurnPlayerIndex: 0,
          currentTurnNumber: 1,
          turnTimerActive: false,
          turnTimerSeconds: 0,
          lastTableEvent: null,
        ),
      );
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'layoutType': '"portrait-portrait-portrait-portrait"',
            'turnTracker':
                '{"isActive":true,"ongoingGame":true,"autoHighroll":false,"turnTimer":{"isActive":false,"duration":0,"countDown":[]},"currentPlayerIndex":0,"startingPlayerIndex":0,"currentTurn":1}',
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

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-turn-tracker-next')),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-next')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-turn-tracker-apply')),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.currentTurnPlayerIndex, 1);
      expect(session.currentTurnNumber, 1);
      expect(host.loadBundleCallCount, 1);
      expect(
        host.executedScripts.any(
          (script) =>
              script.contains('.turn-time-tracker') &&
              script.contains('tracker.click()'),
        ),
        isTrue,
      );
    });

    testWidgets(
      'rewinds one active turn tracker step without reloading the Lotus bundle',
      (tester) async {
        late _FakeLotusHost host;

        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 40, 40, 40],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: null,
            initiativePlayer: null,
            firstPlayerIndex: 0,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 1,
            currentTurnNumber: 1,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );
        await LotusStorageSnapshotStore().save(
          const LotusStorageSnapshot(
            values: {
              'layoutType': '"portrait-portrait-portrait-portrait"',
              'turnTracker':
                  '{"isActive":true,"ongoingGame":true,"autoHighroll":false,"turnTimer":{"isActive":false,"duration":0,"countDown":[]},"currentPlayerIndex":1,"startingPlayerIndex":0,"currentTurn":1}',
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

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-turn-tracker-previous')),
          250,
          scrollable: find.byType(Scrollable).first,
        );

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-previous')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-apply')),
        );
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.currentTurnPlayerIndex, 0);
        expect(session.currentTurnNumber, 1);
        expect(host.loadBundleCallCount, 1);
        expect(
          host.executedScripts.any(
            (script) =>
                script.contains("MouseEvent('mousedown'") &&
                script.contains("MouseEvent('mouseup'"),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'rewinds two active turn tracker steps without reloading the Lotus bundle',
      (tester) async {
        late _FakeLotusHost host;

        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 40, 40, 40],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: null,
            initiativePlayer: null,
            firstPlayerIndex: 0,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 2,
            currentTurnNumber: 1,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );
        await LotusStorageSnapshotStore().save(
          const LotusStorageSnapshot(
            values: {
              'layoutType': '"portrait-portrait-portrait-portrait"',
              'turnTracker':
                  '{"isActive":true,"ongoingGame":true,"autoHighroll":false,"turnTimer":{"isActive":false,"duration":0,"countDown":[]},"currentPlayerIndex":2,"startingPlayerIndex":0,"currentTurn":1}',
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

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-turn-tracker-previous')),
          250,
          scrollable: find.byType(Scrollable).first,
        );

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-previous')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-previous')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-apply')),
        );
        await tester.pump(const Duration(milliseconds: 2400));
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.currentTurnPlayerIndex, 0);
        expect(session.currentTurnNumber, 1);
        expect(host.loadBundleCallCount, 1);
        expect(
          host.executedScripts.any(
            (script) =>
                script.contains("MouseEvent('mousedown'") &&
                script.contains("index < 2"),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'sanitizes stale table ownership when native turn tracker is applied',
      (tester) async {
        late _FakeLotusHost host;

        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 0, 40, 40],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: 1,
            initiativePlayer: 2,
            firstPlayerIndex: 1,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 1,
            currentTurnNumber: 3,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );
        await LotusStorageSnapshotStore().save(
          const LotusStorageSnapshot(
            values: {
              'layoutType': '"portrait-portrait-portrait-portrait"',
              'turnTracker':
                  '{"isActive":true,"ongoingGame":true,"autoHighroll":false,"turnTimer":{"isActive":false,"duration":0,"countDown":[]},"currentPlayerIndex":1,"startingPlayerIndex":1,"currentTurn":3}',
              'players': '[]',
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

        await tester.tap(
          find.byKey(const Key('life-counter-native-turn-tracker-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.monarchPlayer, isNull);
        expect(session.initiativePlayer, 2);
        expect(session.firstPlayerIndex, 2);
        expect(session.currentTurnPlayerIndex, 2);
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets('opens native game timer from shell shortcut', (tester) async {
      late _FakeLotusHost host;

      await LifeCounterGameTimerStateStore().save(
        const LifeCounterGameTimerState(
          startTimeEpochMs: 1_000,
          isPaused: false,
          pausedTimeEpochMs: null,
        ),
      );
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'gameTimerState':
                '{"startTime":1000,"isPaused":false,"pausedTime":0}',
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
        '{"type":"open-native-game-timer","source":"game_timer_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Timer'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-apply')),
      );
      await tester.pumpAndSettle();

      final state = await LifeCounterGameTimerStateStore().load();
      expect(state, isNotNull);
      expect(state!.isActive, isTrue);
      expect(state.isPaused, isTrue);
      expect(host.loadBundleCallCount, 1);
      expect(
        host.executedScripts.any((script) => script.contains(".game-timer")),
        isTrue,
      );
    });

    testWidgets('opens native game timer from clock shell shortcut', (
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
        '{"type":"open-native-game-timer","source":"clock_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Timer'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-game-timer-start')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-start')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-apply')),
      );
      await tester.pumpAndSettle();

      final state = await LifeCounterGameTimerStateStore().load();
      expect(state, isNotNull);
      expect(state!.isActive, isTrue);
      expect(state.isPaused, isFalse);
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('opens native dice from shell shortcut', (tester) async {
      late _FakeLotusHost host;

      await LifeCounterSessionStore().save(
        LifeCounterSession.initial(playerCount: 4),
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
        '{"type":"open-native-dice","source":"dice_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dice Tools'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-dice-high-roll')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-native-dice-apply')));
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.lastHighRolls.whereType<int>().length, 4);
      expect(host.loadBundleCallCount, 2);
    });
  });
}
