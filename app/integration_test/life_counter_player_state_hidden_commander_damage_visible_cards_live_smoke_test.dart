import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
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

Future<LifeCounterSession?> _pumpUntilCommanderDamageApplied(
  WidgetTester tester,
  LifeCounterSessionStore sessionStore,
) async {
  var session = await sessionStore.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.resolvedCommanderDamageDetails[0][1].commanderOneDamage !=
                1);
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 500));
    session = await sessionStore.load();
  }
  return session;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'applies hidden commander damage through player state hub with visible player cards',
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

      await settingsStore.save(
        LifeCounterSettings.defaults.copyWith(
          autoKill: false,
          lifeLossOnCommanderDamage: false,
          showCountersOnPlayerCard: true,
          showCommanderDamageCounters: false,
        ),
      );
      await sessionStore.save(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 32, 25, 11],
          poison: [0, 0, 0, 0],
          energy: [0, 0, 0, 0],
          experience: [0, 0, 0, 0],
          commanderCasts: [0, 0, 0, 0],
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
          firstPlayerIndex: null,
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

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-commander-damage'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-commander-damage'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-state-manage-commander-damage'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-native-commander-damage-apply')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-commander-damage-plus-1-c1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-commander-damage-plus-1-c1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-commander-damage-plus-1-c1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-commander-damage-apply')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      final session = await _pumpUntilCommanderDamageApplied(
        tester,
        sessionStore,
      );
      expect(session, isNotNull);
      expect(
        session!.resolvedCommanderDamageDetails[0][1].commanderOneDamage,
        1,
      );

      final history = await historyStore.load();
      expect(history, isNotNull);
      expect(history!.lastTableEvent, isNull);

      final rawSnapshot = await snapshotStore.load();
      expect(rawSnapshot, isNotNull);
      expect(rawSnapshot!.values['players'], isNotNull);
      final players = List<Map<String, dynamic>>.from(
        (jsonDecode(rawSnapshot.values['players']!) as List).map(
          (entry) => Map<String, dynamic>.from(entry as Map),
        ),
      );
      final commanderDamageEntries = List<Map<String, dynamic>>.from(
        (players[0]['commanderDamage'] as List).map(
          (entry) => Map<String, dynamic>.from(entry as Map),
        ),
      );
      final playerTwoEntry = commanderDamageEntries.singleWhere(
        (entry) => entry['player'] == 'Player 2',
      );
      expect(Map<String, dynamic>.from(playerTwoEntry['damage'] as Map), {
        'commander1': 1,
      });
    },
  );
}
