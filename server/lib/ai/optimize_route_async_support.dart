import 'dart:async';

import 'package:postgres/postgres.dart';

import '../ai_plan_reservation_handle.dart';
import '../ai_plan_reservation_settlement.dart';
import '../logger.dart';
import 'optimize_job.dart';
import 'optimize_route_internal.dart';
import 'optimize_route_request_support.dart';
import 'optimize_runtime_support.dart';
import 'optimize_stage_telemetry.dart';
import 'optimize_state_support.dart' as optimize_state;
import 'otimizacao.dart';

Future<String> createOptimizeAsyncJob({
  required OptimizeStageTelemetry telemetry,
  required Pool pool,
  required String deckId,
  required String archetype,
  required String userId,
}) {
  return telemetry.trackAsync(
    'request.async_job_create',
    () => OptimizeJobStore.create(
      pool: pool,
      deckId: deckId,
      archetype: archetype,
      userId: userId,
    ),
  );
}

Map<String, dynamic> buildOptimizeModeAsyncAcceptedBody({
  required String deckId,
  required String requestMode,
  required String jobId,
  required int elapsedMs,
  required Map<String, dynamic> telemetrySnapshot,
  required OptimizeIntensityConfig intensity,
}) {
  final timings = {
    'deck_id': deckId,
    'request_mode': requestMode,
    'job_id': jobId,
    'total_ms': elapsedMs,
    'accepted_ms': elapsedMs,
    'stages_ms': telemetrySnapshot['stages_ms'],
  };
  return {
    'job_id': jobId,
    'status': 'pending',
    'mode': 'optimize',
    'message':
        'Optimize agressivo iniciado em background. Acompanhe o progresso via polling.',
    'poll_url': '/ai/optimize/jobs/$jobId',
    'poll_interval_ms': 1000,
    'job_timeout_ms': OptimizeJobStore.executionTimeout.inMilliseconds,
    'total_stages': 6,
    'intensity': intensity.selected,
    'optimize_intensity': intensity.toJson(returnedSwaps: 0),
    'async': {'accepted_ms': elapsedMs, 'executor': 'optimize_async_job'},
    'timings': timings,
    'stage_telemetry': timings,
  };
}

void startOptimizeModeAsyncJob({
  required Pool pool,
  required String jobId,
  required Uri internalOptimizeUrl,
  required Map<String, dynamic> syncPayload,
  required String? authorization,
  AiPlanReservationHandle? planReservation,
}) {
  unawaited(
    runZonedGuarded(
      () async {
        await processOptimizeModeAsync(
          pool: pool,
          jobId: jobId,
          internalOptimizeUrl: internalOptimizeUrl,
          syncPayload: syncPayload,
          authorization: authorization,
        );
        await _settleOptimizeJobQuota(
          pool: pool,
          jobId: jobId,
          planReservation: planReservation,
        );
      },
      (error, _) {
        Log.e(
          'Background optimize job $jobId crashed '
          'type=${error.runtimeType}',
        );
        unawaited(
          _failOptimizeJobAndReleaseQuota(
            pool: pool,
            jobId: jobId,
            error: 'Falha interna ao processar optimize async.',
            planReservation: planReservation,
          ),
        );
      },
    ),
  );
}

Map<String, dynamic> buildCompleteModeAsyncAcceptedBody({
  required String jobId,
  required Map<String, dynamic> telemetrySnapshot,
  required OptimizeIntensityConfig intensity,
}) {
  return {
    'job_id': jobId,
    'status': 'pending',
    'message':
        'Otimização iniciada em background. Consulte o progresso via polling.',
    'poll_url': '/ai/optimize/jobs/$jobId',
    'poll_interval_ms': 2000,
    'job_timeout_ms': OptimizeJobStore.executionTimeout.inMilliseconds,
    'total_stages': 6,
    'intensity': intensity.selected,
    'optimize_intensity': intensity.toJson(returnedSwaps: 0),
    'timings': telemetrySnapshot,
    'stage_telemetry': telemetrySnapshot,
  };
}

void startCompleteModeAsyncJob({
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
  AiPlanReservationHandle? planReservation,
}) {
  unawaited(
    runZonedGuarded(
      () async {
        await processCompleteModeAsync(
          jobId: jobId,
          pool: pool,
          deckId: deckId,
          deckFormat: deckFormat,
          maxTotal: maxTotal,
          currentTotalCards: currentTotalCards,
          commanders: commanders,
          allCardData: allCardData,
          deckColors: deckColors,
          commanderColorIdentity: commanderColorIdentity,
          originalCountsById: originalCountsById,
          optimizer: optimizer,
          themeProfile: themeProfile,
          targetArchetype: targetArchetype,
          bracket: bracket,
          keepTheme: keepTheme,
          deckAnalysis: deckAnalysis,
          userId: userId,
          deckSignature: deckSignature,
          cacheKey: cacheKey,
          intensity: intensity,
          userPreferences: userPreferences,
          hasBracketOverride: hasBracketOverride,
          hasKeepThemeOverride: hasKeepThemeOverride,
          recommendationContext: recommendationContext,
        );
        await _settleOptimizeJobQuota(
          pool: pool,
          jobId: jobId,
          planReservation: planReservation,
        );
      },
      (error, _) {
        Log.e(
          'Background optimize job $jobId crashed '
          'type=${error.runtimeType}',
        );
        unawaited(
          _failOptimizeJobAndReleaseQuota(
            pool: pool,
            jobId: jobId,
            error: 'Falha interna ao processar a otimização.',
            planReservation: planReservation,
          ),
        );
      },
    ),
  );
}

Future<void> _settleOptimizeJobQuota({
  required Pool pool,
  required String jobId,
  required AiPlanReservationHandle? planReservation,
}) async {
  if (planReservation == null) return;
  try {
    final job = await OptimizeJobStore.get(pool, jobId);
    await settleDeferredAiPlanReservation(
      pool: pool,
      handle: planReservation,
      successful: job?.status == 'completed',
    );
  } catch (error) {
    Log.w('Optimize async quota settlement failed type=${error.runtimeType}');
  }
}

Future<void> _failOptimizeJobAndReleaseQuota({
  required Pool pool,
  required String jobId,
  required String error,
  required AiPlanReservationHandle? planReservation,
}) async {
  try {
    await OptimizeJobStore.fail(pool, jobId, error: error);
  } catch (failure) {
    Log.w(
      'Optimize async failure persistence failed type=${failure.runtimeType}',
    );
  }
  if (planReservation == null) return;
  try {
    await settleDeferredAiPlanReservation(
      pool: pool,
      handle: planReservation,
      successful: false,
    );
  } catch (failure) {
    Log.w('Optimize async quota release failed type=${failure.runtimeType}');
  }
}
