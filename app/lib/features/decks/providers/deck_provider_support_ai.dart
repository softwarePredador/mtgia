import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import 'deck_provider_support_common.dart';

Map<String, dynamic> buildOptimizeRequestPayload({
  required String deckId,
  required String archetype,
  int? bracket,
  required bool keepTheme,
}) {
  return <String, dynamic>{
    'deck_id': deckId,
    'archetype': archetype,
    if (bracket != null) 'bracket': bracket,
    'keep_theme': keepTheme,
  };
}

Future<OptimizeDeckRequestResult> requestOptimizeDeck(
  ApiClient apiClient, {
  required String deckId,
  required String archetype,
  int? bracket,
  required bool keepTheme,
}) async {
  final payload = buildOptimizeRequestPayload(
    deckId: deckId,
    archetype: archetype,
    bracket: bracket,
    keepTheme: keepTheme,
  );

  await saveOptimizeDebugSnapshot(request: payload);
  AppLogger.debug('🧪 [AI Optimize] request=$payload');

  final response = await apiClient.post('/ai/optimize', payload);

  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    await saveOptimizeDebugSnapshot(response: data);
    AppLogger.debug('🧪 [AI Optimize] response=$data');
    return OptimizeDeckRequestResult.completed(data);
  }

  if (response.statusCode == 202) {
    final data = asDynamicMap(response.data);
    final jobId = data['job_id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw Exception('Job assíncrono inválido retornado pelo servidor.');
    }
    final pollInterval = data['poll_interval_ms'] as int? ?? 2000;
    final totalStages = data['total_stages'] as int? ?? 6;
    AppLogger.debug('🧪 [AI Optimize] async job criado: $jobId');
    return OptimizeDeckRequestResult.async(
      jobId: jobId,
      pollIntervalMs: pollInterval,
      totalStages: totalStages,
    );
  }

  if (response.statusCode == 422) {
    final data = asDynamicMap(response.data);
    await saveOptimizeDebugSnapshot(
      response: {'statusCode': 422, 'data': data},
    );
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

  await saveOptimizeDebugSnapshot(
    response: {'statusCode': response.statusCode, 'data': response.data},
  );
  throw Exception('Falha ao otimizar deck: ${response.statusCode}');
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

  throw Exception('Falha ao reconstruir deck: ${response.statusCode}');
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
      await saveOptimizeDebugSnapshot(response: resultMap);
      return OptimizeJobPollResult.completed(resultMap);
    }
    if (status == 'failed') {
      final qualityError = asDynamicMap(data['quality_error']);
      final errorMsg =
          data['error'] as String? ??
          qualityError['message'] as String? ??
          'Otimização falhou no servidor.';
      AppLogger.warning('⚠️ [AI Optimize] job $jobId failed: $errorMsg');
      throw buildDeckAiFlowException(
        data,
        fallbackMessage: errorMsg,
        fallbackCode: qualityError['code']?.toString() ?? 'OPTIMIZE_JOB_FAILED',
      );
    }
    return OptimizeJobPollResult.pending(
      stage: data['stage'] as String? ?? 'Processando...',
      stageNumber: data['stage_number'] as int? ?? 0,
      totalStages: data['total_stages'] as int? ?? 6,
    );
  }

  if (response.statusCode == 404) {
    throw Exception('Job de otimização expirou ou não foi encontrado.');
  }

  throw Exception(
    'Falha ao consultar job de otimização: ${response.statusCode}',
  );
}
