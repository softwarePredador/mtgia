import 'dart:convert';

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

Future<dynamic> _pumpUntilUiSnapshotFontsReady(
  WidgetTester tester,
  LotusUiSnapshotStore uiSnapshotStore, {
  bool requireTimerFonts = false,
}) async {
  dynamic snapshot = await uiSnapshotStore.load();
  for (var attempt = 0; attempt < 12; attempt += 1) {
    final fontsLoaded =
        snapshot != null &&
        snapshot.documentFontsStatus == 'loaded' &&
        snapshot.uiFontReady == true &&
        snapshot.displayFontReady == true &&
        snapshot.uiFontFamily.contains('Manrope');
    final timerFontsLoaded =
        !requireTimerFonts ||
        (snapshot != null &&
            snapshot.gameTimerFontFamily.contains('Manrope') &&
            snapshot.turnTrackerFontFamily.contains('Manrope'));
    if (fontsLoaded && timerFontsLoaded) {
      return snapshot;
    }

    await tester.pump(const Duration(seconds: 1));
    snapshot = await uiSnapshotStore.load();
  }

  return snapshot;
}

Map<String, dynamic> _decodeJavaScriptMap(Object? rawResult) {
  Object? value = rawResult;

  for (var attempt = 0; attempt < 3; attempt += 1) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.cast<String, dynamic>();
    }

    if (value is! String || value.isEmpty) {
      break;
    }

    value = jsonDecode(value);
  }

  throw StateError('Could not decode JavaScript result: $rawResult');
}

Future<Map<String, dynamic>> _readFontDiagnostics(dynamic screenState) async {
  final rawResult = await screenState.debugRunJavaScriptReturningResult('''
(() => JSON.stringify((() => {
  const safeRect = (node) => node ? node.getBoundingClientRect() : null;
  const safeStyle = (node) => node ? window.getComputedStyle(node) : null;
  const fontSet = document.fonts;
  const body = document.body;
  const firstName = document.querySelector('.player-name');
  const firstLifeBox = document.querySelector('.player-life-count');
  const timer = document.querySelector('.game-timer');
  const tracker = document.querySelector('.turn-time-tracker');
  const firstNameRect = safeRect(firstName);
  const firstLifeBoxRect = safeRect(firstLifeBox);
  const timerRect = safeRect(timer);
  const trackerRect = safeRect(tracker);
  const bodyStyle = safeStyle(body);
  const nameStyle = safeStyle(firstName);

  return {
    fonts_status: fontSet ? fontSet.status || '' : 'unsupported',
    body_font_family: bodyStyle ? bodyStyle.fontFamily || '' : '',
    first_name_present: !!firstName,
    first_name_font_family: nameStyle ? nameStyle.fontFamily || '' : '',
    manrope_ready: bodyStyle
      ? (bodyStyle.fontFamily || '').includes('Manrope')
      : (fontSet ? fontSet.check('16px "Manrope"') : false),
    fraunces_ready: nameStyle
      ? (nameStyle.fontFamily || '').includes('Fraunces')
      : (fontSet ? fontSet.check('16px "Fraunces"') : false),
    first_name_width: firstNameRect ? firstNameRect.width || 0 : 0,
    first_name_height: firstNameRect ? firstNameRect.height || 0 : 0,
    first_life_box_width: firstLifeBoxRect ? firstLifeBoxRect.width || 0 : 0,
    first_life_box_height: firstLifeBoxRect ? firstLifeBoxRect.height || 0 : 0,
    timer_width: timerRect ? timerRect.width || 0 : 0,
    timer_height: timerRect ? timerRect.height || 0 : 0,
    tracker_width: trackerRect ? trackerRect.width || 0 : 0,
    tracker_height: trackerRect ? trackerRect.height || 0 : 0,
  };
})()))()
''');

  return _decodeJavaScriptMap(rawResult);
}

Future<Map<String, dynamic>> _readIntroDiagnostics(dynamic screenState) async {
  final rawResult = await screenState.debugRunJavaScriptReturningResult('''
(() => JSON.stringify((() => {
  const hasVisibleNode = (selector) => {
    const node = document.querySelector(selector);
    if (!node) {
      return false;
    }

    const style = window.getComputedStyle(node);
    return (
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      style.opacity !== '0'
    );
  };

  return {
    tutorial_overlay_seen:
      window.localStorage.getItem('tutorialOverlay_v1') === 'true',
    own_commander_hint_seen:
      window.localStorage.getItem('ownCommanderDamageHintOverlay_v1') === 'true',
    turn_tracker_hint_seen:
      window.localStorage.getItem('turnTrackerHintOverlay_v1') === 'true',
    counters_hint_seen:
      window.localStorage.getItem('countersOnPlayerCardHintOverlay_v1') ===
      'true',
    first_time_overlay_visible: hasVisibleNode('.first-time-user-overlay'),
    own_commander_hint_visible: hasVisibleNode(
      '.own-commander-damage-hint-overlay'
    ),
    turn_tracker_hint_visible: hasVisibleNode('.turn-tracker-hint-overlay'),
    counters_hint_visible: hasVisibleNode('.show-counters-hint-overlay'),
  };
})()))()
''');

  return _decodeJavaScriptMap(rawResult);
}

Future<Map<String, dynamic>> _pumpUntilFontsLoaded(
  WidgetTester tester,
  dynamic screenState,
) async {
  var diagnostics = await _readFontDiagnostics(screenState);
  for (var attempt = 0; attempt < 12; attempt += 1) {
    final fontsLoaded = diagnostics['fonts_status'] == 'loaded';
    final manropeReady = diagnostics['manrope_ready'] == true;
    final frauncesReady = diagnostics['fraunces_ready'] == true;
    if (fontsLoaded && manropeReady && frauncesReady) {
      return diagnostics;
    }

    await tester.pump(const Duration(seconds: 1));
    diagnostics = await _readFontDiagnostics(screenState);
  }

  return diagnostics;
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

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));

    await tester.pump();

    expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
    expect(find.text('Life counter unavailable'), findsNothing);

    await tester.pump(const Duration(seconds: 8));
    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final uiSnapshot = await _pumpUntilUiSnapshotFontsReady(
      tester,
      uiSnapshotStore,
    );
    final dynamic screenState = tester.state(
      find.byType(LotusLifeCounterScreen),
    );
    final firstFontDiagnostics = await _pumpUntilFontsLoaded(
      tester,
      screenState,
    );
    final introDiagnostics = await _readIntroDiagnostics(screenState);
    await tester.pump(const Duration(seconds: 2));
    final secondFontDiagnostics = await _pumpUntilFontsLoaded(
      tester,
      screenState,
    );

    expect(find.text('Life counter unavailable'), findsNothing);
    expect(uiSnapshot, isNotNull);
    expect(uiSnapshot!.viewportWidth, greaterThan(300));
    expect(uiSnapshot.viewportHeight, greaterThan(600));
    expect(uiSnapshot.screenWidth, closeTo(uiSnapshot.viewportWidth, 1));
    expect(uiSnapshot.screenHeight, closeTo(uiSnapshot.viewportHeight, 1));
    expect(uiSnapshot.visualSkinApplied, isTrue);
    expect(uiSnapshot.uiFontFamily, contains('Manrope'));
    expect(uiSnapshot.documentFontsStatus, 'loaded');
    expect(uiSnapshot.uiFontReady, isTrue);
    expect(uiSnapshot.displayFontReady, isTrue);
    expect(uiSnapshot.horizontalOverflowPx, lessThanOrEqualTo(1.5));
    expect(uiSnapshot.verticalOverflowPx, lessThanOrEqualTo(1.5));
    expect(uiSnapshot.playerCardCount, 4);
    expect(uiSnapshot.firstPlayerCardWidth, greaterThan(150));
    expect(uiSnapshot.firstPlayerCardHeight, greaterThan(300));
    expect(uiSnapshot.firstPlayerLifeBoxWidth, greaterThan(60));
    expect(uiSnapshot.firstPlayerLifeBoxHeight, greaterThan(80));
    expect(uiSnapshot.firstLifeCountFontSize, greaterThan(0));
    expect(firstFontDiagnostics['fonts_status'], 'loaded');
    expect(firstFontDiagnostics['manrope_ready'], isTrue);
    expect(firstFontDiagnostics['fraunces_ready'], isTrue);
    expect(introDiagnostics['tutorial_overlay_seen'], isTrue);
    expect(introDiagnostics['own_commander_hint_seen'], isTrue);
    expect(introDiagnostics['turn_tracker_hint_seen'], isTrue);
    expect(introDiagnostics['counters_hint_seen'], isTrue);
    expect(introDiagnostics['first_time_overlay_visible'], isFalse);
    expect(introDiagnostics['own_commander_hint_visible'], isFalse);
    expect(introDiagnostics['turn_tracker_hint_visible'], isFalse);
    expect(introDiagnostics['counters_hint_visible'], isFalse);
    expect(firstFontDiagnostics['body_font_family'], contains('Manrope'));
    if (firstFontDiagnostics['first_name_present'] == true) {
      expect(
        firstFontDiagnostics['first_name_font_family'],
        contains('Fraunces'),
      );
    }
    expect(secondFontDiagnostics['fonts_status'], 'loaded');
    expect(secondFontDiagnostics['manrope_ready'], isTrue);
    expect(secondFontDiagnostics['fraunces_ready'], isTrue);
    expect(
      (secondFontDiagnostics['first_life_box_width'] as num).toDouble(),
      closeTo(
        (firstFontDiagnostics['first_life_box_width'] as num).toDouble(),
        0.5,
      ),
    );
    expect(
      (secondFontDiagnostics['first_life_box_height'] as num).toDouble(),
      closeTo(
        (firstFontDiagnostics['first_life_box_height'] as num).toDouble(),
        0.5,
      ),
    );
    expect(
      (secondFontDiagnostics['timer_width'] as num).toDouble(),
      closeTo((firstFontDiagnostics['timer_width'] as num).toDouble(), 0.5),
    );
    expect(
      (secondFontDiagnostics['tracker_width'] as num).toDouble(),
      closeTo((firstFontDiagnostics['tracker_width'] as num).toDouble(), 0.5),
    );
  });

  testWidgets(
    'bootstraps Lotus from canonical state when raw snapshot is absent',
    (tester) async {
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
        const MaterialApp(home: LotusLifeCounterScreen()),
      );

      await tester.pump();
      expect(find.text('Life counter unavailable'), findsNothing);

      await _pumpUntilSnapshotAvailable(tester, snapshotStore);
      await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);
      final restoredSnapshot = await snapshotStore.load();
      final uiSnapshot = await _pumpUntilUiSnapshotFontsReady(
        tester,
        uiSnapshotStore,
        requireTimerFonts: true,
      );
      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final introDiagnostics = await _readIntroDiagnostics(screenState);

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
      expect(uiSnapshot.visualSkinApplied, isTrue);
      expect(uiSnapshot.uiFontFamily, contains('Manrope'));
      expect(uiSnapshot.documentFontsStatus, 'loaded');
      expect(uiSnapshot.uiFontReady, isTrue);
      expect(uiSnapshot.displayFontReady, isTrue);
      expect(uiSnapshot.gameTimerFontFamily, contains('Manrope'));
      expect(uiSnapshot.turnTrackerFontFamily, contains('Manrope'));
      expect(uiSnapshot.gameTimerFontSize, inInclusiveRange(24, 40));
      expect(uiSnapshot.turnTrackerFontSize, inInclusiveRange(18, 28));
      expect(uiSnapshot.horizontalOverflowPx, lessThanOrEqualTo(1.5));
      expect(uiSnapshot.verticalOverflowPx, lessThanOrEqualTo(1.5));
      expect(uiSnapshot.firstPlayerLifeBoxWidth, greaterThan(60));
      expect(uiSnapshot.firstPlayerLifeBoxHeight, greaterThan(80));
      expect(introDiagnostics['tutorial_overlay_seen'], isTrue);
      expect(introDiagnostics['own_commander_hint_seen'], isTrue);
      expect(introDiagnostics['turn_tracker_hint_seen'], isTrue);
      expect(introDiagnostics['counters_hint_seen'], isTrue);
      expect(introDiagnostics['first_time_overlay_visible'], isFalse);
      expect(introDiagnostics['own_commander_hint_visible'], isFalse);
      expect(introDiagnostics['turn_tracker_hint_visible'], isFalse);
      expect(introDiagnostics['counters_hint_visible'], isFalse);

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
      expect(rebuiltSession.partnerCommanders, const [
        false,
        true,
        false,
        false,
      ]);
      expect(rebuiltSession.playerSpecialStates, const [
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.none,
        LifeCounterPlayerSpecialState.deckedOut,
        LifeCounterPlayerSpecialState.answerLeft,
      ]);
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
    },
  );
}
