import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<Map<String, dynamic>> _readCommanderDamageHubState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey =
      '__manaloom_test_player_state_hidden_commander_damage_lifeloss_fallback';
  const nonceKey =
      '__manaloom_test_player_state_hidden_commander_damage_lifeloss_fallback_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    localStorage.setItem('$storageKey', JSON.stringify({
      probe: window.__manaloomPlayerStateHiddenCommanderDamageLifeLossProbe ?? null
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

Future<LifeCounterSession?> _pumpUntilCommanderDamageApplied(
  WidgetTester tester,
  LifeCounterSessionStore store,
) async {
  LifeCounterSession? session = await store.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.resolvedCommanderDamageDetails[0][1].totalDamage != 1);
    attempt += 1
  ) {
    await tester.pump(const Duration(seconds: 1));
    session = await store.load();
  }
  return session;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'falls back on hidden commander damage through player state when life loss on commander damage stays enabled',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      await snapshotStore.clear();
      await LifeCounterSettingsStore().save(
        LifeCounterSettings.defaults.copyWith(
          autoKill: false,
          lifeLossOnCommanderDamage: true,
          showCountersOnPlayerCard: false,
          showCommanderDamageCounters: false,
        ),
      );
      await LifeCounterSessionStore().save(
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
      await tester.pump(const Duration(seconds: 8));

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugRunJavaScript('''
(() => {
  window.__manaloomPlayerStateHiddenCommanderDamageLifeLossProbe = 'alive';
})()
''');
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
        LifeCounterSessionStore(),
      );
      expect(session, isNotNull);
      expect(
        session!.resolvedCommanderDamageDetails[0][1],
        const LifeCounterCommanderDamageDetail(
          commanderOneDamage: 1,
          commanderTwoDamage: 0,
        ),
      );

      final commanderDamageHubState = await _readCommanderDamageHubState(
        tester,
        snapshotStore,
        state,
      );
      expect(commanderDamageHubState['probe'], isNull);

      final rawSnapshot = await snapshotStore.load();
      expect(rawSnapshot, isNotNull);
      expect(rawSnapshot!.values['players'], isNotNull);
    },
  );
}
