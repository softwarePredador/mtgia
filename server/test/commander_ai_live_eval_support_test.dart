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
    expect(result['intensity'], 'aggressive');
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

  test('live eval metrics expose p50/p95 and cost by intensity', () {
    final summary = summarizeCommanderAiLiveEvalResults([
      {
        'status': 'ok',
        'model_requested': 'gpt-4o-mini',
        'model_returned': 'gpt-4o-mini-2024-07-18',
        'intensity': 'light',
        'latency_ms': 100,
        'usage': {'prompt_tokens': 1000, 'completion_tokens': 500},
        'evaluation': {'status': 'pass', 'score': 95},
      },
      {
        'status': 'ok',
        'model_requested': 'gpt-4o-mini',
        'model_returned': 'gpt-4o-mini-2024-07-18',
        'intensity': 'light',
        'latency_ms': 900,
        'usage': {'prompt_tokens': 500, 'completion_tokens': 250},
        'evaluation': {'status': 'fail', 'score': 80},
      },
      {
        'status': 'error',
        'model_requested': 'gpt-5.4-mini',
        'intensity': 'aggressive',
        'latency_ms': 500,
        'error_code': 'provider_timeout',
      },
    ]);

    final global = (summary['global'] as Map).cast<String, dynamic>();
    final latency = (global['latency_ms'] as Map).cast<String, dynamic>();
    final intensities = (summary['intensities'] as List).cast<Map>();
    final light = intensities.firstWhere(
      (entry) => entry['intensity'] == 'light',
    );
    final aggressive = intensities.firstWhere(
      (entry) => entry['intensity'] == 'aggressive',
    );

    expect(latency['p50'], 500);
    expect(latency['p95'], 900);
    expect(global['estimated_cost_usd'], greaterThan(0));
    expect(global['estimated_cost_coverage_ratio'], 1.0);
    expect(light['successful_case_count'], 2);
    expect(light['failed_case_count'], 1);
    expect(aggressive['error_case_count'], 1);
  });

  test('live eval fails closed for provider HTTP failures', () async {
    for (final status in [401, 429, 500]) {
      final result = await runCommanderAiLiveEvalCase(
        client: MockClient((request) async => http.Response('{}', status)),
        apiKey: 'test-key',
        model: 'gpt-4o-mini',
        systemPrompt: 'Return strict JSON swaps.',
        testCase: lorehold,
      );

      expect(result['status'], 'error', reason: 'HTTP $status');
      expect(result['error_code'], 'provider_http_error');
      expect(result['provider_status'], status);
      expect(commanderAiLiveEvalShouldFail([result]), isTrue);
    }
  });

  test('live eval fails closed for timeout and malformed success', () async {
    final timeout = await runCommanderAiLiveEvalCase(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
      apiKey: 'test-key',
      model: 'gpt-4o-mini',
      systemPrompt: 'Return strict JSON swaps.',
      testCase: lorehold,
      timeout: const Duration(milliseconds: 1),
    );
    final malformed = await runCommanderAiLiveEvalCase(
      client: MockClient((request) async => http.Response('{}', 200)),
      apiKey: 'test-key',
      model: 'gpt-4o-mini',
      systemPrompt: 'Return strict JSON swaps.',
      testCase: lorehold,
    );

    expect(timeout['error_code'], 'provider_timeout');
    expect(malformed['error_code'], 'provider_response_invalid');
    expect(commanderAiLiveEvalShouldFail([timeout, malformed]), isTrue);
  });
}
