import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<LifeCounterSession?> _pumpUntilAppearanceProfileApplied(
  WidgetTester tester,
  LifeCounterSessionStore store,
) async {
  LifeCounterSession? session = await store.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.resolvedPlayerAppearances[1].nickname != 'Profiled Pilot' ||
            session.resolvedPlayerAppearances[1].background != '#40B9FF');
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
    'applies a saved ManaLoom player appearance profile on the live WebView path',
    (tester) async {
      final profileStore = LifeCounterPlayerAppearanceProfileStore();
      await LotusStorageSnapshotStore().clear();
      await LifeCounterSettingsStore().clear();
      await LifeCounterSessionStore().clear();
      await profileStore.clear();

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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(background: '#FF0A5B'),
            LifeCounterPlayerAppearance(background: '#CF7AEF'),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
          ],
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

      await profileStore.saveProfile(
        name: 'Partner Pod',
        appearance: const LifeCounterPlayerAppearance(
          background: '#40B9FF',
          nickname: 'Profiled Pilot',
        ),
      );
      final profiles = await profileStore.load();
      expect(profiles, hasLength(1));
      final profileId = profiles.first.id;

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(
          Key('life-counter-native-player-appearance-apply-profile-$profileId'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          Key('life-counter-native-player-appearance-apply-profile-$profileId'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-appearance-apply')),
      );
      await tester.pumpAndSettle();

      final session = await _pumpUntilAppearanceProfileApplied(
        tester,
        LifeCounterSessionStore(),
      );
      expect(session, isNotNull);
      expect(session!.resolvedPlayerAppearances[1].nickname, 'Profiled Pilot');
      expect(session.resolvedPlayerAppearances[1].background, '#40B9FF');
    },
  );
}
