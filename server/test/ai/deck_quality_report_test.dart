import 'dart:convert';
import 'dart:io';

import 'package:server/ai/deck_quality_report.dart';
import 'package:test/test.dart';

/// Builds a deck of exactly [total] cards: [lands] basics of [landName] plus
/// filler spells carrying [spellCost].
List<Map<String, dynamic>> _deck({
  required int lands,
  String landName = 'Plains',
  String spellCost = '{1}{W}',
  int total = 100,
}) {
  return [
    {
      'name': landName,
      'type_line': 'Basic Land — ${landName == 'Plains' ? 'Plains' : landName}',
      'quantity': lands,
      'oracle_text': '{T}: Add {${landName == 'Plains' ? 'W' : 'U'}}.',
      'cmc': 0,
    },
    {
      'name': 'Filler Spell',
      'type_line': 'Creature — Human',
      'quantity': total - lands,
      'mana_cost': spellCost,
      'cmc': 2,
      'oracle_text': 'Vanilla.',
    },
  ];
}

void main() {
  group('buildDeckQualityReport', () {
    test('is deterministic: identical input yields an identical report', () {
      final cards = _deck(lands: 36);

      final first = buildDeckQualityReport(cards: cards, simulations: 200);
      final second = buildDeckQualityReport(cards: cards, simulations: 200);

      // This is the property the whole gate rests on. GoldfishSimulator seeds
      // from a stable deck hash, so a drift here means the scoring path
      // changed, never that the run was noisy.
      expect(jsonEncode(first), jsonEncode(second));
    });

    test('flags a deck below the Commander land floor', () {
      final report = buildDeckQualityReport(
        cards: _deck(lands: 20),
        simulations: 200,
      );

      expect(report['issue_codes'], contains('land_count_below_minimum'));
      expect(
        (report['mana_foundation'] as Map)['satisfied'],
        isFalse,
      );
    });

    test('accepts a deck inside the land floor band', () {
      final report = buildDeckQualityReport(
        cards: _deck(lands: 36),
        simulations: 200,
      );

      expect(report['issue_codes'], isNot(contains('land_count_below_minimum')));
      expect((report['mana_foundation'] as Map)['satisfied'], isTrue);
    });

    test('flags a colour the mana base cannot support', () {
      // 36 Islands cannot cast a deck whose pips are all white.
      final report = buildDeckQualityReport(
        cards: _deck(lands: 36, landName: 'Island', spellCost: '{1}{W}'),
        simulations: 200,
      );

      expect(report['issue_codes'], contains('insufficient_color_sources'));
      final white = (report['color_requirements'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['color'] == 'W');
      expect(white['satisfied'], isFalse);
      expect(white['sources_with_any'], 0);
    });

    test('counts an any-colour land as a source for every colour', () {
      final cards = <Map<String, dynamic>>[
        {
          'name': 'City of Brass',
          'type_line': 'Land',
          'quantity': 36,
          'oracle_text': '{T}: Add one mana of any color.',
          'cmc': 0,
        },
        {
          'name': 'Filler Spell',
          'type_line': 'Creature — Human',
          'quantity': 64,
          'mana_cost': '{1}{W}',
          'cmc': 2,
          'oracle_text': 'Vanilla.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);

      expect(report['any_color_sources'], 36);
      expect(report['issue_codes'], isNot(contains('insufficient_color_sources')));
    });

    test('does not treat a fetchland as a colour source because of its name', () {
      // Regression: matching basic-land names as substrings counted "Misty
      // Rainforest" as a green source. It is a fetchland -- it produces no
      // mana at all. Over-counting sources makes the report understate a
      // broken mana base, which is the dangerous direction for a gate.
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Misty Rainforest',
          'type_line': 'Land',
          'quantity': 36,
          'oracle_text':
              '{T}, Pay 1 life, Sacrifice this land: Search your library '
              'for a Forest or Island card, put it onto the battlefield.',
          'cmc': 0,
        },
        {
          'name': 'Filler Spell',
          'type_line': 'Creature — Human',
          'quantity': 64,
          'mana_cost': '{1}{G}',
          'cmc': 2,
          'oracle_text': 'Vanilla.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);
      final green = (report['color_requirements'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['color'] == 'G');

      expect(green['sources'], 0);
      expect(report['issue_codes'], contains('insufficient_color_sources'));
    });

    test('reads basic land colour from the type line, not the card name', () {
      // "Cori Mountain Monastery" is a utility land, not a Mountain. It is a
      // red source only because its text says so.
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Cori Mountain Monastery',
          'type_line': 'Land',
          'quantity': 36,
          'oracle_text': 'This land enters tapped unless you control a Plains '
              'or an Island.\n{T}: Add {R}.',
          'cmc': 0,
        },
        {
          'name': 'Filler Spell',
          'type_line': 'Creature — Human',
          'quantity': 64,
          'mana_cost': '{1}{W}',
          'cmc': 2,
          'oracle_text': 'Vanilla.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);
      final requirements = (report['color_requirements'] as List)
          .cast<Map<String, dynamic>>();
      final white = requirements.firstWhere((entry) => entry['color'] == 'W');

      // The word "Plains" appears in its text but it adds no white mana.
      expect(white['sources'], 0);
      expect(report['issue_codes'], contains('insufficient_color_sources'));
    });

    test('excludes hybrid pips from the strict colour requirement', () {
      // The simulator itself treats hybrid as generic; the report must agree,
      // otherwise a hybrid deck would be told to add sources it never needs.
      final report = buildDeckQualityReport(
        cards: _deck(lands: 36, spellCost: '{1}{W/U}'),
        simulations: 200,
      );

      expect(report['total_strict_pips'], 0);
      expect(report['flexible_pips'], greaterThan(0));
      expect(report['issue_codes'], isNot(contains('insufficient_color_sources')));
    });

    test('reports data-quality gaps instead of silently scoring them', () {
      final cards = <Map<String, dynamic>>[
        {'name': 'Plains', 'type_line': 'Basic Land', 'quantity': 36, 'cmc': 0},
        {
          'name': 'Unknown Spell',
          'type_line': 'Creature',
          'quantity': 64,
          'oracle_text': 'No cost data.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);
      final dataQuality = report['data_quality'] as Map<String, dynamic>;

      expect(dataQuality['nonland_missing_mana_cost'], 1);
      expect(dataQuality['nonland_suspicious_cmc'], 1);
    });

    test('degrades cleanly instead of crashing on a non-int quantity', () {
      // GoldfishSimulator reads quantity with a hard `as int?` cast, so a
      // deck carrying 36.0 used to throw a TypeError. A gate that crashes
      // hides its own verdict behind a stack trace.
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Plains',
          'type_line': 'Basic Land — Plains',
          'quantity': 36.0,
          'oracle_text': '{T}: Add {W}.',
          'cmc': 0,
        },
        {
          'name': 'Filler Spell',
          'type_line': 'Creature — Human',
          'quantity': 64,
          'mana_cost': '{W}',
          'cmc': 1,
          'oracle_text': 'Vanilla.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);

      expect(report['card_count'], 100);
      expect((report['data_quality'] as Map)['coerced_quantities'], 1);
    });

    test('handles degenerate decks without throwing', () {
      for (final cards in <List<Map<String, dynamic>>>[
        const [],
        [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 100,
            'oracle_text': '{T}: Add {W}.',
            'cmc': 0,
          },
        ],
      ]) {
        final report = buildDeckQualityReport(cards: cards, simulations: 50);
        expect(report['consistency_score'], inInclusiveRange(0, 100));
      }
    });

    test('carries the schema version', () {
      final report = buildDeckQualityReport(
        cards: _deck(lands: 36),
        simulations: 200,
      );
      expect(report['schema_version'], deckQualityReportSchemaVersion);
    });
  });

  group('committed fixture', () {
    late Map<String, dynamic> fixture;

    setUpAll(() {
      fixture =
          jsonDecode(
                File('test/fixtures/deck_quality_fixture.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('every fixture deck is a legal 100-card Commander deck', () {
      final decks = (fixture['decks'] as List).cast<Map<String, dynamic>>();
      expect(decks, isNotEmpty);

      for (final deck in decks) {
        final cards = (deck['cards'] as List).cast<Map<String, dynamic>>();
        final total = cards.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        );
        expect(
          total,
          100,
          reason: 'deck ${deck['deck_id']} has $total cards, not 100',
        );
      }
    });

    test('scores every fixture deck without throwing', () {
      final decks = (fixture['decks'] as List).cast<Map<String, dynamic>>();

      for (final deck in decks) {
        final report = buildDeckQualityReport(
          cards: (deck['cards'] as List).cast<Map<String, dynamic>>(),
          simulations: 100,
        );
        expect(report['consistency_score'], inInclusiveRange(0, 100));
        expect(report['card_count'], 100);
      }
    });
  });
}
