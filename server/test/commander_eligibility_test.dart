import 'package:server/commander_eligibility.dart';
import 'package:test/test.dart';

void main() {
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
}
