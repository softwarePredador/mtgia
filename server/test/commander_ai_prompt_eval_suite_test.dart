import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_ai_prompt_eval_suite.dart';
import 'package:test/test.dart';

void main() {
  group('Commander AI prompt eval suite', () {
    late Map<String, dynamic> fixture;

    setUpAll(() {
      fixture = jsonDecode(
        File('test/fixtures/commander_ai_prompt_eval_cases.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('passes all fixed product eval cases', () {
      final report = evaluateCommanderAiPromptSuite(fixture);

      expect(report['schema_version'], commanderAiPromptEvalSchemaVersion);
      expect(report['status'], 'pass');
      expect(report['case_count'], 3);
      expect(report['failed_case_count'], 0);
      expect(report['score'], greaterThanOrEqualTo(90));
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
                'Funcao: removal barato. Risco: corta engine importante. Curva: baixa. Preco: BRL 6. Bracket: bracket 3.'
          }
        ],
      };

      final report = evaluateCommanderAiPromptSuite(
        fixture,
        responseOverride: badResponse,
        onlyCaseId: 'kaalia_collection_budget_bracket3',
      );

      expect(report['status'], 'fail');
      final firstCase = (report['cases'] as List).single as Map;
      final failureCodes = ((firstCase['failures'] as List).cast<Map>())
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
            'reasoning': 'Better ramp.'
          }
        ],
      };

      final report = evaluateCommanderAiPromptSuite(
        fixture,
        responseOverride: shallowResponse,
        onlyCaseId: 'atraxa_budget_curve_no_cedh',
      );

      expect(report['status'], 'fail');
      final firstCase = (report['cases'] as List).single as Map;
      final failureCodes = ((firstCase['failures'] as List).cast<Map>())
          .map((entry) => entry['code'])
          .toSet();
      expect(failureCodes, contains('swap_1_rich_explanation'));
    });

    test('renders markdown report with case summaries', () {
      final report = evaluateCommanderAiPromptSuite(fixture);
      final markdown = commanderAiPromptEvalMarkdown(report);

      expect(markdown, contains('# Commander AI Prompt Eval'));
      expect(markdown, contains('kaalia_collection_budget_bracket3'));
      expect(markdown, contains('No failures.'));
    });
  });
}
