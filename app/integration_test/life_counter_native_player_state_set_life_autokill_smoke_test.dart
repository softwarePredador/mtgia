import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<LifeCounterSession?> _pumpUntilKnockoutApplied(
  WidgetTester tester,
  LifeCounterSessionStore store,
) async {
  LifeCounterSession? session = await store.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.lives[1] != 0 ||
            session.lastTableEvent != 'Jogador 2 foi nocauteado');
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
    'auto-knocks out from the ManaLoom player state set life hub on the live WebView path',
    (tester) async {
      await LotusStorageSnapshotStore().clear();
      await LifeCounterSettingsStore().save(
        LifeCounterSettings.defaults.copyWith(autoKill: true),
      );
      await LifeCounterSessionStore().save(
        const LifeCounterSession(
          playerCount: 4,
          startingLifeTwoPlayer: 20,
          startingLifeMultiPlayer: 40,
          lives: [40, 5, 25, 11],
          poison: [0, 0, 0, 0],
          energy: [0, 0, 0, 0],
          experience: [0, 0, 0, 0],
          commanderCasts: [0, 0, 0, 0],
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
      await tester.pump(const Duration(seconds: 8));

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-player-state","source":"player_option_card_presented","targetPlayerIndex":1}',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-player-state-set-life')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-player-state-set-life')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-set-life')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-adjust-minus-10')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-apply')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final session = await _pumpUntilKnockoutApplied(
        tester,
        LifeCounterSessionStore(),
      );
      expect(session, isNotNull);
      expect(session!.lives[1], 0);
      expect(session.lastTableEvent, 'Jogador 2 foi nocauteado');
    },
  );
}
