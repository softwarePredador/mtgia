import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../ai_provider_runtime_support.dart';
import '../../openai_structured_output_support.dart';
import 'commander_ai_prompt_eval_suite.dart';

String buildCommanderAiLiveEvalPrompt(Map<String, dynamic> testCase) {
  return jsonEncode({
    'task':
        'Recommend safe one-for-one Commander deck swaps using only the supplied catalog.',
    'commander': testCase['commander'],
    'archetype': testCase['archetype'],
    'bracket': testCase['bracket'],
    'color_identity': testCase['color_identity'],
    'current_decklist': testCase['deck'],
    'protected_cards': testCase['protected_cards'],
    'blocked_pairs': testCase['blocked_pairs'],
    'recommendation_context': testCase['recommendation_context'],
    'card_catalog': testCase['card_catalog'],
    'constraints': {
      'keep_theme': true,
      'preserve_protected_cards': true,
      'never_use_blocked_pairs': true,
      'candidate_cards_must_exist_in_catalog': true,
      'respect_color_identity_budget_collection_and_bracket': true,
      'prefer_owned_candidates_when_requested':
          testCase['recommendation_context'] is Map &&
          (testCase['recommendation_context'] as Map)['prefer_collection'] ==
              true,
      'owned_candidate_requirement':
          'When collection preference is enabled, use an owned same-lane '
          'candidate whenever the catalog provides a legal option.',
    },
  });
}

Future<Map<String, dynamic>> runCommanderAiLiveEvalCase({
  required http.Client client,
  required String apiKey,
  required String model,
  required String systemPrompt,
  required Map<String, dynamic> testCase,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final started = Stopwatch()..start();
  late final http.Response response;
  try {
    response = await client
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            ...aiSafetyIdentifierPayload('commander-ai-live-eval'),
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {
                'role': 'user',
                'content': buildCommanderAiLiveEvalPrompt(testCase),
              },
            ],
            'temperature': 0.2,
            ...openAiTokenLimitPayload(model: model, maxTokens: 1400),
            'response_format': openAiStructuredResponseFormat(
              model: model,
              name: 'commander_model_eval',
              schema: openAiDeckOptimizationSchema,
            ),
          }),
        )
        .timeout(timeout);
  } on TimeoutException {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      code: 'provider_timeout',
      latencyMs: started.elapsedMilliseconds,
    );
  } catch (error) {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      code: 'provider_transport_error',
      latencyMs: started.elapsedMilliseconds,
      errorType: error.runtimeType.toString(),
    );
  }

  if (response.statusCode != HttpStatus.ok) {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      code: 'provider_http_error',
      providerStatus: response.statusCode,
      latencyMs: started.elapsedMilliseconds,
    );
  }

  try {
    final outer =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = outer['choices'] as List<dynamic>;
    final first = (choices.first as Map).cast<String, dynamic>();
    final message = (first['message'] as Map).cast<String, dynamic>();
    final content = message['content'] as String;
    final candidate = (jsonDecode(content) as Map).cast<String, dynamic>();
    final evaluation = evaluateCommanderAiPromptCase(
      testCase,
      candidateResponse: candidate,
      minimumScore: 0,
    );
    final usage =
        outer['usage'] is Map
            ? (outer['usage'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};

    return {
      'status': 'ok',
      'case_id': testCase['id'],
      'model_requested': model,
      'model_returned': outer['model'],
      'latency_ms': started.elapsedMilliseconds,
      'usage': {
        'prompt_tokens': usage['prompt_tokens'],
        'completion_tokens': usage['completion_tokens'],
        'total_tokens': usage['total_tokens'],
      },
      'candidate_response': candidate,
      'evaluation': evaluation,
    };
  } catch (error) {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      code: 'provider_response_invalid',
      latencyMs: started.elapsedMilliseconds,
      errorType: error.runtimeType.toString(),
    );
  }
}

Map<String, dynamic> _liveEvalError({
  required String model,
  required String? caseId,
  required String code,
  required int latencyMs,
  int? providerStatus,
  String? errorType,
}) {
  return {
    'status': 'error',
    'case_id': caseId,
    'model_requested': model,
    'error_code': code,
    if (providerStatus != null) 'provider_status': providerStatus,
    if (errorType != null) 'error_type': errorType,
    'latency_ms': latencyMs,
  };
}

bool commanderAiLiveEvalShouldFail(
  List<Map<String, dynamic>> results, {
  bool allowQualityFailures = false,
}) {
  for (final result in results) {
    if (result['status'] != 'ok') return true;
    if (allowQualityFailures) continue;
    final evaluation = result['evaluation'];
    if (evaluation is! Map || evaluation['status'] != 'pass') return true;
  }
  return false;
}
