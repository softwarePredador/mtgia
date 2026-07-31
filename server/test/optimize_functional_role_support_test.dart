import 'package:test/test.dart';

import '../lib/ai/functional_card_tags.dart';
import '../lib/ai/optimize_functional_role_support.dart';

void main() {
  group('optimize functional role support', () {
    test('uses persisted tags before legacy text heuristics', () {
      final role = inferFunctionalRoleForCard({
        'name': 'Silent Value Piece',
        'type_line': 'Creature',
        'oracle_text': 'Whenever this attacks, gain 1 life.',
        'functional_tags': const [
          {'tag': 'board_wipe', 'confidence': 0.92, 'source': 'test'},
        ],
      });

      expect(role, equals('wipe'));
    });

    test('prioritizes real wipes without counting friendly mass buffs', () {
      const decreeOracle =
          "Destroy all creatures. They can't be regenerated. "
          'Draw a card for each creature destroyed this way.';
      const catharsOracle =
          'Whenever a creature enters the battlefield under your control, '
          'put a +1/+1 counter on each creature you control.';

      expect(
        inferFunctionalRole(
          name: 'Decree of Pain',
          typeLine: 'Sorcery',
          oracleText: decreeOracle,
        ),
        equals('wipe'),
      );
      expect(looksLikeBoardWipe(decreeOracle), isTrue);
      expect(looksLikeBoardWipe(catharsOracle), isFalse);
      expect(
        inferFunctionalRole(
          name: "Cathars' Crusade",
          typeLine: 'Enchantment',
          oracleText: catharsOracle,
        ),
        isNot(equals('wipe')),
      );
      expect(
        inferFunctionalRoleForCard(const {
          'name': 'Decree of Pain',
          'type_line': 'Sorcery',
          'oracle_text': decreeOracle,
          'functional_tags': ['draw'],
        }),
        equals('wipe'),
        reason: 'partial persisted tags cannot hide a canonical wipe',
      );
    });

    test('recognizes global negative modifiers as sweepers', () {
      expect(
        looksLikeBoardWipe('Until end of turn, each creature gets -4/-4.'),
        isTrue,
      );
      expect(
        looksLikeBoardWipe(
          'Creatures you control get +1/+1 until end of turn.',
        ),
        isFalse,
      );
    });

    test('does not count mass exile outside the battlefield as a wipe', () {
      for (final oracle in const [
        'Exile all cards from all graveyards.',
        "Exile all cards from target player's hand.",
        "Exile all creature cards from target player's graveyard.",
        'Exile all cards from the top of target player’s library.',
      ]) {
        expect(looksLikeBoardWipe(oracle), isFalse, reason: oracle);
      }

      expect(
        looksLikeBoardWipe(
          'Exile all creatures. Exile all cards from all graveyards.',
        ),
        isTrue,
      );
    });

    test('assesses quantity-aware Commander wipe floors by archetype', () {
      final control = assessCommanderFunctionalRoleFloors(
        cards: const [
          {
            'name': 'Plains',
            'type_line': 'Basic Land — Plains',
            'quantity': 36,
          },
          {'name': 'Fair Creature', 'type_line': 'Creature', 'quantity': 62},
          {
            'name': 'Wrath of God',
            'type_line': 'Sorcery',
            'oracle_text': 'Destroy all creatures.',
            'quantity': 2,
          },
        ],
        targetArchetype: 'control',
      );

      expect(control.applies, isTrue);
      expect(control.actualCounts['wipe'], 2);
      expect(control.minimumCounts['wipe'], 3);
      expect(control.deficits['wipe'], 1);
      expect(control.satisfied, isFalse);

      expect(
        buildCommanderCriticalRoleFloorNeeds(
          cards: const [
            {'name': 'Fair Creature', 'type_line': 'Creature', 'quantity': 100},
          ],
          targetArchetype: 'midrange',
          limit: 10,
        ),
        const ['wipe', 'wipe'],
      );
      expect(minimumCommanderWipeCountForArchetype('aggro'), 1);
      expect(minimumCommanderWipeCountForArchetype('combo'), 2);
    });

    test(
      'maps curated combo role while heuristic combo stays conservative',
      () {
        final tags = inferFunctionalCardTags(
          name: 'Dramatic Reversal',
          typeLine: 'Instant',
          oracleText: 'Untap all nonland permanents you control.',
        );
        final heuristicCombo = tags.firstWhere(
          (tag) => tag.tag == 'combo_piece',
        );
        expect(heuristicCombo.confidence, lessThan(0.65));

        final role = inferFunctionalRoleForCard({
          'name': 'Dramatic Reversal',
          'type_line': 'Instant',
          'oracle_text': 'Untap all nonland permanents you control.',
          'functional_tags': const [
            {
              'tag': 'combo_piece',
              'confidence': 0.96,
              'source': 'commander_spellbook_combo_v1',
            },
          ],
        });

        expect(role, equals('wincon'));
      },
    );

    test('keeps land-search out of tutor matching', () {
      expect(
        matchesFunctionalNeed(
          'tutor',
          oracleText: 'Search your library for a basic land card.',
          typeLine: 'Sorcery',
        ),
        isFalse,
      );
      expect(
        inferOptimizeFunctionalNeed(
          name: 'Rampant Growth',
          typeLine: 'Sorcery',
          oracleText: 'Search your library for a basic land card.',
        ),
        equals('ramp'),
      );
    });

    test('keeps inclusive ramp labels but narrows generic ramp needs', () {
      const rubyOracle = 'Red spells you cast cost {1} less to cast.';
      const scoreOracle = 'Draw two cards and create two Treasure tokens.';

      expect(
        inferFunctionalRoleForCard(const {
          'name': 'Ruby Medallion',
          'type_line': 'Artifact',
          'oracle_text': rubyOracle,
          'functional_tags': ['ramp'],
        }),
        equals('ramp'),
      );
      expect(
        inferOptimizeFunctionalNeed(
          name: 'Ruby Medallion',
          typeLine: 'Artifact',
          oracleText: rubyOracle,
        ),
        equals('ramp'),
      );

      for (final contextual in const [rubyOracle, scoreOracle]) {
        expect(
          matchesFunctionalNeed(
            'ramp',
            oracleText: contextual,
            typeLine: contextual == rubyOracle ? 'Artifact' : 'Instant',
          ),
          isFalse,
        );
      }

      expect(
        matchesFunctionalNeed(
          'ramp',
          name: 'Arcane Signet',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
          typeLine: 'Artifact',
        ),
        isTrue,
      );
      expect(
        matchesFunctionalNeed(
          'ramp',
          name: "Nature's Lore",
          oracleText:
              'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
          typeLine: 'Sorcery',
        ),
        isTrue,
      );
      expect(
        matchesFunctionalNeed(
          'ramp',
          name: 'Sylvan Scrying',
          oracleText:
              'Search your library for a land card, reveal it, put it into your hand, then shuffle.',
          typeLine: 'Sorcery',
        ),
        isFalse,
      );
    });

    test('penalizes temporary mana bursts compared with stable ramp', () {
      final stableRampScore = scoreOptimizeReplacementCandidate(
        functionalNeed: 'ramp',
        cardName: 'Arcane Signet',
        typeLine: 'Artifact',
        oracleText: '{T}: Add one mana of any color.',
        manaCost: '{2}',
        popScore: 100,
        preferredNames: const {},
        rejectedAdditionCounts: const {},
      );
      final ritualScore = scoreOptimizeReplacementCandidate(
        functionalNeed: 'ramp',
        cardName: 'Seething Song',
        typeLine: 'Instant',
        oracleText: 'Add {R}{R}{R}{R}{R}.',
        manaCost: '{2}{R}',
        popScore: 100,
        preferredNames: const {},
        rejectedAdditionCounts: const {},
      );

      expect(stableRampScore, greaterThan(ritualScore));
    });
  });
}
