import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
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
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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

Future<LifeCounterSession?> _pumpUntilSetLifeApplied(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
) async {
  var session = await sessionStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.lives[1] != 35 ||
            session.lastTableEvent != null);
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    session = await sessionStore.load();
  }
  return session;
}

Future<Map<String, dynamic>> _readSetLifeLiveState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_set_life_live';
  const nonceKey = '__manaloom_test_set_life_live_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    localStorage.setItem('$storageKey', JSON.stringify({
      probe: window.__manaloomSetLifeLiveProbe ?? null
    }));
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

  testWidgets('applies direct set life live on the WebView path', (
    tester,
  ) async {
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
      const LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 32, 25, 11],
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
        firstPlayerIndex: null,
        turnTrackerActive: false,
        turnTrackerOngoingGame: false,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: null,
        currentTurnNumber: 1,
        turnTimerActive: false,
        turnTimerSeconds: 0,
        lastTableEvent: 'D20: 18',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();

    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
    await state.debugRunJavaScript('''
(() => {
  window.__manaloomSetLifeLiveProbe = 'alive';
})()
''');
    await state.debugHandleShellMessage(
      '{"type":"open-native-set-life","source":"player_life_total_surface_pressed","targetPlayerIndex":1}',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('life-counter-native-set-life-apply')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-set-life-clear')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-clear')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-digit-3')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-digit-5')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-apply')),
    );
    await tester.pumpAndSettle();

    final session = await _pumpUntilSetLifeApplied(tester, sessionStore);
    expect(session, isNotNull);
    expect(session!.lives[1], 35);
    expect(session.lastTableEvent, isNull);

    final history = await historyStore.load();
    expect(history, isNotNull);
    expect(history!.lastTableEvent, isNull);

    final rawSnapshot = await snapshotStore.load();
    expect(rawSnapshot, isNotNull);
    expect(rawSnapshot!.values['players'], isNotNull);
    final players = List<Map<String, dynamic>>.from(
      (jsonDecode(rawSnapshot.values['players']!) as List).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      ),
    );
    expect(players[1]['life'], 35);

    final liveState = await _readSetLifeLiveState(tester, snapshotStore, state);
    expect(liveState['probe'], 'alive');
  });
}
