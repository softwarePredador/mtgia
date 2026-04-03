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

Future<Map<String, dynamic>> _readCommanderDamageState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_commander_damage_state';
  const nonceKey = '__manaloom_test_commander_damage_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const rawPlayers = localStorage.getItem('players');
    const players = rawPlayers ? JSON.parse(rawPlayers) : [];
    const target = Array.isArray(players) && players.length > 0 ? players[0] : null;
    const entries = Array.isArray(target?.commanderDamage) ? target.commanderDamage : [];
    const playerTwoEntry = entries.find((entry) => entry?.player === 'Player 2') ?? null;
    localStorage.setItem('$storageKey', JSON.stringify({
      player_two_damage: playerTwoEntry?.damage ?? null
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

LifeCounterSession _buildSessionWithCommanderDamage({
  required int commanderOneDamage,
}) {
  return LifeCounterSession(
    playerCount: 4,
    startingLifeTwoPlayer: 20,
    startingLifeMultiPlayer: 40,
    lives: const [40, 32, 25, 11],
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
    commanderDamage: <List<int>>[
      <int>[0, commanderOneDamage, 0, 0],
      const <int>[0, 0, 0, 0],
      const <int>[0, 0, 0, 0],
      const <int>[0, 0, 0, 0],
    ],
    commanderDamageDetails: <List<LifeCounterCommanderDamageDetail>>[
      <LifeCounterCommanderDamageDetail>[
        LifeCounterCommanderDamageDetail.zero,
        LifeCounterCommanderDamageDetail(
          commanderOneDamage: commanderOneDamage,
          commanderTwoDamage: 0,
        ),
        LifeCounterCommanderDamageDetail.zero,
        LifeCounterCommanderDamageDetail.zero,
      ],
      List<LifeCounterCommanderDamageDetail>.filled(
        4,
        LifeCounterCommanderDamageDetail.zero,
      ),
      List<LifeCounterCommanderDamageDetail>.filled(
        4,
        LifeCounterCommanderDamageDetail.zero,
      ),
      List<LifeCounterCommanderDamageDetail>.filled(
        4,
        LifeCounterCommanderDamageDetail.zero,
      ),
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
    lastTableEvent: null,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reapplies canonical commander damage over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final canonicalSession = _buildSessionWithCommanderDamage(
        commanderOneDamage: 5,
      );
      final staleSession = _buildSessionWithCommanderDamage(
        commanderOneDamage: 0,
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
      final liveState = await _readCommanderDamageState(
        tester,
        snapshotStore,
        screenState,
      );

      expect(liveState['player_two_damage'], {'commander1': 5});

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
      final reopenedCommanderDamage = await _readCommanderDamageState(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedCommanderDamage['player_two_damage'], {'commander1': 5});
    },
  );
}
