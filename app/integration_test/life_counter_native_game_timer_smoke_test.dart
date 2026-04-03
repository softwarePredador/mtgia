import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
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

Future<void> _pumpUntilPausedStateAvailable(
  WidgetTester tester,
  LifeCounterGameTimerStateStore store,
) async {
  LifeCounterGameTimerState? state = await store.load();
  for (
    var attempt = 0;
    attempt < 20 && (state == null || !state.isPaused);
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    state = await store.load();
  }
  expect(state, isNotNull);
  expect(state!.isActive, isTrue);
  expect(state.isPaused, isTrue);
}

Future<Map<String, dynamic>> _readTimerDomState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_timer_pause_state';
  const nonceKey = '__manaloom_test_timer_pause_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const timer = document.querySelector('.game-timer:not(.current-time-clock)');
    localStorage.setItem('$storageKey', JSON.stringify({
      present: !!timer,
      paused: !!timer && timer.classList.contains('paused'),
      text: timer instanceof HTMLElement ? (timer.textContent || '').trim() : '',
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

Future<Map<String, dynamic>> _pumpUntilPausedTimerVisible(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  var state = await _readTimerDomState(tester, snapshotStore, screenState);
  for (
    var attempt = 0;
    attempt < 20 && (state['present'] != true || state['paused'] != true);
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    state = await _readTimerDomState(tester, snapshotStore, screenState);
  }

  expect(state['present'], isTrue);
  expect(state['paused'], isTrue);
  return state;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pauses the game timer live on the WebView path', (tester) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final uiSnapshotStore = LotusUiSnapshotStore();
    final gameTimerStateStore = LifeCounterGameTimerStateStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();

    await _stabilizeHarness(
      tester,
      snapshotStore: snapshotStore,
      uiSnapshotStore: uiSnapshotStore,
      gameTimerStateStore: gameTimerStateStore,
      sessionStore: sessionStore,
      settingsStore: settingsStore,
    );

    await gameTimerStateStore.save(
      LifeCounterGameTimerState(
        startTimeEpochMs:
            DateTime.now().millisecondsSinceEpoch -
            const Duration(seconds: 45).inMilliseconds,
        isPaused: false,
        pausedTimeEpochMs: null,
      ),
    );
    await sessionStore.save(LifeCounterSession.initial(playerCount: 4));

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();

    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
    await state.debugHandleShellMessage(
      '{"type":"open-native-game-timer","source":"game_timer_surface_pressed"}',
    );
    await tester.pumpAndSettle();

    expect(find.text('Game Timer'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('life-counter-native-game-timer-pause')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-timer-pause')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('life-counter-native-game-timer-apply')),
    );
    await tester.pumpAndSettle();

    await _pumpUntilPausedStateAvailable(tester, gameTimerStateStore);
    final timerDomState = await _pumpUntilPausedTimerVisible(
      tester,
      snapshotStore,
      state,
    );

    final updatedState = await gameTimerStateStore.load();
    expect(updatedState, isNotNull);
    expect(updatedState!.isActive, isTrue);
    expect(updatedState.isPaused, isTrue);
    expect(updatedState.pausedTimeEpochMs, isNotNull);
    expect(timerDomState['present'], isTrue);
    expect(timerDomState['paused'], isTrue);
    expect((timerDomState['text'] as String).isNotEmpty, isTrue);

    final rawSnapshot = await snapshotStore.load();
    expect(rawSnapshot, isNotNull);
    expect(rawSnapshot!.values['gameTimerState'], isNotNull);
    final storedTimerState =
        jsonDecode(rawSnapshot.values['gameTimerState']!)
            as Map<String, dynamic>;
    expect(storedTimerState['isPaused'], isTrue);
    expect(storedTimerState['pausedTime'], isNotNull);
  });
}
