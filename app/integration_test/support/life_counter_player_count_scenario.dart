import 'dart:convert';

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
  for (
    var attempt = 0;
    attempt < 20 &&
        (snapshot == null ||
            snapshot.values['playerCount'] != '$expectedPlayerCount');
    attempt += 1
  ) {
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
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null || session.playerCount != expectedPlayerCount);
    attempt += 1
  ) {
    await tester.pump(const Duration(seconds: 1));
    session = await sessionStore.load();
  }
  expect(session, isNotNull);
  expect(session!.playerCount, expectedPlayerCount);
}

const Map<int, List<String>> _expectedSeatFacings = <int, List<String>>{
  2: <String>['opposite', 'near'],
  3: <String>['opposite', 'opposite', 'near'],
  4: <String>['opposite', 'opposite', 'near', 'near'],
  5: <String>['opposite', 'opposite', 'left', 'right', 'near'],
  6: <String>['opposite', 'opposite', 'left', 'right', 'near', 'near'],
};

const Map<String, String> _expectedSeatRotations = <String, String>{
  'opposite': '180deg',
  'near': '0deg',
  'left': '90deg',
  'right': '-90deg',
};

Future<List<Map<String, dynamic>>> _readTabletopSeatLayout(
  WidgetTester tester,
  dynamic screenState,
  int expectedPlayerCount,
) async {
  final requestId = DateTime.now().microsecondsSinceEpoch;
  Object? lastPayload;
  Object? lastDiagnostics;
  for (var attempt = 0; attempt < 24; attempt += 1) {
    screenState.debugClearLastShellMessage();
    await screenState.debugRunJavaScript('''
(() => {
  const payload = window.__ManaLoomTabletopSeatLayout?.snapshot?.() || [];
  FlutterManaLoomShellBridge.postMessage(JSON.stringify({
    type: 'debug_tabletop_seat_layout',
    request_id: $requestId,
    payload,
    diagnostics: {
      apiPresent: !!window.__ManaLoomTabletopSeatLayout,
      playerCount: localStorage.getItem('playerCount'),
      layoutType: localStorage.getItem('layoutType'),
      bodyClass: document.body?.className || '',
      cards: Array.from(document.querySelectorAll('.player-card')).map((card) => {
        const bounds = card.getBoundingClientRect();
        return {
          className: card.className,
          parentClassName: card.parentElement?.className || '',
          parentTagName: card.parentElement?.tagName || '',
          overlayAncestor: card.closest('[class*="overlay"]')?.className || null,
          width: bounds.width,
          height: bounds.height,
          top: bounds.top,
          left: bounds.left,
        };
      }),
    },
  }));
})()
''');
    await tester.pump(const Duration(milliseconds: 250));
    final rawMessage = screenState.debugGetLastShellMessage();
    if (rawMessage is! String || rawMessage.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map ||
          decoded['type'] != 'debug_tabletop_seat_layout' ||
          decoded['request_id'] != requestId ||
          decoded['payload'] is! List) {
        continue;
      }
      lastPayload = decoded['payload'];
      lastDiagnostics = decoded['diagnostics'];
      final payload = (decoded['payload'] as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
      if (payload.length == expectedPlayerCount) {
        return payload;
      }
    } catch (_) {}
  }

  fail(
    'Tabletop seat layout did not stabilize for $expectedPlayerCount players. '
    'lastPayload=$lastPayload diagnostics=$lastDiagnostics',
  );
}

void _expectTabletopSeatLayout(
  List<Map<String, dynamic>> seats,
  int playerCount,
) {
  final expectedFacings = _expectedSeatFacings[playerCount]!;
  expect(
    seats.map((seat) => seat['facing']).toList(growable: false),
    expectedFacings,
  );
  for (var index = 0; index < seats.length; index += 1) {
    final seat = seats[index];
    final facing = expectedFacings[index];
    expect(seat['rotation'], _expectedSeatRotations[facing]);
    expect((seat['cardWidth'] as num?) ?? 0, greaterThan(0));
    expect((seat['cardHeight'] as num?) ?? 0, greaterThan(0));
    expect((seat['panelWidth'] as num?) ?? 0, greaterThan(0));
    expect((seat['panelHeight'] as num?) ?? 0, greaterThan(0));
    expect(seat['panelFits'], isTrue);
  }
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

  await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
  await tester.pump();
  expect(find.text('Life counter unavailable'), findsNothing);

  await _pumpUntilSnapshotAvailable(
    tester,
    snapshotStore,
    scenario.playerCount,
  );
  await _pumpUntilCanonicalSessionAvailable(
    tester,
    sessionStore,
    scenario.playerCount,
  );

  final snapshot = await snapshotStore.load();
  final rebuiltSession = await sessionStore.load();
  final rebuiltSettings = await settingsStore.load();
  final dynamic screenState = tester.state(find.byType(LotusLifeCounterScreen));
  final seats = await _readTabletopSeatLayout(
    tester,
    screenState,
    scenario.playerCount,
  );

  expect(snapshot, isNotNull);
  expect(snapshot!.values['playerCount'], '${scenario.playerCount}');
  expect(
    snapshot.values[scenario.playerCount == 2
        ? 'startingLife2P'
        : 'startingLifeMP'],
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
  _expectTabletopSeatLayout(seats, scenario.playerCount);

  await _bestEffortTeardown(
    tester,
    snapshotStore: snapshotStore,
    sessionStore: sessionStore,
    settingsStore: settingsStore,
  );
}
