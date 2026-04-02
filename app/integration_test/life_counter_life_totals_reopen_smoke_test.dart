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
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await LotusStorageSnapshotStore().clear();
  await LifeCounterSettingsStore().clear();
  await LifeCounterSessionStore().clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
}

Future<Map<String, dynamic>> _readLifeTotalsState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_life_totals_state';
  const nonceKey = '__manaloom_test_life_totals_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const rawPlayers = localStorage.getItem('players');
    const players = rawPlayers ? JSON.parse(rawPlayers) : [];
    localStorage.setItem('$storageKey', JSON.stringify({
      player_one_life: Array.isArray(players) && players.length > 0 ? players[0]?.life ?? null : null,
      player_two_life: Array.isArray(players) && players.length > 1 ? players[1]?.life ?? null : null,
      player_four_life: Array.isArray(players) && players.length > 3 ? players[3]?.life ?? null : null
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

LifeCounterSession _buildSessionWithLifeTotals(List<int> lives) {
  return LifeCounterSession(
    playerCount: 4,
    startingLifeTwoPlayer: 20,
    startingLifeMultiPlayer: 40,
    lives: lives,
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
    'reapplies canonical life totals over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final canonicalSession = _buildSessionWithLifeTotals(const [41, 27, 15, 6]);
      final staleSession = _buildSessionWithLifeTotals(const [40, 40, 40, 40]);

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

      await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final liveState = await _readLifeTotalsState(
        tester,
        snapshotStore,
        screenState,
      );

      expect(liveState['player_one_life'], 41);
      expect(liveState['player_two_life'], 27);
      expect(liveState['player_four_life'], 6);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await sessionStore.clear();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic reopenedState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final reopenedLifeTotals = await _readLifeTotalsState(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedLifeTotals['player_one_life'], 41);
      expect(reopenedLifeTotals['player_two_life'], 27);
      expect(reopenedLifeTotals['player_four_life'], 6);
    },
  );
}
