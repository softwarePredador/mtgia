import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../ai_provider_runtime_support.dart';
import '../../openai_structured_output_support.dart';
import '../../plan_service.dart';
import 'commander_ai_prompt_eval_suite.dart';

String buildCommanderAiLiveEvalPrompt(Map<String, dynamic> testCase) {
  final recommendationContext =
      testCase['recommendation_context'] is Map
          ? (testCase['recommendation_context'] as Map)
          : const <String, dynamic>{};
  final expected =
      testCase['expected'] is Map
          ? (testCase['expected'] as Map)
          : const <String, dynamic>{};
  final sameLaneCandidates = buildCommanderAiLiveEvalSameLaneCandidates(
    testCase,
  );
  final preferCollection = recommendationContext['prefer_collection'] == true;
  final ownedCandidateAvailable = sameLaneCandidates.any(
    (candidate) => candidate['collection_match'] == true,
  );

  return jsonEncode({
    'task':
        'Recommend safe one-for-one Commander deck swaps using only the supplied catalog.',
    'commander': testCase['commander'],
    'archetype': testCase['archetype'],
    'intensity': testCase['intensity'],
    'bracket': testCase['bracket'],
    'color_identity': testCase['color_identity'],
    'current_decklist': testCase['deck'],
    'protected_cards': testCase['protected_cards'],
    'blocked_pairs': testCase['blocked_pairs'],
    'recommendation_context': testCase['recommendation_context'],
    'card_catalog': testCase['card_catalog'],
    'deterministic_same_lane_candidates': sameLaneCandidates,
    'constraints': {
      'keep_theme': true,
      'preserve_protected_cards': true,
      'never_use_blocked_pairs': true,
      'candidate_cards_must_exist_in_catalog': true,
      'every_swap_must_share_at_least_one_catalog_role': true,
      'respect_color_identity_budget_collection_and_bracket': true,
      'minimum_role_counts_after_swaps':
          expected['role_count_after_at_least'] ?? const <String, dynamic>{},
      'prefer_owned_candidates_when_requested': preferCollection,
      'owned_same_lane_candidate_available': ownedCandidateAvailable,
      'owned_candidate_requirement':
          preferCollection && ownedCandidateAvailable
              ? 'At least one addition must have collection_match=true. '
                  'Choose it from deterministic_same_lane_candidates.'
              : 'No owned addition is required for this case.',
    },
  });
}

List<Map<String, dynamic>> buildCommanderAiLiveEvalSameLaneCandidates(
  Map<String, dynamic> testCase,
) {
  final catalog =
      testCase['card_catalog'] is Map
          ? (testCase['card_catalog'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
  final deck =
      (testCase['deck'] as List?)
          ?.map((card) => card.toString())
          .toList(growable: false) ??
      const <String>[];
  final deckKeys = deck.map(_normalizeCardName).toSet();
  final protectedKeys =
      (testCase['protected_cards'] as List?)
          ?.map((card) => _normalizeCardName(card.toString()))
          .toSet() ??
      const <String>{};
  final blockedPairs =
      (testCase['blocked_pairs'] as List?)
          ?.whereType<Map>()
          .map(
            (pair) =>
                '${_normalizeCardName(pair['out']?.toString() ?? '')}\u0000'
                '${_normalizeCardName(pair['in']?.toString() ?? '')}',
          )
          .toSet() ??
      const <String>{};
  final commanderColors =
      (testCase['color_identity'] as List?)
          ?.map((color) => color.toString().toUpperCase())
          .toSet() ??
      const <String>{};
  final bracket = (testCase['bracket'] as num?)?.toInt();
  final candidates = <Map<String, dynamic>>[];

  for (final outName in deck) {
    final outKey = _normalizeCardName(outName);
    if (protectedKeys.contains(outKey)) continue;
    final outData = catalog[outName];
    if (outData is! Map) continue;
    final outRoles = _catalogRoles(outData);
    if (outRoles.isEmpty) continue;

    for (final entry in catalog.entries) {
      final inName = entry.key;
      if (deckKeys.contains(_normalizeCardName(inName))) continue;
      final inData = entry.value;
      if (inData is! Map) continue;
      final inRoles = _catalogRoles(inData);
      final sharedRoles = outRoles.intersection(inRoles).toList()..sort();
      if (sharedRoles.isEmpty) continue;
      final pairKey = '$outKey\u0000${_normalizeCardName(inName)}';
      if (blockedPairs.contains(pairKey)) continue;

      final candidateColors =
          (inData['color_identity'] as List?)
              ?.map((color) => color.toString().toUpperCase())
              .toSet() ??
          const <String>{};
      if (!commanderColors.containsAll(candidateColors)) continue;
      final minimumBracket = (inData['min_bracket'] as num?)?.toInt();
      if (bracket != null &&
          minimumBracket != null &&
          minimumBracket > bracket) {
        continue;
      }

      candidates.add({
        'out': outName,
        'in': inName,
        'shared_roles': sharedRoles,
        'collection_match': inData['owned'] == true,
        'price_brl': inData['price_brl'],
      });
    }
  }

  candidates.sort((left, right) {
    final byOwned = (right['collection_match'] == true ? 1 : 0).compareTo(
      left['collection_match'] == true ? 1 : 0,
    );
    if (byOwned != 0) return byOwned;
    final byOut = left['out'].toString().compareTo(right['out'].toString());
    if (byOut != 0) return byOut;
    return left['in'].toString().compareTo(right['in'].toString());
  });
  return candidates;
}

Set<String> _catalogRoles(Map<dynamic, dynamic> cardData) =>
    (cardData['roles'] as List?)
        ?.map((role) => role.toString().trim().toLowerCase())
        .where((role) => role.isNotEmpty && role != 'commander')
        .toSet() ??
    const <String>{};

String _normalizeCardName(String value) => value.trim().toLowerCase();

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
      intensity: testCase['intensity']?.toString(),
      code: 'provider_timeout',
      latencyMs: started.elapsedMilliseconds,
    );
  } catch (error) {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      intensity: testCase['intensity']?.toString(),
      code: 'provider_transport_error',
      latencyMs: started.elapsedMilliseconds,
      errorType: error.runtimeType.toString(),
    );
  }

  if (response.statusCode != HttpStatus.ok) {
    return _liveEvalError(
      model: model,
      caseId: testCase['id']?.toString(),
      intensity: testCase['intensity']?.toString(),
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
      'intensity': testCase['intensity']?.toString() ?? 'unspecified',
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
      intensity: testCase['intensity']?.toString(),
      code: 'provider_response_invalid',
      latencyMs: started.elapsedMilliseconds,
      errorType: error.runtimeType.toString(),
    );
  }
}

Map<String, dynamic> _liveEvalError({
  required String model,
  required String? caseId,
  required String? intensity,
  required String code,
  required int latencyMs,
  int? providerStatus,
  String? errorType,
}) {
  return {
    'status': 'error',
    'case_id': caseId,
    'intensity': intensity ?? 'unspecified',
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

Map<String, dynamic> summarizeCommanderAiLiveEvalResults(
  List<Map<String, dynamic>> results,
) {
  final models =
      results
          .map((row) => row['model_requested']?.toString() ?? '')
          .where((model) => model.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  const intensityOrder = <String>['light', 'focused', 'aggressive', 'rebuild'];
  final observedIntensities =
      results
          .map((row) => row['intensity']?.toString() ?? 'unspecified')
          .toSet();
  final intensities = <String>[
    ...intensityOrder.where(observedIntensities.contains),
    ...(observedIntensities.difference(intensityOrder.toSet()).toList()
      ..sort()),
  ];

  return {
    'pricing_version': PlanService.estimatedCostPricingVersion,
    'global': _summarizeCommanderAiLiveEvalGroup(results),
    'models': [
      for (final model in models)
        {
          'model': model,
          ..._summarizeCommanderAiLiveEvalGroup(
            results
                .where((row) => row['model_requested']?.toString() == model)
                .toList(growable: false),
          ),
        },
    ],
    'intensities': [
      for (final intensity in intensities)
        {
          'intensity': intensity,
          ..._summarizeCommanderAiLiveEvalGroup(
            results
                .where(
                  (row) =>
                      (row['intensity']?.toString() ?? 'unspecified') ==
                      intensity,
                )
                .toList(growable: false),
          ),
        },
    ],
  };
}

Map<String, dynamic> _summarizeCommanderAiLiveEvalGroup(
  List<Map<String, dynamic>> rows,
) {
  final successful = rows.where((row) => row['status'] == 'ok').toList();
  final passed =
      successful
          .where((row) => (row['evaluation'] as Map?)?['status'] == 'pass')
          .length;
  final scores =
      successful
          .map((row) => _asInt((row['evaluation'] as Map?)?['score']))
          .whereType<int>()
          .toList();
  final latencies =
      rows.map((row) => _asInt(row['latency_ms'])).whereType<int>().toList()
        ..sort();
  final usage = <AiProviderUsageTotals>[];
  var inputTokens = 0;
  var outputTokens = 0;
  for (final row in successful) {
    final rowUsage = row['usage'] as Map? ?? const <String, dynamic>{};
    final rowInput = _asInt(rowUsage['prompt_tokens']) ?? 0;
    final rowOutput = _asInt(rowUsage['completion_tokens']) ?? 0;
    inputTokens += rowInput;
    outputTokens += rowOutput;
    usage.add(
      AiProviderUsageTotals(
        model:
            row['model_returned']?.toString() ??
            row['model_requested']?.toString() ??
            '',
        inputTokens: rowInput,
        outputTokens: rowOutput,
      ),
    );
  }
  final cost = estimateAiProviderCost(usage);

  return {
    'case_count': rows.length,
    'successful_case_count': successful.length,
    'error_case_count': rows.length - successful.length,
    'passed_case_count': passed,
    'failed_case_count': successful.length - passed,
    'average_score':
        scores.isEmpty
            ? null
            : double.parse(
              (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(
                2,
              ),
            ),
    'latency_ms': {
      'p50': _nearestRankPercentile(latencies, 0.50),
      'p95': _nearestRankPercentile(latencies, 0.95),
      'max': latencies.isEmpty ? null : latencies.last,
    },
    'usage': {
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'total_tokens': inputTokens + outputTokens,
    },
    'estimated_cost_usd': double.parse(cost.usd.toStringAsFixed(6)),
    'estimated_cost_coverage_ratio': double.parse(
      cost.coverageRatio.toStringAsFixed(4),
    ),
  };
}

int? _nearestRankPercentile(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return null;
  final rank = (percentile * sortedValues.length).ceil().clamp(
    1,
    sortedValues.length,
  );
  return sortedValues[rank - 1];
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
