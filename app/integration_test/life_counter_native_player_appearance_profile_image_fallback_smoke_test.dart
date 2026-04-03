import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<LifeCounterSession?> _pumpUntilImageProfileApplied(
  WidgetTester tester,
  LifeCounterSessionStore store,
) async {
  LifeCounterSession? session = await store.load();
  for (
    var attempt = 0;
    attempt < 20 &&
        (session == null ||
            session.resolvedPlayerAppearances[1].background != '#40B9FF' ||
            session.resolvedPlayerAppearances[1].backgroundImage !=
                'indexeddb://imageDatabase/images/10' ||
            session.resolvedPlayerAppearances[1].backgroundImagePartner !=
                'indexeddb://imageDatabase/images/11');
    attempt += 1
  ) {
    await tester.pump(const Duration(seconds: 1));
    session = await store.load();
  }
  return session;
}

Future<Map<String, dynamic>> _readImageProfileAppearanceState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_player_appearance_image_profile';
  const nonceKey = '__manaloom_test_player_appearance_image_profile_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const rawPlayers = localStorage.getItem('players');
    const rawAppearances = localStorage.getItem('__manaloom_player_appearances');
    const players = rawPlayers ? JSON.parse(rawPlayers) : [];
    const appearances = rawAppearances ? JSON.parse(rawAppearances) : [];
    const player = Array.isArray(players) && players.length > 1 ? players[1] : null;
    const appearance = Array.isArray(appearances) && appearances.length > 1 ? appearances[1] : null;
    localStorage.setItem('$storageKey', JSON.stringify({
      player_background: player?.background ?? null,
      player_background_image: player?.backgroundImage ?? null,
      player_background_image_partner: player?.backgroundImagePartner ?? null,
      appearance_background: appearance?.background ?? null,
      appearance_background_image: appearance?.backgroundImage ?? null,
      appearance_background_image_partner: appearance?.backgroundImagePartner ?? null,
      probe: window.__manaloomPlayerAppearanceImageProfileProbe ?? null
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
    'keeps image-backed player appearance profiles on reload fallback in the live WebView path',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final profileStore = LifeCounterPlayerAppearanceProfileStore();
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await snapshotStore.clear();
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

      final profiles = await profileStore.saveProfile(
        name: 'Image Pod',
        appearance: const LifeCounterPlayerAppearance(
          background: '#40B9FF',
          backgroundImage: 'indexeddb://imageDatabase/images/10',
          backgroundImagePartner: 'indexeddb://imageDatabase/images/11',
        ),
      );
      final profileId = profiles.single.id;

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugRunJavaScript('''
(() => {
  window.__manaloomPlayerAppearanceImageProfileProbe = 'alive';
})()
''');
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

      final session = await _pumpUntilImageProfileApplied(
        tester,
        LifeCounterSessionStore(),
      );
      expect(session, isNotNull);
      expect(session!.resolvedPlayerAppearances[1].background, '#40B9FF');
      expect(
        session.resolvedPlayerAppearances[1].backgroundImage,
        'indexeddb://imageDatabase/images/10',
      );
      expect(
        session.resolvedPlayerAppearances[1].backgroundImagePartner,
        'indexeddb://imageDatabase/images/11',
      );

      final appearanceState = await _readImageProfileAppearanceState(
        tester,
        snapshotStore,
        state,
      );
      expect(appearanceState['player_background'], '#40B9FF');
      expect(appearanceState['appearance_background'], '#40B9FF');
      expect(appearanceState['probe'], isNull);
    },
  );
}
