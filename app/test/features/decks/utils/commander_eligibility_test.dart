import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/utils/commander_eligibility.dart';

DeckCardItem _card({
  required String typeLine,
  String? oracleText,
  String? power,
  String? toughness,
}) {
  return DeckCardItem(
    id: 'candidate',
    name: 'Candidate',
    typeLine: typeLine,
    oracleText: oracleText,
    power: power,
    toughness: toughness,
    setCode: 'tst',
    rarity: 'rare',
    quantity: 1,
    isCommander: false,
  );
}

void main() {
  test('recognizes commander-style formats', () {
    expect(isCommanderStyleDeckFormat('Commander'), isTrue);
    expect(isCommanderStyleDeckFormat('brawl'), isTrue);
    expect(isCommanderStyleDeckFormat('standard'), isFalse);
  });

  test('legendary creatures are eligible in Commander', () {
    expect(
      isPotentialCommander(
        _card(typeLine: 'Legendary Creature — Wizard'),
        format: 'commander',
      ),
      isTrue,
    );
  });

  test('legendary planeswalkers are eligible only in Brawl', () {
    final card = _card(typeLine: 'Legendary Planeswalker — Teferi');
    expect(isPotentialCommander(card, format: 'commander'), isFalse);
    expect(isPotentialCommander(card, format: 'brawl'), isTrue);
  });

  test('legendary Vehicles require a power and toughness box', () {
    expect(
      isPotentialCommander(
        _card(
          typeLine: 'Legendary Artifact — Vehicle',
          power: '4',
          toughness: '4',
        ),
        format: 'commander',
      ),
      isTrue,
    );
    expect(
      isPotentialCommander(
        _card(typeLine: 'Legendary Artifact — Vehicle'),
        format: 'commander',
      ),
      isFalse,
    );
  });

  test('explicit oracle permission remains eligible', () {
    expect(
      isPotentialCommander(
        _card(
          typeLine: 'Enchantment — Background',
          oracleText: 'This card can be your commander.',
        ),
        format: 'commander',
      ),
      isTrue,
    );
  });
}
