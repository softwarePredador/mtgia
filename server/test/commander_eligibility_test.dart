import 'package:server/commander_eligibility.dart';
import 'package:server/deck_rules_service.dart';
import 'package:test/test.dart';

void main() {
  group('isCommanderStyleFormat', () {
    test('only Commander and Brawl allow commander slots', () {
      expect(isCommanderStyleFormat('commander'), isTrue);
      expect(isCommanderStyleFormat('Commander'), isTrue);
      expect(isCommanderStyleFormat('brawl'), isTrue);
      expect(isCommanderStyleFormat('standard'), isFalse);
      expect(isCommanderStyleFormat('modern'), isFalse);
    });
  });

  group('isCommanderEligibleCard', () {
    test('accepts legendary creatures', () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Creature — Phyrexian Praetor',
        ),
        isTrue,
      );
    });

    test('accepts explicit can-be-your-commander exceptions', () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Planeswalker — Urza',
          oracleText: 'Urza, Academy Headmaster can be your commander.',
        ),
        isTrue,
      );
    });

    test('keeps Commander planeswalker eligibility strict by default', () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Planeswalker — Chandra',
        ),
        isFalse,
      );
    });

    test('accepts legendary planeswalkers for Brawl commanders', () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Planeswalker — Chandra',
          format: 'brawl',
        ),
        isTrue,
      );
    });

    test('accepts 2026 legendary Vehicle and Spacecraft commanders with P/T',
        () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Artifact — Vehicle',
          power: '5',
          toughness: '5',
        ),
        isTrue,
      );
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Artifact — Spacecraft',
          power: '3',
          toughness: '4',
        ),
        isTrue,
      );
    });

    test('rejects legendary Vehicle or Spacecraft without P/T', () {
      expect(
        isCommanderEligibleCard(typeLine: 'Legendary Artifact — Vehicle'),
        isFalse,
      );
      expect(
        isCommanderEligibleCard(typeLine: 'Legendary Artifact — Spacecraft'),
        isFalse,
      );
    });

    test('rejects background and nonlegendary cards as solo commanders', () {
      expect(
        isCommanderEligibleCard(
          typeLine: 'Legendary Enchantment — Background',
          oracleText: 'Choose this Background when you create your character.',
        ),
        isFalse,
      );
      expect(isCommanderEligibleCard(typeLine: 'Artifact'), isFalse);
    });
  });

  group('validateCommanderSlotAllowedForFormat', () {
    test('rejects commander slot flags outside Commander/Brawl', () {
      expect(
        () => validateCommanderSlotAllowedForFormat(
          format: 'standard',
          cards: const [
            {'card_id': 'card-1', 'quantity': 1, 'is_commander': true},
          ],
        ),
        throwsA(
          isA<DeckRulesException>().having(
            (e) => e.message,
            'message',
            contains('Commander/Brawl'),
          ),
        ),
      );
    });

    test('allows commander slot flags in Commander/Brawl', () {
      expect(
        () => validateCommanderSlotAllowedForFormat(
          format: 'commander',
          cards: const [
            {'card_id': 'card-1', 'quantity': 1, 'is_commander': true},
          ],
        ),
        returnsNormally,
      );
      expect(
        () => validateCommanderSlotAllowedForFormat(
          format: 'brawl',
          cards: const [
            {'card_id': 'card-1', 'quantity': 1, 'is_commander': true},
          ],
        ),
        returnsNormally,
      );
    });
  });
}
