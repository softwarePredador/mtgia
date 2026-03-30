import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _pumpUntilSnapshotAvailable(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  int expectedPlayerCount,
) async {
  var snapshot = await snapshotStore.load();
  for (var attempt = 0;
      attempt < 20 &&
          (snapshot == null ||
              snapshot.values['playerCount'] != '$expectedPlayerCount');
      attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await snapshotStore.load();
  }
  expect(snapshot, isNotNull);
  expect(snapshot!.values['playerCount'], '$expectedPlayerCount');
}

Future<void> _pumpUntilCanonicalSessionAvailable(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
  int expectedPlayerCount,
) async {
  var session = await sessionStore.load();
  for (var attempt = 0;
      attempt < 20 &&
          (session == null || session.playerCount != expectedPlayerCount);
      attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    session = await sessionStore.load();
  }
  expect(session, isNotNull);
  expect(session!.playerCount, expectedPlayerCount);
}

Future<void> _clearStateAndWaitForSnapshotToStayGone(
  WidgetTester tester, {
  required LotusStorageSnapshotStore snapshotStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));

  for (var attempt = 0; attempt < 5; attempt += 1) {
    await snapshotStore.clear();
    await sessionStore.clear();
    await settingsStore.clear();
    await tester.pump(const Duration(seconds: 1));

    if (await snapshotStore.load() == null) {
      await tester.pump(const Duration(milliseconds: 300));
      await snapshotStore.clear();
      if (await snapshotStore.load() == null) {
        return;
      }
    }
  }

  expect(await snapshotStore.load(), isNull);
}

Future<void> _bestEffortTeardown(
  WidgetTester tester, {
  required LotusStorageSnapshotStore snapshotStore,
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  await snapshotStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
}

const LifeCounterSettings defaultPlayerCountSmokeSettings = LifeCounterSettings(
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
  randomPlayerColors: false,
  preserveBackgroundImagesOnShuffle: true,
  setLifeByTappingNumber: true,
  verticalTapAreas: false,
  cleanLook: false,
  criticalDamageWarning: true,
  customLongTapEnabled: false,
  customLongTapValue: 10,
  whitelabelIcon: null,
);

Future<void> runPlayerCountScenario(
  WidgetTester tester,
  LifeCounterSession scenario,
) async {
  final snapshotStore = LotusStorageSnapshotStore();
  final sessionStore = LifeCounterSessionStore();
  final settingsStore = LifeCounterSettingsStore();

  await _clearStateAndWaitForSnapshotToStayGone(
    tester,
    snapshotStore: snapshotStore,
    sessionStore: sessionStore,
    settingsStore: settingsStore,
  );
  await sessionStore.save(scenario);
  await settingsStore.save(defaultPlayerCountSmokeSettings);

  expect(await snapshotStore.load(), isNull);

  await tester.pumpWidget(
    const MaterialApp(
      home: LotusLifeCounterScreen(),
    ),
  );
  await tester.pump();
  expect(find.text('Life counter unavailable'), findsNothing);

  await _pumpUntilSnapshotAvailable(tester, snapshotStore, scenario.playerCount);
  await _pumpUntilCanonicalSessionAvailable(
    tester,
    sessionStore,
    scenario.playerCount,
  );

  final snapshot = await snapshotStore.load();
  final rebuiltSession = await sessionStore.load();
  final rebuiltSettings = await settingsStore.load();

  expect(snapshot, isNotNull);
  expect(snapshot!.values['playerCount'], '${scenario.playerCount}');
  expect(
    snapshot.values[
        scenario.playerCount == 2 ? 'startingLife2P' : 'startingLifeMP'],
    '${scenario.startingLife}',
  );

  expect(rebuiltSession, isNotNull);
  expect(rebuiltSession!.playerCount, scenario.playerCount);
  expect(rebuiltSession.lives, scenario.lives);
  expect(rebuiltSession.poison, scenario.poison);
  expect(rebuiltSession.partnerCommanders, scenario.partnerCommanders);
  expect(rebuiltSession.playerSpecialStates, scenario.playerSpecialStates);
  if (scenario.playerCount == 6) {
    expect(rebuiltSession.firstPlayerIndex, isNotNull);
    expect(rebuiltSession.firstPlayerIndex, inInclusiveRange(0, 5));
  } else {
    expect(rebuiltSession.firstPlayerIndex, scenario.firstPlayerIndex);
  }
  expect(rebuiltSession.turnTrackerActive, scenario.turnTrackerActive);
  expect(
    rebuiltSession.turnTrackerOngoingGame,
    scenario.turnTrackerOngoingGame,
  );
  expect(
    rebuiltSession.turnTrackerAutoHighRoll,
    scenario.turnTrackerAutoHighRoll,
  );
  expect(
    rebuiltSession.currentTurnPlayerIndex,
    scenario.currentTurnPlayerIndex,
  );
  expect(rebuiltSession.currentTurnNumber, scenario.currentTurnNumber);
  expect(rebuiltSession.turnTimerActive, scenario.turnTimerActive);
  expect(
    rebuiltSession.turnTimerSeconds,
    inInclusiveRange(scenario.turnTimerSeconds, scenario.turnTimerSeconds + 5),
  );

  expect(rebuiltSettings, isNotNull);
  expect(
    rebuiltSettings!.showCountersOnPlayerCard,
    defaultPlayerCountSmokeSettings.showCountersOnPlayerCard,
  );

  await _bestEffortTeardown(
    tester,
    snapshotStore: snapshotStore,
    sessionStore: sessionStore,
    settingsStore: settingsStore,
  );
}
