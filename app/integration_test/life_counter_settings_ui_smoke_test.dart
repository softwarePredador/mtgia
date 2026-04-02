import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
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
  required LifeCounterGameTimerStateStore gameTimerStateStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await gameTimerStateStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('applies settings that materially change the live Lotus UI', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();
    final uiSnapshotStore = LotusUiSnapshotStore();
    final gameTimerStateStore = LifeCounterGameTimerStateStore();

    const session = LifeCounterSession(
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
      turnTrackerAutoHighRoll: false,
      currentTurnPlayerIndex: 1,
      currentTurnNumber: 7,
      turnTimerActive: true,
      turnTimerSeconds: 93,
      lastTableEvent: null,
    );

    const enabledSettings = LifeCounterSettings(
      autoKill: true,
      lifeLossOnCommanderDamage: true,
      showCountersOnPlayerCard: true,
      showRegularCounters: true,
      showCommanderDamageCounters: true,
      clickableCommanderDamageCounters: true,
      keepZeroCountersOnPlayerCard: true,
      saltyDefeatMessages: true,
      cycleSaltyDefeatMessages: true,
      gameTimer: true,
      gameTimerMainScreen: true,
      showClockOnMainScreen: true,
      randomPlayerColors: false,
      preserveBackgroundImagesOnShuffle: true,
      setLifeByTappingNumber: true,
      verticalTapAreas: true,
      cleanLook: true,
      criticalDamageWarning: true,
      customLongTapEnabled: true,
      customLongTapValue: 15,
      whitelabelIcon: null,
    );

    const disabledSettings = LifeCounterSettings(
      autoKill: true,
      lifeLossOnCommanderDamage: true,
      showCountersOnPlayerCard: false,
      showRegularCounters: false,
      showCommanderDamageCounters: false,
      clickableCommanderDamageCounters: false,
      keepZeroCountersOnPlayerCard: false,
      saltyDefeatMessages: true,
      cycleSaltyDefeatMessages: true,
      gameTimer: false,
      gameTimerMainScreen: false,
      showClockOnMainScreen: false,
      randomPlayerColors: false,
      preserveBackgroundImagesOnShuffle: true,
      setLifeByTappingNumber: false,
      verticalTapAreas: false,
      cleanLook: false,
      criticalDamageWarning: true,
      customLongTapEnabled: false,
      customLongTapValue: 10,
      whitelabelIcon: null,
    );

    Future<void> prepareStores(LifeCounterSettings settings) async {
      await snapshotStore.clear();
      await sessionStore.clear();
      await settingsStore.clear();
      await uiSnapshotStore.clear();
      await gameTimerStateStore.clear();
      await sessionStore.save(session);
      await settingsStore.save(settings);
    }

    await _stabilizeHarness(
      tester,
      snapshotStore: snapshotStore,
      uiSnapshotStore: uiSnapshotStore,
      gameTimerStateStore: gameTimerStateStore,
      sessionStore: sessionStore,
      settingsStore: settingsStore,
    );
    await prepareStores(enabledSettings);

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );
    await tester.pump();

    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);
    final enabledUiSnapshot = await uiSnapshotStore.load();

    expect(enabledUiSnapshot, isNotNull);
    expect(enabledUiSnapshot!.playerCardCount, 4);
    expect(enabledUiSnapshot.setLifeByTapEnabled, isTrue);
    expect(enabledUiSnapshot.verticalTapAreasEnabled, isTrue);
    expect(enabledUiSnapshot.cleanLookEnabled, isTrue);
    expect(enabledUiSnapshot.regularCounterCount, greaterThan(0));
    expect(enabledUiSnapshot.commanderDamageCounterCount, greaterThan(0));
    expect(enabledUiSnapshot.gameTimerCount, 1);
    expect(enabledUiSnapshot.gameTimerPausedCount, 0);
    expect(enabledUiSnapshot.clockCount, 1);
    expect(enabledUiSnapshot.clockWithGameTimerCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    await _stabilizeHarness(
      tester,
      snapshotStore: snapshotStore,
      uiSnapshotStore: uiSnapshotStore,
      gameTimerStateStore: gameTimerStateStore,
      sessionStore: sessionStore,
      settingsStore: settingsStore,
    );
    await prepareStores(disabledSettings);

    await tester.pumpWidget(
      const MaterialApp(
        home: LotusLifeCounterScreen(),
      ),
    );
    await tester.pump();

    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);
    final disabledUiSnapshot = await uiSnapshotStore.load();

    expect(disabledUiSnapshot, isNotNull);
    expect(disabledUiSnapshot!.playerCardCount, 4);
    expect(disabledUiSnapshot.setLifeByTapEnabled, isFalse);
    expect(disabledUiSnapshot.verticalTapAreasEnabled, isFalse);
    expect(disabledUiSnapshot.cleanLookEnabled, isFalse);
    expect(disabledUiSnapshot.regularCounterCount, 0);
    expect(disabledUiSnapshot.commanderDamageCounterCount, 0);
    expect(disabledUiSnapshot.gameTimerCount, 0);
    expect(disabledUiSnapshot.gameTimerPausedCount, 0);
    expect(disabledUiSnapshot.clockCount, 0);
    expect(disabledUiSnapshot.clockWithGameTimerCount, 0);
  });
}
