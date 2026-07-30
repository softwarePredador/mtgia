import 'package:server/deck_card_eligibility.dart';
import 'package:test/test.dart';

void main() {
  group('main deck card eligibility', () {
    test('rejects supplemental game objects', () {
      for (final typeLine in const [
        'Artifact — Attraction',
        'Artifact — Contraption',
        'Conspiracy',
        'Dungeon',
        'Emblem',
        'Plane — Ravnica',
        'Phenomenon',
        'Scheme',
        'Stickers',
        'Token Creature — Goblin',
        'Vanguard',
      ]) {
        expect(
          mainDeckCardIneligibilityReason(typeLine: typeLine),
          'supplemental_game_object',
          reason: typeLine,
        );
      }
    });

    test('rejects non-deck layouts and playtest products', () {
      expect(
        mainDeckCardIneligibilityReason(
          typeLine: 'Creature — Goblin',
          layout: 'token',
        ),
        'non_deck_layout',
      );
      expect(
        mainDeckCardIneligibilityReason(typeLine: 'Sorcery', setCode: 'UNK'),
        'playtest_product',
      );
    });

    test('keeps ordinary Eternal-legal Unfinity cards eligible', () {
      expect(
        isMainDeckCardEligible(
          typeLine: 'Creature — Elephant Performer',
          setCode: 'unf',
          layout: 'normal',
        ),
        isTrue,
      );
    });

    test('keeps legitimate Mystery Booster 2 reprints eligible', () {
      expect(
        isMainDeckCardEligible(
          typeLine: "Enchantment Land — Urza's Saga",
          setCode: 'mb2',
          layout: 'normal',
        ),
        isTrue,
      );
      expect(
        mainDeckCardIneligibilityReason(
          typeLine: 'Artifact — Attraction',
          setCode: 'mb2',
          layout: 'normal',
        ),
        'supplemental_game_object',
      );
    });

    test('SQL and runtime guards reject the same core fields', () {
      final sql = mainDeckCardEligibilitySql(tableAlias: 'card');
      expect(sql, contains('card.type_line'));
      expect(sql, contains('card.layout'));
      expect(sql, contains('card.set_code'));
      expect(sql, contains('attraction'));
      expect(sql, contains("'unk'"));
      expect(
        () => mainDeckCardEligibilitySql(tableAlias: 'card; DROP TABLE cards'),
        throwsArgumentError,
      );
    });
  });
}
