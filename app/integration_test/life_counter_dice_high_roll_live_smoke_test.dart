import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
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
  required LifeCounterHistoryStore historyStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await historyStore.clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<LifeCounterSession?> _pumpUntilHighRollApplied(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
) async {
  var session = await sessionStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.lastHighRolls.whereType<int>().length !=
                session.playerCount ||
            !(session.lastTableEvent?.startsWith('High Roll') ?? false) &&
                !(session.lastTableEvent?.startsWith(
                      'Desempate do High Roll',
                    ) ??
                    false));
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    session = await sessionStore.load();
  }
  return session;
}

Future<LifeCounterHistoryState?> _pumpUntilHistoryMirrorsLastEvent(
  WidgetTester tester,
  LifeCounterHistoryStore historyStore,
) async {
  var history = await historyStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (history == null ||
            !(history.lastTableEvent?.startsWith('High Roll') ?? false) &&
                !(history.lastTableEvent?.startsWith(
                      'Desempate do High Roll',
                    ) ??
                    false));
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    history = await historyStore.load();
  }
  return history;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'applies high roll with canonical sync on the live WebView path',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final uiSnapshotStore = LotusUiSnapshotStore();
      final sessionStore = LifeCounterSessionStore();
      final settingsStore = LifeCounterSettingsStore();
      final historyStore = LifeCounterHistoryStore();

      await _stabilizeHarness(
        tester,
        snapshotStore: snapshotStore,
        uiSnapshotStore: uiSnapshotStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
        historyStore: historyStore,
      );

      await sessionStore.save(LifeCounterSession.initial(playerCount: 4));

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-dice","source":"dice_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dice Tools'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-dice-high-roll')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-native-dice-apply')));
      await tester.pumpAndSettle();

      final session = await _pumpUntilHighRollApplied(tester, sessionStore);
      final history = await _pumpUntilHistoryMirrorsLastEvent(
        tester,
        historyStore,
      );

      expect(session, isNotNull);
      expect(
        session!.lastHighRolls.whereType<int>().length,
        session.playerCount,
      );
      expect(
        session.lastTableEvent?.startsWith('High Roll') == true ||
            session.lastTableEvent?.startsWith('Desempate do High Roll') ==
                true,
        isTrue,
      );
      expect(session.lastPlayerRolls.whereType<int>(), isEmpty);

      expect(history, isNotNull);
      expect(history!.lastTableEvent, session.lastTableEvent);

      final rawSnapshot = await snapshotStore.load();
      expect(rawSnapshot, isNotNull);
      expect(rawSnapshot!.values['__manaloom_table_state'], isNotNull);
      final tableState = Map<String, dynamic>.from(
        jsonDecode(rawSnapshot.values['__manaloom_table_state']!) as Map,
      );

      expect(
        List<Object?>.from(tableState['lastHighRolls'] as List),
        equals(session.lastHighRolls),
      );
      expect(
        List<Object?>.from(tableState['lastPlayerRolls'] as List),
        equals(session.lastPlayerRolls),
      );
      expect(tableState['firstPlayerIndex'], session.firstPlayerIndex);
    },
  );
}
