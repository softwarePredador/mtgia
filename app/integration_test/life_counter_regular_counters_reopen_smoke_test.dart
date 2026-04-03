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

Future<Map<String, dynamic>> _readRegularCountersState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_regular_counters_state';
  const nonceKey = '__manaloom_test_regular_counters_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const rawPlayers = localStorage.getItem('players');
    const players = rawPlayers ? JSON.parse(rawPlayers) : [];
    const playerOneCounters =
      Array.isArray(players) && players.length > 0 ? players[0]?.counters ?? null : null;
    const playerTwoCounters =
      Array.isArray(players) && players.length > 1 ? players[1]?.counters ?? null : null;
    localStorage.setItem('$storageKey', JSON.stringify({
      player_one_poison: playerOneCounters?.poison ?? null,
      player_one_energy: playerOneCounters?.energy ?? null,
      player_two_xp: playerTwoCounters?.xp ?? null
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

LifeCounterSession _buildSessionWithRegularCounters({
  required List<int> poison,
  required List<int> energy,
  required List<int> experience,
}) {
  return LifeCounterSession(
    playerCount: 4,
    startingLifeTwoPlayer: 20,
    startingLifeMultiPlayer: 40,
    lives: const [40, 30, 20, 10],
    poison: poison,
    energy: energy,
    experience: experience,
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
    firstPlayerIndex: 0,
    turnTrackerActive: false,
    turnTrackerOngoingGame: false,
    turnTrackerAutoHighRoll: false,
    currentTurnPlayerIndex: null,
    currentTurnNumber: 1,
    turnTimerActive: false,
    turnTimerSeconds: 0,
    lastTableEvent: null,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reapplies canonical regular counters over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final canonicalSession = _buildSessionWithRegularCounters(
        poison: const [4, 0, 0, 0],
        energy: const [2, 0, 0, 0],
        experience: const [0, 5, 0, 0],
      );
      final staleSession = _buildSessionWithRegularCounters(
        poison: const [0, 0, 0, 0],
        energy: const [0, 0, 0, 0],
        experience: const [0, 0, 0, 0],
      );

      await _bootHarness(tester);
      await sessionStore.save(canonicalSession);
      await snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(
            LotusLifeCounterSessionAdapter.buildPlayerRuntimeSnapshotValues(
              staleSession,
            ),
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
      final liveState = await _readRegularCountersState(
        tester,
        snapshotStore,
        screenState,
      );

      expect(liveState['player_one_poison'], 4);
      expect(liveState['player_one_energy'], 2);
      expect(liveState['player_two_xp'], 5);

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
      final reopenedCounters = await _readRegularCountersState(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedCounters['player_one_poison'], 4);
      expect(reopenedCounters['player_one_energy'], 2);
      expect(reopenedCounters['player_two_xp'], 5);
    },
  );
}
