import 'package:server/ai/commander_deckbuilding_contract_support.dart';
import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/ai/commander_staple_impact_policy.dart';
import 'package:test/test.dart';

void main() {
  group('Commander deckbuilding contract diagnostics', () {
    test(
      'links source lanes and marks valid commander deck ready for gate',
      () {
        final diagnostics = buildCommanderDeckbuildingContractDiagnostics(
          format: 'Commander',
          generatedDeck: {
            'commander': {'name': 'Lorehold, the Historian'},
            'cards': [
              {'name': 'Sol Ring', 'quantity': 1},
              {'name': 'Arcane Signet', 'quantity': 1},
              {'name': 'Approach of the Second Sun', 'quantity': 1},
            ],
          },
          validationSummary: const {
            'is_valid': true,
            'invalid_cards': <String>[],
            'errors': <String>[],
            'warnings': <String>[],
          },
          referenceProfile: const {
            'commander': 'Lorehold, the Historian',
            'confidence': 'high',
            'expected_packages': {
              'mana_ramp_foundation': ['Sol Ring', 'Arcane Signet'],
              'miracle_payoffs_expensive_spells': [
                'Approach of the Second Sun',
              ],
            },
          },
          referenceCardStats: const [
            CommanderReferenceCardStat(
              commanderName: 'Lorehold, the Historian',
              commanderNameNormalized: 'lorehold, the historian',
              cardName: 'Sol Ring',
              cardNameNormalized: 'sol ring',
              packageKey: 'mana_ramp_foundation',
              role: 'ramp',
              score: 100,
              confidence: 'high',
              confidenceRank: 5,
              source: 'test',
              evidenceCount: 3,
              unresolved: false,
            ),
            CommanderReferenceCardStat(
              commanderName: 'Lorehold, the Historian',
              commanderNameNormalized: 'lorehold, the historian',
              cardName: 'Approach of the Second Sun',
              cardNameNormalized: 'approach of the second sun',
              packageKey: 'miracle_payoffs_expensive_spells',
              role: 'wincon',
              score: 90,
              confidence: 'high',
              confidenceRank: 5,
              source: 'test',
              evidenceCount: 2,
              unresolved: false,
            ),
          ],
          referenceDeckCorpusGuidance:
              const CommanderReferenceDeckCorpusGuidance(
                commanderName: 'Lorehold, the Historian',
                source: 'test_corpus',
                deckCount: 3,
                acceptedDeckCount: 3,
                averageRoleCounts: {'ramp': 10},
                topCards: [
                  {
                    'card_name': 'Sol Ring',
                    'deck_count': 3,
                    'total_quantity': 3,
                    'role': 'ramp',
                  },
                  {
                    'card_name': 'Arcane Signet',
                    'deck_count': 3,
                    'total_quantity': 3,
                    'role': 'ramp',
                  },
                ],
                themeCounts: {'miracle': 3},
              ),
          activeLearnedDeck: const CommanderLearnedDeckInput(
            commanderName: 'Lorehold, the Historian',
            deckName: 'Test learned',
            sourceSystem: 'test',
            sourceRef: 'learned:test',
            cardList: '''
1 Sol Ring
1 Arcane Signet
1 Approach of the Second Sun
''',
            cardCount: 100,
            legalStatus: 'commander_legal',
            isActive: true,
          ),
          usageHotCards: const [
            {'canonical_name': 'Arcane Signet', 'usage_count': 5},
          ],
          referenceDeterministicDeckDiagnostics: const {
            'main_deck_quantity': 99,
            'distinct_card_count': 99,
          },
        );

        expect(diagnostics['version'], commanderDeckbuildingContractVersion);
        expect(diagnostics['status'], 'ready_for_battle_gate');
        expect(
          diagnostics['planning_flow_version'],
          commanderDeckPlanningFlowVersion,
        );
        expect(
          diagnostics['planning_flow'],
          containsAll([
            'commander_intent_and_archetype',
            'primary_and_backup_win_plan',
            'staple_impact_and_role_policy',
            'lane_balanced_cuts_and_anchor_protection',
            'goldfish_battle_replay_iteration',
          ]),
        );
        expect(
          diagnostics['lane_order'],
          containsAllInOrder([
            'legal_identity',
            'commander_intent',
            'win_plan',
            'mana_base',
            'ramp',
            'card_draw_selection',
            'interaction_removal',
            'staple_floor_and_context',
            'same_lane_cuts',
            'battle_and_replay_validation',
          ]),
        );
        expect(
          diagnostics['deck_overview_required_fields'],
          containsAll([
            'commander_plan_sentence',
            'primary_win_lines',
            'role_counts_vs_targets',
            'staple_impact_by_role',
            'protected_anchors_and_cut_rules',
          ]),
        );
        final staplePolicy = diagnostics['staple_impact_policy'] as Map;
        expect(staplePolicy['version'], commanderStapleImpactPolicyVersion);
        expect(
          staplePolicy['guardrails'],
          contains('Do not let global staple rank override commander intent.'),
        );
        expect((diagnostics['gates'] as Map)['has_any_reference_lane'], isTrue);
        expect((diagnostics['gates'] as Map)['battle_gate_status'], 'pending');
        final sourceLanes = diagnostics['source_lanes'] as Map;
        expect(sourceLanes['reference_profile_used'], isTrue);
        expect(sourceLanes['reference_card_stats_resolved_count'], 2);
        expect(sourceLanes['reference_corpus_used'], isTrue);
        expect(sourceLanes['active_learned_deck_used'], isTrue);

        final sample = diagnostics['card_source_sample'] as List;
        final solRing = sample.cast<Map>().firstWhere(
          (card) => card['card_name'] == 'Sol Ring',
        );
        expect(
          solRing['sources'],
          containsAll([
            'active_learned_deck',
            'deterministic_fallback',
            'profile_expected_packages',
            'reference_card_stats',
            'reference_corpus_packages',
          ]),
        );
      },
    );

    test('blocks invalid commander output without reference lanes', () {
      final diagnostics = buildCommanderDeckbuildingContractDiagnostics(
        format: 'Commander',
        generatedDeck: const {
          'commander': {'name': ''},
          'cards': [
            {'name': 'Unknown Card', 'quantity': 1},
          ],
        },
        validationSummary: const {
          'is_valid': false,
          'invalid_cards': ['Unknown Card'],
          'errors': ['missing commander'],
        },
      );

      expect(diagnostics['status'], 'blocked');
      expect(diagnostics['blockers'], contains('commander_missing'));
      expect(diagnostics['blockers'], contains('validation_failed'));
      expect(diagnostics['blockers'], contains('unresolved_cards_present'));
      expect(diagnostics['blockers'], contains('reference_lanes_missing'));
    });
  });
}
