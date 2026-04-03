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

Future<Map<String, dynamic>> _readDismissState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey =
      '__manaloom_test_option_card_player_state_appearance_dismiss_live';
  const nonceKey =
      '__manaloom_test_option_card_player_state_appearance_dismiss_live_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const playerCards = Array.from(document.querySelectorAll('.player-card'));
    const targetCard = playerCards[1];
    localStorage.setItem('$storageKey', JSON.stringify({
      probe: window.__manaloomOptionCardAppearanceDismissProbe ?? null,
      option_card_count:
        targetCard instanceof HTMLElement
          ? targetCard.querySelectorAll('.player-card-inner.option-card').length
          : null
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'dismisses player state appearance from option-card takeover without bundle reload on the WebView path',
    (tester) async {
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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(background: '#FF0A5B'),
            LifeCounterPlayerAppearance(background: '#CF7AEF'),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
          ],
          partnerCommanders: [false, false, false, false],
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
      await state.debugRunJavaScript('''
(() => {
  window.__manaloomOptionCardAppearanceDismissProbe = 'alive';
})()
''');
      await state.debugHandleShellMessage(
        '{"type":"open-native-player-state","source":"player_option_card_presented","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-native-player-appearance-apply')),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      final session = await sessionStore.load();
      expect(session, isNotNull);
      expect(session!.resolvedPlayerAppearances[1].background, '#FF0A5B');
      expect(
        session.resolvedPlayerAppearances[1].nickname,
        anyOf(isNull, equals('')),
      );

      final dismissState = await _readDismissState(
        tester,
        snapshotStore,
        state,
      );
      expect(dismissState['probe'], 'alive');
      expect(dismissState['option_card_count'], 0);
    },
  );
}
