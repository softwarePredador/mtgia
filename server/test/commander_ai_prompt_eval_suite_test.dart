import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_ai_prompt_eval_suite.dart';
import 'package:test/test.dart';

void main() {
  group('Commander AI prompt eval suite', () {
    late Map<String, dynamic> fixture;

    setUpAll(() {
      fixture =
          jsonDecode(
                File(
                  'test/fixtures/commander_ai_prompt_eval_cases.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('passes all fixed product eval cases', () {
      final report = evaluateCommanderAiPromptSuite(fixture);

      expect(report['schema_version'], commanderAiPromptEvalSchemaVersion);
      expect(report['status'], 'pass');
      expect(report['case_count'], 12);
      expect(report['failed_case_count'], 0);
      expect(report['score'], greaterThanOrEqualTo(90));
      final coverage = report['coverage'] as Map<String, dynamic>;
      expect(coverage['status'], 'pass');
      expect(coverage['brackets'], [1, 2, 3, 4, 5]);
      expect(coverage['color_buckets'], [
        'colorless',
        'mono',
        'three_plus',
        'two',
      ]);
      expect(coverage['archetype_family_count'], 12);
      expect(coverage['commander_pairing_mechanics'], ['background']);
      expect(coverage['color_features'], ['five_color', 'hybrid_mana']);
      expect(coverage['card_layouts'], ['adventure', 'modal_dfc', 'split']);
      expect(coverage['source_states'], [
        'corpus_sparse',
        'profile_low_confidence',
        'profile_missing',
      ]);
      expect(coverage['constraint_states'], [
        'collection_only',
        'incomplete_deck',
        'zero_budget',
      ]);
    });

    test('fails closed when a held-out coverage bucket is removed', () {
      final incomplete =
          jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      (incomplete['cases'] as List).removeWhere(
        (entry) =>
            (entry as Map<String, dynamic>)['id'] ==
            'kozilek_colorless_fast_mana_bracket5',
      );

      final report = evaluateCommanderAiPromptSuite(incomplete);
      final coverage = report['coverage'] as Map<String, dynamic>;
      final failureCodes =
          (coverage['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(report['status'], 'fail');
      expect(coverage['status'], 'fail');
      expect(failureCodes, contains('minimum_case_count'));
      expect(failureCodes, contains('required_brackets'));
      expect(failureCodes, contains('required_color_buckets'));
    });

    test('fails closed when fixture schema is stale', () {
      final stale = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      stale['schema_version'] = 'commander_ai_prompt_eval_v1_2026-07-06';

      final report = evaluateCommanderAiPromptSuite(stale);
      final coverage = report['coverage'] as Map<String, dynamic>;
      final failureCodes =
          (coverage['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(report['status'], 'fail');
      expect(failureCodes, contains('fixture_schema_current'));
    });

    test('does not credit multiface labels without matching face evidence', () {
      final malformed = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List).cast<Map<String, dynamic>>();
      final layoutCase = cases.firstWhere(
        (entry) => entry['id'] == 'marchesa_multiface_layouts_bracket3',
      );
      final catalog =
          (layoutCase['card_catalog'] as Map).cast<String, dynamic>();
      (catalog['Wear // Tear'] as Map).remove('faces');

      final report = evaluateCommanderAiPromptSuite(malformed);
      final coverage = report['coverage'] as Map<String, dynamic>;
      final failureCodes =
          (coverage['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(report['status'], 'fail');
      expect(coverage['card_layouts'], isNot(contains('split')));
      expect(failureCodes, contains('required_card_layouts'));
    });

    test('does not credit background pairing without oracle/type evidence', () {
      final malformed = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List).cast<Map<String, dynamic>>();
      final backgroundCase = cases.firstWhere(
        (entry) => entry['id'] == 'wilson_background_pair_bracket2',
      );
      final catalog =
          (backgroundCase['card_catalog'] as Map).cast<String, dynamic>();
      (catalog['Wilson, Refined Grizzly'] as Map)['oracle_text'] =
          'Vigilance, reach. Wilson cannot be countered.';

      final report = evaluateCommanderAiPromptSuite(malformed);
      final coverage = report['coverage'] as Map<String, dynamic>;
      final failureCodes =
          (coverage['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();
      final evaluatedCase = (report['cases'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (entry) => entry['id'] == 'wilson_background_pair_bracket2',
          );
      final caseFailureCodes =
          (evaluatedCase['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(report['status'], 'fail');
      expect(failureCodes, contains('required_commander_pairing_mechanics'));
      expect(caseFailureCodes, contains('commander_pairing_verified'));
    });

    test('does not credit hybrid coverage from five-color label alone', () {
      final malformed = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List).cast<Map<String, dynamic>>();
      final hybridCase = cases.firstWhere(
        (entry) => entry['id'] == 'kenrith_five_color_hybrid_bracket3',
      );
      final catalog =
          (hybridCase['card_catalog'] as Map).cast<String, dynamic>();
      (catalog['Kitchen Finks'] as Map).remove('mana_cost');

      final report = evaluateCommanderAiPromptSuite(malformed);
      final coverage = report['coverage'] as Map<String, dynamic>;
      final failureCodes =
          (coverage['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(report['status'], 'fail');
      expect(coverage['color_features'], contains('five_color'));
      expect(coverage['color_features'], isNot(contains('hybrid_mana')));
      expect(failureCodes, contains('required_color_features'));
    });

    test('requires source-limit disclosures derived from numeric evidence', () {
      final sourceCase = (fixture['cases'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (entry) =>
                entry['id'] == 'otaria_low_profile_sparse_corpus_bracket2',
          );
      final candidate =
          jsonDecode(jsonEncode(sourceCase['candidate_response']))
              as Map<String, dynamic>;
      candidate['summary'] = 'Esta recomendação tem confiança alta e exata.';

      final evaluated = evaluateCommanderAiPromptCase(
        sourceCase,
        candidateResponse: candidate,
        minimumScore: 90,
      );
      final failureCodes =
          (evaluated['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(
        failureCodes,
        contains('source_state_profile_low_confidence_disclosed'),
      );
      expect(failureCodes, contains('source_state_corpus_sparse_disclosed'));
      expect(failureCodes, contains('reference_fallback_disclosed'));
      expect(
        failureCodes,
        contains('no_unsupported_reference_confidence_claim'),
      );
    });

    test('collection_only rejects an unowned zero-price addition', () {
      final constraintCase = (fixture['cases'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (entry) =>
                entry['id'] == 'konrad_collection_only_zero_budget_incomplete',
          );
      final candidate =
          jsonDecode(jsonEncode(constraintCase['candidate_response']))
              as Map<String, dynamic>;
      ((candidate['swaps'] as List).single as Map)['in'] = 'Mind Stone';

      final evaluated = evaluateCommanderAiPromptCase(
        constraintCase,
        candidateResponse: candidate,
        minimumScore: 90,
      );
      final checks = (evaluated['checks'] as List).cast<Map<String, dynamic>>();
      final failureCodes =
          (evaluated['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(failureCodes, contains('collection_only_respected'));
      expect(
        checks.firstWhere(
          (entry) => entry['code'] == 'budget_limit_respected',
        )['status'],
        'pass',
      );
    });

    test('requires an actual incomplete deck to be acknowledged', () {
      final constraintCase = (fixture['cases'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (entry) =>
                entry['id'] == 'konrad_collection_only_zero_budget_incomplete',
          );
      final candidate =
          jsonDecode(jsonEncode(constraintCase['candidate_response']))
              as Map<String, dynamic>;
      candidate['summary'] = 'Uma troca conservadora usando a coleção.';

      final evaluated = evaluateCommanderAiPromptCase(
        constraintCase,
        candidateResponse: candidate,
        minimumScore: 90,
      );
      final failureCodes =
          (evaluated['failures'] as List)
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['code'])
              .toSet();

      expect(failureCodes, contains('incomplete_deck_acknowledged'));
    });

    test('blocks exact add/cut pairs rejected by battle feedback', () {
      final badResponse = {
        'summary': 'Kaalia adds removal by cutting a blocked ramp engine.',
        'swaps': [
          {
            'out': 'Birgi, God of Storytelling // Harnfel, Horn of Bounty',
            'in': 'Feed the Swarm',
            'category': 'Removal',
            'reasoning':
                'Funcao: removal barato. Risco: corta engine importante. Curva: baixa. Preco: BRL 6. Bracket: bracket 3.',
          },
        ],
      };

      final report = evaluateCommanderAiPromptSuite(
        fixture,
        responseOverride: badResponse,
        onlyCaseId: 'kaalia_collection_budget_bracket3',
      );

      expect(report['status'], 'fail');
      final firstCase = (report['cases'] as List).single as Map;
      final failureCodes =
          ((firstCase['failures'] as List).cast<Map>())
              .map((entry) => entry['code'])
              .toSet();
      expect(failureCodes, contains('swap_1_protected_anchor_preserved'));
      expect(failureCodes, contains('swap_1_not_blocked_by_battle_feedback'));
    });

    test('fails responses without rich swap explanation', () {
      final shallowResponse = {
        'summary': 'Atraxa gets upgrades.',
        'swaps': [
          {
            'out': 'Cultivate',
            'in': 'Nature\'s Lore',
            'category': 'Mana Ramp',
            'reasoning': 'Better ramp.',
          },
        ],
      };

      final report = evaluateCommanderAiPromptSuite(
        fixture,
        responseOverride: shallowResponse,
        onlyCaseId: 'atraxa_budget_curve_no_cedh',
      );

      expect(report['status'], 'fail');
      final firstCase = (report['cases'] as List).single as Map;
      final failureCodes =
          ((firstCase['failures'] as List).cast<Map>())
              .map((entry) => entry['code'])
              .toSet();
      expect(failureCodes, contains('swap_1_rich_explanation'));
    });

    test('accepts accented Portuguese evidence labels', () {
      final lorehold = (fixture['cases'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (testCase) =>
                testCase['id'] == 'lorehold_protected_anchor_bracket2',
          );
      final candidate =
          jsonDecode(jsonEncode(lorehold['candidate_response']))
              as Map<String, dynamic>;
      for (final swap in (candidate['swaps'] as List).cast<Map>()) {
        swap['reasoning'] =
            'Função: preserva a lane. Risco: baixo. Curva: reduz mana value. '
            'Preço: já possuída, BRL 0. Bracket: adequada ao nível 2.';
      }

      final evaluated = evaluateCommanderAiPromptCase(
        lorehold,
        candidateResponse: candidate,
        minimumScore: 90,
      );
      final failureCodes =
          ((evaluated['failures'] as List).cast<Map>())
              .map((entry) => entry['code'])
              .toSet();

      expect(
        failureCodes.where(
          (code) => code.toString().endsWith('_rich_explanation'),
        ),
        isEmpty,
      );
    });

    test('renders markdown report with case summaries', () {
      final report = evaluateCommanderAiPromptSuite(fixture);
      final markdown = commanderAiPromptEvalMarkdown(report);

      expect(markdown, contains('# Commander AI Prompt Eval'));
      expect(markdown, contains('## Held-out coverage'));
      expect(markdown, contains('kaalia_collection_budget_bracket3'));
      expect(markdown, contains('No failures.'));
    });
  });
}
