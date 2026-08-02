import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_functional_role_support.dart';
import '../lib/ai/optimize_route_recommendation_context_support.dart';
import '../lib/ai/optimize_runtime_support.dart' as runtime;
import '../lib/ai/optimize_swap_candidate_support.dart';

Pool _unusedPool() {
  return Pool.withEndpoints([
    Endpoint(
      host: '127.0.0.1',
      port: 65535,
      database: 'unused',
      username: 'unused',
      password: 'unused',
    ),
  ], settings: const PoolSettings(maxConnectionCount: 1));
}

void main() {
  group('optimize swap candidate support', () {
    test('binder preference parameters have explicit PostgreSQL types', () {
      final source =
          File(
            'lib/ai/optimize_swap_candidate_support.dart',
          ).readAsStringSync();

      expect(source, contains('CAST(@prefer_collection AS boolean)'));
      expect(source, contains('CAST(@check_collection AS boolean)'));
      expect(source, contains("NULLIF(CAST(@user_id AS text), '')"));
      expect(
        source,
        contains("CAST(NULLIF(CAST(@user_id AS text), '') AS uuid)"),
      );
      expect(source, contains('commander_card_synergy'));
      expect(source, contains('@commander_names::text[]'));
      expect(source, contains('@preferred_names::text[]'));
      expect(source, contains('AS minimum_bracket'));
      expect(
        source,
        matches(
          RegExp(
            "crs\\.subformat = 'competitive_commander'.*"
            "crs\\.bracket_scope = 'bracket_5' THEN 5",
            dotAll: true,
          ),
        ),
      );
      expect(
        source,
        matches(
          RegExp("'bracket_4_plus', 'bracket_4_5'.*THEN 4", dotAll: true),
        ),
      );
    });

    test('returns no swaps for empty deck without touching database', () async {
      final pool = _unusedPool();
      addTearDown(pool.close);

      final result = await buildDeterministicOptimizeSwapCandidates(
        pool: pool,
        allCardData: const [],
        commanders: const ['Talrand, Sky Summoner'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'control',
        bracket: 2,
        keepTheme: true,
        detectedTheme: null,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(result, isEmpty);
    });

    test(
      'runtime re-export keeps existing swap builder API compatible',
      () async {
        final pool = _unusedPool();
        addTearDown(pool.close);

        final result = await runtime.buildDeterministicOptimizeSwapCandidates(
          pool: pool,
          allCardData: const [],
          commanders: const ['Talrand, Sky Summoner'],
          commanderColorIdentity: const {'U'},
          targetArchetype: 'control',
          bracket: 2,
          keepTheme: true,
          detectedTheme: null,
          coreCards: const [],
          commanderPriorityNames: const [],
        );

        expect(result, isEmpty);
        expect(runtime.findSynergyReplacements, isA<Function>());
      },
    );

    test('replacement result preserves CMC and reservation ownership', () {
      final result = buildOptimizeReplacementResult(
        const {
          'id': 'card-id',
          'name': 'Six Mana Spell',
          'type_line': 'Sorcery',
          'oracle_text': 'Draw three cards.',
          'mana_cost': '{4}{U}{U}',
          'cmc': 6.0,
          'colors': ['U'],
          'color_identity': ['U'],
        },
        functionalNeed: 'draw',
        hasRecommendationReservation: true,
      );

      expect(result['cmc'], 6.0);
      expect(result['mana_cost'], '{4}{U}{U}');
      expect(result[optimizeRecommendationReservationMarker], isTrue);
    });

    test('verifies critical draw while preserving persisted engine role', () {
      final candidate = {
        'name': 'Source-backed Engine',
        'type_line': 'Enchantment',
        'oracle_text':
            'Whenever you cast your second spell each turn, draw a card.',
        'functional_tags': const ['engine', 'draw'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 72,
      };

      expect(
        matchesFunctionalNeedForCandidate(
          'draw',
          candidate: candidate,
          enforceCommanderCriticalFloor: true,
        ),
        isTrue,
      );
      expect(
        matchesFunctionalNeedForCandidate('engine', candidate: candidate),
        isTrue,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'draw',
          candidate: candidate,
        ),
        greaterThan(90),
      );
    });

    test(
      'critical draw matching uses the same predicate as the final gate',
      () {
        final falsePositive = {
          'name': 'Graveyard Purge',
          'type_line': 'Instant',
          'oracle_text': 'Exile all cards from target player\'s graveyard.',
          'functional_tags': const <String>[],
          'semantic_tags_v2': const <Map<String, dynamic>>[],
        };
        final realDraw = {
          'name': 'Divination',
          'type_line': 'Sorcery',
          'oracle_text': 'Draw two cards.',
          'functional_tags': const <String>[],
          'semantic_tags_v2': const <Map<String, dynamic>>[],
        };

        expect(
          matchesFunctionalNeedForCandidate(
            'draw',
            candidate: falsePositive,
            enforceCommanderCriticalFloor: true,
          ),
          isFalse,
        );
        expect(
          countOptimizationFunctionalRole([falsePositive], role: 'draw'),
          0,
        );
        expect(
          matchesFunctionalNeedForCandidate(
            'draw',
            candidate: realDraw,
            enforceCommanderCriticalFloor: true,
          ),
          isTrue,
        );
        expect(countOptimizationFunctionalRole([realDraw], role: 'draw'), 1);
      },
    );

    test(
      'critical interaction matching uses the same predicate as the final gate',
      () {
        final stalePersistedInteraction = {
          'name': 'Clue Ceremony',
          'type_line': 'Sorcery',
          'oracle_text': 'Target player investigates.',
          'functional_tags': const ['interaction', 'removal'],
          'semantic_tags_v2': const <Map<String, dynamic>>[],
        };
        final realInteraction = {
          'name': 'Murder',
          'type_line': 'Instant',
          'oracle_text': 'Destroy target creature.',
          'functional_tags': const <String>[],
          'semantic_tags_v2': const <Map<String, dynamic>>[],
        };

        expect(
          matchesFunctionalNeedForCandidate(
            'interaction',
            candidate: stalePersistedInteraction,
            enforceCommanderCriticalFloor: true,
          ),
          isFalse,
        );
        expect(
          countOptimizationFunctionalRole([
            stalePersistedInteraction,
          ], role: 'interaction'),
          0,
        );
        expect(
          matchesFunctionalNeedForCandidate(
            'interaction',
            candidate: realInteraction,
            enforceCommanderCriticalFloor: true,
          ),
          isTrue,
        );
        expect(
          countOptimizationFunctionalRole([
            realInteraction,
          ], role: 'interaction'),
          1,
        );
      },
    );

    test(
      'matches replacement need from semantic v2 when text is ambiguous',
      () {
        final candidate = {
          'name': 'Traceable Answer',
          'type_line': 'Instant',
          'oracle_text': 'Choose one — target player investigates.',
          'functional_tags': const <String>[],
          'semantic_tags_v2': const [
            {
              'role_confidence': 0.91,
              'tags': ['removal', 'protection'],
            },
          ],
          'best_role_score': 51,
        };

        expect(
          matchesFunctionalNeedForCandidate('removal', candidate: candidate),
          isTrue,
        );
        expect(
          semanticReplacementScoreBoost(
            functionalNeed: 'removal',
            candidate: candidate,
          ),
          greaterThan(90),
        );
      },
    );

    test('does not fill a generic ramp need with contextual ramp tags', () {
      final contextualRamp = {
        'name': 'Ruby Medallion',
        'type_line': 'Artifact',
        'oracle_text': 'Red spells you cast cost {1} less to cast.',
        'functional_tags': const ['ramp'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 92,
      };
      final genericFloorRamp = {
        'name': 'Arcane Signet',
        'type_line': 'Artifact',
        'oracle_text':
            '{T}: Add one mana of any color in your commander\'s color identity.',
        'functional_tags': const ['ramp'],
        'semantic_tags_v2': const <Map<String, dynamic>>[],
        'best_role_score': 92,
      };

      expect(
        matchesFunctionalNeedForCandidate('ramp', candidate: contextualRamp),
        isFalse,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'ramp',
          candidate: contextualRamp,
        ),
        equals(0),
      );
      expect(
        matchesFunctionalNeedForCandidate('ramp', candidate: genericFloorRamp),
        isTrue,
      );
      expect(
        semanticReplacementScoreBoost(
          functionalNeed: 'ramp',
          candidate: genericFloorRamp,
        ),
        greaterThan(90),
      );
    });

    test('keeps Miracle Big Spells candidates aligned with the deck theme', () {
      final topDeckSpell = {
        'name': 'Mystical Tutor',
        'type_line': 'Instant',
        'oracle_text':
            'Search your library for an instant or sorcery card, reveal it, then put it on top of your library.',
        'functional_tags': const ['tutor'],
      };
      final offPlanEquipment = {
        'name': 'Cori-Steel Cutter',
        'type_line': 'Artifact — Equipment',
        'oracle_text':
            'Whenever you cast your second spell each turn, create a 1/1 Monk creature token.',
        'functional_tags': const ['token', 'payoff', 'engine'],
      };

      expect(
        scoreOptimizeThemeAffinity(
          candidate: topDeckSpell,
          detectedTheme: 'Miracle Big Spells',
          keepTheme: true,
        ),
        greaterThan(200),
      );
      expect(
        scoreOptimizeThemeAffinity(
          candidate: offPlanEquipment,
          detectedTheme: 'Miracle Big Spells',
          keepTheme: true,
        ),
        lessThan(0),
      );
      expect(
        scoreOptimizeThemeAffinity(
          candidate: offPlanEquipment,
          detectedTheme: 'Miracle Big Spells',
          keepTheme: false,
        ),
        0,
      );
    });

    test('selected archetype remains part of the theme ranking context', () {
      expect(
        buildOptimizeThemeContext(
          targetArchetype: 'Miracle Big Spells',
          detectedTheme: 'wheels',
        ),
        'Miracle Big Spells / wheels',
      );
      expect(
        buildOptimizeThemeContext(
          targetArchetype: 'Miracle Big Spells',
          detectedTheme: 'miracle big spells',
        ),
        'Miracle Big Spells',
      );
    });

    test(
      'deprioritizes candidates whose reviewed scope starts above bracket',
      () {
        expect(
          scoreOptimizeBracketScopeAffinity(
            candidate: const {'minimum_bracket': 3},
            bracket: 2,
          ),
          -220,
        );
        expect(
          scoreOptimizeBracketScopeAffinity(
            candidate: const {'minimum_bracket': 2},
            bracket: 2,
          ),
          0,
        );
        expect(
          scoreOptimizeBracketScopeAffinity(
            candidate: const {'minimum_bracket': 4},
            bracket: 1,
          ),
          -660,
        );
        expect(
          scoreOptimizeBracketScopeAffinity(
            candidate: const {'minimum_bracket': 5},
            bracket: 4,
          ),
          -220,
        );
      },
    );

    test('pairs replacements by functional lane instead of list position', () {
      final pairs = buildSameLaneOptimizeSwapPairs(
        removalCandidates: const [
          {
            'name': 'Mind Stone',
            'role': 'ramp',
            'score': 20,
            'protected_anchor': true,
            'anchor_reasons': ['commander_priority_card'],
          },
          {'name': 'Divination', 'role': 'draw', 'score': 18},
        ],
        replacements: const [
          {
            'name': 'Faithless Looting',
            'functional_need': 'draw',
            'purchase_required': false,
          },
          {
            'name': 'Arcane Signet',
            'functional_need': 'ramp',
            'purchase_required': false,
          },
        ],
      );

      expect(pairs, hasLength(2));
      expect(pairs[0]['remove'], 'Mind Stone');
      expect(pairs[0]['add'], 'Arcane Signet');
      expect(pairs[0]['remove_role'], 'ramp');
      expect(pairs[0]['add_role'], 'ramp');
      expect(pairs[0]['same_lane'], isTrue);
      expect(pairs[0]['protected_anchor'], isTrue);
      expect(pairs[0]['anchor_policy_satisfied'], isTrue);
      expect(pairs[0]['anchor_reasons'], contains('commander_priority_card'));
      expect(pairs[1]['remove'], 'Divination');
      expect(pairs[1]['add'], 'Faithless Looting');
    });

    test('rejects cross-lane and unclassified replacement fillers', () {
      final pairs = buildSameLaneOptimizeSwapPairs(
        removalCandidates: const [
          {'name': 'Arcane Signet', 'role': 'ramp'},
        ],
        replacements: const [
          {'name': 'Storm-Kiln Artist', 'functional_need': 'engine'},
          {'name': 'Generic Filler'},
        ],
      );

      expect(pairs, isEmpty);
    });

    test('allows a traced cross-lane swap only for role-floor repair', () {
      final pairs = buildSameLaneOptimizeSwapPairs(
        removalCandidates: const [
          {
            'name': 'Expensive Filler',
            'role': 'utility',
            'functional_role_repair': true,
            'functional_role_repair_target': 'wipe',
          },
        ],
        replacements: const [
          {
            'name': 'Wrath of God',
            'functional_need': 'wipe',
            'purchase_required': false,
          },
        ],
      );

      expect(pairs, hasLength(1));
      expect(pairs.single['same_lane'], isFalse);
      expect(pairs.single['functional_role_repair'], isTrue);
      expect(pairs.single['functional_role_repair_target'], 'wipe');
      expect(pairs.single['add_role'], 'wipe');
      expect(pairs.single['reason'], contains('piso funcional'));
    });

    test('budget gate fails closed for unknown prices', () {
      expect(
        isOptimizeCandidateWithinBudget(
          budgetLimitBrl: 100,
          budgetUsedBrl: 0,
          availableQuantity: 0,
          estimatedPriceBrl: null,
        ),
        isFalse,
      );
      expect(
        isOptimizeCandidateWithinBudget(
          budgetLimitBrl: 100,
          budgetUsedBrl: 90,
          availableQuantity: 0,
          estimatedPriceBrl: 15,
        ),
        isFalse,
      );
      expect(
        isOptimizeCandidateWithinBudget(
          budgetLimitBrl: 100,
          budgetUsedBrl: 90,
          availableQuantity: 1,
          estimatedPriceBrl: null,
        ),
        isTrue,
      );
      expect(
        isOptimizeCandidateWithinBudget(
          budgetLimitBrl: 0,
          budgetUsedBrl: 0,
          availableQuantity: 0,
          estimatedPriceBrl: 0.01,
        ),
        isFalse,
      );
      expect(
        isOptimizeCandidateWithinBudget(
          budgetLimitBrl: 0,
          budgetUsedBrl: 0,
          availableQuantity: 1,
          estimatedPriceBrl: null,
        ),
        isTrue,
      );
    });
  });
}
