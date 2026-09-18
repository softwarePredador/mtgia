import 'package:server/ai/deck_quality_report.dart';
import 'package:test/test.dart';

/// These tests do not assert that the harness is CORRECT. They pin what it
/// cannot see, so the score is never mistaken for a verdict on deck power.
///
/// Every expectation here is a known limitation with an owner-facing cost. If
/// one of them starts failing, the model got better and the test should be
/// rewritten deliberately -- not deleted.
void main() {
  group('known limits of consistency_score', () {
    test(
      'a strictly terrible deck ties the best real deck in the fixture',
      () {
        // 36 Forest + 64 identical vanilla two-drops: no interaction, no card
        // draw, no ramp, no win condition, illegal as singleton Commander.
        // The best REAL deck in the committed fixture scores 84.
        final junk = <Map<String, dynamic>>[
          {
            'name': 'Forest',
            'type_line': 'Basic Land — Forest',
            'quantity': 36,
            'oracle_text': '{T}: Add {G}.',
            'cmc': 0,
          },
          {
            'name': 'Grizzly Bears',
            'type_line': 'Creature — Bear',
            'quantity': 64,
            'mana_cost': '{1}{G}',
            'cmc': 2,
            'oracle_text': 'Vanilla.',
          },
        ];

        final report = buildDeckQualityReport(cards: junk, simulations: 1000);

        expect(report['consistency_score'], greaterThanOrEqualTo(84));
        expect(
          report['issue_codes'],
          isEmpty,
          reason: 'the harness cannot see that this deck is unplayable',
        );
      },
    );

    test('mana rocks and dorks are not counted as colour sources', () {
      // Only lands are counted. A deck leaning on rocks will be reported as
      // colour-starved even when it is not.
      final cards = <Map<String, dynamic>>[
        {
          'name': 'Island',
          'type_line': 'Basic Land — Island',
          'quantity': 36,
          'oracle_text': '{T}: Add {U}.',
          'cmc': 0,
        },
        {
          'name': 'Marble Diamond',
          'type_line': 'Artifact',
          'quantity': 64,
          'mana_cost': '{2}',
          'cmc': 2,
          'oracle_text': 'Marble Diamond enters tapped. {T}: Add {W}.',
        },
      ];

      final report = buildDeckQualityReport(cards: cards, simulations: 200);

      // 64 white sources are present and invisible to the report.
      final white = (report['color_requirements'] as List)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['color'] == 'W');
      expect(
        white,
        isEmpty,
        reason: 'artifacts carry no strict pips, so W never enters the '
            'requirement list at all',
      );
      expect(report['any_color_sources'], 0);
    });

    test(
      'a modal double-faced land is invisible when only its front face is known',
      () {
        // Emeria's Call // Emeria, Shattered Skyclave is a land on its back
        // face, but local data stores only the front type line. The report
        // counts it as a spell and surfaces the uncertainty instead of
        // pretending the land count is exact.
        final cards = <Map<String, dynamic>>[
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 30,
            'oracle_text': '{T}: Add {W}.',
            'cmc': 0,
          },
          {
            'name': "Emeria's Call // Emeria, Shattered Skyclave",
            'type_line': 'Sorcery',
            'quantity': 4,
            'mana_cost': '{4}{W}{W}',
            'cmc': 6,
            'oracle_text': 'Create two 4/4 white Angel Warrior creature tokens.',
          },
          {
            'name': 'Filler Spell',
            'type_line': 'Creature — Human',
            'quantity': 66,
            'mana_cost': '{1}{W}',
            'cmc': 2,
            'oracle_text': 'Vanilla.',
          },
        ];

        final report = buildDeckQualityReport(cards: cards, simulations: 200);
        final mana = report['mana_foundation'] as Map<String, dynamic>;
        final dataQuality = report['data_quality'] as Map<String, dynamic>;

        expect(mana['land_count'], 30, reason: 'back face is not counted');
        expect(report['issue_codes'], contains('land_count_below_minimum'));
        // The escape hatch: the count is flagged as possibly understated.
        expect(dataQuality['possible_back_face_lands'], 4);
      },
    );
  });
}
