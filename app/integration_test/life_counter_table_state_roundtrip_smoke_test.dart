import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _pumpUntilSnapshotAvailable(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
) async {
  var snapshot = await snapshotStore.load();
  for (var attempt = 0; attempt < 20 && snapshot == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await snapshotStore.load();
  }
  expect(snapshot, isNotNull);
}

Future<void> _pumpUntilCanonicalSessionAvailable(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
) async {
  var session = await sessionStore.load();
  for (var attempt = 0; attempt < 20 && session == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    session = await sessionStore.load();
  }
  expect(session, isNotNull);
}

Future<void> _stabilizeHarness(
  WidgetTester tester, {
  required LotusStorageSnapshotStore snapshotStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'round-trips storm monarch and initiative through the live Lotus snapshot',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final settingsStore = LifeCounterSettingsStore();

      await _stabilizeHarness(
        tester,
        snapshotStore: snapshotStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );

      await sessionStore.save(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 33, 18, 12],
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
          stormCount: 9,
          monarchPlayer: 2,
          initiativePlayer: 1,
          firstPlayerIndex: 0,
          turnTrackerActive: false,
          turnTrackerOngoingGame: false,
          turnTrackerAutoHighRoll: false,
          currentTurnPlayerIndex: null,
          currentTurnNumber: 1,
          turnTimerActive: false,
          turnTimerSeconds: 0,
          lastTableEvent: null,
        ),
      );
      await settingsStore.save(LifeCounterSettings.defaults);

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilSnapshotAvailable(tester, snapshotStore);
      final snapshot = await snapshotStore.load();
      expect(snapshot, isNotNull);

      final rawTableState =
          jsonDecode(snapshot!.values['__manaloom_table_state']!)
              as Map<String, dynamic>;
      expect(rawTableState, {
        'stormCount': 9,
        'monarchPlayer': 2,
        'initiativePlayer': 1,
      });

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await sessionStore.clear();
      await settingsStore.clear();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilCanonicalSessionAvailable(tester, sessionStore);
      final restoredSession = await sessionStore.load();

      expect(restoredSession, isNotNull);
      expect(restoredSession!.stormCount, 9);
      expect(restoredSession.monarchPlayer, 2);
      expect(restoredSession.initiativePlayer, 1);
    },
  );
}
