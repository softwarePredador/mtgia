import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'optimize_complete_support.dart' as optimize_complete;
import 'optimize_analysis_support.dart' as optimize_analysis;
import 'optimize_job.dart';
import 'optimize_runtime_support.dart';
import 'optimize_stage_telemetry.dart';
import 'optimization_validator.dart';
import 'otimizacao.dart';
import 'optimize_state_support.dart' as optimize_state;
import 'optimize_route_request_support.dart';
import '../ai_generate_internal_url_support.dart';
import '../internal_ai_request_token.dart';
import '../logger.dart';

Future<void> processOptimizeModeAsync({
  required Pool pool,
  required String jobId,
  required Uri internalOptimizeUrl,
  required Map<String, dynamic> syncPayload,
  required String? authorization,
}) async {
  await OptimizeJobStore.progress(
    pool,
    jobId,
    stage: 'Preparando optimize agressivo...',
    stageNumber: 1,
  );

  final stopwatch = Stopwatch()..start();
  await OptimizeJobStore.progress(
    pool,
    jobId,
    stage: 'Gerando preview seguro...',
    stageNumber: 2,
  );

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'X-Internal-AI-Request-Token': InternalAiRequestToken.value,
    if (authorization != null && authorization.trim().isNotEmpty)
      'Authorization': authorization,
  };

  late final http.Response response;
  try {
    response = await http
        .post(
          internalOptimizeUrl,
          headers: headers,
          body: jsonEncode(syncPayload),
        )
        .timeout(const Duration(minutes: 3));
  } on TimeoutException {
    await OptimizeJobStore.fail(
      pool,
      jobId,
      error: 'Tempo limite excedido ao otimizar deck async.',
    );
    return;
  }

  await OptimizeJobStore.progress(
    pool,
    jobId,
    stage: 'Persistindo resultado...',
    stageNumber: 5,
  );

  Map<String, dynamic> resultBody;
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    resultBody =
        decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
            ? decoded.cast<String, dynamic>()
            : <String, dynamic>{'value': decoded};
  } catch (_) {
    await OptimizeJobStore.fail(
      pool,
      jobId,
      error: 'Optimize async recebeu resposta invalida do executor interno.',
    );
    return;
  }

  resultBody['async'] = {
    'job_id': jobId,
    'completed_ms': stopwatch.elapsedMilliseconds,
    'result_status_code': response.statusCode,
    'executor': 'optimize_async_job',
  };

  if (response.statusCode == HttpStatus.ok) {
    await OptimizeJobStore.complete(pool, jobId, result: resultBody);
    return;
  }

  if (response.statusCode == HttpStatus.unprocessableEntity) {
    final qualityError =
        resultBody['quality_error'] is Map
            ? (resultBody['quality_error'] as Map).cast<String, dynamic>()
            : <String, dynamic>{
              'code':
                  resultBody['outcome_code']?.toString() ??
                  'OPTIMIZE_ASYNC_QUALITY_REJECTED',
              'message':
                  resultBody['error']?.toString() ??
                  'Optimize async foi bloqueado pelo gate de qualidade.',
            };
    final optimizeDiagnostics =
        resultBody['optimize_diagnostics'] is Map
            ? (resultBody['optimize_diagnostics'] as Map)
                .cast<String, dynamic>()
            : const <String, dynamic>{};
    final asyncQualityError = <String, dynamic>{
      ...qualityError,
      if (resultBody['outcome_code'] != null)
        'outcome_code': resultBody['outcome_code']?.toString(),
      if (optimizeDiagnostics.isNotEmpty)
        'optimize_diagnostics': optimizeDiagnostics,
    };
    await OptimizeJobStore.fail(
      pool,
      jobId,
      error:
          resultBody['error']?.toString() ??
          'Optimize async nao produziu preview seguro.',
      qualityError: asyncQualityError,
    );
    return;
  }

  await OptimizeJobStore.fail(
    pool,
    jobId,
    error: resultBody['error']?.toString() ?? 'Falha ao otimizar deck async.',
  );
}

Uri resolveInternalOptimizeUrl(Request request) {
  return resolveInternalAiRouteUrl(
    headers: request.headers,
    requestUri: request.uri,
    routePath: '/ai/optimize',
    configuredBaseUrl: Platform.environment['AI_OPTIMIZE_INTERNAL_BASE_URL'],
    fallbackPort: Platform.environment['PORT']?.trim(),
  );
}

Future<String> semanticV2SelectSql(Pool pool) async {
  final exists = await hasOptimizeTable(pool, 'card_semantic_tags_v2');
  if (!exists) return 'NULL::jsonb AS semantic_tags_v2';
  return '''
                     (
                       SELECT jsonb_agg(jsonb_build_object(
                         'tags', cstv2.tags,
                         'role_confidence', cstv2.role_confidence,
                         'engine', cstv2.engine,
                         'payoff', cstv2.payoff,
                         'enabler', cstv2.enabler,
                         'wincon', cstv2.wincon,
                         'combo_piece', cstv2.combo_piece
                       ))
                        FROM card_semantic_tags_v2 cstv2
                       WHERE cstv2.card_id = cards.id
                     ) AS semantic_tags_v2''';
}

Future<String> functionalTagsSelectSql(Pool pool) async {
  final exists = await hasOptimizeTable(pool, 'card_function_tags');
  if (!exists) return "'[]'::jsonb AS functional_tags";
  return '''
                     COALESCE(
                       (SELECT jsonb_agg(jsonb_build_object(
                         'tag', cft.tag,
                         'confidence', cft.confidence,
                         'evidence', cft.evidence,
                         'source', cft.source
                       ) ORDER BY cft.confidence DESC, cft.tag)
                       FROM card_function_tags cft
                       WHERE cft.card_id = cards.id
                       ),
                       '[]'::jsonb
                     ) AS functional_tags''';
}

Future<bool> hasOptimizeTable(Pool pool, String tableName) async {
  try {
    final result = await pool.execute(
      Sql.named("SELECT to_regclass(@name) IS NOT NULL"),
      parameters: {'name': tableName},
    );
    return result.isNotEmpty && result.first[0] == true;
  } catch (_) {
    return false;
  }
}

Future<void> recordOptimizeAnalysisOutcome({
  required Pool pool,
  required String deckId,
  required String? userId,
  required String commanderName,
  required List<String> commanderColors,
  required String operationMode,
  required String requestedMode,
  required String targetArchetype,
  required String? detectedTheme,
  required Map<String, dynamic> deckAnalysis,
  required Map<String, dynamic>? postAnalysis,
  required List<String> removals,
  required List<String> additions,
  required int statusCode,
  required Map<String, dynamic>? qualityError,
  required ValidationReport? validationReport,
  required List<String> validationWarnings,
  required List<String> blockedByColorIdentity,
  required List<Map<String, dynamic>> blockedByBracket,
  required List<String> commanderPriorityNames,
  required String commanderPrioritySource,
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String cacheKey,
  required int executionTimeMs,
}) async {
  await optimize_analysis.recordOptimizeAnalysisOutcome(
    pool: pool,
    deckId: deckId,
    userId: userId,
    commanderName: commanderName,
    commanderColors: commanderColors,
    operationMode: operationMode,
    requestedMode: requestedMode,
    targetArchetype: targetArchetype,
    detectedTheme: detectedTheme,
    deckAnalysis: deckAnalysis,
    postAnalysis: postAnalysis,
    removals: removals,
    additions: additions,
    statusCode: statusCode,
    qualityError: qualityError,
    validationReport: validationReport,
    validationWarnings: validationWarnings,
    blockedByColorIdentity: blockedByColorIdentity,
    blockedByBracket: blockedByBracket,
    commanderPriorityNames: commanderPriorityNames,
    commanderPrioritySource: commanderPrioritySource,
    deterministicSwapCandidates: deterministicSwapCandidates,
    cacheKey: cacheKey,
    executionTimeMs: executionTimeMs,
  );
}

/// Processa o modo complete em background (async job).
/// Chamada via `unawaited()` â€” NÃƒO bloqueia a resposta HTTP.
Future<void> processCompleteModeAsync({
  required String jobId,
  required Pool pool,
  required String deckId,
  required String deckFormat,
  required int maxTotal,
  required int currentTotalCards,
  required List<String> commanders,
  required List<Map<String, dynamic>> allCardData,
  required Set<String> deckColors,
  required Set<String> commanderColorIdentity,
  required Map<String, int> originalCountsById,
  DeckOptimizerService? optimizer,
  required optimize_state.DeckThemeProfileResult themeProfile,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required Map<String, dynamic> deckAnalysis,
  required String? userId,
  required String deckSignature,
  required String? cacheKey,
  required OptimizeIntensityConfig intensity,
  required Map<String, dynamic> userPreferences,
  required bool hasBracketOverride,
  required bool hasKeepThemeOverride,
  required OptimizeRecommendationContext recommendationContext,
}) async {
  try {
    final telemetry = OptimizeStageTelemetry(
      deckId: deckId,
      requestMode: 'complete_async',
      jobId: jobId,
    );
    await OptimizeJobStore.progress(
      pool,
      jobId,
      stage: 'Preparando referÃªncias do commander...',
      stageNumber: 1,
    );

    Map<String, dynamic> jsonResponse;
    final state = optimize_complete.CompleteBuildAccumulator.fromDeck(
      allCardData: allCardData,
      originalCountsById: originalCountsById,
      currentTotalCards: currentTotalCards,
    );
    await telemetry.trackAsync(
      'complete.prepare_commander_seed',
      () => optimize_complete.prepareCompleteCommanderSeed(
        pool: pool,
        commanders: commanders,
        maxTotal: maxTotal,
        currentTotalCards: currentTotalCards,
        state: state,
        bracket: bracket,
      ),
    );

    if (optimizer != null) {
      await OptimizeJobStore.progress(
        pool,
        jobId,
        stage: 'Consultando IA para sugestÃµes...',
        stageNumber: 2,
      );
      await telemetry.trackAsync(
        'complete.ai_suggestion_loop',
        () => optimize_complete.runCompleteAiSuggestionLoop(
          pool: pool,
          optimizer: optimizer,
          commanders: commanders,
          deckColors: deckColors,
          commanderColorIdentity: commanderColorIdentity,
          deckFormat: deckFormat,
          targetArchetype: targetArchetype,
          bracket: bracket,
          keepTheme: keepTheme,
          detectedTheme: themeProfile.theme,
          coreCards: themeProfile.coreCards,
          maxTotal: maxTotal,
          state: state,
        ),
      );
    } else {
      await OptimizeJobStore.progress(
        pool,
        jobId,
        stage: 'Pulando IA (modo determinÃ­stico)...',
        stageNumber: 2,
      );
    }

    telemetry.trackSync(
      'complete.rebalance_land_deficit',
      () => optimize_complete.rebalanceCompleteDeckForLandDeficit(
        state: state,
        maxTotal: maxTotal,
      ),
    );

    await OptimizeJobStore.progress(
      pool,
      jobId,
      stage: 'Preenchendo com cartas sinÃ©rgicas...',
      stageNumber: 3,
    );
    await OptimizeJobStore.progress(
      pool,
      jobId,
      stage: 'Ajustando base de mana...',
      stageNumber: 4,
    );

    await telemetry.trackAsync(
      'complete.fill_remainder',
      () => optimize_complete.fillCompleteDeckRemainder(
        pool: pool,
        commanders: commanders,
        commanderColorIdentity: commanderColorIdentity,
        deckFormat: deckFormat,
        targetArchetype: targetArchetype,
        bracket: bracket,
        keepTheme: keepTheme,
        detectedTheme: themeProfile.theme,
        coreCards: themeProfile.coreCards,
        maxTotal: maxTotal,
        state: state,
      ),
    );

    jsonResponse = telemetry.trackSync(
      'complete.build_intermediate_payload',
      () => optimize_complete.buildCompleteIntermediatePayload(
        state: state,
        maxTotal: maxTotal,
        currentTotalCards: currentTotalCards,
        targetArchetype: targetArchetype,
      ),
    );

    await OptimizeJobStore.progress(
      pool,
      jobId,
      stage: 'Processando resultado final...',
      stageNumber: 6,
    );

    // Post-processing: validar qualidade e construir resposta
    if (jsonResponse['mode'] == 'complete' &&
        jsonResponse['additions_detailed'] is List) {
      final qualityError = jsonResponse['quality_error'];
      if (qualityError is Map) {
        await OptimizeJobStore.fail(
          pool,
          jobId,
          error: 'Complete mode nÃ£o atingiu qualidade mÃ­nima.',
          qualityError: qualityError.cast<String, dynamic>(),
        );
        return;
      }

      final responseBody = await telemetry.trackAsync(
        'complete.build_final_response',
        () => optimize_complete.buildCompleteFinalResponse(
          pool: pool,
          deckFormat: deckFormat,
          originalDeck: allCardData,
          deckColors: deckColors,
          keepTheme: keepTheme,
          theme: themeProfile.toJson(),
          bracket: bracket,
          deckAnalysis: deckAnalysis,
          jsonResponse: jsonResponse,
          targetArchetype: targetArchetype,
          intensity: intensity.selected,
        ),
      );
      if (cacheKey != null && cacheKey.isNotEmpty) {
        responseBody['cache'] = {'hit': false, 'cache_key': cacheKey};
        responseBody['intensity'] = intensity.selected;
        responseBody['optimize_intensity'] = intensity.toJson(
          returnedSwaps:
              (responseBody['additions_detailed'] as List?)?.length ?? 0,
        );
        responseBody['preferences'] = {
          'memory_applied': !hasBracketOverride || !hasKeepThemeOverride,
          'keep_theme': keepTheme,
          'preferred_bracket': userPreferences['preferred_bracket'],
        };
      }
      responseBody['timings'] = telemetry.snapshot();
      responseBody['stage_telemetry'] = responseBody['timings'];
      attachRecommendationContextToOptimizeResponse(
        responseBody,
        recommendationContext,
      );
      telemetry.logSummary();
      if (cacheKey != null && cacheKey.isNotEmpty) {
        await saveOptimizeCache(
          pool: pool,
          cacheKey: cacheKey,
          userId: userId,
          deckId: deckId,
          deckSignature: deckSignature,
          payload: responseBody,
        );
      }
      await OptimizeJobStore.complete(pool, jobId, result: responseBody);
    } else {
      // Fallback: se por algum motivo nÃ£o veio como complete
      if (cacheKey != null && cacheKey.isNotEmpty) {
        jsonResponse['cache'] = {'hit': false, 'cache_key': cacheKey};
      }
      jsonResponse['intensity'] = intensity.selected;
      jsonResponse['optimize_intensity'] = intensity.toJson(
        returnedSwaps:
            (jsonResponse['additions_detailed'] as List?)?.length ??
            (jsonResponse['additions'] as List?)?.length ??
            0,
      );
      jsonResponse['timings'] = telemetry.snapshot();
      jsonResponse['stage_telemetry'] = jsonResponse['timings'];
      attachRecommendationContextToOptimizeResponse(
        jsonResponse,
        recommendationContext,
      );
      telemetry.logSummary();
      if (cacheKey != null && cacheKey.isNotEmpty) {
        await saveOptimizeCache(
          pool: pool,
          cacheKey: cacheKey,
          userId: userId,
          deckId: deckId,
          deckSignature: deckSignature,
          payload: jsonResponse,
        );
      }
      await OptimizeJobStore.complete(pool, jobId, result: jsonResponse);
    }
  } catch (e, stackTrace) {
    Log.e('Background optimize job $jobId failed: $e\n$stackTrace');
    await OptimizeJobStore.fail(pool, jobId, error: e.toString());
  }
}
