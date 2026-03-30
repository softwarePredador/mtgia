import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifeCounterSessionStore', () {
    late LifeCounterSessionStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LifeCounterSessionStore();
    });

    test('saves and restores a round-trip session', () async {
      final session = LifeCounterSession(
        playerCount: 4,
        startingLifeTwoPlayer: 20,
        startingLifeMultiPlayer: 40,
        lives: const [40, 33, 25, 0],
        poison: const [0, 3, 1, 10],
        energy: const [2, 0, 7, 1],
        experience: const [0, 4, 0, 2],
        commanderCasts: const [0, 1, 3, 2],
        commanderCastDetails: const [
          LifeCounterCommanderCastDetail.zero,
          LifeCounterCommanderCastDetail(
            commanderOneCasts: 1,
            commanderTwoCasts: 0,
          ),
          LifeCounterCommanderCastDetail(
            commanderOneCasts: 2,
            commanderTwoCasts: 3,
          ),
          LifeCounterCommanderCastDetail(
            commanderOneCasts: 0,
            commanderTwoCasts: 2,
          ),
        ],
        playerExtraCounters: const [
          {'charge': 3},
          {'rad': 1},
          {},
          {'tickets': 2},
        ],
        partnerCommanders: const [false, true, false, false],
        playerSpecialStates: const [
          LifeCounterPlayerSpecialState.none,
          LifeCounterPlayerSpecialState.deckedOut,
          LifeCounterPlayerSpecialState.answerLeft,
          LifeCounterPlayerSpecialState.none,
        ],
        lastPlayerRolls: const [6, null, 18, 4],
        lastHighRolls: const [12, 20, 16, 8],
        commanderDamage: const [
          [0, 7, 0, 0],
          [5, 0, 0, 0],
          [0, 4, 0, 0],
          [0, 0, 9, 0],
        ],
        commanderDamageDetails: const [
          [
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail(
              commanderOneDamage: 5,
              commanderTwoDamage: 2,
            ),
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail.zero,
          ],
          [
            LifeCounterCommanderDamageDetail(
              commanderOneDamage: 5,
              commanderTwoDamage: 0,
            ),
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail.zero,
          ],
          [
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail(
              commanderOneDamage: 1,
              commanderTwoDamage: 3,
            ),
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail.zero,
          ],
          [
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail.zero,
            LifeCounterCommanderDamageDetail(
              commanderOneDamage: 7,
              commanderTwoDamage: 2,
            ),
            LifeCounterCommanderDamageDetail.zero,
          ],
        ],
        stormCount: 13,
        monarchPlayer: 1,
        initiativePlayer: 2,
        firstPlayerIndex: 1,
        turnTrackerActive: true,
        turnTrackerOngoingGame: true,
        turnTrackerAutoHighRoll: false,
        currentTurnPlayerIndex: 2,
        currentTurnNumber: 9,
        turnTimerActive: true,
        turnTimerSeconds: 125,
        lastTableEvent: 'Primeiro jogador: Jogador 2',
      );

      await store.save(session);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.toJson(), session.toJson());
    });

    test(
      'sanitizes legacy set-life events on load and writes back normalized json',
      () async {
        SharedPreferences.setMockInitialValues({
          legacyLifeCounterSessionPrefsKey: jsonEncode({
            'player_count': 4,
            'starting_life': 40,
            'starting_life_two_player': 20,
            'starting_life_multi_player': 40,
            'lives': [40, 40, 40, 40],
            'poison': [0, 0, 0, 0],
            'energy': [0, 0, 0, 0],
            'experience': [0, 0, 0, 0],
            'commander_casts': [0, 0, 0, 0],
            'commander_damage': [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            'storm_count': 0,
            'last_table_event': 'Jogador 3 ajustado para 15 de vida',
          }),
        });
        store = LifeCounterSessionStore();

        final restored = await store.load();
        final prefs = await SharedPreferences.getInstance();
        final normalizedRaw = prefs.getString(legacyLifeCounterSessionPrefsKey);

        expect(restored, isNotNull);
        expect(restored!.lastTableEvent, isNull);
        expect(normalizedRaw, isNotNull);
        expect(normalizedRaw, contains('"last_table_event":null'));
      },
    );

    test(
      'restores missing optional collections with compatibility defaults',
      () async {
        SharedPreferences.setMockInitialValues({
          legacyLifeCounterSessionPrefsKey: jsonEncode({
            'player_count': 2,
            'starting_life': 20,
            'lives': [17, 5],
            'poison': [0, 9],
            'energy': [2, 0],
            'experience': [0, 1],
            'commander_casts': [1, 0],
            'commander_damage': [
              [0, 3],
              [7, 0],
            ],
            'storm_count': 4,
            'turn_tracker_active': true,
            'turn_tracker_ongoing_game': true,
            'current_turn_player_index': 1,
            'current_turn_number': 3,
            'turn_timer_active': true,
            'turn_timer_seconds': 30,
          }),
        });
        store = LifeCounterSessionStore();

        final restored = await store.load();

        expect(restored, isNotNull);
        expect(
          restored!.playerSpecialStates,
          everyElement(LifeCounterPlayerSpecialState.none),
        );
        expect(restored.lastPlayerRolls, const [null, null]);
        expect(restored.lastHighRolls, const [null, null]);
        expect(restored.startingLifeTwoPlayer, 20);
        expect(restored.startingLifeMultiPlayer, 40);
        expect(restored.partnerCommanders, const [false, false]);
        expect(restored.turnTrackerActive, isTrue);
        expect(restored.turnTrackerOngoingGame, isTrue);
        expect(restored.currentTurnPlayerIndex, 1);
        expect(restored.currentTurnNumber, 3);
        expect(restored.turnTimerActive, isTrue);
        expect(restored.turnTimerSeconds, 30);
      },
    );

    test('returns null for invalid payloads', () async {
      SharedPreferences.setMockInitialValues({
        legacyLifeCounterSessionPrefsKey: jsonEncode({
          'player_count': 9,
          'lives': [40, 40],
        }),
      });
      store = LifeCounterSessionStore();

      final restored = await store.load();

      expect(restored, isNull);
    });

    test('clears the persisted session', () async {
      await store.save(LifeCounterSession.initial(playerCount: 2));
      await store.clear();

      final restored = await store.load();

      expect(restored, isNull);
    });

    test('round-trips player appearances in the canonical session store', () async {
      const session = LifeCounterSession(
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
          LifeCounterPlayerAppearance(
            background: '#CF7AEF',
            nickname: 'Partner Pilot',
            backgroundImage: 'main-image-ref',
            backgroundImagePartner: 'partner-image-ref',
          ),
          LifeCounterPlayerAppearance(background: '#4B57FF'),
          LifeCounterPlayerAppearance(background: '#44E063'),
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
      );

      await store.save(session);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(
        restored!.resolvedPlayerAppearances[1],
        const LifeCounterPlayerAppearance(
          background: '#CF7AEF',
          nickname: 'Partner Pilot',
          backgroundImage: 'main-image-ref',
          backgroundImagePartner: 'partner-image-ref',
        ),
      );
    });
  });
}
