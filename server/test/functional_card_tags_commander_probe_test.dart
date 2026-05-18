import 'package:server/ai/functional_card_tags.dart';
import 'package:test/test.dart';

void main() {
  group('Functional Card Tags v1 commander proof slices', () {
    for (final probe in _probes) {
      test('${probe.name} reduces unclassified functional cards', () {
        final before = _legacyComposition(probe.cards);
        final after = summarizeFunctionalTagsForDeck(probe.cards);

        expect(after.otherRows, lessThan(before.otherRows), reason: probe.name);
        expect(after.count('ramp'), greaterThanOrEqualTo(before.ramp));
        expect(
          after.count('removal'),
          greaterThanOrEqualTo(before.removal > 0 ? 1 : 0),
        );
        expect(after.toJson()['samples'], isA<Map<String, dynamic>>());
      });
    }
  });
}

final _probes = <_CommanderProbe>[
  _CommanderProbe(
    name: 'Lorehold sanitized slice',
    cards: [
      _card(
        'Lorehold, the Historian',
        'Legendary Creature',
        'Instant and sorcery cards in your hand have miracle {2}.',
      ),
      _card('Sol Ring', 'Artifact', '{T}: Add {C}{C}.'),
      _card(
        'Arcane Signet',
        'Artifact',
        '{T}: Add one mana of any color in your commander\'s color identity.',
      ),
      _card(
        'Jeska\'s Will',
        'Sorcery',
        'If you control a commander, you may choose both. Add {R} for each card in target opponent\'s hand. Exile the top three cards of your library. You may play them this turn.',
      ),
      _card(
        'Skullclamp',
        'Artifact - Equipment',
        'Whenever equipped creature dies, draw two cards.',
      ),
      _card(
        'Ephemerate',
        'Instant',
        'Exile target creature you control, then return it to the battlefield under its owner\'s control.',
      ),
      _card('Wrath of God', 'Sorcery', 'Destroy all creatures.'),
      _card('Swords to Plowshares', 'Instant', 'Exile target creature.'),
      _card(
        'Young Pyromancer',
        'Creature',
        'Whenever you cast an instant or sorcery spell, create a 1/1 red Elemental creature token.',
      ),
    ],
  ),
  _CommanderProbe(
    name: 'Dina sanitized slice',
    cards: [
      _card(
        'Dina, Soul Steeper',
        'Legendary Creature',
        'Whenever you gain life, each opponent loses 1 life.',
      ),
      _card('Sol Ring', 'Artifact', '{T}: Add {C}{C}.'),
      _card(
        'Arcane Signet',
        'Artifact',
        '{T}: Add one mana of any color in your commander\'s color identity.',
      ),
      _card(
        'Blood Artist',
        'Creature',
        'Whenever Blood Artist or another creature dies, target player loses 1 life and you gain 1 life.',
      ),
      _card(
        'Reanimate',
        'Sorcery',
        'Put target creature card from a graveyard onto the battlefield under your control.',
      ),
      _card(
        'Village Rites',
        'Instant',
        'As an additional cost to cast this spell, sacrifice a creature. Draw two cards.',
      ),
      _card(
        'Essence Warden',
        'Creature',
        'Whenever another creature enters the battlefield, you gain 1 life.',
      ),
    ],
  ),
  _CommanderProbe(
    name: 'Feather sanitized slice',
    cards: [
      _card(
        'Feather, the Redeemed',
        'Legendary Creature',
        'Whenever you cast an instant or sorcery spell that targets a creature you control, exile that card instead of putting it into your graveyard.',
      ),
      _card('Sol Ring', 'Artifact', '{T}: Add {C}{C}.'),
      _card(
        'Ephemerate',
        'Instant',
        'Exile target creature you control, then return it to the battlefield under its owner\'s control.',
      ),
      _card(
        'Gods Willing',
        'Instant',
        'Target creature you control gains protection from the color of your choice until end of turn. Scry 1.',
      ),
      _card(
        'Young Pyromancer',
        'Creature',
        'Whenever you cast an instant or sorcery spell, create a 1/1 red Elemental creature token.',
      ),
      _card('Swords to Plowshares', 'Instant', 'Exile target creature.'),
      _card(
        'Jeska\'s Will',
        'Sorcery',
        'If you control a commander, you may choose both. Add {R} for each card in target opponent\'s hand. Exile the top three cards of your library. You may play them this turn.',
      ),
    ],
  ),
];

Map<String, dynamic> _card(String name, String typeLine, String oracleText) => {
      'name': name,
      'type_line': typeLine,
      'oracle_text': oracleText,
      'mana_cost': '',
      'quantity': 1,
    };

class _CommanderProbe {
  const _CommanderProbe({required this.name, required this.cards});

  final String name;
  final List<Map<String, dynamic>> cards;
}

class _LegacyComposition {
  const _LegacyComposition({
    required this.ramp,
    required this.draw,
    required this.removal,
    required this.boardWipes,
    required this.otherRows,
  });

  final int ramp;
  final int draw;
  final int removal;
  final int boardWipes;
  final int otherRows;
}

_LegacyComposition _legacyComposition(List<Map<String, dynamic>> cards) {
  var ramp = 0;
  var draw = 0;
  var removal = 0;
  var boardWipes = 0;
  var otherRows = 0;

  for (final card in cards) {
    final text = ((card['oracle_text'] as String?) ?? '').toLowerCase();
    final type = ((card['type_line'] as String?) ?? '').toLowerCase();
    var tagged = false;

    if (type.contains('basic land')) continue;

    if (text.contains('add {') ||
        text.contains('search your library for a land') ||
        text.contains('create a treasure') ||
        text.contains('put a land card from your hand')) {
      ramp++;
      tagged = true;
    }

    if (text.contains('draw a card') || text.contains('draw cards')) {
      draw++;
      tagged = true;
    }

    if (text.contains('destroy target') ||
        text.contains('exile target') ||
        text.contains('deal') && text.contains('damage to target')) {
      removal++;
      tagged = true;
    }

    if (text.contains('destroy all') || text.contains('exile all')) {
      boardWipes++;
      tagged = true;
    }

    if (!tagged) otherRows++;
  }

  return _LegacyComposition(
    ramp: ramp,
    draw: draw,
    removal: removal,
    boardWipes: boardWipes,
    otherRows: otherRows,
  );
}
