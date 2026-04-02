import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
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
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  LotusUiSnapshotStore uiSnapshotStore,
  LifeCounterGameTimerStateStore gameTimerStateStore,
  LifeCounterSessionStore sessionStore,
  LifeCounterSettingsStore settingsStore,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await gameTimerStateStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots the embedded life counter without host error', (
    tester,
  ) async {
    final uiSnapshotStore = LotusUiSnapshotStore();

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );

    await tester.pump();

    expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
    expect(find.text('Life counter unavailable'), findsNothing);

    await tester.pump(const Duration(seconds: 8));
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final uiSnapshot = await uiSnapshotStore.load();

    expect(find.text('Life counter unavailable'), findsNothing);
    expect(uiSnapshot, isNotNull);
    expect(uiSnapshot!.viewportWidth, greaterThan(300));
    expect(uiSnapshot.viewportHeight, greaterThan(600));
    expect(uiSnapshot.screenWidth, closeTo(uiSnapshot.viewportWidth, 1));
    expect(uiSnapshot.screenHeight, closeTo(uiSnapshot.viewportHeight, 1));
    expect(uiSnapshot.playerCardCount, 4);
    expect(uiSnapshot.firstPlayerCardWidth, greaterThan(150));
    expect(uiSnapshot.firstPlayerCardHeight, greaterThan(300));
  });

  testWidgets('bootstraps Lotus from canonical state when raw snapshot is absent', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final uiSnapshotStore = LotusUiSnapshotStore();
    final gameTimerStateStore = LifeCounterGameTimerStateStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();

    await _stabilizeHarness(
      tester,
      snapshotStore,
      uiSnapshotStore,
      gameTimerStateStore,
      sessionStore,
      settingsStore,
    );
    await snapshotStore.clear();
    await gameTimerStateStore.save(
      const LifeCounterGameTimerState(
        startTimeEpochMs: 1711800000000,
        isPaused: true,
        pausedTimeEpochMs: 1711800005000,
      ),
    );
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

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );

    await tester.pump();
    expect(find.text('Life counter unavailable'), findsNothing);

    await _pumpUntilSnapshotAvailable(tester, snapshotStore);
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);
    final restoredSnapshot = await snapshotStore.load();
    final uiSnapshot = await uiSnapshotStore.load();

    expect(restoredSnapshot, isNotNull);
    expect(restoredSnapshot!.values['playerCount'], '4');
    expect(restoredSnapshot.values['startingLifeMP'], '40');
    expect(restoredSnapshot.values['players'], isNotNull);
    expect(restoredSnapshot.values['gameSettings'], isNotNull);
    expect(restoredSnapshot.values['gameTimerState'], isNotNull);
    expect(uiSnapshot, isNotNull);
    expect(uiSnapshot!.viewportWidth, greaterThan(300));
    expect(uiSnapshot.viewportHeight, greaterThan(600));
    expect(uiSnapshot.firstPlayerCardWidth, greaterThan(150));

    final rebuiltGameTimerState = await gameTimerStateStore.load();
    final rebuiltSession = await sessionStore.load();
    final rebuiltSettings = await settingsStore.load();

    expect(rebuiltGameTimerState, isNotNull);
    expect(rebuiltGameTimerState!.startTimeEpochMs, 1711800000000);
    expect(rebuiltGameTimerState.isPaused, isTrue);
    expect(rebuiltGameTimerState.pausedTimeEpochMs, 1711800005000);
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
    expect(rebuiltSession.firstPlayerIndex, 1);
    expect(rebuiltSession.turnTrackerActive, isTrue);
    expect(rebuiltSession.turnTrackerOngoingGame, isTrue);
    expect(rebuiltSession.turnTrackerAutoHighRoll, isTrue);
    expect(rebuiltSession.currentTurnPlayerIndex, 1);
    expect(rebuiltSession.currentTurnNumber, 7);
    expect(rebuiltSession.turnTimerActive, isTrue);
    expect(rebuiltSession.turnTimerSeconds, greaterThanOrEqualTo(93));

    expect(rebuiltSettings, isNotNull);
    expect(rebuiltSettings!.autoKill, isFalse);
    expect(rebuiltSettings.gameTimer, isTrue);
    expect(rebuiltSettings.customLongTapValue, 25);
    expect(rebuiltSettings.whitelabelIcon, isNull);
  });

}
