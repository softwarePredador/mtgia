import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _pumpUntilUiSnapshotAvailable(
  WidgetTester tester,
  LotusUiSnapshotStore uiSnapshotStore,
) async {
  var snapshot = await uiSnapshotStore.load();
  for (var attempt = 0; attempt < 20 && snapshot == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await uiSnapshotStore.load();
  }
  expect(snapshot, isNotNull);
}

Future<void> _stabilizeHarness(
  WidgetTester tester, {
  required LotusStorageSnapshotStore snapshotStore,
  required LotusUiSnapshotStore uiSnapshotStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
  required LifeCounterHistoryStore historyStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await historyStore.clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<LifeCounterSession?> _pumpUntilDiceApplied(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
) async {
  var session = await sessionStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            !(session.lastTableEvent?.startsWith('D20: ') ?? false));
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    session = await sessionStore.load();
  }
  return session;
}

Future<LifeCounterHistoryState?> _pumpUntilHistoryMirrorsLastEvent(
  WidgetTester tester,
  LifeCounterHistoryStore historyStore,
) async {
  var history = await historyStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (history == null ||
            !(history.lastTableEvent?.startsWith('D20: ') ?? false));
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    history = await historyStore.load();
  }
  return history;
}

Future<Map<String, dynamic>> _readTurnTrackerState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_dice_turn_tracker';
  const nonceKey = '__manaloom_test_dice_turn_tracker_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const raw = localStorage.getItem('turnTracker');
    localStorage.setItem('$storageKey', raw ?? '{}');
    localStorage.setItem('$nonceKey', '$nonce');
  } catch (_) {}
})()
''');

  String? encodedState;
  for (var attempt = 0; attempt < 20 && encodedState == null; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 300));
    final snapshot = await snapshotStore.load();
    if (snapshot == null) {
      continue;
    }
    if (snapshot.values[nonceKey] != nonce) {
      continue;
    }
    encodedState = snapshot.values[storageKey];
  }

  expect(encodedState, isNotNull);
  final decoded = jsonDecode(encodedState!);
  return Map<String, dynamic>.from(decoded as Map);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'applies table D20 with canonical sync on the live WebView path',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final uiSnapshotStore = LotusUiSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final settingsStore = LifeCounterSettingsStore();
      final historyStore = LifeCounterHistoryStore();

      await _stabilizeHarness(
        tester,
        snapshotStore: snapshotStore,
        uiSnapshotStore: uiSnapshotStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
        historyStore: historyStore,
      );

      await sessionStore.save(
        LifeCounterSession.initial(playerCount: 4).copyWith(
          turnTrackerActive: true,
          turnTrackerOngoingGame: true,
          turnTrackerAutoHighRoll: false,
          firstPlayerIndex: 1,
          currentTurnPlayerIndex: 1,
          currentTurnNumber: 3,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-dice","source":"dice_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dice Tools'), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-native-dice-d20')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-native-dice-apply')));
      await tester.pumpAndSettle();

      final session = await _pumpUntilDiceApplied(tester, sessionStore);
      final history = await _pumpUntilHistoryMirrorsLastEvent(
        tester,
        historyStore,
      );
      final trackerState = await _readTurnTrackerState(
        tester,
        snapshotStore,
        state,
      );

      expect(session, isNotNull);
      expect(session!.turnTrackerActive, isTrue);
      expect(session.turnTrackerOngoingGame, isTrue);
      expect(session.firstPlayerIndex, 1);
      expect(session.currentTurnPlayerIndex, 1);
      expect(session.currentTurnNumber, 3);
      expect(session.lastTableEvent, startsWith('D20: '));
      expect(session.lastPlayerRolls.whereType<int>(), isEmpty);
      expect(session.lastHighRolls.whereType<int>(), isEmpty);

      expect(history, isNotNull);
      expect(history!.lastTableEvent, session.lastTableEvent);

      final expectedTracker = Map<String, dynamic>.from(
        jsonDecode(
              LotusLifeCounterSessionAdapter.buildTurnTrackerSnapshotValues(
                session,
              )['turnTracker']!,
            )
            as Map,
      );

      expect(trackerState['isActive'], expectedTracker['isActive']);
      expect(trackerState['ongoingGame'], expectedTracker['ongoingGame']);
      expect(trackerState['autoHighroll'], expectedTracker['autoHighroll']);
      expect(
        trackerState['startingPlayerIndex'],
        expectedTracker['startingPlayerIndex'],
      );
      expect(
        trackerState['currentPlayerIndex'],
        expectedTracker['currentPlayerIndex'],
      );
      expect(trackerState['currentTurn'], expectedTracker['currentTurn']);

      final rawSnapshot = await snapshotStore.load();
      expect(rawSnapshot, isNotNull);
      expect(rawSnapshot!.values['turnTracker'], isNotNull);
    },
  );
}
