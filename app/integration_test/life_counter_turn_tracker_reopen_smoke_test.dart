import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _bootHarness(WidgetTester tester) async {
  await LotusStorageSnapshotStore().clear();
  await LifeCounterSettingsStore().clear();
  await LifeCounterSessionStore().clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
}

Future<Map<String, dynamic>> _readTurnTrackerState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_turn_tracker_state';
  const nonceKey = '__manaloom_test_turn_tracker_state_nonce';
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

LifeCounterSession _buildSessionWithTurnTracker({
  required int? firstPlayerIndex,
  required int? currentTurnPlayerIndex,
  required int currentTurnNumber,
  required bool isActive,
  required bool ongoingGame,
  required bool autoHighRoll,
}) {
  return LifeCounterSession(
    playerCount: 4,
    startingLifeTwoPlayer: 20,
    startingLifeMultiPlayer: 40,
    lives: const [40, 31, 22, 13],
    poison: const [0, 0, 0, 0],
    energy: const [0, 0, 0, 0],
    experience: const [0, 0, 0, 0],
    commanderCasts: const [0, 0, 0, 0],
    partnerCommanders: const [false, false, false, false],
    playerSpecialStates: const [
      LifeCounterPlayerSpecialState.none,
      LifeCounterPlayerSpecialState.none,
      LifeCounterPlayerSpecialState.none,
      LifeCounterPlayerSpecialState.none,
    ],
    lastPlayerRolls: const [null, null, null, null],
    lastHighRolls: const [null, null, null, null],
    commanderDamage: const [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    stormCount: 0,
    monarchPlayer: null,
    initiativePlayer: null,
    firstPlayerIndex: firstPlayerIndex,
    turnTrackerActive: isActive,
    turnTrackerOngoingGame: ongoingGame,
    turnTrackerAutoHighRoll: autoHighRoll,
    currentTurnPlayerIndex: currentTurnPlayerIndex,
    currentTurnNumber: currentTurnNumber,
    turnTimerActive: false,
    turnTimerSeconds: 0,
    lastTableEvent: null,
  );
}

Map<String, dynamic> _expectedTurnTrackerPayload(LifeCounterSession session) {
  final encoded =
      LotusLifeCounterSessionAdapter.buildTurnTrackerSnapshotValues(
        session,
      )['turnTracker']!;
  final decoded = jsonDecode(encoded);
  return Map<String, dynamic>.from(decoded as Map);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reapplies canonical turn tracker over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final canonicalSession = _buildSessionWithTurnTracker(
        firstPlayerIndex: 2,
        currentTurnPlayerIndex: 1,
        currentTurnNumber: 7,
        isActive: true,
        ongoingGame: true,
        autoHighRoll: true,
      );
      final staleSession = _buildSessionWithTurnTracker(
        firstPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        currentTurnNumber: 1,
        isActive: false,
        ongoingGame: false,
        autoHighRoll: false,
      );
      final expectedTracker = _expectedTurnTrackerPayload(canonicalSession);

      await _bootHarness(tester);
      await sessionStore.save(canonicalSession);
      await snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(
            LotusLifeCounterSessionAdapter.buildSnapshotValues(staleSession),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final liveState = await _readTurnTrackerState(
        tester,
        snapshotStore,
        screenState,
      );

      expect(liveState['isActive'], expectedTracker['isActive']);
      expect(liveState['ongoingGame'], expectedTracker['ongoingGame']);
      expect(liveState['autoHighroll'], expectedTracker['autoHighroll']);
      expect(
        liveState['startingPlayerIndex'],
        expectedTracker['startingPlayerIndex'],
      );
      expect(
        liveState['currentPlayerIndex'],
        expectedTracker['currentPlayerIndex'],
      );
      expect(liveState['currentTurn'], expectedTracker['currentTurn']);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await sessionStore.clear();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic reopenedState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final reopenedTracker = await _readTurnTrackerState(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedTracker['isActive'], expectedTracker['isActive']);
      expect(reopenedTracker['ongoingGame'], expectedTracker['ongoingGame']);
      expect(reopenedTracker['autoHighroll'], expectedTracker['autoHighroll']);
      expect(
        reopenedTracker['startingPlayerIndex'],
        expectedTracker['startingPlayerIndex'],
      );
      expect(
        reopenedTracker['currentPlayerIndex'],
        expectedTracker['currentPlayerIndex'],
      );
      expect(reopenedTracker['currentTurn'], expectedTracker['currentTurn']);
    },
  );
}
