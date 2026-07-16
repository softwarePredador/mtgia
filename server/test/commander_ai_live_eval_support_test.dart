import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/commander_ai_live_eval_support.dart';
import 'package:server/ai/commander_ai_prompt_eval_suite.dart';
import 'package:test/test.dart';

void main() {
  final suite = loadCommanderAiPromptEvalFixture(
    'test/fixtures/commander_ai_prompt_eval_cases.json',
  );
  final lorehold = (suite['cases'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere(
        (testCase) => testCase['id'] == 'lorehold_protected_anchor_bracket2',
      );

  test('live eval prompt carries decision constraints and card evidence', () {
    final prompt = buildCommanderAiLiveEvalPrompt(lorehold);
    final decoded = jsonDecode(prompt) as Map<String, dynamic>;
    final constraints = (decoded['constraints'] as Map).cast<String, dynamic>();

    expect(prompt, contains('Velomachus Lorehold'));
    expect(prompt, contains('protected_cards'));
    expect(prompt, contains('card_catalog'));
    expect(prompt, contains('budget_limit_brl'));
    expect(decoded['deterministic_same_lane_candidates'], isNotEmpty);
    expect(
      constraints['every_swap_must_share_at_least_one_catalog_role'],
      isTrue,
    );
    expect(constraints['minimum_role_counts_after_swaps'], isNotEmpty);
  });

  test('live eval exposes owned legal same-lane candidates', () {
    final atraxa = (suite['cases'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (testCase) => testCase['id'] == 'atraxa_budget_curve_no_cedh',
        );

    final candidates = buildCommanderAiLiveEvalSameLaneCandidates(atraxa);

    expect(
      candidates,
      contains(
        allOf(
          containsPair('out', 'Cultivate'),
          containsPair('in', "Nature's Lore"),
          containsPair('collection_match', true),
        ),
      ),
    );
    expect(
      candidates.where((candidate) => candidate['collection_match'] == true),
      isNotEmpty,
    );
  });

  test('live eval runner applies the existing deterministic scorer', () async {
    final candidate =
        (lorehold['candidate_response'] as Map).cast<String, dynamic>();
    late Map<String, dynamic> requestPayload;
    final result = await runCommanderAiLiveEvalCase(
      client: MockClient((request) async {
        requestPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'model': 'gpt-5.4-mini-2026-03-17',
            'choices': [
              {
                'message': {'content': jsonEncode(candidate)},
              },
            ],
            'usage': {
              'prompt_tokens': 100,
              'completion_tokens': 50,
              'total_tokens': 150,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      apiKey: 'test-key',
      model: 'gpt-5.4-mini',
      systemPrompt: 'Return strict JSON swaps.',
      testCase: lorehold,
    );

    expect(result['status'], 'ok');
    expect((result['evaluation'] as Map)['status'], 'pass');
    expect(requestPayload, contains('max_completion_tokens'));
    expect(requestPayload, isNot(contains('max_tokens')));
    expect(
      requestPayload['response_format'],
      containsPair('type', 'json_schema'),
    );
    expect(requestPayload['safety_identifier'], startsWith('manaloom_'));
  });

  test('live eval gate fails on provider errors and quality failures', () {
    expect(
      commanderAiLiveEvalShouldFail([
        {
          'status': 'ok',
          'evaluation': {'status': 'pass'},
        },
      ]),
      isFalse,
    );
    expect(
      commanderAiLiveEvalShouldFail([
        {
          'status': 'ok',
          'evaluation': {'status': 'fail'},
        },
      ]),
      isTrue,
    );
    expect(
      commanderAiLiveEvalShouldFail([
        {'status': 'error'},
      ]),
      isTrue,
    );
    expect(
      commanderAiLiveEvalShouldFail([
        {
          'status': 'ok',
          'evaluation': {'status': 'fail'},
        },
      ], allowQualityFailures: true),
      isFalse,
    );
  });
}
