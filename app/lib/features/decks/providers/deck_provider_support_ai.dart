import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/logger.dart';
import 'deck_provider_support_common.dart';

const _genericOptimizeJobFailureMessage =
    'Não foi possível concluir a otimização agora. Tente novamente em instantes.';

const minOptimizePollIntervalMs = 1000;
const maxOptimizePollIntervalMs = 10000;
const defaultOptimizePollTimeoutMs = 300000;
const optimizePollTimeoutGraceMs = 15000;
const minOptimizePollTimeoutMs = 30000;
const maxOptimizePollTimeoutMs = 420000;

int normalizeOptimizePollIntervalMs(Object? raw, {int fallback = 2000}) {
  final parsed = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  final effective = parsed != null && parsed > 0 ? parsed : fallback;
  return effective.clamp(minOptimizePollIntervalMs, maxOptimizePollIntervalMs);
}

int normalizeOptimizePollTimeoutMs(
  Object? raw, {
  int fallback = defaultOptimizePollTimeoutMs,
}) {
  final parsed = switch (raw) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || parsed <= 0) {
    return fallback.clamp(minOptimizePollTimeoutMs, maxOptimizePollTimeoutMs);
  }
  return (parsed + optimizePollTimeoutGraceMs).clamp(
    minOptimizePollTimeoutMs,
    maxOptimizePollTimeoutMs,
  );
}

Map<String, dynamic> buildOptimizeRequestPayload({
  required String deckId,
  required String archetype,
  int? bracket,
  required bool keepTheme,
  OptimizeIntensity intensity = OptimizeIntensity.focused,
  Map<String, dynamic>? recommendationContext,
  String? requestKey,
}) {
  return <String, dynamic>{
    'deck_id': deckId,
    'archetype': archetype,
    if (bracket != null) 'bracket': bracket,
    'keep_theme': keepTheme,
    'intensity': intensity.apiValue,
    if (recommendationContext != null && recommendationContext.isNotEmpty)
      'recommendation_context': recommendationContext,
    if (requestKey != null && requestKey.trim().isNotEmpty)
      'request_key': requestKey.trim(),
  };
}

Future<OptimizeDeckRequestResult> requestOptimizeDeck(
  ApiClient apiClient, {
  required String deckId,
  required String archetype,
  int? bracket,
  required bool keepTheme,
  OptimizeIntensity intensity = OptimizeIntensity.focused,
  Map<String, dynamic>? recommendationContext,
  String? requestKey,
}) async {
  final payload = buildOptimizeRequestPayload(
    deckId: deckId,
    archetype: archetype,
    bracket: bracket,
    keepTheme: keepTheme,
    intensity: intensity,
    recommendationContext: recommendationContext,
    requestKey: requestKey,
  );

  AppLogger.debug('🧪 [AI Optimize] request=$payload');
  await AppObservability.instance.recordEvent(
    'ai_optimize_requested',
    category: 'deck_optimize',
    data: {
      'deck_id': deckId,
      'archetype': archetype,
      if (bracket != null) 'bracket': bracket,
      'keep_theme': keepTheme,
      'intensity': intensity.apiValue,
      if (recommendationContext != null && recommendationContext.isNotEmpty)
        'recommendation_context': recommendationContext,
    },
  );

  final response = await apiClient.post('/ai/optimize', payload);

  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    AppLogger.debug('🧪 [AI Optimize] response=$data');
    if (data['mode'] == 'rebuild_guided' ||
        data['outcome_code'] == 'rebuild_guided') {
      throw buildDeckAiFlowException(
        data,
        fallbackMessage:
            'Este deck precisa de reconstrução guiada antes de upgrades pontuais.',
        fallbackCode: 'OPTIMIZE_REBUILD_GUIDED',
      );
    }
    return OptimizeDeckRequestResult.completed(data);
  }

  if (response.statusCode == 202) {
    final data = asDynamicMap(response.data);
    final jobId = data['job_id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw Exception(
        'Não foi possível iniciar a otimização agora. Tente novamente em instantes.',
      );
    }
    final pollInterval = normalizeOptimizePollIntervalMs(
      data['poll_interval_ms'],
    );
    final pollTimeout = normalizeOptimizePollTimeoutMs(data['job_timeout_ms']);
    final totalStages = data['total_stages'] as int? ?? 6;
    final idempotency = asDynamicMap(data['idempotency']);
    AppLogger.debug('🧪 [AI Optimize] async job criado: $jobId');
    return OptimizeDeckRequestResult.async(
      jobId: jobId,
      pollIntervalMs: pollInterval,
      pollTimeoutMs: pollTimeout,
      totalStages: totalStages,
      requestKey:
          idempotency['request_key']?.toString() ?? requestKey?.trim(),
    );
  }

  if (response.statusCode == 422) {
    final data = asDynamicMap(response.data);
    final qualityError = asDynamicMap(data['quality_error']);
    final errorMsg =
        data['error'] as String? ??
        qualityError['message'] as String? ??
        'A otimização não atingiu a qualidade mínima.';
    final code = qualityError['code'] as String? ?? 'QUALITY_ERROR';
    AppLogger.warning('⚠️ [AI Optimize] quality gate: $code — $errorMsg');
    throw buildDeckAiFlowException(
      data,
      fallbackMessage: errorMsg,
      fallbackCode: code,
    );
  }

  throw Exception(
    FriendlyErrorMapper.fromApiResponse(
      response,
      context: FriendlyErrorContext.deckOptimize,
    ),
  );
}

Map<String, dynamic> buildRebuildDeckRequestPayload({
  required String deckId,
  String? archetype,
  String? theme,
  int? bracket,
  required String rebuildScope,
  required String saveMode,
  required List<String> mustKeep,
  required List<String> mustAvoid,
}) {
  return <String, dynamic>{
    'deck_id': deckId,
    if (archetype != null && archetype.trim().isNotEmpty)
      'archetype': archetype,
    if (theme != null && theme.trim().isNotEmpty) 'theme': theme,
    if (bracket != null) 'bracket': bracket,
    'rebuild_scope': rebuildScope,
    'save_mode': saveMode,
    if (mustKeep.isNotEmpty) 'must_keep': mustKeep,
    if (mustAvoid.isNotEmpty) 'must_avoid': mustAvoid,
  };
}

Future<RebuildDeckRequestResult> requestRebuildDeck(
  ApiClient apiClient, {
  required String deckId,
  String? archetype,
  String? theme,
  int? bracket,
  required String rebuildScope,
  required String saveMode,
  required List<String> mustKeep,
  required List<String> mustAvoid,
}) async {
  final payload = buildRebuildDeckRequestPayload(
    deckId: deckId,
    archetype: archetype,
    theme: theme,
    bracket: bracket,
    rebuildScope: rebuildScope,
    saveMode: saveMode,
    mustKeep: mustKeep,
    mustAvoid: mustAvoid,
  );

  final response = await apiClient.post(
    '/ai/rebuild',
    payload,
    timeout: const Duration(minutes: 4),
  );

  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    final draftDeckId = data['draft_deck_id']?.toString();
    return RebuildDeckRequestResult(payload: data, draftDeckId: draftDeckId);
  }

  if (response.statusCode == 422) {
    final data = asDynamicMap(response.data);
    throw buildDeckAiFlowException(
      data,
      fallbackMessage:
          data['error']?.toString() ?? 'A reconstrução guiada falhou.',
      fallbackCode: 'REBUILD_FAILED',
    );
  }

  throw Exception(
    FriendlyErrorMapper.fromApiResponse(
      response,
      context: FriendlyErrorContext.deckOptimize,
      fallback:
          'Não foi possível reconstruir este deck agora. Tente novamente em instantes.',
    ),
  );
}

Future<OptimizeJobPollResult> pollOptimizeJobRequest(
  ApiClient apiClient,
  String jobId,
) async {
  final response = await apiClient.get('/ai/optimize/jobs/$jobId');

  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    final status = data['status'] as String?;
    if (status == 'completed') {
      final resultMap = asDynamicMap(data['result']);
      if (resultMap['mode'] == 'rebuild_guided' ||
          resultMap['outcome_code'] == 'rebuild_guided') {
        throw buildDeckAiFlowException(
          resultMap,
          fallbackMessage:
              'Este deck precisa de reconstrução guiada antes de upgrades pontuais.',
          fallbackCode: 'OPTIMIZE_REBUILD_GUIDED',
        );
      }
      return OptimizeJobPollResult.completed(resultMap);
    }
    if (status == 'failed') {
      final qualityError = asDynamicMap(data['quality_error']);
      final errorCode =
          qualityError['code']?.toString() ?? 'OPTIMIZE_JOB_FAILED';
      final hasQualityMessage =
          qualityError['message'] != null &&
          qualityError['message'].toString().trim().isNotEmpty;
      final rawErrorMsg =
          hasQualityMessage
              ? qualityError['message'].toString()
              : data['error']?.toString() ?? 'Otimização falhou no servidor.';
      final errorMsg = _friendlyOptimizeJobFailureMessage(
        rawErrorMsg,
        code: errorCode,
        hasQualityMessage: hasQualityMessage,
      );
      AppLogger.warning('⚠️ [AI Optimize] job $jobId failed: $rawErrorMsg');
      throw buildDeckAiFlowException(
        {...data, 'error': errorMsg},
        fallbackMessage: errorMsg,
        fallbackCode: errorCode,
      );
    }
    if (status == 'cancelled') {
      throw const OptimizeJobCancelledException();
    }
    return OptimizeJobPollResult.pending(
      stage: data['stage'] as String? ?? 'Processando...',
      stageNumber: data['stage_number'] as int? ?? 0,
      totalStages: data['total_stages'] as int? ?? 6,
    );
  }

  if (response.statusCode == 404) {
    throw Exception(
      'A otimização demorou mais que o esperado. Inicie uma nova tentativa.',
    );
  }

  throw Exception(
    FriendlyErrorMapper.fromApiResponse(
      response,
      context: FriendlyErrorContext.deckOptimize,
    ),
  );
}

Future<Map<String, dynamic>> cancelOptimizeJobRequest(
  ApiClient apiClient,
  String jobId,
) async {
  final response = await apiClient.delete('/ai/optimize/jobs/$jobId');
  if (response.statusCode == 200) return asDynamicMap(response.data);
  throw Exception(
    FriendlyErrorMapper.fromApiResponse(
      response,
      context: FriendlyErrorContext.deckOptimize,
    ),
  );
}

Future<Map<String, dynamic>?> fetchLatestOptimizeJobRequest(
  ApiClient apiClient, {
  required String deckId,
  bool activeOnly = true,
}) async {
  final query = Uri(queryParameters: {
    'deck_id': deckId,
    'active': activeOnly ? 'true' : 'false',
  }).query;
  final response = await apiClient.get('/ai/optimize/jobs/latest?$query');
  if (response.statusCode == 404) return null;
  if (response.statusCode == 200) return asDynamicMap(response.data);
  throw Exception(
    FriendlyErrorMapper.fromApiResponse(
      response,
      context: FriendlyErrorContext.deckOptimize,
    ),
  );
}

String _friendlyOptimizeJobFailureMessage(
  String rawMessage, {
  required String code,
  required bool hasQualityMessage,
}) {
  if (code == 'OPTIMIZE_JOB_FAILED' && !hasQualityMessage) {
    return _genericOptimizeJobFailureMessage;
  }

  return FriendlyErrorMapper.fromException(
    Exception(rawMessage),
    context: FriendlyErrorContext.deckOptimize,
    fallback: _genericOptimizeJobFailureMessage,
  );
}
