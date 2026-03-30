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
    'round-trips partner commander cast detail through the live Lotus snapshot',
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
          lives: [40, 29, 19, 14],
          poison: [0, 0, 0, 0],
          energy: [0, 0, 0, 0],
          experience: [0, 0, 0, 0],
          commanderCasts: [0, 3, 0, 0],
          commanderCastDetails: [
            LifeCounterCommanderCastDetail.zero,
            LifeCounterCommanderCastDetail(
              commanderOneCasts: 1,
              commanderTwoCasts: 3,
            ),
            LifeCounterCommanderCastDetail.zero,
            LifeCounterCommanderCastDetail.zero,
          ],
          partnerCommanders: [false, true, false, false],
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
      await settingsStore.save(
        const LifeCounterSettings(
          autoKill: true,
          lifeLossOnCommanderDamage: true,
          showCountersOnPlayerCard: true,
          showRegularCounters: true,
          showCommanderDamageCounters: true,
          clickableCommanderDamageCounters: true,
          keepZeroCountersOnPlayerCard: false,
          saltyDefeatMessages: true,
          cycleSaltyDefeatMessages: true,
          gameTimer: false,
          gameTimerMainScreen: false,
          showClockOnMainScreen: false,
          randomPlayerColors: false,
          preserveBackgroundImagesOnShuffle: true,
          setLifeByTappingNumber: true,
          verticalTapAreas: false,
          cleanLook: false,
          criticalDamageWarning: true,
          customLongTapEnabled: false,
          customLongTapValue: 10,
          whitelabelIcon: null,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilSnapshotAvailable(tester, snapshotStore);
      final snapshot = await snapshotStore.load();
      expect(snapshot, isNotNull);

      final players = jsonDecode(snapshot!.values['players']!) as List<dynamic>;
      final playerTwoCounters =
          (players[1] as Map<String, dynamic>)['counters']
              as Map<String, dynamic>;

      expect((players[1] as Map<String, dynamic>)['partnerCommander'], isTrue);
      expect(playerTwoCounters['tax-1'], 2);
      expect(playerTwoCounters['tax-2'], 6);

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
      expect(restoredSession!.partnerCommanders, const [
        false,
        true,
        false,
        false,
      ]);
      expect(restoredSession.commanderCasts, const [0, 3, 0, 0]);
      expect(restoredSession.resolvedCommanderCastDetails, const [
        LifeCounterCommanderCastDetail.zero,
        LifeCounterCommanderCastDetail(
          commanderOneCasts: 1,
          commanderTwoCasts: 3,
        ),
        LifeCounterCommanderCastDetail.zero,
        LifeCounterCommanderCastDetail.zero,
      ]);
    },
  );
}
