import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/card_validation_service.dart';
import '../../../lib/internal_ai_request_token.dart';
import '../../../lib/runtime_environment.dart';
import '../../../lib/ai_plan_reservation_handle.dart';
import '../../../lib/ai/optimize_analysis_support.dart' as optimize_analysis;
import '../../../lib/ai/optimize_deck_support.dart' as optimize_deck;
import '../../../lib/ai/optimize_request_support.dart' as optimize_request;
import '../../../lib/ai/optimize_state_support.dart' as optimize_state;
import '../../../lib/ai/optimize_stage_telemetry.dart';
import '../../../lib/ai/otimizacao.dart';
import '../../../lib/ai/optimization_functional_roles.dart';
import '../../../lib/ai/optimization_quality_gate.dart';
import '../../../lib/ai/optimize_complete_support.dart' as optimize_complete;
import '../../../lib/ai/optimize_runtime_support.dart';
import '../../../lib/ai/optimize_runtime_support.dart' as optimize_support;
import '../../../lib/ai/optimize_route_async_support.dart'
    as optimize_route_async;
import '../../../lib/ai/optimize_route_addition_data_support.dart'
    as optimize_route_addition_data;
import '../../../lib/ai/optimize_route_bracket_policy_filter_support.dart'
    as optimize_route_bracket_policy_filter;
import '../../../lib/ai/optimize_route_color_identity_filter_support.dart'
    as optimize_route_color_identity_filter;
import '../../../lib/ai/optimize_route_complete_top_up_support.dart'
    as optimize_route_complete_top_up;
import '../../../lib/ai/optimize_route_land_removal_protection_support.dart'
    as optimize_route_land_removal_protection;
import '../../../lib/ai/optimize_route_payload_support.dart'
    as optimize_route_payload;
import '../../../lib/ai/optimize_route_recommendation_context_support.dart'
    as optimize_route_recommendation_context;
import '../../../lib/ai/optimize_route_rebalance_support.dart'
    as optimize_route_rebalance;
import '../../../lib/ai/optimize_route_diagnostics_support.dart'
    as optimize_route_diagnostics;
import '../../../lib/ai/optimize_route_empty_fallback_support.dart'
    as optimize_route_empty_fallback;
import '../../../lib/ai/optimize_feedback_support.dart' as optimize_feedback;
import '../../../lib/ai/optimize_route_final_gate_support.dart'
    as optimize_route_final_gate;
import '../../../lib/ai/optimize_route_quality_rejection_support.dart'
    as optimize_route_quality_rejection;
import '../../../lib/ai/optimize_route_post_validation_support.dart'
    as optimize_route_post_validation;
import '../../../lib/ai/optimize_route_outcome_support.dart'
    as optimize_route_outcome;
import '../../../lib/ai/optimize_route_request_support.dart'
    as optimize_route_request;
import '../../../lib/ai/optimize_route_retry_support.dart'
    as optimize_route_retry;
import '../../../lib/ai/optimize_route_response_support.dart'
    as optimize_route_response;
import '../../../lib/ai/optimize_route_suggestion_filter_support.dart'
    as optimize_route_suggestion_filter;
import '../../../lib/ai/optimize_route_virtual_analysis_support.dart'
    as optimize_route_virtual_analysis;
import '../../../lib/ai/optimize_route_validator_support.dart'
    as optimize_route_validator;
import '../../../lib/ai/optimize_route_warnings_support.dart'
    as optimize_route_warnings;
import '../../../lib/ai/optimize_swap_integrity.dart';
import '../../../lib/ai/optimization_validator.dart';
import '../../../lib/ai/edhrec_service.dart';
import '../../../lib/ai/theme_contextual_rules_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/json_object_support.dart';
import '../../../lib/logger.dart';
import '../../../lib/meta/meta_deck_reference_support.dart';
import '../../../lib/observability.dart';
import '../../../lib/openai_runtime_config.dart';
import '../../../lib/ai/optimize_route_internal.dart';
import '../../../lib/ai/optimize_response_support.dart';
export '../../../lib/ai/optimize_response_support.dart';

int _optimizeRequestCount = 0;
int _emptySuggestionFallbackTriggeredCount = 0;
int _emptySuggestionFallbackAppliedCount = 0;
int _emptySuggestionFallbackNoCandidateCount = 0;
int _emptySuggestionFallbackNoReplacementCount = 0;

Map<String, dynamic> parseOptimizeSuggestions(Map<String, dynamic> payload) =>
    optimize_support.parseOptimizeSuggestions(payload);

Map<String, dynamic> buildDeterministicOptimizeResponse({
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String targetArchetype,
  OptimizeIntensityConfig? intensity,
}) => optimize_support.buildDeterministicOptimizeResponse(
  deterministicSwapCandidates: deterministicSwapCandidates,
  targetArchetype: targetArchetype,
  intensity: intensity,
);

OptimizeIntensityConfig resolveOptimizeIntensity(dynamic raw) =>
    optimize_support.resolveOptimizeIntensity(raw);

String resolveOptimizeArchetype({
  required String requestedArchetype,
  required String? detectedArchetype,
}) => optimize_support.resolveOptimizeArchetype(
  requestedArchetype: requestedArchetype,
  detectedArchetype: detectedArchetype,
);

bool shouldRetryOptimizeWithAiFallback({
  required bool deterministicFirstEnabled,
  required bool fallbackAlreadyAttempted,
  required String? strategySource,
  required String? qualityErrorCode,
  required bool isComplete,
}) => optimize_support.shouldRetryOptimizeWithAiFallback(
  deterministicFirstEnabled: deterministicFirstEnabled,
  fallbackAlreadyAttempted: fallbackAlreadyAttempted,
  strategySource: strategySource,
  qualityErrorCode: qualityErrorCode,
  isComplete: isComplete,
);

bool matchesFunctionalNeed(
  String need, {
  required String oracleText,
  required String typeLine,
}) => optimize_support.matchesFunctionalNeed(
  need,
  oracleText: oracleText,
  typeLine: typeLine,
);

int scoreOptimizeReplacementCandidate({
  required String functionalNeed,
  required String cardName,
  required String typeLine,
  required String oracleText,
  required String manaCost,
  required int popScore,
  required Set<String> preferredNames,
  required Map<String, int> rejectedAdditionCounts,
  bool preferLowCurve = false,
}) => optimize_support.scoreOptimizeReplacementCandidate(
  functionalNeed: functionalNeed,
  cardName: cardName,
  typeLine: typeLine,
  oracleText: oracleText,
  manaCost: manaCost,
  popScore: popScore,
  preferredNames: preferredNames,
  rejectedAdditionCounts: rejectedAdditionCounts,
  preferLowCurve: preferLowCurve,
);

bool isOptimizeStructuralRecoveryScenario({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderColorIdentity,
}) => optimize_support.isOptimizeStructuralRecoveryScenario(
  allCardData: allCardData,
  commanderColorIdentity: commanderColorIdentity,
);

int computeOptimizeStructuralRecoverySwapTarget({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
}) => optimize_support.computeOptimizeStructuralRecoverySwapTarget(
  allCardData: allCardData,
  commanderColorIdentity: commanderColorIdentity,
  targetArchetype: targetArchetype,
);

List<String> buildStructuralRecoveryFunctionalNeeds({
  required List<Map<String, dynamic>> allCardData,
  required String targetArchetype,
  required int limit,
}) => optimize_support.buildStructuralRecoveryFunctionalNeeds(
  allCardData: allCardData,
  targetArchetype: targetArchetype,
  limit: limit,
);

List<Map<String, dynamic>> buildDeterministicOptimizeRemovalCandidates({
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required bool keepTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
  int swapLimit = 6,
}) => optimize_support.buildDeterministicOptimizeRemovalCandidates(
  allCardData: allCardData,
  commanders: commanders,
  commanderColorIdentity: commanderColorIdentity,
  targetArchetype: targetArchetype,
  keepTheme: keepTheme,
  coreCards: coreCards,
  commanderPriorityNames: commanderPriorityNames,
  swapLimit: swapLimit,
);

Future<List<Map<String, dynamic>>> buildDeterministicOptimizeSwapCandidates({
  required Pool pool,
  required List<Map<String, dynamic>> allCardData,
  required List<String> commanders,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required String? detectedTheme,
  required List<String>? coreCards,
  required List<String> commanderPriorityNames,
  int swapLimit = 6,
  String intensity = 'focused',
  Map<String, dynamic>? diagnosticsOut,
  String? userId,
  bool preferCollection = false,
  int? budgetLimitBrl,
}) => optimize_support.buildDeterministicOptimizeSwapCandidates(
  pool: pool,
  allCardData: allCardData,
  commanders: commanders,
  commanderColorIdentity: commanderColorIdentity,
  targetArchetype: targetArchetype,
  bracket: bracket,
  keepTheme: keepTheme,
  detectedTheme: detectedTheme,
  coreCards: coreCards,
  commanderPriorityNames: commanderPriorityNames,
  swapLimit: swapLimit,
  intensity: intensity,
  diagnosticsOut: diagnosticsOut,
  userId: userId,
  preferCollection: preferCollection,
  budgetLimitBrl: budgetLimitBrl,
);

Map<String, dynamic> buildOptimizationAnalysisLogEntry({
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
  String? validationRunToken,
}) => optimize_analysis.buildOptimizationAnalysisLogEntry(
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
  validationRunToken: validationRunToken,
);

List<Map<String, dynamic>> buildOptimizeAdditionEntries({
  required List<String> requestedAdditions,
  required List<Map<String, dynamic>> additionsData,
}) => optimize_deck.buildOptimizeAdditionEntries(
  requestedAdditions: requestedAdditions,
  additionsData: additionsData,
);

List<Map<String, dynamic>> buildVirtualDeckForAnalysis({
  required List<Map<String, dynamic>> originalDeck,
  List<String> removals = const [],
  List<Map<String, dynamic>> additions = const [],
}) => optimize_deck.buildVirtualDeckForAnalysis(
  originalDeck: originalDeck,
  removals: removals,
  additions: additions,
);

Map<String, dynamic> _buildEmptyFallbackAggregate() {
  final triggered = _emptySuggestionFallbackTriggeredCount;
  final applied = _emptySuggestionFallbackAppliedCount;
  final triggerRate =
      _optimizeRequestCount > 0 ? (triggered / _optimizeRequestCount) : 0.0;
  final applyRate = triggered > 0 ? (applied / triggered) : 0.0;

  return {
    'request_count': _optimizeRequestCount,
    'triggered_count': triggered,
    'applied_count': applied,
    'no_candidate_count': _emptySuggestionFallbackNoCandidateCount,
    'no_replacement_count': _emptySuggestionFallbackNoReplacementCount,
    'trigger_rate': triggerRate,
    'apply_rate': applyRate,
  };
}

class DeckArchetypeAnalyzer extends optimize_state.DeckArchetypeAnalyzerCore {
  DeckArchetypeAnalyzer(super.cards, super.colors);
}

class DeckThemeProfile extends optimize_state.DeckThemeProfileResult {
  const DeckThemeProfile({
    required super.theme,
    required super.confidence,
    required super.matchScore,
    required super.coreCards,
  });
}

class DeckOptimizationState extends optimize_state.DeckOptimizationStateResult {
  const DeckOptimizationState({
    required super.status,
    required super.recommendedMode,
    required super.suggestedScope,
    required super.reasons,
    required super.severityScore,
    super.repairPlan = const <String, dynamic>{},
  });
}

DeckOptimizationState assessDeckOptimizationState({
  required List<Map<String, dynamic>> cards,
  required Map<String, dynamic> deckAnalysis,
  required String deckFormat,
  required int currentTotalCards,
  required Set<String> commanderColorIdentity,
}) {
  final result = optimize_state.assessDeckOptimizationStateCore(
    cards: cards,
    deckAnalysis: deckAnalysis,
    deckFormat: deckFormat,
    currentTotalCards: currentTotalCards,
    commanderColorIdentity: commanderColorIdentity,
  );

  return DeckOptimizationState(
    status: result.status,
    recommendedMode: result.recommendedMode,
    suggestedScope: result.suggestedScope,
    reasons: result.reasons,
    severityScore: result.severityScore,
    repairPlan: result.repairPlan,
  );
}

String deriveOptimizeOutcomeCode({
  required int statusCode,
  required Map<String, dynamic> body,
  required DeckOptimizationState deckState,
  ValidationReport? validationReport,
}) => optimize_route_outcome.deriveOptimizeOutcomeCode(
  statusCode: statusCode,
  body: body,
  deckState: deckState,
  validationReport: validationReport,
);

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    String? userId;
    try {
      userId = context.read<String>();
    } catch (_) {
      userId = null;
    }

    Map<String, dynamic> body;
    try {
      body = requireJsonObject(await context.request.json());
    } on JsonObjectValidationException catch (error) {
      return badRequest(error.message);
    } catch (_) {
      return badRequest('JSON invalido');
    }
    final routeRequest = optimize_route_request.parseOptimizeRouteRequest(
      body,
      allowForceSync: InternalAiRequestToken.matches(context.request.headers),
    );
    if (routeRequest.validationError != null) {
      return badRequest(routeRequest.validationError!);
    }
    final deckId = routeRequest.deckId;
    final archetype = routeRequest.archetype;
    final parsedBracket = routeRequest.parsedBracket;
    final parsedKeepTheme = routeRequest.parsedKeepTheme;
    final requestMode = routeRequest.requestMode;
    final intensity = routeRequest.intensity;
    final recommendationContext = routeRequest.recommendationContext;
    if (!intensity.valid) {
      return badRequest(
        'intensity must be light, focused, aggressive or rebuild.',
      );
    }
    final requestStopwatch = Stopwatch()..start();
    final forceSyncExecutor = routeRequest.forceSyncExecutor;
    final asyncRequested = routeRequest.asyncRequested;
    final telemetry = OptimizeStageTelemetry(
      deckId: routeRequest.telemetryDeckId,
      requestMode: requestMode,
    );
    final hasBracketOverride = routeRequest.hasBracketOverride;
    final hasKeepThemeOverride = routeRequest.hasKeepThemeOverride;
    final env = loadRuntimeEnvironment();
    final semanticV2OptimizeEnforcementMode =
        resolveSemanticV2OptimizeEnforcementMode(
          env['SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT'],
        );
    final semanticV2ExpandedCriticalRoles =
        resolveSemanticV2ExpandedCriticalRoles(
          env['SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES'],
        );
    final aiConfig = OpenAiRuntimeConfig(env);
    final apiKey = env['OPENAI_API_KEY'];
    final aiProviderMissingInProduction =
        (apiKey == null || apiKey.isEmpty) && !aiConfig.allowsMockFallbacks;

    _optimizeRequestCount++;

    if (deckId == null || archetype == null) {
      return badRequest('deck_id and archetype are required');
    }

    if (userId == null || userId.isEmpty) {
      return unauthorized('Authentication required');
    }
    final authenticatedUserId = userId;

    if (aiProviderMissingInProduction && !intensity.isRebuild) {
      return apiError(
        HttpStatus.serviceUnavailable,
        'AI provider is not configured',
      );
    }

    // 1. Fetch Deck Data
    final pool = context.read<Pool>();

    if (shouldUseAsyncOptimizeExecutor(
      intensity: intensity,
      requestMode: requestMode,
      forceSync: forceSyncExecutor,
      asyncRequested: asyncRequested,
    )) {
      try {
        await telemetry.trackAsync(
          'request.deck_access',
          () => optimize_request.verifyOptimizeDeckAccess(
            pool: pool,
            deckId: deckId,
            userId: authenticatedUserId,
          ),
        );
      } on optimize_request.OptimizeDeckContextException catch (e) {
        if (e.code == 'DECK_NOT_FOUND') {
          return notFound('Deck not found');
        }
        rethrow;
      }

      final jobId = await optimize_route_async.createOptimizeAsyncJob(
        telemetry: telemetry,
        pool: pool,
        deckId: deckId,
        archetype: archetype,
        userId: authenticatedUserId,
      );
      final planReservation = deferAiPlanReservationIfAvailable(context);
      final syncPayload =
          Map<String, dynamic>.from(body)
            ..['_force_sync'] = true
            ..['async'] = false;
      final authorization = context.request.headers['Authorization'];
      final internalOptimizeUrl = resolveInternalOptimizeUrl(context.request);

      optimize_route_async.startOptimizeModeAsyncJob(
        pool: pool,
        jobId: jobId,
        internalOptimizeUrl: internalOptimizeUrl,
        syncPayload: syncPayload,
        authorization: authorization,
        planReservation: planReservation,
      );

      telemetry.logSummary();
      final responseBody = optimize_route_async
          .buildOptimizeModeAsyncAcceptedBody(
            deckId: deckId,
            requestMode: requestMode,
            jobId: jobId,
            elapsedMs: requestStopwatch.elapsedMilliseconds,
            telemetrySnapshot: telemetry.snapshot(),
            intensity: intensity,
          );
      optimize_route_request.attachRecommendationContextToOptimizeResponse(
        responseBody,
        recommendationContext,
      );
      return Response.json(statusCode: HttpStatus.accepted, body: responseBody);
    }

    // Memória de preferências do usuário (se autenticado):
    // aplica default somente quando o request não enviar override explícito.
    final userPreferences = await telemetry.trackAsync(
      'request.user_preferences',
      () => loadUserAiPreferences(pool: pool, userId: userId),
    );
    final bracket =
        hasBracketOverride
            ? parsedBracket
            : (userPreferences['preferred_bracket'] as int? ?? parsedBracket);
    final keepTheme =
        hasKeepThemeOverride
            ? (parsedKeepTheme ?? true)
            : (userPreferences['keep_theme_default'] as bool? ?? true);

    late final optimize_request.OptimizeDeckContextData deckContext;
    try {
      deckContext = await telemetry.trackAsync(
        'request.deck_context',
        () => optimize_request.loadOptimizeDeckContext(
          pool: pool,
          deckId: deckId,
          userId: authenticatedUserId,
          targetArchetype: archetype,
          requestMode: requestMode,
          intensity: intensity.selected,
          bracket: bracket,
          keepTheme: keepTheme,
          recommendationContextSignature: recommendationContext.cacheSignature,
          telemetry: telemetry,
        ),
      );
    } on optimize_request.OptimizeDeckContextException catch (e) {
      if (e.code == 'DECK_NOT_FOUND') {
        return notFound('Deck not found');
      }
      if (e.code == 'DECK_FORMAT_MISSING') {
        return internalServerError('Deck format is missing');
      }
      rethrow;
    }

    final deckFormat = deckContext.deckFormat;
    final effectiveMode = deckContext.effectiveMode;
    final deckSignature = deckContext.deckSignature;
    final cacheKey = deckContext.cacheKey;

    final cachedResponse =
        semanticV2OptimizeEnforcementMode ==
                SemanticV2OptimizeEnforcementMode.disabled
            ? await telemetry.trackAsync(
              'request.cache_lookup',
              () => loadOptimizeCache(pool: pool, cacheKey: cacheKey),
            )
            : null;
    if (cachedResponse != null) {
      final responseBody = optimize_route_response.buildCachedOptimizeResponse(
        cachedResponse: cachedResponse,
        cacheKey: cacheKey,
        intensity: intensity,
        effectiveMode: effectiveMode,
        timings: telemetry.snapshot(),
        hasBracketOverride: hasBracketOverride,
        hasKeepThemeOverride: hasKeepThemeOverride,
        keepTheme: keepTheme,
        userPreferences: userPreferences,
      );
      if (responseBody != null) {
        optimize_route_request.attachRecommendationContextToOptimizeResponse(
          responseBody,
          recommendationContext,
        );
        telemetry.logSummary();
        return Response.json(body: responseBody);
      }
    }

    final commanders = deckContext.commanders;
    final allCardData = deckContext.allCardData;
    final deckColors = deckContext.deckColors;
    final commanderColorIdentity = deckContext.commanderColorIdentity;
    final currentTotalCards = deckContext.currentTotalCards;
    final originalCountsById = deckContext.originalCountsById;
    final deckAnalysis = deckContext.deckAnalysis;
    final themeProfile = DeckThemeProfile(
      theme: deckContext.themeProfile.theme,
      confidence: deckContext.themeProfile.confidence,
      matchScore: deckContext.themeProfile.matchScore,
      coreCards: deckContext.themeProfile.coreCards,
    );
    final deckState = DeckOptimizationState(
      status: deckContext.deckState.status,
      recommendedMode: deckContext.deckState.recommendedMode,
      suggestedScope: deckContext.deckState.suggestedScope,
      reasons: deckContext.deckState.reasons,
      severityScore: deckContext.deckState.severityScore,
      repairPlan: deckContext.deckState.repairPlan,
    );

    final targetArchetype = archetype;
    final effectiveOptimizeArchetype = deckContext.effectiveOptimizeArchetype;

    Map<String, dynamic> buildRebuildGuidedOutcome({
      required String explanation,
      required String trigger,
      String qualityCode = 'OPTIMIZE_REBUILD_GUIDED',
    }) {
      return optimize_route_response.buildOptimizeRebuildGuidedOutcome(
        explanation: explanation,
        trigger: trigger,
        qualityCode: qualityCode,
        intensity: intensity,
        deckState: deckState,
        deckId: deckId,
        bracket: bracket,
        archetype: effectiveOptimizeArchetype,
        themeProfile: themeProfile,
        deckAnalysis: deckAnalysis,
      );
    }

    final commanderNameForLogs =
        commanders.isNotEmpty ? commanders.first.trim() : 'unknown';
    var optimizeCommanderPrioritySource = 'none';
    final optimizeCommanderPriorityNames = <String>[];
    Map<String, dynamic>? optimizeCommanderRoleTargets;
    String? optimizeMetaEvidenceContext;
    Map<String, dynamic>? optimizeMetaReferenceContext;
    final deterministicSwapCandidates = <Map<String, dynamic>>[];
    final aggressiveCandidateQualityDiagnostics = <String, dynamic>{};
    final aggressiveRejectionReasonBuckets = <String, int>{};

    void mergeAggressiveRejectionBuckets(Map<String, int> buckets) {
      optimize_route_response.mergeOptimizeReasonBuckets(
        aggressiveRejectionReasonBuckets,
        buckets,
      );
    }

    Map<String, dynamic> buildAggressiveCandidateQualityDiagnostics({
      int? returnedSwaps,
    }) {
      return optimize_route_response.buildAggressiveCandidateQualityDiagnostics(
        diagnostics: aggressiveCandidateQualityDiagnostics,
        rejectionReasonBuckets: aggressiveRejectionReasonBuckets,
        intensity: intensity,
        returnedSwaps: returnedSwaps,
      );
    }

    Future<Response> respondWithOptimizeTelemetry({
      required int statusCode,
      required Map<String, dynamic> body,
      Map<String, dynamic>? postAnalysisOverride,
      ValidationReport? validationReport,
      List<String>? removalsOverride,
      List<String>? additionsOverride,
      List<String> validationWarningsOverride = const [],
      List<String> blockedByColorIdentityOverride = const [],
      List<Map<String, dynamic>> blockedByBracketOverride = const [],
      bool persistOutcome = true,
    }) async {
      final responseBody = Map<String, dynamic>.from(body);
      optimize_route_request.attachRecommendationContextToOptimizeResponse(
        responseBody,
        recommendationContext,
      );
      responseBody['deck_state'] ??= deckState.toJson();
      responseBody['intensity'] ??= intensity.selected;
      responseBody['optimize_intensity'] ??= intensity.toJson(
        candidateSwaps: deterministicSwapCandidates.length,
        returnedSwaps: optimize_route_response.countOptimizeResponseSwaps(
          responseBody: responseBody,
          effectiveMode: effectiveMode,
        ),
      );
      if (intensity.selected == 'aggressive') {
        final existingDiagnostics =
            responseBody['optimize_diagnostics'] is Map
                ? (responseBody['optimize_diagnostics'] as Map)
                    .cast<String, dynamic>()
                : <String, dynamic>{};
        responseBody['optimize_diagnostics'] = {
          ...existingDiagnostics,
          'aggressive_candidate_quality':
              buildAggressiveCandidateQualityDiagnostics(
                returnedSwaps: optimize_route_response
                    .countOptimizeResponseSwaps(
                      responseBody: responseBody,
                      effectiveMode: effectiveMode,
                    ),
              ),
        };
      }
      if (validationReport?.functional.semanticLayerV2.isNotEmpty == true) {
        final existingDiagnostics =
            responseBody['optimize_diagnostics'] is Map
                ? (responseBody['optimize_diagnostics'] as Map)
                    .cast<String, dynamic>()
                : <String, dynamic>{};
        responseBody['optimize_diagnostics'] = {
          ...existingDiagnostics,
          'semantic_layer_v2': withOptimizationSemanticV2EnforcementDiagnostics(
            semanticLayerV2: validationReport!.functional.semanticLayerV2,
            mode: semanticV2OptimizeEnforcementMode,
            expandedCriticalRoles: semanticV2ExpandedCriticalRoles,
          ),
        };
      }
      if (statusCode >= 200 && statusCode < 300) {
        optimize_route_outcome.enforceSuccessfulOptimizeOutcomeSafety(
          responseBody,
        );
      } else {
        responseBody['outcome_code'] ??= deriveOptimizeOutcomeCode(
          statusCode: statusCode,
          body: responseBody,
          deckState: deckState,
          validationReport: validationReport,
        );
      }
      responseBody['timings'] ??= telemetry.snapshot();
      responseBody['stage_telemetry'] ??= responseBody['timings'];
      final resolvedRemovals =
          removalsOverride ??
          ((responseBody['removals'] as List?)?.map((e) => '$e').toList() ??
              const <String>[]);
      final resolvedAdditions =
          additionsOverride ??
          ((responseBody['additions'] as List?)?.map((e) => '$e').toList() ??
              const <String>[]);
      final resolvedQualityError =
          responseBody['quality_error'] is Map
              ? (responseBody['quality_error'] as Map).cast<String, dynamic>()
              : null;
      final resolvedValidationWarnings =
          validationWarningsOverride.isNotEmpty
              ? validationWarningsOverride
              : ((responseBody['validation_warnings'] as List?)
                      ?.map((e) => '$e')
                      .toList() ??
                  const <String>[]);

      // Integridade dos swaps: liga o conjunto remove/add ao estado do deck
      // (deck_signature) via SHA-256, para o caminho de aplicação verificar
      // adulteração ou drift de deck antes de mutar deck_cards.
      if (responseBody['swap_integrity'] == null) {
        final integrity = buildSwapIntegrityForResponse(
          deckId: deckId,
          deckSignature: deckSignature,
          responseBody: responseBody,
        );
        if (integrity != null) responseBody['swap_integrity'] = integrity;
      }

      if (persistOutcome) {
        await recordOptimizeAnalysisOutcome(
          pool: pool,
          deckId: deckId,
          userId: userId,
          commanderName: commanderNameForLogs,
          commanderColors: commanderColorIdentity.toList(),
          operationMode: responseBody['mode']?.toString() ?? effectiveMode,
          requestedMode: requestMode,
          targetArchetype: targetArchetype,
          detectedTheme: themeProfile.theme,
          deckAnalysis: deckAnalysis,
          postAnalysis: postAnalysisOverride,
          removals: resolvedRemovals,
          additions: resolvedAdditions,
          statusCode: statusCode,
          qualityError: resolvedQualityError,
          validationReport: validationReport,
          validationWarnings: resolvedValidationWarnings,
          blockedByColorIdentity: blockedByColorIdentityOverride,
          blockedByBracket: blockedByBracketOverride,
          commanderPriorityNames: optimizeCommanderPriorityNames,
          commanderPrioritySource: optimizeCommanderPrioritySource,
          deterministicSwapCandidates: deterministicSwapCandidates,
          cacheKey: cacheKey,
          executionTimeMs: requestStopwatch.elapsedMilliseconds,
        );
        if (responseBody['learning_eligible'] != false) {
          await optimize_feedback.recordOptimizeMlFeedback(
            connection: pool,
            feedback: optimize_feedback.buildOptimizeMlFeedback(
              deckId: deckId,
              userId: userId,
              archetype: targetArchetype,
              commanderName: commanderNameForLogs,
              operationMode: responseBody['mode']?.toString() ?? effectiveMode,
              outcomeCode:
                  responseBody['outcome_code']?.toString() ?? 'unknown',
              statusCode: statusCode,
              removals: resolvedRemovals,
              additions: resolvedAdditions,
              qualityError: resolvedQualityError,
              validationWarnings: resolvedValidationWarnings,
              blockedByColorIdentity: blockedByColorIdentityOverride,
              blockedByBracket: blockedByBracketOverride,
            ),
          );
        }
      }

      telemetry.logSummary();
      return Response.json(statusCode: statusCode, body: responseBody);
    }

    if (intensity.isRebuild) {
      return respondWithOptimizeTelemetry(
        statusCode: HttpStatus.ok,
        body: buildRebuildGuidedOutcome(
          explanation:
              'Intensidade rebuild selecionada: o backend retornou uma reconstrucao guiada para revisao em draft, sem aplicar mudancas automaticamente.',
          trigger: 'explicit_intensity',
        ),
      );
    }

    if (deckState.status == 'needs_repair') {
      return respondWithOptimizeTelemetry(
        statusCode: HttpStatus.unprocessableEntity,
        body: {
          'error':
              'O deck precisa de rebuild_guided antes de uma micro-otimizacao segura.',
          ...buildRebuildGuidedOutcome(
            explanation:
                'O deck atual esta fora da faixa em que optimize por swaps pontuais funciona bem. Use rebuild_guided para revisar uma reconstrucao segura.',
            trigger: 'deck_state_needs_repair',
            qualityCode: 'OPTIMIZE_NEEDS_REPAIR',
          ),
          'cache': {'hit': false, 'cache_key': cacheKey},
        },
      );
    }

    // 2. Otimização via DeckOptimizerService (IA + RAG)
    final disableCompleteAi = env['OPTIMIZE_COMPLETE_DISABLE_OPENAI'] == '1';

    final deckOptimizer =
        (apiKey != null && apiKey.isNotEmpty)
            ? DeckOptimizerService(apiKey, db: pool)
            : null;

    // Preparar dados para o otimizador
    final deckData = {'cards': allCardData, 'colors': deckColors.toList()};

    if (commanders.isNotEmpty) {
      try {
        final commanderName = commanders.first.trim();
        if (commanderName.isNotEmpty) {
          final commanderMetaScope = resolveCommanderOptimizeMetaScope(
            deckFormat: deckFormat,
            bracket: bracket,
          );
          final commanderReferenceFuture = telemetry.trackAsync(
            'request.commander_reference_cache',
            () => loadCommanderReferenceProfileFromCache(
              pool: pool,
              commanderName: commanderName,
            ),
          );
          final metaSelectionFuture =
              commanderMetaScope == null
                  ? Future.value(
                    emptyCommanderMetaReferenceSelection(
                      commanderScope: commanderMetaScope,
                    ),
                  )
                  : telemetry.trackAsync(
                    'request.commander_priority_query',
                    () => loadCommanderMetaReferenceSelection(
                      pool: pool,
                      commanderNames: commanders,
                      limitDecks: 4,
                      priorityCardLimit: 120,
                      metaScope: commanderMetaScope,
                      preferExternalCompetitive: true,
                    ),
                  );
          final results = await Future.wait<dynamic>([
            commanderReferenceFuture,
            metaSelectionFuture,
          ]);
          final commanderReferenceProfile = results[0] as Map<String, dynamic>?;
          final metaSelection = results[1] as MetaDeckReferenceSelectionResult;
          final rawRoleTargets = commanderReferenceProfile?['role_targets'];
          if (rawRoleTargets is Map) {
            optimizeCommanderRoleTargets =
                rawRoleTargets.cast<String, dynamic>();
          }

          if (metaSelection.priorityCardNames.isNotEmpty) {
            optimizeCommanderPrioritySource =
                metaSelection.optimizePrioritySource;
            optimizeCommanderPriorityNames.addAll(
              metaSelection.priorityCardNames,
            );
          }
          if (metaSelection.hasReferences) {
            optimizeMetaEvidenceContext = buildMetaDeckEvidenceText(
              metaSelection,
              maxPriorityCards: 14,
              maxReferences: 3,
            );
            optimizeMetaReferenceContext = buildMetaDeckEvidencePayload(
              metaSelection,
              maxPriorityCards: 14,
              maxReferences: 3,
            );
          }
          final averageDeckSeedNames = extractAverageDeckSeedNamesFromProfile(
            commanderReferenceProfile,
            limit: 80,
          );
          final profileTopNames = extractTopCardNamesFromProfile(
            commanderReferenceProfile,
            limit: 80,
          );

          if (optimizeCommanderPriorityNames.isEmpty &&
              averageDeckSeedNames.isNotEmpty) {
            optimizeCommanderPrioritySource = 'reference_average_deck_seed';
          } else if (optimizeCommanderPriorityNames.isEmpty &&
              profileTopNames.isNotEmpty) {
            optimizeCommanderPrioritySource = 'reference_top_cards';
          }

          optimizeCommanderPriorityNames
            ..addAll(averageDeckSeedNames)
            ..addAll(profileTopNames);

          if (optimizeCommanderPriorityNames.isEmpty) {
            final liveEdhrec = await telemetry.trackAsync(
              'request.commander_live_edhrec',
              () => EdhrecService().fetchCommanderData(commanderName),
            );
            if (liveEdhrec != null && liveEdhrec.topCards.isNotEmpty) {
              optimizeCommanderPrioritySource = 'live_edhrec';
              optimizeCommanderPriorityNames.addAll(
                liveEdhrec.topCards
                    .map((card) => card.name.trim())
                    .where((name) => name.isNotEmpty)
                    .take(120),
              );
            }
          }

          final dedupedPriorityNames = <String>[];
          final seenPriorityNames = <String>{};
          for (final rawName in optimizeCommanderPriorityNames) {
            final name = rawName.trim();
            if (name.isEmpty) continue;
            final lower = name.toLowerCase();
            if (!seenPriorityNames.add(lower)) continue;
            dedupedPriorityNames.add(name);
          }
          optimizeCommanderPriorityNames
            ..clear()
            ..addAll(dedupedPriorityNames.take(120));

          if (optimizeCommanderPriorityNames.isNotEmpty) {
            Log.d(
              'Optimize commander priority pool carregado: ${optimizeCommanderPriorityNames.length} cartas ($optimizeCommanderPrioritySource)',
            );
          }
        }
      } catch (e) {
        optimizeCommanderPrioritySource = 'load_failed';
        Log.w(
          'Falha ao carregar priority pool do optimize '
          'type=${e.runtimeType}',
        );
      }
    }

    try {
      deterministicSwapCandidates.addAll(
        await telemetry.trackAsync(
          'request.deterministic_shortlist',
          () => buildDeterministicOptimizeSwapCandidates(
            pool: pool,
            allCardData: allCardData,
            commanders: commanders,
            commanderColorIdentity: commanderColorIdentity,
            targetArchetype: effectiveOptimizeArchetype,
            bracket: bracket,
            keepTheme: keepTheme,
            detectedTheme: themeProfile.theme,
            coreCards: themeProfile.coreCards,
            commanderPriorityNames: optimizeCommanderPriorityNames,
            swapLimit: intensity.targetMax,
            intensity: intensity.selected,
            diagnosticsOut: aggressiveCandidateQualityDiagnostics,
            userId: authenticatedUserId,
            preferCollection: recommendationContext.preferCollection == true,
            budgetLimitBrl: recommendationContext.budgetLimitBrl,
          ),
        ),
      );
      if (deterministicSwapCandidates.isNotEmpty) {
        Log.d(
          'Optimize deterministic shortlist carregado: ${deterministicSwapCandidates.length} swap(s)',
        );
      }
    } catch (e) {
      Log.w(
        'Falha ao montar shortlist deterministico do optimize '
        'type=${e.runtimeType}',
      );
    }

    Map<String, dynamic> jsonResponse;

    // ================================================================
    //  ASYNC JOB MODE: modo complete roda em background
    // ================================================================
    final maxTotal =
        deckFormat == 'commander' ? 100 : (deckFormat == 'brawl' ? 60 : null);
    final isCompleteMode = maxTotal != null && currentTotalCards < maxTotal;

    if (isCompleteMode) {
      // Validação rápida antes de criar o job
      if (commanders.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'error':
                'Selecione um comandante antes de completar um deck $deckFormat.',
          },
        );
      }

      final jobId = await optimize_route_async.createOptimizeAsyncJob(
        telemetry: telemetry,
        pool: pool,
        deckId: deckId,
        archetype: targetArchetype,
        userId: authenticatedUserId,
      );
      final planReservation = deferAiPlanReservationIfAvailable(context);

      // Fire-and-forget: processamento pesado roda em background.
      // A closure captura todas as variáveis do setup (pool, allCardData, etc.)
      // O Pool é singleton e sobrevive ao ciclo do request.
      optimize_route_async.startCompleteModeAsyncJob(
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
        optimizer: disableCompleteAi ? null : deckOptimizer,
        themeProfile: themeProfile,
        targetArchetype: targetArchetype,
        bracket: bracket,
        keepTheme: keepTheme,
        deckAnalysis: deckAnalysis,
        userId: authenticatedUserId,
        deckSignature: deckSignature,
        cacheKey: cacheKey,
        intensity: intensity,
        userPreferences: userPreferences,
        hasBracketOverride: hasBracketOverride,
        hasKeepThemeOverride: hasKeepThemeOverride,
        recommendationContext: recommendationContext,
        planReservation: planReservation,
      );

      final responseBody = optimize_route_async
          .buildCompleteModeAsyncAcceptedBody(
            jobId: jobId,
            telemetrySnapshot: telemetry.snapshot(),
            intensity: intensity,
          );
      optimize_route_request.attachRecommendationContextToOptimizeResponse(
        responseBody,
        recommendationContext,
      );
      return Response.json(statusCode: HttpStatus.accepted, body: responseBody);
    }

    // ================================================================
    //  SYNC MODE: optimize simples (troca de cartas) — roda inline
    // ================================================================
    if (deckOptimizer == null) {
      // Mock response for development (optimize-only). It is deliberately
      // non-actionable and excluded from telemetry/ML learning so a local
      // environment connected to shared data cannot promote fabricated swaps.
      return respondWithOptimizeTelemetry(
        statusCode: HttpStatus.ok,
        body: {
          'removals': const <String>[],
          'additions': const <String>[],
          'reasoning':
              'Mock optimization (No API Key): preview nao acionavel; configure o provedor para receber trocas reais.',
          'deck_analysis': deckAnalysis,
          'constraints': {'keep_theme': keepTheme},
          'theme': themeProfile.toJson(),
          'mode': 'optimize',
          'outcome_code': 'mock_non_actionable',
          'can_apply': false,
          'learning_eligible': false,
          'is_mock': true,
        },
        persistOutcome: false,
      );
    }

    final optimizer = deckOptimizer;

    final deterministicFirstEnabled =
        effectiveMode == 'optimize' && deterministicSwapCandidates.isNotEmpty;
    var optimizeFallbackAttempted = false;

    Future<Map<String, dynamic>?> runAiOptimizeAttempt({
      required String trigger,
    }) async {
      try {
        final aiResponse = await telemetry.trackAsync(
          'request.ai_optimize_call',
          () => optimizer.optimizeDeck(
            deckData: deckData,
            commanders: commanders,
            targetArchetype: effectiveOptimizeArchetype,
            priorityPool: optimizeCommanderPriorityNames,
            deterministicSwapCandidates: deterministicSwapCandidates,
            bracket: bracket,
            keepTheme: keepTheme,
            detectedTheme: themeProfile.theme,
            coreCards: themeProfile.coreCards,
            metaEvidenceContext: optimizeMetaEvidenceContext,
            userId: authenticatedUserId,
            deckId: deckId,
            preferCollection: recommendationContext.preferCollection == true,
            budgetLimitBrl: recommendationContext.budgetLimitBrl,
          ),
        );
        return optimize_route_retry.attachAiOptimizeAttemptMetadata(
          aiResponse: aiResponse,
          deterministicFirstEnabled: deterministicFirstEnabled,
          trigger: trigger,
        );
      } catch (e) {
        Log.e('Optimization failed type=${e.runtimeType}');
        return null;
      }
    }

    if (deterministicFirstEnabled) {
      jsonResponse = buildDeterministicOptimizeResponse(
        deterministicSwapCandidates: deterministicSwapCandidates,
        targetArchetype: effectiveOptimizeArchetype,
        intensity: intensity,
      );
      Log.i(
        'Optimize deterministic-first ativado com ${deterministicSwapCandidates.length} swap(s) candidatos.',
      );
    } else {
      final aiResponse = await runAiOptimizeAttempt(trigger: 'primary');
      if (aiResponse == null) {
        final executionFailedButPreserved =
            deckState.status == 'healthy' &&
            deckState.recommendedMode == 'optimize';
        return respondWithOptimizeTelemetry(
          statusCode:
              executionFailedButPreserved
                  ? HttpStatus.unprocessableEntity
                  : HttpStatus.internalServerError,
          body: {
            'error':
                executionFailedButPreserved
                    ? 'Nenhuma otimizacao segura foi produzida; deck original preservado.'
                    : 'Optimization failed',
            'quality_error': {
              'code': 'OPTIMIZE_EXECUTION_FAILED',
              'message':
                  executionFailedButPreserved
                      ? 'A execução da otimização falhou; o deck original foi preservado em estado saudável.'
                      : 'A execucao da otimizacao falhou antes da validacao final.',
              'details':
                  'Falha ao executar optimizeDeck na tentativa primaria.',
            },
            'mode': 'optimize',
          },
        );
      }
      jsonResponse = aiResponse;
    }

    optimizeAttemptLoop:
    while (true) {
      jsonResponse = telemetry.trackSync(
        'request.normalize_payload',
        () => normalizeOptimizePayload(jsonResponse, defaultMode: 'optimize'),
      );

      // Se o modo complete já veio determinístico (com card_id/quantity),
      // devolve diretamente sem passar pelo fluxo antigo de validação por nomes.
      if (jsonResponse['mode'] == 'complete' &&
          jsonResponse['additions_detailed'] is List) {
        final qualityError = jsonResponse['quality_error'];
        if (qualityError is Map) {
          return Response.json(
            statusCode: HttpStatus.unprocessableEntity,
            body: {
              'error':
                  'Complete mode não atingiu qualidade mínima para montagem competitiva.',
              'quality_error': qualityError,
              'mode': 'complete',
              'target_additions': jsonResponse['target_additions'],
            },
          );
        }

        final responseBody = await optimize_complete.buildCompleteFinalResponse(
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
        );
        responseBody['intensity'] = intensity.selected;
        responseBody['optimize_intensity'] = intensity.toJson(
          returnedSwaps:
              (responseBody['additions_detailed'] as List?)?.length ?? 0,
        );
        responseBody['timings'] = telemetry.snapshot();
        responseBody['stage_telemetry'] = responseBody['timings'];
        responseBody['strategy_source'] ??=
            jsonResponse['strategy_source'] ?? 'complete_pipeline';
        optimize_route_outcome.enforceSuccessfulOptimizeOutcomeSafety(
          responseBody,
        );

        return Response.json(body: responseBody);
      }

      // Validar cartas sugeridas pela IA

      // Validar cartas sugeridas pela IA
      final validationService = CardValidationService(pool);

      List<String> removals = [];
      List<String> additions = [];
      var emptySuggestionFallbackTriggered = false;
      var emptySuggestionFallbackApplied = false;
      String? emptySuggestionFallbackReason;
      var emptySuggestionFallbackCandidateCount = 0;
      var emptySuggestionFallbackReplacementCount = 0;
      var emptySuggestionFallbackPairCount = 0;

      final parsedSuggestions = parseOptimizeSuggestions(jsonResponse);
      removals = parsedSuggestions['removals'] as List<String>;
      additions = parsedSuggestions['additions'] as List<String>;
      final recognizedSuggestionFormat =
          parsedSuggestions['recognized_format'] as bool? ?? false;

      final deckNamesLower =
          allCardData
              .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
              .where((n) => n.isNotEmpty)
              .toSet();
      final commanderLower = commanders.map((c) => c.toLowerCase()).toSet();
      final coreLower =
          themeProfile.coreCards.map((c) => c.toLowerCase()).toSet();
      final blockedByTheme = <String>[];
      final recommendationDetailsByName = <String, Map<String, dynamic>>{};
      final recommendationConstraintWarnings = <String>[];
      Map<String, dynamic>? recommendationConstraintDiagnostics;

      final isComplete = jsonResponse['mode'] == 'complete';

      if (removals.isEmpty && additions.isEmpty && !isComplete) {
        emptySuggestionFallbackTriggered = true;
        _emptySuggestionFallbackTriggeredCount++;
        final fallbackRemovalCandidates = optimize_route_empty_fallback
            .selectEmptySuggestionFallbackRemovalCandidates(
              allCardData: allCardData,
              commanderLower: commanderLower,
              coreLower: coreLower,
            );
        emptySuggestionFallbackCandidateCount =
            fallbackRemovalCandidates.length;

        if (fallbackRemovalCandidates.isNotEmpty) {
          final replacements = await findSynergyReplacements(
            pool: pool,
            commanders: commanders,
            commanderColorIdentity: commanderColorIdentity,
            targetArchetype: targetArchetype,
            bracket: bracket,
            keepTheme: keepTheme,
            detectedTheme: themeProfile.theme,
            coreCards: themeProfile.coreCards,
            missingCount: fallbackRemovalCandidates.length,
            removedCards: fallbackRemovalCandidates,
            excludeNames: deckNamesLower,
            allCardData: allCardData,
            preferredNames:
                optimizeCommanderPriorityNames
                    .map((name) => name.toLowerCase())
                    .toSet(),
            userId: authenticatedUserId,
            preferCollection: recommendationContext.preferCollection == true,
            budgetLimitBrl: recommendationContext.budgetLimitBrl,
          );
          final fallbackApplication = optimize_route_empty_fallback
              .buildEmptySuggestionFallbackApplication(
                removalCandidates: fallbackRemovalCandidates,
                replacements: replacements,
              );
          emptySuggestionFallbackReplacementCount =
              fallbackApplication.replacementCount;
          emptySuggestionFallbackPairCount = fallbackApplication.pairCount;

          if (fallbackApplication.applied) {
            removals = fallbackApplication.removals;
            additions = fallbackApplication.additions;
            emptySuggestionFallbackApplied = true;
            _emptySuggestionFallbackAppliedCount++;
            emptySuggestionFallbackReason = fallbackApplication.successReason;
            Log.i(
              '[AI Optimize] Fallback aplicado com ${fallbackApplication.pairCount} swap(s) após retorno vazio da IA.',
            );
          }
        }

        if (!emptySuggestionFallbackApplied) {
          emptySuggestionFallbackReason = optimize_route_empty_fallback
              .buildEmptySuggestionFallbackFailureReason(
                hasRemovalCandidates: fallbackRemovalCandidates.isNotEmpty,
                replacementCount: emptySuggestionFallbackReplacementCount,
              );
          if (fallbackRemovalCandidates.isEmpty) {
            _emptySuggestionFallbackNoCandidateCount++;
          } else if (emptySuggestionFallbackReplacementCount == 0) {
            _emptySuggestionFallbackNoReplacementCount++;
          }
        }
      }

      // WARN: Se parsing resultou em listas vazias, logar para diagnóstico
      if (removals.isEmpty && additions.isEmpty && !isComplete) {
        if (recognizedSuggestionFormat) {
          Log.d(
            '[AI Optimize] Payload reconhecido, mas sem sugestões úteis (provável filtro/retorno vazio). Keys: ${jsonResponse.keys.toList()}',
          );
        } else {
          Log.w(
            '[AI Optimize] IA retornou formato não reconhecido. Keys: ${jsonResponse.keys.toList()}',
          );
        }
      }

      // Suporte ao modo "complete"
      if (isComplete) {
        removals = [];
        // Quando veio do loop, preferimos additions_detailed.
        final fromDetailed =
            (jsonResponse['additions_detailed'] as List?)
                ?.whereType<Map>()
                .toList();
        if (fromDetailed != null && fromDetailed.isNotEmpty) {
          additions =
              fromDetailed
                  .map((m) => (m['name'] ?? '').toString())
                  .where((s) => s.trim().isNotEmpty)
                  .toList();
        } else {
          additions =
              (jsonResponse['additions'] as List?)?.cast<String>() ?? [];
        }
      }

      final initialSuggestionFilters = optimize_route_suggestion_filter
          .buildInitialOptimizeSuggestionFilters(
            removals: removals,
            additions: additions,
            deckNamesLower: deckNamesLower,
            commanderLower: commanderLower,
            coreLower: coreLower,
            keepTheme: keepTheme,
            isComplete: isComplete,
          );
      var sanitizedRemovals = initialSuggestionFilters.removals;
      var sanitizedAdditions = initialSuggestionFilters.additions;
      blockedByTheme.addAll(initialSuggestionFilters.blockedByTheme);

      // Validar todas as cartas sugeridas
      final allSuggestions = [...sanitizedRemovals, ...sanitizedAdditions];
      final validation = await validationService.validateCardNames(
        allSuggestions,
      );
      final validList =
          (validation['valid'] as List).cast<Map<String, dynamic>>();
      final validByNameLower = <String, Map<String, dynamic>>{};
      for (final v in validList) {
        final n = (v['name'] as String).toLowerCase();
        validByNameLower[n] = v;
      }

      // Filtrar apenas cartas válidas e remover duplicatas
      var validRemovals =
          sanitizedRemovals
              .where((name) {
                return (validation['valid'] as List).any(
                  (card) =>
                      (card['name'] as String).toLowerCase() ==
                      name.toLowerCase(),
                );
              })
              .toSet()
              .toList();

      // No modo complete, preservamos repetição (para básicos) e ordem.
      // No modo optimize (swaps), mantemos set para evitar duplicatas.
      var validAdditions =
          sanitizedAdditions.where((name) {
            return (validation['valid'] as List).any(
              (card) =>
                  (card['name'] as String).toLowerCase() == name.toLowerCase(),
            );
          }).toList();
      if (!isComplete) {
        validAdditions = validAdditions.toSet().toList();
      }

      // DEBUG: Log quantidades antes dos filtros avançados
      Log.d('Antes dos filtros de cor/bracket:');
      Log.d('  validRemovals.length = ${validRemovals.length}');
      Log.d('  validAdditions.length = ${validAdditions.length}');

      // Filtrar adições ilegais para Commander/Brawl (identidade de cor do comandante).
      // Observação: para colorless commander (identity vazia), apenas cartas colorless passam.
      final filteredByColorIdentity = <String>[];
      final filteredByMissingIdentity = <String>[];
      if (commanders.isNotEmpty && validAdditions.isNotEmpty) {
        final additionsIdentityResult = await pool.execute(
          Sql.named('''
            SELECT name, color_identity, colors, oracle_text
            FROM cards
            WHERE name = ANY(@names)
          '''),
          parameters: {'names': validAdditions},
        );

        final identityByName = <String, List<String>>{};
        for (final row in additionsIdentityResult) {
          final name = (row[0] as String).toLowerCase();
          final rawColorIdentity = row[1] as List?;
          final colors = (row[2] as List?)?.cast<String>() ?? const <String>[];
          final oracleText = row[3] as String? ?? '';
          final resolvedIdentity =
              resolvedCardIdentityFromParts(
                colorIdentity: rawColorIdentity?.cast<String>(),
                colors: colors,
                oracleText: oracleText,
              ).toList();
          if (rawColorIdentity != null || resolvedIdentity.isNotEmpty) {
            identityByName[name] = resolvedIdentity;
          }
        }

        final colorIdentityFilter = optimize_route_color_identity_filter
            .filterOptimizeAdditionsByCommanderIdentity(
              validAdditions: validAdditions,
              identityByName: identityByName,
              commanderColorIdentity: commanderColorIdentity,
            );
        validAdditions = colorIdentityFilter.additions;
        filteredByColorIdentity.addAll(
          colorIdentityFilter.filteredByColorIdentity,
        );
        filteredByMissingIdentity.addAll(
          colorIdentityFilter.filteredByMissingIdentity,
        );
      }

      // Bracket policy (intermediário): bloqueia cartas "acima do bracket" baseado no deck atual.
      // Aplica somente em Commander/Brawl, quando bracket foi enviado.
      final blockedByBracket = <Map<String, dynamic>>[];
      if (bracket != null &&
          commanders.isNotEmpty &&
          validAdditions.isNotEmpty) {
        // Dados atuais do deck (já temos oracle/type em allCardData + quantity)
        final additionsInfoResult = await pool.execute(
          Sql.named('''
            SELECT name, type_line, oracle_text
            FROM cards
            WHERE name = ANY(@names)
          '''),
          parameters: {'names': validAdditions},
        );
        final additionsInfo =
            additionsInfoResult
                .map(
                  (row) => optimize_route_bracket_policy_filter
                      .buildOptimizeBracketAdditionCardData(
                        name: row[0],
                        typeLine: row[1],
                        oracleText: row[2],
                      ),
                )
                .toList();

        final bracketFilter = optimize_route_bracket_policy_filter
            .filterOptimizeAdditionsByBracketPolicy(
              bracket: bracket,
              currentDeckCards: allCardData,
              additionsCardsData: additionsInfo,
              validAdditions: validAdditions,
            );

        blockedByBracket.addAll(bracketFilter.blockedByBracket);
        validAdditions = bracketFilter.additions;
      }

      // Top-up determinístico no modo complete:
      // se depois de validações/filtros ainda faltarem cartas para atingir o target, completa com básicos.
      final additionsDetailed = <Map<String, dynamic>>[];
      if (isComplete) {
        final targetAdditions = (jsonResponse['target_additions'] as int?) ?? 0;
        final desired =
            targetAdditions > 0 ? targetAdditions : validAdditions.length;
        final basicNames = basicLandNamesForIdentity(commanderColorIdentity);
        final topUpSeed = optimize_route_complete_top_up
            .buildOptimizeCompleteTopUpSeed(
              validAdditions: validAdditions,
              desired: desired,
              basicNames: basicNames,
              deckFormat: deckFormat,
            );

        Map<String, String> basicsWithIds = const {};
        if (topUpSeed.missing > 0) {
          basicsWithIds = await loadBasicLandIds(pool, basicNames);
        }

        final topUpResult = optimize_route_complete_top_up
            .buildOptimizeCompleteTopUpResult(
              seed: topUpSeed,
              basicIdsByName: basicsWithIds,
              validByNameLower: validByNameLower,
            );
        additionsDetailed.addAll(topUpResult.additionsDetailed);

        // Mantém additions como lista simples (única) para UI; o app aplica via additions_detailed.
        validAdditions = topUpResult.additions;
      }

      // Re-aplicar equilíbrio após validação
      // FILOSOFIA: Quando additions < removals, a IA deve SUGERIR NOVAS CARTAS
      // de sinergia — NÃO preencher com lands genéricos. O propósito é OTIMIZAR.

      if (!isComplete) {
        final landProtectionAdditionData = <Map<String, dynamic>>[];
        if (validAdditions.isNotEmpty) {
          final rows = await pool.execute(
            Sql.named('''
              SELECT name, type_line
              FROM cards
              WHERE name = ANY(@names)
            '''),
            parameters: {'names': validAdditions},
          );
          landProtectionAdditionData.addAll(
            rows.map(
              (row) => <String, dynamic>{'name': row[0], 'type_line': row[1]},
            ),
          );
        }
        final landProtectionResult = optimize_route_land_removal_protection
            .applyOptimizeLandRemovalProtection(
              removals: validRemovals,
              allCardData: allCardData,
              additions: validAdditions,
              additionsCardData: landProtectionAdditionData,
              profileRoleTargets: optimizeCommanderRoleTargets,
            );
        validRemovals = landProtectionResult.removals;
        validAdditions = landProtectionResult.additions;

        if (landProtectionResult.blockedCount > 0) {
          Log.d(
            'Land protection: blocked ${landProtectionResult.blockedCount} '
            'land removals (current=${landProtectionResult.currentLandCount}, '
            'projected=${landProtectionResult.projectedLandCount}, '
            'safe minimum=${landProtectionResult.minSafeLands})',
          );
        }
        if (!landProtectionResult.floorSatisfied) {
          Log.w(
            'Land protection: proposta descartada porque o deck atual tem '
            '${landProtectionResult.currentLandCount} terrenos, abaixo do '
            'piso ${landProtectionResult.minSafeLands}.',
          );
        }
      }

      if (!isComplete && validRemovals.length != validAdditions.length) {
        Log.d('Re-balanceamento pós-filtros:');
        Log.d(
          '  Antes: removals=${validRemovals.length}, additions=${validAdditions.length}',
        );
        final rebalancePlan = optimize_route_rebalance
            .buildOptimizeRebalancePlan(
              removals: validRemovals,
              additions: validAdditions,
              deckNamesLower: deckNamesLower,
              filteredByColorIdentity: [
                ...filteredByColorIdentity,
                ...filteredByMissingIdentity,
              ],
            );

        if (rebalancePlan.needsReplacements) {
          // CORREÇÃO REAL: Reconsultar a IA para cartas substitutas
          Log.d(
            '  Faltam ${rebalancePlan.missingCount} adições - consultando IA para substitutas sinérgicas',
          );

          try {
            final replacementResult = await findSynergyReplacements(
              pool: pool,
              commanders: commanders,
              commanderColorIdentity: commanderColorIdentity,
              targetArchetype: targetArchetype,
              bracket: bracket,
              keepTheme: keepTheme,
              detectedTheme: themeProfile.theme,
              coreCards: themeProfile.coreCards,
              missingCount: rebalancePlan.missingCount,
              removedCards: rebalancePlan.removedButUnmatched,
              excludeNames: rebalancePlan.excludeNames,
              allCardData: allCardData,
              preferredNames:
                  optimizeCommanderPriorityNames
                      .map((name) => name.toLowerCase())
                      .toSet(),
              userId: authenticatedUserId,
              preferCollection: recommendationContext.preferCollection == true,
              budgetLimitBrl: recommendationContext.budgetLimitBrl,
            );

            if (replacementResult.isNotEmpty) {
              final replacementApplication = optimize_route_rebalance
                  .applyOptimizeRebalanceReplacements(
                    additions: validAdditions,
                    replacements: replacementResult,
                  );
              validAdditions = replacementApplication.additions;
              validByNameLower.addAll(
                replacementApplication.validByNameLowerUpdates,
              );
              Log.d(
                '  IA sugeriu ${replacementApplication.addedCount} substitutas sinérgicas',
              );
            }

            // Se AINDA faltar (IA não conseguiu preencher tudo), TRUNCAR remoções
            // para manter equilíbrio. NÃO preencher com básicos em modo optimize —
            // trocar spells por lands é degradação, não otimização.
            if (validAdditions.length < validRemovals.length) {
              final stillMissing = validRemovals.length - validAdditions.length;
              Log.d(
                '  Ainda faltam $stillMissing - truncando remoções (não preencher com básicos em optimize)',
              );
              final trimResult = optimize_route_rebalance
                  .trimOptimizeRebalanceToPairs(
                    removals: validRemovals,
                    additions: validAdditions,
                  );
              validRemovals = trimResult.removals;
              validAdditions = trimResult.additions;
            }
          } catch (e) {
            Log.w(
              'Falha ao buscar substitutas IA; usando fallback '
              'type=${e.runtimeType}',
            );
            // Fallback: truncar remoções para não perder cartas
            final trimResult = optimize_route_rebalance
                .trimOptimizeRebalanceToPairs(
                  removals: validRemovals,
                  additions: validAdditions,
                );
            validRemovals = trimResult.removals;
            validAdditions = trimResult.additions;
          }
        } else {
          // Mais adições que remoções: truncar adições
          final trimResult = optimize_route_rebalance
              .trimOptimizeRebalanceToPairs(
                removals: validRemovals,
                additions: validAdditions,
              );
          validRemovals = trimResult.removals;
          validAdditions = trimResult.additions;
        }

        Log.d(
          '  Depois: removals=${validRemovals.length}, additions=${validAdditions.length}',
        );
      }

      if (!isComplete &&
          (recommendationContext.preferCollection == true ||
              recommendationContext.budgetLimitBrl != null) &&
          validAdditions.isNotEmpty) {
        final recommendationConstraintResult =
            await optimize_route_recommendation_context
                .applyOptimizeRecommendationConstraints(
                  pool: pool,
                  userId: authenticatedUserId,
                  validAdditions: validAdditions,
                  context: recommendationContext,
                );
        recommendationDetailsByName
          ..clear()
          ..addAll(recommendationConstraintResult.detailsByNameLower);
        recommendationConstraintWarnings
          ..clear()
          ..addAll(recommendationConstraintResult.validationWarnings);
        if (recommendationConstraintResult.diagnostics.isNotEmpty) {
          recommendationConstraintDiagnostics =
              recommendationConstraintResult.diagnostics;
        }
        validAdditions = recommendationConstraintResult.additions;
        if (validAdditions.length < validRemovals.length) {
          final trimResult = optimize_route_rebalance
              .trimOptimizeRebalanceToPairs(
                removals: validRemovals,
                additions: validAdditions,
              );
          validRemovals = trimResult.removals;
          validAdditions = trimResult.additions;
        }
      }

      if (!isComplete && (validRemovals.isEmpty || validAdditions.isEmpty)) {
        return respondWithOptimizeTelemetry(
          statusCode: HttpStatus.unprocessableEntity,
          body: {
            'error':
                'A otimizacao nao encontrou trocas acionaveis apos os filtros de seguranca.',
            'quality_error': {
              'code': 'OPTIMIZE_NO_ACTIONABLE_SWAPS',
              'message':
                  'As sugestoes remanescentes foram bloqueadas por tema, bracket, protecao de mana ou qualidade funcional.',
              'blocked_by_theme': blockedByTheme,
              'blocked_by_bracket': blockedByBracket,
            },
            'mode': 'optimize',
            'strategy_source':
                jsonResponse['strategy_source'] ??
                (deterministicFirstEnabled
                    ? 'deterministic_first'
                    : 'ai_primary'),
            if (jsonResponse['fallback_trigger'] != null)
              'fallback_trigger': jsonResponse['fallback_trigger'],
            'cache': {'hit': false, 'cache_key': cacheKey},
            'removals': validRemovals,
            'additions': validAdditions,
            'deck_analysis': deckAnalysis,
          },
          removalsOverride: validRemovals,
          additionsOverride: validAdditions,
          blockedByColorIdentityOverride: filteredByColorIdentity,
          blockedByBracketOverride: blockedByBracket,
        );
      }

      // --- VERIFICAÇÃO PÓS-OTIMIZAÇÃO (Virtual Deck Analysis) ---
      // Simular o deck como ficaria se as mudanças fossem aplicadas e reanalisar
      Map<String, dynamic>? postAnalysis;
      List<String> validationWarnings = [];
      validationWarnings.addAll(recommendationConstraintWarnings);

      // VALIDAÇÃO PÓS-PROCESSAMENTO: Color Identity + EDHREC + Tema

      // 1. Color Identity Warning (se IA sugeriu cartas inválidas)
      final colorIdentityWarning = optimize_route_post_validation
          .buildColorIdentityValidationWarning(filteredByColorIdentity);
      if (colorIdentityWarning != null) {
        validationWarnings.add(colorIdentityWarning);
      }

      // 2. Validação EDHREC: verificar se additions têm sinergia comprovada
      EdhrecCommanderData? edhrecValidationData;
      List<String> additionsNotInEdhrec = [];
      if (commanders.isNotEmpty && validAdditions.isNotEmpty) {
        try {
          final edhrecService = optimizer.edhrecService;
          edhrecValidationData = await edhrecService.fetchCommanderData(
            commanders.firstOrNull ?? "",
          );

          if (edhrecValidationData != null &&
              edhrecValidationData.topCards.isNotEmpty) {
            additionsNotInEdhrec = optimize_route_post_validation
                .collectAdditionsNotInEdhrec(
                  validAdditions: validAdditions,
                  containsCard:
                      (addition) =>
                          edhrecValidationData!.findCard(addition) != null,
                );

            if (additionsNotInEdhrec.isNotEmpty) {
              validationWarnings.addAll(
                optimize_route_post_validation.buildEdhrecValidationWarnings(
                  commanderName: commanders.firstOrNull ?? "",
                  validAdditions: validAdditions,
                  additionsNotInEdhrec: additionsNotInEdhrec,
                ),
              );
            }
          }
        } catch (e) {
          Log.w(
            'EDHREC validation failed (non-blocking) '
            'type=${e.runtimeType}',
          );
        }
      }

      // 3. Comparação de Tema: verificar se tema detectado corresponde aos temas EDHREC
      if (edhrecValidationData != null &&
          edhrecValidationData.themes.isNotEmpty) {
        final themeWarning = optimize_route_post_validation
            .buildThemeMismatchWarning(
              targetArchetype: targetArchetype,
              edhrecThemes: edhrecValidationData.themes,
            );
        if (themeWarning != null) {
          validationWarnings.add(themeWarning);
        }
      }

      ValidationReport? optimizationValidationReport;
      final qualityGateWarnings = <String>[];
      var qualityGateDroppedCount = 0;

      if (validAdditions.isNotEmpty) {
        try {
          var additionsData = await optimize_route_addition_data
              .fetchOptimizeAdditionDataForQualityGate(
                pool,
                validAdditions: validAdditions,
                validByNameLower: validByNameLower,
              );

          if (!isComplete) {
            final gateResult = filterUnsafeOptimizeSwapsByCardData(
              removals: validRemovals,
              additions: validAdditions,
              originalDeck: allCardData,
              additionsData: additionsData,
              archetype: effectiveOptimizeArchetype,
              profileRoleTargets: optimizeCommanderRoleTargets,
            );

            if (gateResult.changed) {
              validRemovals = gateResult.removals;
              validAdditions = gateResult.additions;
              qualityGateDroppedCount += gateResult.droppedReasons.length;
              if (intensity.selected == 'aggressive') {
                mergeAggressiveRejectionBuckets(
                  bucketOptimizeQualityGateDroppedReasons(
                    gateResult.droppedReasons,
                  ),
                );
              }
              qualityGateWarnings.add(
                'Gate de qualidade removeu ${gateResult.droppedReasons.length} troca(s) insegura(s) antes da resposta final.',
              );
              qualityGateWarnings.addAll(
                gateResult.droppedReasons.map((reason) => reason),
              );

              final safeAdditionNames =
                  validAdditions.map((name) => name.toLowerCase()).toSet();
              additionsData =
                  additionsData.where((card) {
                    final name = (card['name'] as String?)?.toLowerCase() ?? '';
                    return safeAdditionNames.contains(name);
                  }).toList();
            }

            if (intensity.selected == 'aggressive' &&
                validRemovals.length > intensity.targetMax) {
              final overflow = validRemovals.length - intensity.targetMax;
              mergeAggressiveRejectionBuckets({'scope_cap': overflow});
              validRemovals = validRemovals.take(intensity.targetMax).toList();
              validAdditions =
                  validAdditions.take(intensity.targetMax).toList();
              qualityGateWarnings.add(
                'Escopo aggressive limitado a ${intensity.targetMax} troca(s) após ranking e gate; $overflow candidata(s) excedentes ficaram como reserva.',
              );
              final safeAdditionNames =
                  validAdditions.map((name) => name.toLowerCase()).toSet();
              additionsData =
                  additionsData.where((card) {
                    final name = (card['name'] as String?)?.toLowerCase() ?? '';
                    return safeAdditionNames.contains(name);
                  }).toList();
            }

            if (validRemovals.isEmpty || validAdditions.isEmpty) {
              final retryPlan = optimize_route_retry
                  .buildOptimizeAiFallbackRetryPlan(
                    deterministicFirstEnabled: deterministicFirstEnabled,
                    fallbackAlreadyAttempted: optimizeFallbackAttempted,
                    strategySource: jsonResponse['strategy_source']?.toString(),
                    qualityErrorCode: 'OPTIMIZE_NO_SAFE_SWAPS',
                    isComplete: isComplete,
                  );
              if (retryPlan.shouldRetry && retryPlan.trigger != null) {
                optimizeFallbackAttempted = true;
                final aiFallbackResponse = await runAiOptimizeAttempt(
                  trigger: retryPlan.trigger!,
                );
                if (aiFallbackResponse != null) {
                  Log.i(retryPlan.logMessage ?? 'Retry de optimize via IA.');
                  jsonResponse = aiFallbackResponse;
                  continue optimizeAttemptLoop;
                }
              }

              return respondWithOptimizeTelemetry(
                statusCode: HttpStatus.unprocessableEntity,
                body: optimize_route_quality_rejection
                    .buildNoSafeSwapsRejectedBody(
                      strategySource:
                          jsonResponse['strategy_source']?.toString() ??
                          (deterministicFirstEnabled
                              ? 'deterministic_first'
                              : 'ai_primary'),
                      cacheKey: cacheKey,
                      fallbackTrigger:
                          jsonResponse['fallback_trigger']?.toString(),
                      optimizeIntensity: intensity.toJson(
                        candidateSwaps: deterministicSwapCandidates.length,
                        returnedSwaps: 0,
                        qualityGateDropped: qualityGateDroppedCount,
                      ),
                      droppedSwaps: qualityGateWarnings,
                      removals: validRemovals,
                      additions: validAdditions,
                    ),
                removalsOverride: validRemovals,
                additionsOverride: validAdditions,
                validationWarningsOverride: qualityGateWarnings,
                blockedByColorIdentityOverride: filteredByColorIdentity,
                blockedByBracketOverride: blockedByBracket,
              );
            }
          }

          final virtualPostAnalysis = optimize_route_virtual_analysis
              .buildOptimizeVirtualPostAnalysis(
                originalDeck: allCardData,
                validRemovals: validRemovals,
                validAdditions: validAdditions,
                additionsData: additionsData,
                deckColors: deckColors,
                deckAnalysis: deckAnalysis,
                effectiveOptimizeArchetype: effectiveOptimizeArchetype,
              );
          final virtualDeck = virtualPostAnalysis.virtualDeck;
          postAnalysis = virtualPostAnalysis.postAnalysis;
          validationWarnings.addAll(virtualPostAnalysis.validationWarnings);

          // 6. VALIDAÇÃO AUTOMÁTICA (Monte Carlo + Funcional + Critic IA)
          try {
            final themeService = ThemeContextualRulesService(pool);
            final validator = OptimizationValidator(
              openAiKey: apiKey,
              safetyIdentifierSource: authenticatedUserId,
              themeService: themeService,
              providerLogDb: pool,
              providerUserId: authenticatedUserId,
              providerDeckId: deckId,
            );
            final validationResult = await optimize_route_validator
                .runOptimizeRouteValidation(
                  validate:
                      ({
                        required originalDeck,
                        required optimizedDeck,
                        required removals,
                        required additions,
                        required commanders,
                        required archetype,
                      }) => validator.validate(
                        originalDeck: originalDeck,
                        optimizedDeck: optimizedDeck,
                        removals: removals,
                        additions: additions,
                        commanders: commanders,
                        archetype: archetype,
                      ),
                  originalDeck: allCardData,
                  optimizedDeck: virtualDeck,
                  removals: validRemovals,
                  additions: validAdditions,
                  commanders: commanders,
                  archetype: effectiveOptimizeArchetype,
                  postAnalysis: postAnalysis,
                  existingValidationWarnings: validationWarnings,
                );
            postAnalysis = validationResult.postAnalysis;
            validationWarnings = validationResult.validationWarnings;
            optimizationValidationReport = validationResult.validationReport;
          } catch (validationError) {
            Log.e('Validation failed type=${validationError.runtimeType}');
            return respondWithOptimizeTelemetry(
              statusCode: HttpStatus.internalServerError,
              body: {
                'error':
                    'Falha interna ao validar a qualidade final da otimizacao.',
                'quality_error': {
                  'code': 'OPTIMIZE_VALIDATION_FAILED',
                  'message':
                      'A validacao automatica da otimizacao falhou. A resposta foi bloqueada para evitar retornar um resultado nao verificado.',
                  'details': 'A validação interna não pôde ser concluída.',
                },
                'mode': 'optimize',
                'removals': validRemovals,
                'additions': validAdditions,
                'deck_analysis': deckAnalysis,
                'post_analysis': postAnalysis,
                'validation_warnings': validationWarnings,
              },
              postAnalysisOverride: postAnalysis,
              removalsOverride: validRemovals,
              additionsOverride: validAdditions,
              validationWarningsOverride: validationWarnings,
              blockedByColorIdentityOverride: filteredByColorIdentity,
              blockedByBracketOverride: blockedByBracket,
            );
          }
        } catch (e) {
          Log.e('Erro na verificação pós-otimização type=${e.runtimeType}');
          return respondWithOptimizeTelemetry(
            statusCode: HttpStatus.internalServerError,
            body: {
              'error':
                  'Falha interna durante a verificacao final da otimizacao.',
              'quality_error': {
                'code': 'OPTIMIZE_POST_ANALYSIS_FAILED',
                'message':
                    'A verificacao final falhou e a resposta foi bloqueada para evitar retornar uma otimizacao sem checagem completa.',
                'details': 'A verificação interna não pôde ser concluída.',
              },
              'mode': 'optimize',
              'removals': validRemovals,
              'additions': validAdditions,
              'deck_analysis': deckAnalysis,
              'post_analysis': postAnalysis,
              'validation_warnings': validationWarnings,
            },
            postAnalysisOverride: postAnalysis,
            removalsOverride: validRemovals,
            additionsOverride: validAdditions,
            validationWarningsOverride: validationWarnings,
            blockedByColorIdentityOverride: filteredByColorIdentity,
            blockedByBracketOverride: blockedByBracket,
          );
        }
      }

      if (qualityGateWarnings.isNotEmpty) {
        validationWarnings.insertAll(0, qualityGateWarnings);
      }

      final preCurve =
          double.tryParse('${deckAnalysis['average_cmc'] ?? '0'}') ?? 0.0;
      final postCurve =
          double.tryParse(
            '${(postAnalysis ?? const <String, dynamic>{})['average_cmc'] ?? '0'}',
          ) ??
          0.0;
      final preManaAssessment =
          deckAnalysis['mana_base_assessment']?.toString() ?? '';
      final postManaAssessment =
          (postAnalysis?['mana_base_assessment']?.toString()) ?? '';

      final finalQualityGateDecision = optimize_route_final_gate
          .evaluateOptimizeRouteQualityGate(
            isComplete: isComplete,
            validationReport: optimizationValidationReport,
            archetype: effectiveOptimizeArchetype,
            preCurve: preCurve,
            postCurve: postCurve,
            preManaAssessment: preManaAssessment,
            postManaAssessment: postManaAssessment,
            profileRoleTargets: optimizeCommanderRoleTargets,
          );

      if (finalQualityGateDecision.rejected) {
        final retryPlan = optimize_route_retry.buildOptimizeAiFallbackRetryPlan(
          deterministicFirstEnabled: deterministicFirstEnabled,
          fallbackAlreadyAttempted: optimizeFallbackAttempted,
          strategySource: jsonResponse['strategy_source']?.toString(),
          qualityErrorCode: 'OPTIMIZE_QUALITY_REJECTED',
          isComplete: isComplete,
        );
        if (retryPlan.shouldRetry && retryPlan.trigger != null) {
          optimizeFallbackAttempted = true;
          final aiFallbackResponse = await runAiOptimizeAttempt(
            trigger: retryPlan.trigger!,
          );
          if (aiFallbackResponse != null) {
            Log.i(retryPlan.logMessage ?? 'Retry de optimize via IA.');
            jsonResponse = aiFallbackResponse;
            continue optimizeAttemptLoop;
          }
        }

        return respondWithOptimizeTelemetry(
          statusCode: HttpStatus.unprocessableEntity,
          body: optimize_route_quality_rejection.buildQualityRejectedBody(
            strategySource:
                jsonResponse['strategy_source']?.toString() ??
                (deterministicFirstEnabled
                    ? 'deterministic_first'
                    : 'ai_primary'),
            cacheKey: cacheKey,
            fallbackTrigger: jsonResponse['fallback_trigger']?.toString(),
            reasons: finalQualityGateDecision.reasons,
            validation: finalQualityGateDecision.validation,
            removals: validRemovals,
            additions: validAdditions,
            deckAnalysis: deckAnalysis,
            postAnalysis: postAnalysis,
            validationWarnings: validationWarnings,
          ),
          postAnalysisOverride: postAnalysis,
          validationReport: optimizationValidationReport,
          removalsOverride: validRemovals,
          additionsOverride: validAdditions,
          validationWarningsOverride: validationWarnings,
          blockedByColorIdentityOverride: filteredByColorIdentity,
          blockedByBracketOverride: blockedByBracket,
        );
      }

      final responseValidationJson =
          (postAnalysis?['validation'] as Map?)?.cast<String, dynamic>();
      final serializedValidationDecision = optimize_route_final_gate
          .evaluateSerializedOptimizeValidation(
            isComplete: isComplete,
            serializedValidation: responseValidationJson,
            validationReport: optimizationValidationReport,
            archetype: effectiveOptimizeArchetype,
            preCurve: preCurve,
            postCurve: postCurve,
            preManaAssessment: preManaAssessment,
            postManaAssessment: postManaAssessment,
            profileRoleTargets: optimizeCommanderRoleTargets,
          );
      if (serializedValidationDecision.rejected) {
        return respondWithOptimizeTelemetry(
          statusCode: HttpStatus.unprocessableEntity,
          body: optimize_route_quality_rejection.buildQualityRejectedBody(
            strategySource:
                jsonResponse['strategy_source']?.toString() ??
                (deterministicFirstEnabled
                    ? 'deterministic_first'
                    : 'ai_primary'),
            cacheKey: cacheKey,
            fallbackTrigger: jsonResponse['fallback_trigger']?.toString(),
            reasons: serializedValidationDecision.reasons,
            validation: serializedValidationDecision.validation,
            removals: validRemovals,
            additions: validAdditions,
            deckAnalysis: deckAnalysis,
            postAnalysis: postAnalysis,
            validationWarnings: validationWarnings,
          ),
          postAnalysisOverride: postAnalysis,
          validationReport: optimizationValidationReport,
          removalsOverride: validRemovals,
          additionsOverride: validAdditions,
          validationWarningsOverride: validationWarnings,
          blockedByColorIdentityOverride: filteredByColorIdentity,
          blockedByBracketOverride: blockedByBracket,
        );
      }

      final semanticV2GateDecision = optimize_route_final_gate
          .evaluateOptimizeRouteSemanticV2Gate(
            isComplete: isComplete,
            validationReport: optimizationValidationReport,
            enforcementMode: semanticV2OptimizeEnforcementMode,
            expandedCriticalRoles: semanticV2ExpandedCriticalRoles,
          );
      if (semanticV2GateDecision.rejected) {
        final semanticRejectionBody = buildSemanticV2OptimizeRejectedBody(
          semanticLayerV2: semanticV2GateDecision.semanticLayerV2,
          enforcementMode: semanticV2OptimizeEnforcementMode,
          expandedCriticalRoles: semanticV2ExpandedCriticalRoles,
          validation: optimizationValidationReport!.toJson(),
          removals: validRemovals,
          additions: validAdditions,
          deckAnalysis: deckAnalysis,
          postAnalysis: postAnalysis,
          validationWarnings: validationWarnings,
        );
        semanticRejectionBody['strategy_source'] =
            jsonResponse['strategy_source'] ??
            (deterministicFirstEnabled ? 'deterministic_first' : 'ai_primary');
        if (jsonResponse['fallback_trigger'] != null) {
          semanticRejectionBody['fallback_trigger'] =
              jsonResponse['fallback_trigger'];
        }
        semanticRejectionBody['cache'] = {'hit': false, 'cache_key': cacheKey};

        return respondWithOptimizeTelemetry(
          statusCode: HttpStatus.unprocessableEntity,
          body: semanticRejectionBody,
          postAnalysisOverride: postAnalysis,
          validationReport: optimizationValidationReport,
          removalsOverride: validRemovals,
          additionsOverride: validAdditions,
          validationWarningsOverride: validationWarnings,
          blockedByColorIdentityOverride: filteredByColorIdentity,
          blockedByBracketOverride: blockedByBracket,
        );
      }

      // Preparar resposta com avisos sobre cartas inválidas
      final invalidCards = validation['invalid'] as List<String>;
      final suggestions =
          validation['suggestions'] as Map<String, List<String>>;

      Map<String, dynamic>? persistedFallbackAggregate;
      try {
        await recordOptimizeFallbackTelemetry(
          pool: pool,
          userId: userId,
          deckId: deckId,
          mode: jsonResponse['mode']?.toString() ?? 'optimize',
          recognizedFormat: recognizedSuggestionFormat,
          triggered: emptySuggestionFallbackTriggered,
          applied: emptySuggestionFallbackApplied,
          noCandidate:
              emptySuggestionFallbackTriggered &&
              emptySuggestionFallbackCandidateCount == 0,
          noReplacement:
              emptySuggestionFallbackTriggered &&
              emptySuggestionFallbackCandidateCount > 0 &&
              emptySuggestionFallbackReplacementCount == 0,
          candidateCount: emptySuggestionFallbackCandidateCount,
          replacementCount: emptySuggestionFallbackReplacementCount,
          pairCount: emptySuggestionFallbackPairCount,
        );
        persistedFallbackAggregate = await loadPersistedEmptyFallbackAggregate(
          pool,
        );
      } catch (e) {
        Log.w('Persisted fallback telemetry unavailable type=${e.runtimeType}');
      }

      final preCmc =
          double.tryParse('${deckAnalysis['average_cmc'] ?? '0'}') ?? 0.0;
      final postCmc =
          postAnalysis == null
              ? preCmc
              : (double.tryParse('${postAnalysis['average_cmc'] ?? preCmc}') ??
                  preCmc);
      final originalCardByName = <String, Map<String, dynamic>>{
        for (final card in allCardData)
          (((card['name'] as String?) ?? '').trim().toLowerCase()): card,
      }..removeWhere((key, value) => key.isEmpty);
      final detailRisk = intensity.selected == 'aggressive' ? 'medium' : 'low';
      final detailPriority = intensity.selected == 'light' ? 'Medium' : 'High';

      final responseBody = {
        'mode': jsonResponse['mode'],
        'strategy_source':
            jsonResponse['strategy_source'] ??
            (deterministicFirstEnabled ? 'deterministic_first' : 'ai_primary'),
        if (jsonResponse['fallback_trigger'] != null)
          'fallback_trigger': jsonResponse['fallback_trigger'],
        'constraints': {'keep_theme': keepTheme},
        'cache': {'hit': false, 'cache_key': cacheKey},
        'preferences': {
          'memory_applied': !hasBracketOverride || !hasKeepThemeOverride,
          'keep_theme': keepTheme,
          'preferred_bracket': userPreferences['preferred_bracket'],
        },
        'theme': themeProfile.toJson(),
        'removals': validRemovals,
        'additions': validAdditions,
        'reasoning': normalizeOptimizeReasoning(jsonResponse['reasoning']),
        'deck_analysis': deckAnalysis,
        'post_analysis':
            postAnalysis, // Retorna a análise futura para o front mostrar
        'validation_warnings': validationWarnings,
        'bracket': bracket,
        'target_additions': jsonResponse['target_additions'],
        'optimize_diagnostics': optimize_route_diagnostics
            .buildEmptySuggestionFallbackDiagnostics(
              triggered: emptySuggestionFallbackTriggered,
              applied: emptySuggestionFallbackApplied,
              candidateCount: emptySuggestionFallbackCandidateCount,
              replacementCount: emptySuggestionFallbackReplacementCount,
              pairCount: emptySuggestionFallbackPairCount,
              aggregate: _buildEmptyFallbackAggregate(),
              persistedAggregate: persistedFallbackAggregate,
            ),
        // Validação EDHREC
        if (edhrecValidationData != null)
          'edhrec_validation': {
            'commander': commanders.firstOrNull ?? "",
            'deck_count': edhrecValidationData.deckCount,
            'themes': edhrecValidationData.themes,
            'additions_validated':
                validAdditions.length - additionsNotInEdhrec.length,
            'additions_not_in_edhrec': additionsNotInEdhrec,
          },
      };

      // Gerar additions_detailed apenas para cartas com card_id válido
      responseBody['additions_detailed'] =
          isComplete
              ? additionsDetailed
                  .whereType<Map<String, dynamic>>()
                  .map((entry) {
                    final name = entry['name']?.toString() ?? '';
                    final cardId = entry['card_id']?.toString() ?? '';
                    if (name.isEmpty || cardId.isEmpty) return null;
                    return buildOptimizeRecommendationDetail(
                      type: 'add',
                      name: name,
                      cardId: cardId,
                      quantity: (entry['quantity'] as int?) ?? 1,
                      targetArchetype: targetArchetype,
                      confidenceLevel: themeProfile.confidence,
                      cmcBefore: preCmc,
                      cmcAfter: postCmc,
                      keepTheme: keepTheme,
                      priority: detailPriority,
                      risk: detailRisk,
                    )..addAll(
                      recommendationDetailsByName[name.toLowerCase()] ??
                          const <String, dynamic>{},
                    );
                  })
                  .where((e) => e != null)
                  .toList()
              : validAdditions
                  .map((name) {
                    final v = validByNameLower[name.toLowerCase()];
                    if (v == null || v['id'] == null) return null;
                    return buildOptimizeRecommendationDetail(
                      type: 'add',
                      name: '${v['name']}',
                      cardId: '${v['id']}',
                      quantity: 1,
                      targetArchetype: targetArchetype,
                      confidenceLevel: themeProfile.confidence,
                      cmcBefore: preCmc,
                      cmcAfter: postCmc,
                      keepTheme: keepTheme,
                      priority: detailPriority,
                      risk: detailRisk,
                    )..addAll(
                      recommendationDetailsByName[name.toLowerCase()] ??
                          const <String, dynamic>{},
                    );
                  })
                  .where((e) => e != null)
                  .toList();

      // Gerar removals_detailed apenas para cartas com card_id válido
      responseBody['removals_detailed'] =
          validRemovals
              .map((name) {
                final v = validByNameLower[name.toLowerCase()];
                if (v == null || v['id'] == null) return null;
                final originalCard = originalCardByName[name.toLowerCase()];
                final resolvedRoles =
                    originalCard == null
                        ? const <String>[]
                        : (optimizationFunctionalRolesForCard(
                            originalCard,
                          ).toList()
                          ..sort());
                return buildOptimizeRecommendationDetail(
                  type: 'remove',
                  name: '${v['name']}',
                  cardId: '${v['id']}',
                  quantity: 1,
                  targetArchetype: targetArchetype,
                  confidenceLevel: themeProfile.confidence,
                  cmcBefore: preCmc,
                  cmcAfter: postCmc,
                  keepTheme: keepTheme,
                  functionalRole: inferFunctionalRole(
                    name: name,
                    typeLine: originalCard?['type_line']?.toString() ?? '',
                    oracleText: originalCard?['oracle_text']?.toString() ?? '',
                  ),
                  functionalRoles: resolvedRoles,
                  priority: detailPriority,
                  risk: detailRisk,
                );
              })
              .where((e) => e != null)
              .toList();

      optimize_route_payload.balanceOptimizeDetailedPayload(
        responseBody: responseBody,
        validAdditions: validAdditions,
        validRemovals: validRemovals,
        validByNameLower: validByNameLower,
        isComplete: isComplete,
      );
      optimize_route_payload.enforceOptimizeFinalPayloadIntegrity(
        responseBody: responseBody,
        deckNamesLower: deckNamesLower,
        deckFormat: deckFormat,
        isComplete: isComplete,
      );

      responseBody['optimization_contract'] = buildOptimizeDecisionContract(
        mode: effectiveMode,
        targetArchetype: targetArchetype,
        intensity: intensity.selected,
        keepTheme: keepTheme,
        additionCount:
            (responseBody['additions_detailed'] as List?)?.length ??
            validAdditions.length,
        removalCount:
            (responseBody['removals_detailed'] as List?)?.length ??
            validRemovals.length,
      );
      responseBody['battle_validation'] =
          (responseBody['optimization_contract'] as Map)['battle_validation'];
      optimize_route_outcome.enforceSuccessfulOptimizeOutcomeSafety(
        responseBody,
      );

      responseBody['intensity'] = intensity.selected;
      responseBody['optimize_intensity'] = intensity.toJson(
        candidateSwaps: deterministicSwapCandidates.length,
        returnedSwaps: optimize_route_response.countOptimizeResponseSwaps(
          responseBody: responseBody,
          effectiveMode: effectiveMode,
        ),
        qualityGateDropped: qualityGateDroppedCount,
      );
      if (optimizationValidationReport?.functional.semanticLayerV2.isNotEmpty ==
          true) {
        optimize_route_diagnostics.attachOptimizeDiagnostic(
          responseBody,
          key: 'semantic_layer_v2',
          value: withOptimizationSemanticV2EnforcementDiagnostics(
            semanticLayerV2:
                optimizationValidationReport!.functional.semanticLayerV2,
            mode: semanticV2OptimizeEnforcementMode,
            expandedCriticalRoles: semanticV2ExpandedCriticalRoles,
          ),
        );
      }
      if (intensity.selected == 'aggressive') {
        optimize_route_diagnostics.attachOptimizeDiagnostic(
          responseBody,
          key: 'aggressive_candidate_quality',
          value: buildAggressiveCandidateQualityDiagnostics(
            returnedSwaps: optimize_route_response.countOptimizeResponseSwaps(
              responseBody: responseBody,
              effectiveMode: effectiveMode,
            ),
          ),
        );
      }
      if (recommendationConstraintDiagnostics != null) {
        optimize_route_diagnostics.attachOptimizeDiagnostic(
          responseBody,
          key: 'recommendation_constraints',
          value: recommendationConstraintDiagnostics,
        );
      }

      attachOptimizeBracketPolicyDiagnostics(
        responseBody,
        bracket: bracket,
        blockedByBracket: blockedByBracket,
      );

      final warnings = optimize_route_warnings.buildOptimizeWarnings(
        invalidCards: invalidCards,
        suggestions: suggestions,
        filteredByColorIdentity: filteredByColorIdentity,
        filteredByMissingIdentity: filteredByMissingIdentity,
        commanderColorIdentity: commanderColorIdentity,
        blockedByBracket: blockedByBracket,
        bracket: bracket,
        blockedByTheme: blockedByTheme,
        keepTheme: keepTheme,
        emptySuggestionFallbackReason: emptySuggestionFallbackReason,
        recognizedSuggestionFormat: recognizedSuggestionFormat,
        emptySuggestionFallbackApplied: emptySuggestionFallbackApplied,
      );

      if (warnings.isNotEmpty) {
        responseBody['warnings'] = warnings;
      }

      if (optimizeMetaReferenceContext != null &&
          optimizeMetaReferenceContext.isNotEmpty) {
        responseBody['meta_reference_context'] =
            augmentMetaDeckEvidencePayloadWithOutputMatches(
              optimizeMetaReferenceContext,
              outputCardNames: (responseBody['additions'] as List).map(
                (entry) => '$entry',
              ),
            );
      }
      optimize_route_request.attachRecommendationContextToOptimizeResponse(
        responseBody,
        recommendationContext,
      );

      try {
        if (semanticV2OptimizeEnforcementMode ==
            SemanticV2OptimizeEnforcementMode.disabled) {
          await saveOptimizeCache(
            pool: pool,
            cacheKey: cacheKey,
            userId: userId,
            deckId: deckId,
            deckSignature: deckSignature,
            payload: responseBody,
          );
        }
        await saveUserAiPreferences(
          pool: pool,
          userId: userId,
          preferredArchetype: targetArchetype,
          preferredBracket: bracket,
          keepThemeDefault: keepTheme,
          preferredColors: commanderColorIdentity.toList(),
        );
      } catch (e) {
        Log.w(
          'Falha ao persistir cache/preferências de optimize '
          'type=${e.runtimeType}',
        );
      }

      return respondWithOptimizeTelemetry(
        statusCode: HttpStatus.ok,
        body: responseBody,
        postAnalysisOverride: postAnalysis,
        validationReport: optimizationValidationReport,
        removalsOverride:
            (responseBody['removals'] as List).map((e) => '$e').toList(),
        additionsOverride:
            (responseBody['additions'] as List).map((e) => '$e').toList(),
        validationWarningsOverride: validationWarnings,
        blockedByColorIdentityOverride: filteredByColorIdentity,
        blockedByBracketOverride: blockedByBracket,
      );
    }
  } catch (e, stackTrace) {
    Log.e('[ai-optimize] request failed type=${e.runtimeType}');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_optimize'},
    );
    return internalServerError('Failed to optimize deck');
  }
}
