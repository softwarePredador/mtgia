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
        stormCount: 13,
        monarchPlayer: 1,
        initiativePlayer: 2,
        firstPlayerIndex: 1,
        lastTableEvent: 'Primeiro jogador: Jogador 2',
      );

      await store.save(session);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.toJson(), session.toJson());
    });

    test('sanitizes legacy set-life events on load and writes back normalized json', () async {
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
    });

    test('restores missing optional collections with compatibility defaults', () async {
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
    });

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
  });
}
