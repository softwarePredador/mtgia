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
  required LifeCounterSessionStore sessionStore,
  required LifeCounterSettingsStore settingsStore,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<Map<String, dynamic>> _readTableState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_table_state_ownership_live';
  const nonceKey = '__manaloom_test_table_state_ownership_live_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const raw = localStorage.getItem('__manaloom_table_state');
    localStorage.setItem('$storageKey', raw ?? '{}');
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

Future<void> _pumpUntilOwnership(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore, {
  required int? monarchPlayer,
  required int? initiativePlayer,
}) async {
  var session = await sessionStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.monarchPlayer != monarchPlayer ||
            session.initiativePlayer != initiativePlayer);
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    session = await sessionStore.load();
  }
  expect(session, isNotNull);
  expect(session!.monarchPlayer, monarchPlayer);
  expect(session.initiativePlayer, initiativePlayer);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('applies monarch and initiative live on the WebView path', (
    tester,
  ) async {
    final snapshotStore = LotusStorageSnapshotStore();
    final uiSnapshotStore = LotusUiSnapshotStore();
    final sessionStore = LifeCounterSessionStore();
    final settingsStore = LifeCounterSettingsStore();

    await _stabilizeHarness(
      tester,
      snapshotStore: snapshotStore,
      uiSnapshotStore: uiSnapshotStore,
      sessionStore: sessionStore,
      settingsStore: settingsStore,
    );

    await sessionStore.save(LifeCounterSession.initial(playerCount: 4));

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();

    await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

    final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
    await state.debugHandleShellMessage(
      '{"type":"open-native-table-state","source":"monarch_surface_pressed"}',
    );
    await tester.pumpAndSettle();

    expect(find.text('Table State'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('life-counter-native-table-state-monarch-player-2')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('life-counter-native-table-state-initiative-player-1'),
      ),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-table-state-initiative-player-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('life-counter-native-table-state-apply')),
    );
    await tester.pumpAndSettle();

    await _pumpUntilOwnership(
      tester,
      sessionStore,
      monarchPlayer: 2,
      initiativePlayer: 1,
    );
    final tableState = await _readTableState(tester, snapshotStore, state);

    final session = await sessionStore.load();
    expect(session, isNotNull);
    expect(session!.stormCount, 0);
    expect(session.monarchPlayer, 2);
    expect(session.initiativePlayer, 1);

    expect(tableState['stormCount'], 0);
    expect(tableState['monarchPlayer'], 2);
    expect(tableState['initiativePlayer'], 1);

    final rawSnapshot = await snapshotStore.load();
    expect(rawSnapshot, isNotNull);
    expect(
      rawSnapshot!.values['__manaloom_table_state'],
      contains('"monarchPlayer":2'),
    );
    expect(
      rawSnapshot.values['__manaloom_table_state'],
      contains('"initiativePlayer":1'),
    );
  });
}
