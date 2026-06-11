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

      expect(role, equals('removal'));
    });

    test('maps curated combo role while heuristic combo stays conservative',
        () {
      final tags = inferFunctionalCardTags(
        name: 'Dramatic Reversal',
        typeLine: 'Instant',
        oracleText: 'Untap all nonland permanents you control.',
      );
      final heuristicCombo = tags.firstWhere((tag) => tag.tag == 'combo_piece');
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
    });

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

    test('penalizes temporary mana bursts compared with stable ramp', () {
      final stableRampScore = scoreOptimizeReplacementCandidate(
        functionalNeed: 'ramp',
        cardName: 'Arcane Signet',
        typeLine: 'Artifact',
        oracleText: 'Add one mana of any color.',
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
