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

Future<void> _pumpUntilCanonicalStateAvailable(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
  LifeCounterSettingsStore settingsStore,
) async {
  var session = await sessionStore.load();
  var settings = await settingsStore.load();
  for (var attempt = 0;
      attempt < 20 && (session == null || settings == null);
      attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    session = await sessionStore.load();
    settings = await settingsStore.load();
  }
  expect(session, isNotNull);
  expect(settings, isNotNull);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots the embedded life counter without host error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );

    await tester.pump();

    expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
    expect(find.text('Life counter unavailable'), findsNothing);

    await tester.pump(const Duration(seconds: 8));

    expect(find.text('Life counter unavailable'), findsNothing);
  });

  testWidgets('bootstraps Lotus from canonical state when raw snapshot is absent', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();

    await snapshotStore.clear();
    await sessionStore.save(
      const LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [40, 27, 12, 3],
        poison: [0, 1, 7, 10],
        energy: [2, 0, 5, 1],
        experience: [0, 4, 0, 2],
        commanderCasts: [0, 1, 3, 2],
        partnerCommanders: [false, true, false, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.deckedOut,
          LifeCounterPlayerSpecialState.answerLeft,
        ],
        lastPlayerRolls: [null, null, null, null],
        lastHighRolls: [null, null, null, null],
        commanderDamage: [
          [0, 5, 0, 0],
          [0, 0, 8, 0],
          [0, 0, 0, 3],
          [11, 0, 0, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 2,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: true,
        currentTurnPlayerIndex: 1,
        currentTurnNumber: 7,
        turnTimerActive: true,
        turnTimerSeconds: 93,
        lastTableEvent: null,
      ),
    );
    await settingsStore.save(
      const LifeCounterSettings(
        autoKill: false,
        lifeLossOnCommanderDamage: false,
        showCountersOnPlayerCard: true,
        showRegularCounters: true,
        showCommanderDamageCounters: true,
        clickableCommanderDamageCounters: true,
        keepZeroCountersOnPlayerCard: true,
        saltyDefeatMessages: false,
        cycleSaltyDefeatMessages: false,
        gameTimer: true,
        gameTimerMainScreen: true,
        showClockOnMainScreen: true,
        randomPlayerColors: true,
        preserveBackgroundImagesOnShuffle: false,
        setLifeByTappingNumber: false,
        verticalTapAreas: true,
        cleanLook: true,
        criticalDamageWarning: false,
        customLongTapEnabled: true,
        customLongTapValue: 25,
        whitelabelIcon: null,
      ),
    );

    expect(await snapshotStore.load(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );

    await tester.pump();
    expect(find.text('Life counter unavailable'), findsNothing);

    await _pumpUntilSnapshotAvailable(tester, snapshotStore);
    final restoredSnapshot = await snapshotStore.load();

    expect(restoredSnapshot, isNotNull);
    expect(restoredSnapshot!.values['playerCount'], '4');
    expect(restoredSnapshot.values['startingLifeMP'], '40');
    expect(restoredSnapshot.values['players'], isNotNull);
    expect(restoredSnapshot.values['gameSettings'], isNotNull);

    final rebuiltSession = await sessionStore.load();
    final rebuiltSettings = await settingsStore.load();

    expect(rebuiltSession, isNotNull);
    expect(rebuiltSession!.lives, const [40, 27, 12, 3]);
    expect(rebuiltSession.poison, const [0, 1, 7, 10]);
    expect(rebuiltSession.commanderDamage[3][0], 11);
    expect(rebuiltSession.partnerCommanders, const [false, true, false, false]);
    expect(
      rebuiltSession.playerSpecialStates,
      const [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.deckedOut,
        LifeCounterPlayerSpecialState.answerLeft,
      ],
    );
    expect(rebuiltSession.firstPlayerIndex, 2);
    expect(rebuiltSession.turnTrackerActive, isTrue);
    expect(rebuiltSession.turnTrackerOngoingGame, isTrue);
    expect(rebuiltSession.turnTrackerAutoHighRoll, isTrue);
    expect(rebuiltSession.currentTurnPlayerIndex, 1);
    expect(rebuiltSession.currentTurnNumber, 7);
    expect(rebuiltSession.turnTimerActive, isTrue);
    expect(rebuiltSession.turnTimerSeconds, 93);

    expect(rebuiltSettings, isNotNull);
    expect(rebuiltSettings!.autoKill, isFalse);
    expect(rebuiltSettings.gameTimer, isTrue);
    expect(rebuiltSettings.customLongTapValue, 25);
    expect(rebuiltSettings.whitelabelIcon, isNull);
  });

  testWidgets('reopens from persisted Lotus snapshot after canonical bootstrap', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();

    await snapshotStore.clear();
    await sessionStore.save(
      const LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: [39, 28, 17, 6],
        poison: [0, 2, 5, 8],
        energy: [1, 3, 0, 2],
        experience: [0, 0, 4, 1],
        commanderCasts: [0, 2, 1, 3],
        partnerCommanders: [false, true, false, false],
        playerSpecialStates: [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.answerLeft,
        ],
        lastPlayerRolls: [null, null, null, null],
        lastHighRolls: [null, null, null, null],
        commanderDamage: [
          [0, 0, 7, 0],
          [0, 0, 0, 9],
          [2, 0, 0, 0],
          [0, 4, 0, 0],
        ],
        stormCount: 0,
        monarchPlayer: null,
        initiativePlayer: null,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 3,
        currentTurnNumber: 6,
        turnTimerActive: true,
        turnTimerSeconds: 45,
        lastTableEvent: null,
      ),
    );
    await settingsStore.save(
      const LifeCounterSettings(
        autoKill: true,
        lifeLossOnCommanderDamage: true,
        showCountersOnPlayerCard: true,
        showRegularCounters: true,
        showCommanderDamageCounters: false,
        clickableCommanderDamageCounters: false,
        keepZeroCountersOnPlayerCard: false,
        saltyDefeatMessages: true,
        cycleSaltyDefeatMessages: true,
        gameTimer: false,
        gameTimerMainScreen: false,
        showClockOnMainScreen: false,
        randomPlayerColors: true,
        preserveBackgroundImagesOnShuffle: true,
        setLifeByTappingNumber: true,
        verticalTapAreas: false,
        cleanLook: false,
        criticalDamageWarning: true,
        customLongTapEnabled: true,
        customLongTapValue: 15,
        whitelabelIcon: null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Life counter unavailable'), findsNothing);

    await _pumpUntilSnapshotAvailable(tester, snapshotStore);
    final snapshot = await snapshotStore.load();

    expect(snapshot, isNotNull);
    expect(snapshot!.values['players'], isNotNull);
    expect(snapshot.values['gameSettings'], isNotNull);

    await sessionStore.clear();
    await settingsStore.clear();

    expect(await sessionStore.load(), isNull);
    expect(await settingsStore.load(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Life counter unavailable'), findsNothing);

    await _pumpUntilCanonicalStateAvailable(tester, sessionStore, settingsStore);
    final restoredSession = await sessionStore.load();
    final restoredSettings = await settingsStore.load();

    expect(restoredSession, isNotNull);
    expect(restoredSession!.lives, const [39, 28, 17, 6]);
    expect(restoredSession.poison, const [0, 2, 5, 8]);
    expect(restoredSession.commanderDamage[1][3], 9);
    expect(restoredSession.partnerCommanders, const [false, true, false, false]);
    expect(
      restoredSession.playerSpecialStates,
      const [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.answerLeft,
      ],
    );
    expect(restoredSession.firstPlayerIndex, isNotNull);
    expect(restoredSession.firstPlayerIndex, inInclusiveRange(0, 3));
    expect(restoredSession.turnTrackerActive, isTrue);
    expect(restoredSession.turnTrackerOngoingGame, isTrue);
    expect(restoredSession.currentTurnPlayerIndex, isNotNull);
    expect(restoredSession.currentTurnPlayerIndex, inInclusiveRange(0, 3));
    expect(restoredSession.currentTurnNumber, greaterThanOrEqualTo(6));
    expect(restoredSession.turnTimerActive, isTrue);
    expect(restoredSession.turnTimerSeconds, greaterThanOrEqualTo(45));

    expect(restoredSettings, isNotNull);
    expect(restoredSettings!.autoKill, isTrue);
    expect(restoredSettings.randomPlayerColors, isTrue);
    expect(restoredSettings.customLongTapEnabled, isTrue);
    expect(restoredSettings.customLongTapValue, 15);
  });

}
