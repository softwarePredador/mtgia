import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/color_identity.dart';
import '../../../lib/card_validation_service.dart';
import '../../../lib/ai/optimize_analysis_support.dart' as optimize_analysis;
import '../../../lib/ai/optimize_complete_support.dart' as optimize_complete;
import '../../../lib/ai/optimize_deck_support.dart' as optimize_deck;
import '../../../lib/ai/optimize_request_support.dart' as optimize_request;
import '../../../lib/ai/optimize_state_support.dart' as optimize_state;
import '../../../lib/ai/otimizacao.dart';
import '../../../lib/ai/optimization_quality_gate.dart';
import '../../../lib/ai/optimize_runtime_support.dart';
import '../../../lib/ai/optimize_runtime_support.dart' as optimize_support;
import '../../../lib/ai/optimization_validator.dart';
import '../../../lib/ai/edhrec_service.dart';
import '../../../lib/ai/optimize_job.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/logger.dart';
import '../../../lib/edh_bracket_policy.dart';

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
}) =>
    optimize_support.buildDeterministicOptimizeResponse(
      deterministicSwapCandidates: deterministicSwapCandidates,
      targetArchetype: targetArchetype,
    );

String resolveOptimizeArchetype({
  required String requestedArchetype,
  required String? detectedArchetype,
}) =>
    optimize_support.resolveOptimizeArchetype(
      requestedArchetype: requestedArchetype,
      detectedArchetype: detectedArchetype,
    );

bool shouldRetryOptimizeWithAiFallback({
  required bool deterministicFirstEnabled,
  required bool fallbackAlreadyAttempted,
  required String? strategySource,
  required String? qualityErrorCode,
  required bool isComplete,
}) =>
    optimize_support.shouldRetryOptimizeWithAiFallback(
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
}) =>
    optimize_support.matchesFunctionalNeed(
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
}) =>
    optimize_support.scoreOptimizeReplacementCandidate(
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
}) =>
    optimize_support.isOptimizeStructuralRecoveryScenario(
      allCardData: allCardData,
      commanderColorIdentity: commanderColorIdentity,
    );

int computeOptimizeStructuralRecoverySwapTarget({
  required List<Map<String, dynamic>> allCardData,
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
}) =>
    optimize_support.computeOptimizeStructuralRecoverySwapTarget(
      allCardData: allCardData,
      commanderColorIdentity: commanderColorIdentity,
      targetArchetype: targetArchetype,
    );

List<String> buildStructuralRecoveryFunctionalNeeds({
  required List<Map<String, dynamic>> allCardData,
  required String targetArchetype,
  required int limit,
}) =>
    optimize_support.buildStructuralRecoveryFunctionalNeeds(
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
}) =>
    optimize_support.buildDeterministicOptimizeRemovalCandidates(
      allCardData: allCardData,
      commanders: commanders,
      commanderColorIdentity: commanderColorIdentity,
      targetArchetype: targetArchetype,
      keepTheme: keepTheme,
      coreCards: coreCards,
      commanderPriorityNames: commanderPriorityNames,
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
}) =>
    optimize_support.buildDeterministicOptimizeSwapCandidates(
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
}) =>
    optimize_analysis.buildOptimizationAnalysisLogEntry(
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

List<Map<String, dynamic>> buildOptimizeAdditionEntries({
  required List<String> requestedAdditions,
  required List<Map<String, dynamic>> additionsData,
}) =>
    optimize_deck.buildOptimizeAdditionEntries(
      requestedAdditions: requestedAdditions,
      additionsData: additionsData,
    );

List<Map<String, dynamic>> buildVirtualDeckForAnalysis({
  required List<Map<String, dynamic>> originalDeck,
  List<String> removals = const [],
  List<Map<String, dynamic>> additions = const [],
}) =>
    optimize_deck.buildVirtualDeckForAnalysis(
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
}) {
  if (statusCode >= 200 && statusCode < 300) {
    final mode = body['mode']?.toString() ?? 'optimize';
    return mode == 'complete' ? 'deck_completed' : 'optimized';
  }

  final qualityError = body['quality_error'] is Map
      ? (body['quality_error'] as Map).cast<String, dynamic>()
      : null;
  final qualityCode = qualityError?['code']?.toString() ?? '';
  final validation = qualityError?['validation'] is Map
      ? (qualityError?['validation'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  final healthScore = validationReport?.healthScore ??
      (validation['deck_health_score'] as num?)?.toInt();
  final improvementScore = validationReport?.improvementScore ??
      (validation['improvement_score'] as num?)?.toInt();

  switch (qualityCode) {
    case 'OPTIMIZE_NEEDS_REPAIR':
      return 'needs_repair';
    case 'OPTIMIZE_NO_SAFE_SWAPS':
    case 'OPTIMIZE_NO_ACTIONABLE_SWAPS':
      return deckState.status == 'needs_repair'
          ? 'needs_repair'
          : 'no_safe_upgrade_found';
    case 'OPTIMIZE_QUALITY_REJECTED':
      if (deckState.status == 'needs_repair' ||
          (healthScore != null && healthScore < 45)) {
        return 'needs_repair';
      }
      if (healthScore != null &&
          healthScore >= 80 &&
          improvementScore != null &&
          improvementScore < 35) {
        return 'near_peak';
      }
      return 'no_safe_upgrade_found';
    case 'OPTIMIZE_EXECUTION_FAILED':
    case 'OPTIMIZE_VALIDATION_FAILED':
    case 'OPTIMIZE_POST_ANALYSIS_FAILED':
      if (deckState.status == 'needs_repair') {
        return 'needs_repair';
      }
      if (deckState.status == 'healthy') {
        return 'no_safe_upgrade_found';
      }
      return 'execution_failed';
    default:
      return statusCode >= 500 ? 'execution_failed' : 'blocked';
  }
}

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

    final body = await context.request.json() as Map<String, dynamic>;
    final deckId = body['deck_id'] as String?;
    final archetype = body['archetype'] as String?;
    final bracketRaw = body['bracket'];
    final parsedBracket =
        bracketRaw is int ? bracketRaw : int.tryParse('${bracketRaw ?? ''}');
    final parsedKeepTheme = body['keep_theme'] as bool?;
    final requestedModeRaw =
        body['mode']?.toString().trim().toLowerCase() ?? '';
    final requestMode =
        requestedModeRaw.contains('complete') ? 'complete' : 'optimize';
    final requestStopwatch = Stopwatch()..start();
    final hasBracketOverride = body.containsKey('bracket');
    final hasKeepThemeOverride = body.containsKey('keep_theme');

    _optimizeRequestCount++;

    if (deckId == null || archetype == null) {
      return badRequest('deck_id and archetype are required');
    }

    // 1. Fetch Deck Data
    final pool = context.read<Pool>();

    // Memória de preferências do usuário (se autenticado):
    // aplica default somente quando o request não enviar override explícito.
    final userPreferences = await loadUserAiPreferences(
      pool: pool,
      userId: userId,
    );
    final bracket = hasBracketOverride
        ? parsedBracket
        : (userPreferences['preferred_bracket'] as int? ?? parsedBracket);
    final keepTheme = hasKeepThemeOverride
        ? (parsedKeepTheme ?? true)
        : (userPreferences['keep_theme_default'] as bool? ?? true);

    late final optimize_request.OptimizeDeckContextData deckContext;
    try {
      deckContext = await optimize_request.loadOptimizeDeckContext(
        pool: pool,
        deckId: deckId,
        targetArchetype: archetype,
        requestMode: requestMode,
        bracket: bracket,
        keepTheme: keepTheme,
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

    final cachedResponse = await loadOptimizeCache(
      pool: pool,
      cacheKey: cacheKey,
    );
    if (cachedResponse != null) {
      cachedResponse['cache'] = {
        'hit': true,
        'cache_key': cacheKey,
      };
      cachedResponse['preferences'] = {
        'memory_applied': !hasBracketOverride || !hasKeepThemeOverride,
        'keep_theme': keepTheme,
        'preferred_bracket': userPreferences['preferred_bracket'],
      };
      return Response.json(body: cachedResponse);
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

    final commanderNameForLogs =
        commanders.isNotEmpty ? commanders.first.trim() : 'unknown';
    var optimizeCommanderPrioritySource = 'none';
    final optimizeCommanderPriorityNames = <String>[];
    final deterministicSwapCandidates = <Map<String, dynamic>>[];

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
    }) async {
      final responseBody = Map<String, dynamic>.from(body);
      responseBody['deck_state'] ??= deckState.toJson();
      responseBody['outcome_code'] ??= deriveOptimizeOutcomeCode(
        statusCode: statusCode,
        body: responseBody,
        deckState: deckState,
        validationReport: validationReport,
      );

      await _recordOptimizeAnalysisOutcome(
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
        removals: removalsOverride ??
            ((responseBody['removals'] as List?)?.map((e) => '$e').toList() ??
                const <String>[]),
        additions: additionsOverride ??
            ((responseBody['additions'] as List?)?.map((e) => '$e').toList() ??
                const <String>[]),
        statusCode: statusCode,
        qualityError: responseBody['quality_error'] is Map
            ? (responseBody['quality_error'] as Map).cast<String, dynamic>()
            : null,
        validationReport: validationReport,
        validationWarnings: validationWarningsOverride.isNotEmpty
            ? validationWarningsOverride
            : ((responseBody['validation_warnings'] as List?)
                    ?.map((e) => '$e')
                    .toList() ??
                const <String>[]),
        blockedByColorIdentity: blockedByColorIdentityOverride,
        blockedByBracket: blockedByBracketOverride,
        commanderPriorityNames: optimizeCommanderPriorityNames,
        commanderPrioritySource: optimizeCommanderPrioritySource,
        deterministicSwapCandidates: deterministicSwapCandidates,
        cacheKey: cacheKey,
        executionTimeMs: requestStopwatch.elapsedMilliseconds,
      );

      return Response.json(statusCode: statusCode, body: responseBody);
    }

    if (deckState.status == 'needs_repair') {
      return respondWithOptimizeTelemetry(
        statusCode: HttpStatus.unprocessableEntity,
        body: {
          'error':
              'O deck precisa de reparo estrutural antes de uma micro-otimizacao segura.',
          'quality_error': {
            'code': 'OPTIMIZE_NEEDS_REPAIR',
            'message':
                'O deck atual esta fora da faixa em que optimize por swaps pontuais funciona bem.',
            'reasons': deckState.reasons,
            'recommended_mode': deckState.recommendedMode,
            'repair_plan': deckState.repairPlan,
          },
          'next_action': {
            'type': 'rebuild_guided',
            'endpoint': '/ai/rebuild',
            'payload': {
              'deck_id': deckId,
              'bracket': bracket,
              'archetype': effectiveOptimizeArchetype,
              'theme': themeProfile.theme,
              'rebuild_scope': 'auto',
              'save_mode': 'draft_clone',
            },
          },
          'mode': 'optimize',
          'deck_analysis': deckAnalysis,
          'theme': themeProfile.toJson(),
        },
      );
    }

    // 2. Otimização via DeckOptimizerService (IA + RAG)
    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
    final apiKey = env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      // Mock response for development
      return Response.json(body: {
        'removals': ['Basic Land', 'Weak Card'],
        'additions': ['Sol Ring', 'Arcane Signet'],
        'reasoning':
            'Mock optimization (No API Key): Adicionando staples recomendados.',
        'deck_analysis': deckAnalysis,
        'constraints': {
          'keep_theme': keepTheme,
        },
        'theme': themeProfile.toJson(),
        'is_mock': true
      });
    }

    final optimizer = DeckOptimizerService(apiKey, db: pool);

    // Preparar dados para o otimizador
    final deckData = {
      'cards': allCardData,
      'colors': deckColors.toList(),
    };

    if (commanders.isNotEmpty) {
      try {
        final commanderName = commanders.first.trim();
        if (commanderName.isNotEmpty) {
          final priorityNames = await loadCommanderCompetitivePriorities(
            pool: pool,
            commanderName: commanderName,
            limit: 120,
          );

          if (priorityNames.isNotEmpty) {
            optimizeCommanderPrioritySource = 'competitive_meta';
            optimizeCommanderPriorityNames.addAll(priorityNames);
          }

          final commanderReferenceProfile =
              await loadCommanderReferenceProfileFromCache(
            pool: pool,
            commanderName: commanderName,
          );
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
            final liveEdhrec =
                await EdhrecService().fetchCommanderData(commanderName);
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
        Log.w('Falha ao carregar priority pool do optimize: $e');
      }
    }

    try {
      deterministicSwapCandidates.addAll(
        await buildDeterministicOptimizeSwapCandidates(
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
        ),
      );
      if (deterministicSwapCandidates.isNotEmpty) {
        Log.d(
          'Optimize deterministic shortlist carregado: ${deterministicSwapCandidates.length} swap(s)',
        );
      }
    } catch (e) {
      Log.w('Falha ao montar shortlist deterministico do optimize: $e');
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
                'Selecione um comandante antes de completar um deck $deckFormat.'
          },
        );
      }

      final jobId = await OptimizeJobStore.create(
        pool: pool,
        deckId: deckId,
        archetype: targetArchetype,
        userId: userId,
      );

      // Fire-and-forget: processamento pesado roda em background.
      // A closure captura todas as variáveis do setup (pool, allCardData, etc.)
      // O Pool é singleton e sobrevive ao ciclo do request.
      unawaited(_processCompleteModeAsync(
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
        cacheKey: cacheKey,
        userPreferences: userPreferences,
        hasBracketOverride: hasBracketOverride,
        hasKeepThemeOverride: hasKeepThemeOverride,
      ));

      return Response.json(
        statusCode: HttpStatus.accepted,
        body: {
          'job_id': jobId,
          'status': 'pending',
          'message':
              'Otimização iniciada em background. Consulte o progresso via polling.',
          'poll_url': '/ai/optimize/jobs/$jobId',
          'poll_interval_ms': 2000,
          'total_stages': 6,
        },
      );
    }

    // ================================================================
    //  SYNC MODE: optimize simples (troca de cartas) — roda inline
    // ================================================================
    final deterministicFirstEnabled =
        effectiveMode == 'optimize' && deterministicSwapCandidates.length >= 3;
    var optimizeFallbackAttempted = false;

    Future<Map<String, dynamic>?> runAiOptimizeAttempt({
      required String trigger,
    }) async {
      try {
        final aiResponse = await optimizer.optimizeDeck(
          deckData: deckData,
          commanders: commanders,
          targetArchetype: effectiveOptimizeArchetype,
          priorityPool: optimizeCommanderPriorityNames,
          deterministicSwapCandidates: deterministicSwapCandidates,
          bracket: bracket,
          keepTheme: keepTheme,
          detectedTheme: themeProfile.theme,
          coreCards: themeProfile.coreCards,
        );
        aiResponse['mode'] ??= 'optimize';
        aiResponse['strategy_source'] ??= deterministicFirstEnabled
            ? 'ai_after_deterministic_fallback'
            : 'ai_primary';
        aiResponse['fallback_trigger'] ??= trigger;
        return aiResponse;
      } catch (e, stackTrace) {
        Log.e('Optimization failed: $e\nStack trace:\n$stackTrace');
        return null;
      }
    }

    if (deterministicFirstEnabled) {
      jsonResponse = buildDeterministicOptimizeResponse(
        deterministicSwapCandidates: deterministicSwapCandidates,
        targetArchetype: effectiveOptimizeArchetype,
      );
      Log.i(
        'Optimize deterministic-first ativado com ${deterministicSwapCandidates.length} swap(s) candidatos.',
      );
    } else {
      final aiResponse = await runAiOptimizeAttempt(trigger: 'primary');
      if (aiResponse == null) {
        final executionFailedButPreserved = deckState.status == 'healthy' &&
            deckState.recommendedMode == 'optimize';
        return respondWithOptimizeTelemetry(
          statusCode: executionFailedButPreserved
              ? HttpStatus.unprocessableEntity
              : HttpStatus.internalServerError,
          body: {
            'error': executionFailedButPreserved
                ? 'Nenhuma otimizacao segura foi produzida; deck original preservado.'
                : 'Optimization failed',
            'quality_error': {
              'code': 'OPTIMIZE_EXECUTION_FAILED',
              'message': executionFailedButPreserved
                  ? 'A execucao da otimizacao falhou; o deck original foi preservado em estado saudável.'
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
      jsonResponse = normalizeOptimizePayload(
        jsonResponse,
        defaultMode: 'optimize',
      );

      // Se o modo complete já veio “determinístico” (com card_id/quantity),
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

        final rawAdditionsDetailed =
            (jsonResponse['additions_detailed'] as List)
                .whereType<Map>()
                .map((m) {
                  final mm = m.cast<String, dynamic>();
                  return {
                    'card_id': mm['card_id']?.toString(),
                    'quantity': mm['quantity'] as int? ?? 1,
                  };
                })
                .where((m) => (m['card_id'] as String?)?.isNotEmpty ?? false)
                .toList();

        final ids =
            rawAdditionsDetailed.map((e) => e['card_id'] as String).toList();
        final cardInfoById = <String, Map<String, String>>{};
        var additionsDetailed = <Map<String, dynamic>>[];
        Map<String, dynamic>? postAnalysisComplete;

        if (ids.isNotEmpty) {
          final r = await pool.execute(
            Sql.named(
                'SELECT id::text, name, type_line FROM cards WHERE id = ANY(@ids)'),
            parameters: {'ids': ids},
          );
          for (final row in r) {
            cardInfoById[row[0] as String] = {
              'name': row[1] as String,
              'type_line': (row[2] as String?) ?? '',
            };
          }

          // Colapsa por NOME (não por printing/card_id), aplicando limite de cópias por formato.
          final aggregatedByName = <String, Map<String, dynamic>>{};
          for (final entry in rawAdditionsDetailed) {
            final cardId = entry['card_id'] as String;
            final cardInfo = cardInfoById[cardId];
            if (cardInfo == null) continue;

            final name = cardInfo['name'] ?? '';
            final typeLine = cardInfo['type_line'] ?? '';
            if (name.trim().isEmpty) continue;

            final maxCopies = maxCopiesForFormat(
              deckFormat: deckFormat,
              typeLine: typeLine,
              name: name,
            );

            final existing = aggregatedByName[name.toLowerCase()];
            final currentQty = (existing?['quantity'] as int?) ?? 0;
            final incomingQty = (entry['quantity'] as int?) ?? 1;
            final allowedToAdd = (maxCopies - currentQty).clamp(0, incomingQty);
            if (allowedToAdd <= 0) continue;

            if (existing == null) {
              aggregatedByName[name.toLowerCase()] = {
                'card_id': cardId,
                'quantity': allowedToAdd,
                'name': name,
                'type_line': typeLine,
              };
            } else {
              aggregatedByName[name.toLowerCase()] = {
                ...existing,
                'quantity': currentQty + allowedToAdd,
              };
            }
          }

          additionsDetailed = aggregatedByName.values
              .map((e) => {
                    'card_id': e['card_id'],
                    'quantity': e['quantity'],
                    'name': e['name'],
                    'is_basic_land':
                        isBasicLandName(((e['name'] as String?) ?? '').trim()),
                  })
              .toList();

          // === Gerar post_analysis para modo complete ===
          try {
            // 1. Buscar dados completos das cartas adicionadas
            final additionsDataResult = await pool.execute(
              Sql.named('''
              SELECT name, type_line, mana_cost, colors, 
                     COALESCE(
                       (SELECT SUM(
                         CASE 
                           WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                           WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                           WHEN m[1] = 'X' THEN 0
                           ELSE 1
                         END
                       ) FROM regexp_matches(mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
                       0
                     ) as cmc,
                     oracle_text
              FROM cards 
              WHERE id = ANY(@ids)
            '''),
              parameters: {'ids': ids},
            );

            final additionsData = additionsDataResult
                .map((row) => {
                      'name': (row[0] as String?) ?? '',
                      'type_line': (row[1] as String?) ?? '',
                      'mana_cost': (row[2] as String?) ?? '',
                      'colors': (row[3] as List?)?.cast<String>() ?? [],
                      'cmc': (row[4] as num?)?.toDouble() ?? 0.0,
                      'oracle_text': (row[5] as String?) ?? '',
                    })
                .toList();

            final additionsForAnalysis = additionsDetailed.map((add) {
              final data = additionsData.firstWhere(
                (d) =>
                    (d['name'] as String).toLowerCase() ==
                    ((add['name'] as String?) ?? '').toLowerCase(),
                orElse: () => {
                  'name': add['name'] ?? '',
                  'type_line': '',
                  'mana_cost': '',
                  'colors': <String>[],
                  'cmc': 0.0,
                  'oracle_text': '',
                },
              );
              return {
                ...data,
                'quantity': (add['quantity'] as int?) ?? 1,
              };
            }).toList();
            final virtualDeck = buildVirtualDeckForAnalysis(
              originalDeck: allCardData,
              additions: additionsForAnalysis,
            );

            // 3. Rodar análise no deck virtual
            final postAnalyzer =
                DeckArchetypeAnalyzer(virtualDeck, deckColors.toList());
            postAnalysisComplete = postAnalyzer.generateAnalysis();
          } catch (e) {
            Log.w('Falha ao gerar post_analysis para modo complete: $e');
          }
        }

        final responseBody = {
          'mode': 'complete',
          'constraints': {
            'keep_theme': keepTheme,
          },
          'theme': themeProfile.toJson(),
          'bracket': bracket,
          'target_additions': jsonResponse['target_additions'],
          'iterations': jsonResponse['iterations'],
          'additions':
              additionsDetailed.map((e) => e['name'] ?? e['card_id']).toList(),
          'additions_detailed': additionsDetailed
              .map((e) => {
                    'card_id': e['card_id'],
                    'quantity': e['quantity'],
                    'name': e['name'],
                    'is_basic_land': e['is_basic_land'] ??
                        isBasicLandName(((e['name'] as String?) ?? '').trim()),
                  })
              .toList(),
          'removals': const <String>[],
          'removals_detailed': const <Map<String, dynamic>>[],
          'reasoning': jsonResponse['reasoning'] ?? '',
          'deck_analysis': deckAnalysis,
          'post_analysis': postAnalysisComplete,
          'validation_warnings': const <String>[],
        };

        final warnings = (jsonResponse['warnings'] is Map)
            ? (jsonResponse['warnings'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        if (warnings.isNotEmpty) {
          responseBody['warnings'] = warnings;
        }

        // Incluir quality_warning para adições parciais (PARTIAL)
        final qw = jsonResponse['quality_warning'];
        if (qw is Map) {
          responseBody['quality_warning'] = qw;
        }

        // Incluir consistency_slo para diagnóstico
        final slo = jsonResponse['consistency_slo'];
        if (slo is Map) {
          responseBody['consistency_slo'] = slo;
        }

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

      final deckNamesLower = allCardData
          .map((c) => ((c['name'] as String?) ?? '').toLowerCase())
          .where((n) => n.isNotEmpty)
          .toSet();
      final commanderLower = commanders.map((c) => c.toLowerCase()).toSet();
      final coreLower =
          themeProfile.coreCards.map((c) => c.toLowerCase()).toSet();
      final blockedByTheme = <String>[];

      final isComplete = jsonResponse['mode'] == 'complete';

      if (removals.isEmpty && additions.isEmpty && !isComplete) {
        emptySuggestionFallbackTriggered = true;
        _emptySuggestionFallbackTriggeredCount++;
        final fallbackRemovalCandidates = <String>[];
        final seenLower = <String>{};

        void collectCandidates({required bool preferNonLand}) {
          for (final card in allCardData) {
            final name = ((card['name'] as String?) ?? '').trim();
            if (name.isEmpty) continue;

            final lower = name.toLowerCase();
            if (seenLower.contains(lower)) continue;
            if (commanderLower.contains(lower)) continue;
            if (coreLower.contains(lower)) continue;

            final typeLine =
                ((card['type_line'] as String?) ?? '').toLowerCase();
            final isLand = typeLine.contains('land');
            if (preferNonLand && isLand) continue;

            seenLower.add(lower);
            fallbackRemovalCandidates.add(name);
            if (fallbackRemovalCandidates.length >= 2) break;
          }
        }

        collectCandidates(preferNonLand: true);
        if (fallbackRemovalCandidates.isEmpty) {
          collectCandidates(preferNonLand: false);
        }
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
            preferredNames: optimizeCommanderPriorityNames
                .map((name) => name.toLowerCase())
                .toSet(),
          );
          emptySuggestionFallbackReplacementCount = replacements.length;

          if (replacements.isNotEmpty) {
            final fallbackAdditions = replacements
                .map((r) => (r['name'] as String?)?.trim() ?? '')
                .where((n) => n.isNotEmpty)
                .toList();

            final pairCount =
                fallbackRemovalCandidates.length < fallbackAdditions.length
                    ? fallbackRemovalCandidates.length
                    : fallbackAdditions.length;
            emptySuggestionFallbackPairCount = pairCount;

            if (pairCount > 0) {
              removals = fallbackRemovalCandidates.take(pairCount).toList();
              additions = fallbackAdditions.take(pairCount).toList();
              emptySuggestionFallbackApplied = true;
              _emptySuggestionFallbackAppliedCount++;
              emptySuggestionFallbackReason =
                  'IA retornou sugestões vazias; aplicado fallback heurístico orientado a sinergia.';
              Log.i(
                  '✅ [AI Optimize] Fallback aplicado com $pairCount swap(s) após retorno vazio da IA.');
            }
          }
        }

        if (!emptySuggestionFallbackApplied) {
          if (fallbackRemovalCandidates.isEmpty) {
            _emptySuggestionFallbackNoCandidateCount++;
            emptySuggestionFallbackReason =
                'IA retornou sugestões vazias e o deck não possui candidatas seguras para remoção.';
          } else if (emptySuggestionFallbackReplacementCount == 0) {
            _emptySuggestionFallbackNoReplacementCount++;
            emptySuggestionFallbackReason =
                'IA retornou sugestões vazias e não foi possível encontrar substitutas válidas no fallback.';
          } else {
            emptySuggestionFallbackReason =
                'IA retornou sugestões vazias e não foi possível gerar fallback seguro.';
          }
        }
      }

      // WARN: Se parsing resultou em listas vazias, logar para diagnóstico
      if (removals.isEmpty && additions.isEmpty && !isComplete) {
        if (recognizedSuggestionFormat) {
          Log.d(
              'ℹ️ [AI Optimize] Payload reconhecido, mas sem sugestões úteis (provável filtro/retorno vazio). Keys: ${jsonResponse.keys.toList()}');
        } else {
          Log.w(
              '⚠️ [AI Optimize] IA retornou formato não reconhecido. Keys: ${jsonResponse.keys.toList()}');
        }
      }

      // Suporte ao modo "complete"
      if (isComplete) {
        removals = [];
        // Quando veio do loop, preferimos additions_detailed.
        final fromDetailed = (jsonResponse['additions_detailed'] as List?)
            ?.whereType<Map>()
            .toList();
        if (fromDetailed != null && fromDetailed.isNotEmpty) {
          additions = fromDetailed
              .map((m) => (m['name'] ?? '').toString())
              .where((s) => s.trim().isNotEmpty)
              .toList();
        } else {
          additions =
              (jsonResponse['additions'] as List?)?.cast<String>() ?? [];
        }
      }

      // GARANTIR EQUILÍBRIO NUMÉRICO (Regra de Ouro)
      if (!isComplete) {
        final minCount = removals.length < additions.length
            ? removals.length
            : additions.length;

        if (removals.length != additions.length) {
          Log.w(
            '⚠️ [AI Optimize] Ajustando desequilíbrio: -${removals.length} / +${additions.length} -> $minCount',
          );
          removals = removals.take(minCount).toList();
          additions = additions.take(minCount).toList();
        }
      }

      var sanitizedRemovals =
          removals.map(CardValidationService.sanitizeCardName).toList();
      var sanitizedAdditions =
          additions.map(CardValidationService.sanitizeCardName).toList();

      // Remoções devem existir no deck (evita no-ops e contagem final errada).
      sanitizedRemovals = sanitizedRemovals
          .where((n) => deckNamesLower.contains(n.toLowerCase()))
          .toList();

      // Nunca remover comandantes.
      sanitizedRemovals = sanitizedRemovals
          .where((n) => !commanderLower.contains(n.toLowerCase()))
          .toList();

      // Se o usuário pediu "otimizar", mas mantendo o tema, bloqueia remoções de core.
      if (keepTheme) {
        sanitizedRemovals = sanitizedRemovals.where((n) {
          final isCore = coreLower.contains(n.toLowerCase());
          if (isCore) blockedByTheme.add(n);
          return !isCore;
        }).toList();
      }

      // Em modo optimize (swaps), evita sugerir adicionar algo que já existe (no-op).
      if (!isComplete) {
        sanitizedAdditions = sanitizedAdditions
            .where((n) => !deckNamesLower.contains(n.toLowerCase()))
            .toList();
      }

      // Re-balancear após filtros.
      if (!isComplete) {
        final minCount = sanitizedRemovals.length < sanitizedAdditions.length
            ? sanitizedRemovals.length
            : sanitizedAdditions.length;
        sanitizedRemovals = sanitizedRemovals.take(minCount).toList();
        sanitizedAdditions = sanitizedAdditions.take(minCount).toList();
      }

      // Validar todas as cartas sugeridas
      final allSuggestions = [...sanitizedRemovals, ...sanitizedAdditions];
      final validation =
          await validationService.validateCardNames(allSuggestions);
      final validList =
          (validation['valid'] as List).cast<Map<String, dynamic>>();
      final validByNameLower = <String, Map<String, dynamic>>{};
      for (final v in validList) {
        final n = (v['name'] as String).toLowerCase();
        validByNameLower[n] = v;
      }

      // Filtrar apenas cartas válidas e remover duplicatas
      var validRemovals = sanitizedRemovals
          .where((name) {
            return (validation['valid'] as List).any((card) =>
                (card['name'] as String).toLowerCase() == name.toLowerCase());
          })
          .toSet()
          .toList();

      // No modo complete, preservamos repetição (para básicos) e ordem.
      // No modo optimize (swaps), mantemos set para evitar duplicatas.
      var validAdditions = sanitizedAdditions.where((name) {
        return (validation['valid'] as List).any((card) =>
            (card['name'] as String).toLowerCase() == name.toLowerCase());
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
          final colorIdentity =
              (row[1] as List?)?.cast<String>() ?? const <String>[];
          final colors = (row[2] as List?)?.cast<String>() ?? const <String>[];
          final oracleText = row[3] as String? ?? '';
          identityByName[name] = resolvedCardIdentityFromParts(
            colorIdentity: colorIdentity,
            colors: colors,
            oracleText: oracleText,
          ).toList();
        }

        validAdditions = validAdditions.where((name) {
          final identity =
              identityByName[name.toLowerCase()] ?? const <String>[];
          final ok = isWithinCommanderIdentity(
            cardIdentity: identity,
            commanderIdentity: commanderColorIdentity,
          );
          if (!ok) filteredByColorIdentity.add(name);
          return ok;
        }).toList();
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
        final additionsInfo = additionsInfoResult
            .map((r) => {
                  'name': r[0] as String,
                  'type_line': r[1] as String? ?? '',
                  'oracle_text': r[2] as String? ?? '',
                  'quantity': 1,
                })
            .toList();

        final decision = applyBracketPolicyToAdditions(
          bracket: bracket,
          currentDeckCards: allCardData,
          additionsCardsData: additionsInfo,
        );

        blockedByBracket.addAll(decision.blocked);
        // Modo complete pode conter repetição; para a decisão, usamos os nomes únicos do "allowed"
        // e depois re-aplicamos mantendo repetição quando possível.
        final allowedSet = decision.allowed.map((e) => e.toLowerCase()).toSet();
        validAdditions = validAdditions
            .where((n) => allowedSet.contains(n.toLowerCase()))
            .toList();
      }

      // Top-up determinístico no modo complete:
      // se depois de validações/filtros ainda faltarem cartas para atingir o target, completa com básicos.
      final additionsDetailed = <Map<String, dynamic>>[];
      if (isComplete) {
        final targetAdditions = (jsonResponse['target_additions'] as int?) ?? 0;
        final desired =
            targetAdditions > 0 ? targetAdditions : validAdditions.length;

        // Agrega as adições atuais por nome (quantidade 1 por ocorrência)
        final countsByName = <String, int>{};
        final basicNamesLower =
            basicLandNamesForIdentity(commanderColorIdentity)
                .map((e) => e.toLowerCase())
                .toSet();
        for (final n in validAdditions) {
          final lower = n.toLowerCase();
          final current = countsByName[n] ?? 0;
          final isBasic = basicNamesLower.contains(lower) || lower == 'wastes';
          if (!isBasic &&
              (deckFormat.toLowerCase() == 'commander' ||
                  deckFormat.toLowerCase() == 'brawl') &&
              current >= 1) {
            continue;
          }
          countsByName[n] = current + 1;
        }

        // Se faltar, adiciona básicos para preencher
        var missing =
            desired - countsByName.values.fold<int>(0, (a, b) => a + b);
        Map<String, String> basicsWithIds = const {};
        if (missing > 0) {
          final basicNames = basicLandNamesForIdentity(commanderColorIdentity);
          basicsWithIds = await loadBasicLandIds(pool, basicNames);

          if (basicsWithIds.isNotEmpty) {
            final keys = basicsWithIds.keys.toList();
            var i = 0;
            while (missing > 0) {
              final name = keys[i % keys.length];
              countsByName[name] = (countsByName[name] ?? 0) + 1;
              missing--;
              i++;
            }
          }
        }

        // Converte para additions_detailed com card_id/quantity
        for (final entry in countsByName.entries) {
          final v = validByNameLower[entry.key.toLowerCase()];
          final id =
              v?['id']?.toString() ?? basicsWithIds[entry.key]?.toString();
          final name = v?['name']?.toString() ?? entry.key;
          if (id == null || id.isEmpty) continue;
          additionsDetailed.add({
            'name': name,
            'card_id': id,
            'quantity': entry.value,
          });
        }

        // Mantém additions como lista simples (única) para UI; o app aplica via additions_detailed.
        validAdditions =
            additionsDetailed.map((e) => e['name'] as String).toList();
      }

      // Re-aplicar equilíbrio após validação
      // FILOSOFIA: Quando additions < removals, a IA deve SUGERIR NOVAS CARTAS
      // de sinergia — NÃO preencher com lands genéricos. O propósito é OTIMIZAR.

      // ═══════════════════════════════════════════════════════════
      // PROTEÇÃO DE TERRENOS (sync optimize): impedir remoção de lands quando
      // o deck já tem poucos terrenos. Sem isso, um deck com 24 lands pode ficar com 20.
      // ═══════════════════════════════════════════════════════════
      if (!isComplete) {
        final currentLandCount = allCardData.fold<int>(0, (sum, c) {
          final type = ((c['type_line'] as String?) ?? '').toLowerCase();
          if (!type.contains('land')) return sum;
          return sum + ((c['quantity'] as int?) ?? 1);
        });
        const minSafeLands = 28;

        if (currentLandCount <= minSafeLands + 3) {
          // Bloquear remoções de terrenos
          final landRemovalsBefore = validRemovals.length;
          final landNamesInDeck = <String, String>{};
          for (final card in allCardData) {
            final type = ((card['type_line'] as String?) ?? '').toLowerCase();
            if (type.contains('land')) {
              landNamesInDeck[((card['name'] as String?) ?? '').toLowerCase()] =
                  (card['type_line'] as String?) ?? '';
            }
          }

          validRemovals = validRemovals.where((name) {
            return !landNamesInDeck.containsKey(name.toLowerCase());
          }).toList();

          final landBlockedCount = landRemovalsBefore - validRemovals.length;
          if (landBlockedCount > 0) {
            Log.d(
                '⛔ Land protection: bloqueou $landBlockedCount remoções de terrenos (deck tem $currentLandCount lands, mínimo seguro=$minSafeLands)');
          }
        }
      }

      if (!isComplete && validRemovals.length != validAdditions.length) {
        Log.d('Re-balanceamento pós-filtros:');
        Log.d(
            '  Antes: removals=${validRemovals.length}, additions=${validAdditions.length}');

        if (validAdditions.length < validRemovals.length) {
          // CORREÇÃO REAL: Re-consultar a IA para cartas substitutas
          final missingCount = validRemovals.length - validAdditions.length;
          Log.d(
              '  Faltam $missingCount adições - consultando IA para substitutas sinérgicas');

          // Montar lista de cartas a excluir (já existentes + já sugeridas + filtradas)
          final excludeNames = <String>{
            ...deckNamesLower,
            ...validAdditions.map((n) => n.toLowerCase()),
            ...filteredByColorIdentity.map((n) => n.toLowerCase()),
          };

          // Categorias das cartas removidas para pedir substitutas do mesmo tipo funcional
          final removedButUnmatched =
              validRemovals.sublist(validAdditions.length);

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
              missingCount: missingCount,
              removedCards: removedButUnmatched,
              excludeNames: excludeNames,
              allCardData: allCardData,
              preferredNames: optimizeCommanderPriorityNames
                  .map((name) => name.toLowerCase())
                  .toSet(),
            );

            if (replacementResult.isNotEmpty) {
              for (final replacement in replacementResult) {
                final name = replacement['name'] as String;
                final id = replacement['id'] as String;
                validAdditions.add(name);
                validByNameLower[name.toLowerCase()] = {
                  'id': id,
                  'name': name,
                };
              }
              Log.d(
                  '  IA sugeriu ${replacementResult.length} substitutas sinérgicas');
            }

            // Se AINDA faltar (IA não conseguiu preencher tudo), TRUNCAR remoções
            // para manter equilíbrio. NÃO preencher com básicos em modo optimize —
            // trocar spells por lands é degradação, não otimização.
            if (validAdditions.length < validRemovals.length) {
              final stillMissing = validRemovals.length - validAdditions.length;
              Log.d(
                  '  Ainda faltam $stillMissing - truncando remoções (não preencher com básicos em optimize)');
              validRemovals =
                  validRemovals.take(validAdditions.length).toList();
            }
          } catch (e) {
            Log.w('Falha ao buscar substitutas IA: $e - usando fallback');
            // Fallback: truncar remoções para não perder cartas
            validRemovals = validRemovals.take(validAdditions.length).toList();
          }
        } else {
          // Mais adições que remoções: truncar adições
          validAdditions = validAdditions.take(validRemovals.length).toList();
        }

        Log.d(
            '  Depois: removals=${validRemovals.length}, additions=${validAdditions.length}');
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
      // Simular o deck como ficaria se as mudanças fossem aplicadas e re-analisar
      Map<String, dynamic>? postAnalysis;
      List<String> validationWarnings = [];

      // ═══════════════════════════════════════════════════════════
      // VALIDAÇÃO PÓS-PROCESSAMENTO: Color Identity + EDHREC + Tema
      // ═══════════════════════════════════════════════════════════

      // 1. Color Identity Warning (se IA sugeriu cartas inválidas)
      if (filteredByColorIdentity.isNotEmpty) {
        validationWarnings.add(
            '⚠️ ${filteredByColorIdentity.length} carta(s) sugerida(s) pela IA foram removidas por violar a identidade de cor do commander: ${filteredByColorIdentity.take(3).join(", ")}${filteredByColorIdentity.length > 3 ? "..." : ""}');
      }

      // 2. Validação EDHREC: verificar se additions têm sinergia comprovada
      EdhrecCommanderData? edhrecValidationData;
      List<String> additionsNotInEdhrec = [];
      if (commanders.isNotEmpty && validAdditions.isNotEmpty) {
        try {
          final edhrecService = optimizer.edhrecService;
          edhrecValidationData = await edhrecService
              .fetchCommanderData(commanders.firstOrNull ?? "");

          if (edhrecValidationData != null &&
              edhrecValidationData.topCards.isNotEmpty) {
            for (final addition in validAdditions) {
              final card = edhrecValidationData.findCard(addition);
              if (card == null) {
                additionsNotInEdhrec.add(addition);
              }
            }

            if (additionsNotInEdhrec.isNotEmpty) {
              final percent =
                  (additionsNotInEdhrec.length / validAdditions.length * 100)
                      .toStringAsFixed(0);
              if (additionsNotInEdhrec.length > validAdditions.length * 0.5) {
                validationWarnings.add(
                    '⚠️ ${additionsNotInEdhrec.length} ($percent%) das cartas sugeridas NÃO aparecem nos dados EDHREC de ${commanders.firstOrNull ?? ""}. Isso pode indicar baixa sinergia: ${additionsNotInEdhrec.take(3).join(", ")}${additionsNotInEdhrec.length > 3 ? "..." : ""}');
              } else if (additionsNotInEdhrec.length >= 3) {
                validationWarnings.add(
                    '💡 ${additionsNotInEdhrec.length} carta(s) sugerida(s) não estão nos dados EDHREC - podem ser inovadoras ou de baixa sinergia.');
              }
            }
          }
        } catch (e) {
          Log.w('EDHREC validation failed (non-blocking): $e');
        }
      }

      // 3. Comparação de Tema: verificar se tema detectado corresponde aos temas EDHREC
      if (edhrecValidationData != null &&
          edhrecValidationData.themes.isNotEmpty) {
        final detectedThemeLower = targetArchetype.toLowerCase();
        final edhrecThemesLower =
            edhrecValidationData.themes.map((t) => t.toLowerCase()).toList();

        // Verificar se o tema detectado tem correspondência nos temas EDHREC
        bool themeMatch = false;
        for (final edhrecTheme in edhrecThemesLower) {
          if (detectedThemeLower.contains(edhrecTheme) ||
              edhrecTheme.contains(detectedThemeLower)) {
            themeMatch = true;
            break;
          }
        }

        if (!themeMatch) {
          validationWarnings.add(
              '� Tema detectado "$targetArchetype" não corresponde aos temas populares do EDHREC (${edhrecValidationData.themes.take(3).join(", ")}). O sistema está usando abordagem HÍBRIDA: 70% cartas EDHREC + 30% cartas do seu tema para respeitar sua ideia.');
        }
      }

      ValidationReport? optimizationValidationReport;
      final qualityGateWarnings = <String>[];

      if (validAdditions.isNotEmpty) {
        try {
          // 1. Buscar dados completos das cartas sugeridas (para análise de mana/tipo)
          // Usar nomes corretos do DB (via validByNameLower) para evitar problemas de case
          final correctedAdditionNames = validAdditions.map((n) {
            final v = validByNameLower[n.toLowerCase()];
            return (v?['name'] as String?) ?? n;
          }).toList();
          final additionsDataResult = await pool.execute(
            Sql.named('''
              SELECT DISTINCT ON (LOWER(name))
                     name, type_line, mana_cost, colors, 
                     COALESCE(
                       (SELECT SUM(
                         CASE 
                           WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                           WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                           WHEN m[1] = 'X' THEN 0
                           ELSE 1
                         END
                       ) FROM regexp_matches(mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
                       0
                     ) as cmc,
                     oracle_text
              FROM cards 
              WHERE LOWER(name) = ANY(@names)
              ORDER BY LOWER(name), name
            '''),
            parameters: {
              'names':
                  correctedAdditionNames.map((n) => n.toLowerCase()).toList()
            },
          );

          var additionsData = additionsDataResult
              .map((row) => {
                    'name': (row[0] as String?) ?? '',
                    'type_line': (row[1] as String?) ?? '',
                    'mana_cost': (row[2] as String?) ?? '',
                    'colors': (row[3] as List?)?.cast<String>() ?? [],
                    'cmc': (row[4] as num?)?.toDouble() ?? 0.0,
                    'oracle_text': (row[5] as String?) ?? '',
                  })
              .toList();

          if (!isComplete) {
            final gateResult = filterUnsafeOptimizeSwapsByCardData(
              removals: validRemovals,
              additions: validAdditions,
              originalDeck: allCardData,
              additionsData: additionsData,
              archetype: effectiveOptimizeArchetype,
            );

            if (gateResult.changed) {
              validRemovals = gateResult.removals;
              validAdditions = gateResult.additions;
              qualityGateWarnings.add(
                '🔒 Gate de qualidade removeu ${gateResult.droppedReasons.length} troca(s) insegura(s) antes da resposta final.',
              );
              qualityGateWarnings.addAll(
                gateResult.droppedReasons.map((reason) => '🔒 $reason'),
              );

              final safeAdditionNames =
                  validAdditions.map((name) => name.toLowerCase()).toSet();
              additionsData = additionsData.where((card) {
                final name = (card['name'] as String?)?.toLowerCase() ?? '';
                return safeAdditionNames.contains(name);
              }).toList();
            }

            if (validRemovals.isEmpty || validAdditions.isEmpty) {
              if (shouldRetryOptimizeWithAiFallback(
                deterministicFirstEnabled: deterministicFirstEnabled,
                fallbackAlreadyAttempted: optimizeFallbackAttempted,
                strategySource: jsonResponse['strategy_source']?.toString(),
                qualityErrorCode: 'OPTIMIZE_NO_SAFE_SWAPS',
                isComplete: isComplete,
              )) {
                optimizeFallbackAttempted = true;
                final aiFallbackResponse = await runAiOptimizeAttempt(
                  trigger: 'deterministic_rejected_no_safe_swaps',
                );
                if (aiFallbackResponse != null) {
                  Log.i(
                    'Deterministic-first caiu em NO_SAFE_SWAPS; reexecutando optimize via IA.',
                  );
                  jsonResponse = aiFallbackResponse;
                  continue optimizeAttemptLoop;
                }
              }

              return respondWithOptimizeTelemetry(
                statusCode: HttpStatus.unprocessableEntity,
                body: {
                  'error':
                      'Nenhuma troca segura restou apos o gate de qualidade da otimizacao.',
                  'quality_error': {
                    'code': 'OPTIMIZE_NO_SAFE_SWAPS',
                    'message':
                        'As trocas sugeridas pioravam funcao, curva ou consistencia do deck.',
                    'dropped_swaps': qualityGateWarnings,
                  },
                  'mode': 'optimize',
                  'removals': validRemovals,
                  'additions': validAdditions,
                },
                removalsOverride: validRemovals,
                additionsOverride: validAdditions,
                validationWarningsOverride: qualityGateWarnings,
                blockedByColorIdentityOverride: filteredByColorIdentity,
                blockedByBracketOverride: blockedByBracket,
              );
            }
          }

          final additionsForAnalysis = buildOptimizeAdditionEntries(
            requestedAdditions: validAdditions,
            additionsData: additionsData,
          );
          final virtualDeck = buildVirtualDeckForAnalysis(
            originalDeck: allCardData,
            removals: validRemovals,
            additions: additionsForAnalysis,
          );

          // 3. Rodar Análise no Deck Virtual
          final postAnalyzer =
              DeckArchetypeAnalyzer(virtualDeck, deckColors.toList());
          postAnalysis = postAnalyzer.generateAnalysis();

          // 4. Comparar Antes vs Depois — VALIDAÇÃO QUALITATIVA REAL
          final preManaAssessment =
              deckAnalysis['mana_base_assessment'] as String? ?? '';
          final postManaAssessment =
              postAnalysis['mana_base_assessment'] as String? ?? '';
          final preManaIssues = preManaAssessment.contains('Falta mana');
          final postManaIssues = postManaAssessment.contains('Falta mana');

          if (!preManaIssues && postManaIssues) {
            validationWarnings.add(
                '⚠️ ATENÇÃO: As sugestões da IA podem piorar sua base de mana.');
          }

          final preAvgCmc = deckAnalysis['average_cmc'] as String? ?? '0';
          final postAvgCmc = postAnalysis['average_cmc'] as String? ?? '0';
          final preCurve = double.tryParse(preAvgCmc) ?? 0.0;
          final postCurve = double.tryParse(postAvgCmc) ?? 0.0;

          if (effectiveOptimizeArchetype.toLowerCase() == 'aggro' &&
              postCurve > preCurve) {
            validationWarnings.add(
                '⚠️ ATENÇÃO: O deck está ficando mais lento (CMC aumentou), o que é ruim para Aggro.');
          }

          // 5. ANÁLISE DE QUALIDADE DAS TROCAS (Power Level Assessment)
          final preTypes =
              deckAnalysis['type_distribution'] as Map<String, dynamic>? ?? {};
          final postTypes =
              postAnalysis['type_distribution'] as Map<String, dynamic>? ?? {};

          // Verificar se a otimização não desbalanceou a distribuição de tipos
          final preLands = (preTypes['lands'] as int?) ?? 0;
          final postLands = (postTypes['lands'] as int?) ?? 0;
          if (postLands < preLands - 3) {
            validationWarnings.add(
                '⚠️ A otimização removeu muitos terrenos ($preLands → $postLands). Isso pode causar problemas de mana.');
          }

          // Verificar se a curva melhorou para o arquétipo
          if (effectiveOptimizeArchetype.toLowerCase() == 'control' &&
              postCurve < preCurve - 0.5) {
            validationWarnings.add(
                '💡 O CMC médio diminuiu significativamente ($preAvgCmc → $postAvgCmc). Para Control, isso pode remover respostas de custo alto que são importantes.');
          }

          // Gerar resumo de melhoria
          final improvements = <String>[];
          if (postCurve < preCurve &&
              effectiveOptimizeArchetype.toLowerCase() != 'control') {
            improvements.add('CMC médio otimizado: $preAvgCmc → $postAvgCmc');
          }
          if (preManaIssues && !postManaIssues) {
            improvements.add('Base de mana corrigida');
          }
          if ((postTypes['instants'] as int? ?? 0) >
              (preTypes['instants'] as int? ?? 0)) {
            improvements.add('Mais interação instant-speed adicionada');
          }

          if (improvements.isNotEmpty) {
            postAnalysis['improvements'] = improvements;
          }

          // ═══════════════════════════════════════════════════════════
          // 6. VALIDAÇÃO AUTOMÁTICA (Monte Carlo + Funcional + Critic IA)
          // ═══════════════════════════════════════════════════════════
          try {
            final validator = OptimizationValidator(openAiKey: apiKey);
            final validationReport = await validator.validate(
              originalDeck: allCardData,
              optimizedDeck: virtualDeck,
              removals: validRemovals,
              additions: validAdditions,
              commanders: commanders,
              archetype: effectiveOptimizeArchetype,
            );

            postAnalysis['validation'] = validationReport.toJson();
            optimizationValidationReport = validationReport;

            // Adicionar warnings do validador
            for (final w in validationReport.warnings) {
              validationWarnings.add(w);
            }

            // Se reprovado, alertar
            if (validationReport.verdict == 'reprovado') {
              validationWarnings.insert(0,
                  '🚫 VALIDAÇÃO: As trocas sugeridas NÃO passaram na validação automática (score: ${validationReport.score}/100).');
            }

            Log.d(
                'Validation score: ${validationReport.score}/100 verdict: ${validationReport.verdict}');
          } catch (validationError) {
            Log.e('Validation failed: $validationError');
            return respondWithOptimizeTelemetry(
              statusCode: HttpStatus.internalServerError,
              body: {
                'error':
                    'Falha interna ao validar a qualidade final da otimizacao.',
                'quality_error': {
                  'code': 'OPTIMIZE_VALIDATION_FAILED',
                  'message':
                      'A validacao automatica da otimizacao falhou. A resposta foi bloqueada para evitar retornar um resultado nao verificado.',
                  'details': '$validationError',
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
          Log.e('Erro na verificação pós-otimização: $e');
          return respondWithOptimizeTelemetry(
            statusCode: HttpStatus.internalServerError,
            body: {
              'error':
                  'Falha interna durante a verificacao final da otimizacao.',
              'quality_error': {
                'code': 'OPTIMIZE_POST_ANALYSIS_FAILED',
                'message':
                    'A verificacao final falhou e a resposta foi bloqueada para evitar retornar uma otimizacao sem checagem completa.',
                'details': '$e',
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

      if (!isComplete && optimizationValidationReport != null) {
        final postAnalysisMap = postAnalysis ?? const <String, dynamic>{};
        final rejectionReasons = buildOptimizationRejectionReasons(
          validationReport: optimizationValidationReport,
          archetype: effectiveOptimizeArchetype,
          preCurve:
              double.tryParse('${deckAnalysis['average_cmc'] ?? '0'}') ?? 0.0,
          postCurve:
              double.tryParse('${postAnalysisMap['average_cmc'] ?? '0'}') ??
                  0.0,
          preManaAssessment:
              deckAnalysis['mana_base_assessment']?.toString() ?? '',
          postManaAssessment:
              postAnalysisMap['mana_base_assessment']?.toString() ?? '',
        );
        final hardQualityRejected =
            optimizationValidationReport.verdict != 'aprovado';
        final effectiveRejectionReasons = rejectionReasons.isNotEmpty
            ? rejectionReasons
            : (hardQualityRejected
                ? <String>[
                    'A validação final não fechou como "aprovado" (score ${optimizationValidationReport.score}/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.',
                  ]
                : const <String>[]);

        if (hardQualityRejected || effectiveRejectionReasons.isNotEmpty) {
          if (shouldRetryOptimizeWithAiFallback(
            deterministicFirstEnabled: deterministicFirstEnabled,
            fallbackAlreadyAttempted: optimizeFallbackAttempted,
            strategySource: jsonResponse['strategy_source']?.toString(),
            qualityErrorCode: 'OPTIMIZE_QUALITY_REJECTED',
            isComplete: isComplete,
          )) {
            optimizeFallbackAttempted = true;
            final aiFallbackResponse = await runAiOptimizeAttempt(
              trigger: 'deterministic_rejected_quality_gate',
            );
            if (aiFallbackResponse != null) {
              Log.i(
                'Deterministic-first caiu no gate final de qualidade; reexecutando optimize via IA.',
              );
              jsonResponse = aiFallbackResponse;
              continue optimizeAttemptLoop;
            }
          }

          return respondWithOptimizeTelemetry(
            statusCode: HttpStatus.unprocessableEntity,
            body: {
              'error':
                  'A otimizacao sugerida nao passou no gate final de qualidade.',
              'quality_error': {
                'code': 'OPTIMIZE_QUALITY_REJECTED',
                'message':
                    'As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.',
                'reasons': effectiveRejectionReasons,
                'validation': optimizationValidationReport.toJson(),
              },
              'mode': 'optimize',
              'removals': validRemovals,
              'additions': validAdditions,
              'deck_analysis': deckAnalysis,
              'post_analysis': postAnalysis,
              'validation_warnings': validationWarnings,
            },
            postAnalysisOverride: postAnalysis,
            validationReport: optimizationValidationReport,
            removalsOverride: validRemovals,
            additionsOverride: validAdditions,
            validationWarningsOverride: validationWarnings,
            blockedByColorIdentityOverride: filteredByColorIdentity,
            blockedByBracketOverride: blockedByBracket,
          );
        }
      }

      final responseValidationJson =
          (postAnalysis?['validation'] as Map?)?.cast<String, dynamic>();
      if (!isComplete && responseValidationJson != null) {
        final responseValidationScore =
            (responseValidationJson['validation_score'] as num?)?.toInt() ?? 0;
        final responseValidationVerdict =
            responseValidationJson['verdict']?.toString() ?? '';

        if (responseValidationVerdict != 'aprovado') {
          final serializedValidationReasons = optimizationValidationReport !=
                  null
              ? buildOptimizationRejectionReasons(
                  validationReport: optimizationValidationReport,
                  archetype: effectiveOptimizeArchetype,
                  preCurve: double.tryParse(
                        '${deckAnalysis['average_cmc'] ?? '0'}',
                      ) ??
                      0.0,
                  postCurve: double.tryParse(
                          '${postAnalysis?['average_cmc'] ?? '0'}') ??
                      0.0,
                  preManaAssessment:
                      deckAnalysis['mana_base_assessment']?.toString() ?? '',
                  postManaAssessment:
                      postAnalysis?['mana_base_assessment']?.toString() ?? '',
                )
              : <String>[
                  'A validação final não fechou como "aprovado" (score $responseValidationScore/100). Optimize só retorna sucesso quando a melhoria é aprovada sem ressalvas.',
                ];

          return respondWithOptimizeTelemetry(
            statusCode: HttpStatus.unprocessableEntity,
            body: {
              'error':
                  'A otimizacao sugerida nao passou no gate final de qualidade.',
              'quality_error': {
                'code': 'OPTIMIZE_QUALITY_REJECTED',
                'message':
                    'As trocas foram recusadas porque degradam funcoes criticas ou nao atingem qualidade minima.',
                'reasons': serializedValidationReasons,
                'validation': responseValidationJson,
              },
              'mode': 'optimize',
              'removals': validRemovals,
              'additions': validAdditions,
              'deck_analysis': deckAnalysis,
              'post_analysis': postAnalysis,
              'validation_warnings': validationWarnings,
            },
            postAnalysisOverride: postAnalysis,
            validationReport: optimizationValidationReport,
            removalsOverride: validRemovals,
            additionsOverride: validAdditions,
            validationWarningsOverride: validationWarnings,
            blockedByColorIdentityOverride: filteredByColorIdentity,
            blockedByBracketOverride: blockedByBracket,
          );
        }
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
          noCandidate: emptySuggestionFallbackTriggered &&
              emptySuggestionFallbackCandidateCount == 0,
          noReplacement: emptySuggestionFallbackTriggered &&
              emptySuggestionFallbackCandidateCount > 0 &&
              emptySuggestionFallbackReplacementCount == 0,
          candidateCount: emptySuggestionFallbackCandidateCount,
          replacementCount: emptySuggestionFallbackReplacementCount,
          pairCount: emptySuggestionFallbackPairCount,
        );
        persistedFallbackAggregate =
            await loadPersistedEmptyFallbackAggregate(pool);
      } catch (e) {
        Log.w('Persisted fallback telemetry unavailable: $e');
      }

      final preCmc =
          double.tryParse('${deckAnalysis['average_cmc'] ?? '0'}') ?? 0.0;
      final postCmc = postAnalysis == null
          ? preCmc
          : (double.tryParse('${postAnalysis['average_cmc'] ?? preCmc}') ??
              preCmc);

      final responseBody = {
        'mode': jsonResponse['mode'],
        'strategy_source': jsonResponse['strategy_source'] ??
            (deterministicFirstEnabled ? 'deterministic_first' : 'ai_primary'),
        if (jsonResponse['fallback_trigger'] != null)
          'fallback_trigger': jsonResponse['fallback_trigger'],
        'constraints': {
          'keep_theme': keepTheme,
        },
        'cache': {
          'hit': false,
          'cache_key': cacheKey,
        },
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
        'optimize_diagnostics': {
          'empty_suggestions_fallback': {
            'triggered': emptySuggestionFallbackTriggered,
            'applied': emptySuggestionFallbackApplied,
            'candidate_count': emptySuggestionFallbackCandidateCount,
            'replacement_count': emptySuggestionFallbackReplacementCount,
            'pair_count': emptySuggestionFallbackPairCount,
          },
          'empty_suggestions_fallback_aggregate':
              _buildEmptyFallbackAggregate(),
          if (persistedFallbackAggregate != null)
            'empty_suggestions_fallback_aggregate_persisted':
                persistedFallbackAggregate,
        },
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
      responseBody['additions_detailed'] = isComplete
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
                );
              })
              .where((e) => e != null)
              .toList();

      // Gerar removals_detailed apenas para cartas com card_id válido
      responseBody['removals_detailed'] = validRemovals
          .map((name) {
            final v = validByNameLower[name.toLowerCase()];
            if (v == null || v['id'] == null) return null;
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
            );
          })
          .where((e) => e != null)
          .toList();

      responseBody['recommendations'] = [
        ...(responseBody['removals_detailed'] as List),
        ...(responseBody['additions_detailed'] as List),
      ];

      // CRÍTICO: Balancear additions/removals detailed para manter contagem igual
      final addDet = responseBody['additions_detailed'] as List;
      final remDet = responseBody['removals_detailed'] as List;

      // DEBUG: Log detalhado para rastrear desbalanceamentos
      Log.d('Balanceamento final:');
      Log.d('  validAdditions.length = ${validAdditions.length}');
      Log.d('  validRemovals.length = ${validRemovals.length}');
      Log.d('  additions_detailed.length = ${addDet.length}');
      Log.d('  removals_detailed.length = ${remDet.length}');
      Log.d('  mode = ${jsonResponse['mode']}');

      // Verificar cartas que NÃO foram mapeadas para card_id
      if (addDet.length != validAdditions.length) {
        Log.w('Algumas adições não foram mapeadas para card_id!');
        for (final name in validAdditions) {
          final v = validByNameLower[name.toLowerCase()];
          if (v == null || v['id'] == null) {
            Log.w(
                '  Carta sem card_id: "$name" (key: "${name.toLowerCase()}")');
          }
        }
      }

      // BALANCEAMENTO FINAL (detailed) - Agora as listas já devem estar equilibradas
      // pós re-chamada à IA. Este bloco só age se o detailed ainda tiver gap.
      if (addDet.length < remDet.length && !isComplete) {
        final missingDetailed = remDet.length - addDet.length;
        Log.d(
            '  Gap em detailed: faltam $missingDetailed - construindo de validAdditions');

        // Tentar construir detailed para adições que ainda não estão nele
        final existingNames = addDet
            .map((e) => (e as Map)['name']?.toString().toLowerCase() ?? '')
            .toSet();
        final newDetailed = <Map<String, dynamic>>[];
        for (final name in validAdditions) {
          if (existingNames.contains(name.toLowerCase())) continue;
          final v = validByNameLower[name.toLowerCase()];
          if (v != null && v['id'] != null) {
            newDetailed.add({
              'name': v['name'] ?? name,
              'card_id': v['id'],
              'quantity': 1,
            });
            existingNames.add(name.toLowerCase());
          }
        }
        if (newDetailed.isNotEmpty) {
          responseBody['additions_detailed'] = [...addDet, ...newDetailed];
        }

        // Se AINDA faltar, truncar remoções como último recurso
        final finalAddDet2 = responseBody['additions_detailed'] as List;
        if (finalAddDet2.length < remDet.length) {
          responseBody['removals_detailed'] =
              remDet.take(finalAddDet2.length).toList();
          responseBody['removals'] =
              validRemovals.take(finalAddDet2.length).toList();
        }
      } else if (addDet.length > remDet.length && !isComplete) {
        Log.d('  Truncando adições extras');
        responseBody['additions_detailed'] =
            addDet.take(remDet.length).toList();
        responseBody['additions'] = validAdditions.take(remDet.length).toList();
      }

      // Log final
      final finalAddDet = responseBody['additions_detailed'] as List;
      final finalRemDet = responseBody['removals_detailed'] as List;
      Log.d(
          '  Final: additions_detailed=${finalAddDet.length}, removals_detailed=${finalRemDet.length}');

      // ═══════════════════════════════════════════════════════════
      // VALIDAÇÃO FINAL: Garantir integridade do deck resultante
      // ═══════════════════════════════════════════════════════════
      if (!isComplete) {
        // 1. Verificar que nenhuma adição é de carta que já existe no deck (exceto basics em formatos não-Commander)
        final additionsDetailedFinal =
            responseBody['additions_detailed'] as List;
        final removalsDetailedFinal = responseBody['removals_detailed'] as List;
        final removalNamesFinal = removalsDetailedFinal
            .whereType<Map>()
            .map((e) => (e['name']?.toString() ?? '').toLowerCase())
            .where((n) => n.isNotEmpty)
            .toSet();

        final filteredAdditions = <dynamic>[];
        final filteredAdditionNames = <String>[];
        final filteredRemovalsToKeep = <dynamic>[];
        final filteredRemovalNames = <String>[];

        for (final add in additionsDetailedFinal) {
          if (add is! Map) continue;
          final name = (add['name']?.toString() ?? '').toLowerCase();
          if (name.isEmpty) continue;

          final isBasic = isBasicLandName(name);
          final alreadyInDeck = deckNamesLower.contains(name);
          final beingRemoved = removalNamesFinal.contains(name);

          // Em Commander/Brawl, não-básicos só podem ter 1 cópia.
          // Se a carta já está no deck e não está sendo removida, é inválida.
          if (alreadyInDeck &&
              !beingRemoved &&
              !isBasic &&
              (deckFormat == 'commander' || deckFormat == 'brawl')) {
            Log.w(
                '  Validação final: removendo adição duplicada "$name" (já existe no deck)');
            continue;
          }

          filteredAdditions.add(add);
          filteredAdditionNames.add(add['name']?.toString() ?? name);
        }

        // 2. Rebalancear após filtrar adições inválidas
        if (filteredAdditions.length < additionsDetailedFinal.length) {
          Log.d(
              '  Validação final: ${additionsDetailedFinal.length - filteredAdditions.length} adições removidas por duplicidade');

          // Truncar remoções para manter equilíbrio
          for (var i = 0;
              i < removalsDetailedFinal.length &&
                  filteredRemovalsToKeep.length < filteredAdditions.length;
              i++) {
            filteredRemovalsToKeep.add(removalsDetailedFinal[i]);
            final rem = removalsDetailedFinal[i];
            if (rem is Map) {
              filteredRemovalNames.add(rem['name']?.toString() ?? '');
            }
          }

          responseBody['additions_detailed'] = filteredAdditions;
          responseBody['additions'] = filteredAdditionNames;
          responseBody['removals_detailed'] = filteredRemovalsToKeep;
          responseBody['removals'] = filteredRemovalNames;

          // Rebuild recommendations
          responseBody['recommendations'] = [
            ...filteredRemovalsToKeep,
            ...filteredAdditions,
          ];

          Log.d(
              '  Validação final pós-rebalanceamento: ${filteredAdditions.length} adições, ${filteredRemovalsToKeep.length} remoções');
        }

        // 3. Safety net: ensure additions and removals are exactly balanced
        {
          final finalAdditions = responseBody['additions_detailed'] as List;
          final finalRemovals = responseBody['removals_detailed'] as List;
          if (finalAdditions.length != finalRemovals.length) {
            Log.w(
                '  Safety net: additions(${finalAdditions.length}) != removals(${finalRemovals.length}), rebalancing');
            final minLen = finalAdditions.length < finalRemovals.length
                ? finalAdditions.length
                : finalRemovals.length;
            responseBody['additions_detailed'] =
                finalAdditions.take(minLen).toList();
            responseBody['additions'] =
                (responseBody['additions'] as List).take(minLen).toList();
            responseBody['removals_detailed'] =
                finalRemovals.take(minLen).toList();
            responseBody['removals'] =
                (responseBody['removals'] as List).take(minLen).toList();
          }
        }
      }

      final warnings = <String, dynamic>{};

      // Adicionar avisos se houver cartas inválidas
      if (invalidCards.isNotEmpty) {
        warnings.addAll({
          'invalid_cards': invalidCards,
          'message':
              'Algumas cartas sugeridas pela IA não foram encontradas e foram removidas',
          'suggestions': suggestions,
        });
      }

      // Adicionar avisos se houver cartas filtradas por identidade de cor
      if (filteredByColorIdentity.isNotEmpty) {
        warnings['filtered_by_color_identity'] = {
          'commander_identity': commanderColorIdentity.toList(),
          'removed_additions': filteredByColorIdentity,
          'message':
              'Algumas adições sugeridas pela IA foram removidas por estarem fora da identidade de cor do comandante.',
        };
      }

      if (blockedByBracket.isNotEmpty) {
        warnings['blocked_by_bracket'] = {
          'bracket': bracket,
          'blocked_additions': blockedByBracket,
          'message':
              'Algumas adições sugeridas foram bloqueadas por exceder limites do bracket.',
        };
      }

      if (blockedByTheme.isNotEmpty) {
        warnings['blocked_by_theme'] = {
          'keep_theme': keepTheme,
          'blocked_removals': blockedByTheme,
          'message':
              'Algumas remoções sugeridas foram bloqueadas para preservar o tema do deck.',
        };
      }

      if (emptySuggestionFallbackReason != null) {
        warnings['empty_suggestions_handling'] = {
          'recognized_format': recognizedSuggestionFormat,
          'fallback_applied': emptySuggestionFallbackApplied,
          'message': emptySuggestionFallbackReason,
        };
      }

      if (warnings.isNotEmpty) {
        responseBody['warnings'] = warnings;
      }

      try {
        await saveOptimizeCache(
          pool: pool,
          cacheKey: cacheKey,
          userId: userId,
          deckId: deckId,
          deckSignature: deckSignature,
          payload: responseBody,
        );
        await saveUserAiPreferences(
          pool: pool,
          userId: userId,
          preferredArchetype: targetArchetype,
          preferredBracket: bracket,
          keepThemeDefault: keepTheme,
          preferredColors: commanderColorIdentity.toList(),
        );
      } catch (e) {
        Log.w('Falha ao persistir cache/preferências de optimize: $e');
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
    Log.e('handler: $e\nStack trace:\n$stackTrace');
    return internalServerError('Failed to optimize deck', details: e);
  }
}

Future<void> _recordOptimizeAnalysisOutcome({
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
/// Chamada via `unawaited()` — NÃO bloqueia a resposta HTTP.
Future<void> _processCompleteModeAsync({
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
  required DeckOptimizerService optimizer,
  required DeckThemeProfile themeProfile,
  required String targetArchetype,
  required int? bracket,
  required bool keepTheme,
  required Map<String, dynamic> deckAnalysis,
  required String? userId,
  required String? cacheKey,
  required Map<String, dynamic> userPreferences,
  required bool hasBracketOverride,
  required bool hasKeepThemeOverride,
}) async {
  try {
    await OptimizeJobStore.progress(pool, jobId,
        stage: 'Preparando referências do commander...', stageNumber: 1);

    Map<String, dynamic> jsonResponse;
    final state = optimize_complete.CompleteBuildAccumulator.fromDeck(
      allCardData: allCardData,
      originalCountsById: originalCountsById,
      currentTotalCards: currentTotalCards,
    );
    await optimize_complete.prepareCompleteCommanderSeed(
      pool: pool,
      commanders: commanders,
      maxTotal: maxTotal,
      currentTotalCards: currentTotalCards,
      state: state,
    );

    await OptimizeJobStore.progress(pool, jobId,
        stage: 'Consultando IA para sugestões...', stageNumber: 2);
    await optimize_complete.runCompleteAiSuggestionLoop(
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
    );

    optimize_complete.rebalanceCompleteDeckForLandDeficit(
      state: state,
      maxTotal: maxTotal,
    );

    await OptimizeJobStore.progress(pool, jobId,
        stage: 'Preenchendo com cartas sinérgicas...', stageNumber: 3);
    await OptimizeJobStore.progress(pool, jobId,
        stage: 'Ajustando base de mana...', stageNumber: 4);

    await optimize_complete.fillCompleteDeckRemainder(
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
    );

    jsonResponse = optimize_complete.buildCompleteIntermediatePayload(
      state: state,
      maxTotal: maxTotal,
      currentTotalCards: currentTotalCards,
      targetArchetype: targetArchetype,
    );

    await OptimizeJobStore.progress(pool, jobId,
        stage: 'Processando resultado final...', stageNumber: 6);

    // Post-processing: validar qualidade e construir resposta
    if (jsonResponse['mode'] == 'complete' &&
        jsonResponse['additions_detailed'] is List) {
      final qualityError = jsonResponse['quality_error'];
      if (qualityError is Map) {
        await OptimizeJobStore.fail(
          pool,
          jobId,
          error: 'Complete mode não atingiu qualidade mínima.',
          qualityError: qualityError.cast<String, dynamic>(),
        );
        return;
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
      );
      await OptimizeJobStore.complete(pool, jobId, result: responseBody);
    } else {
      // Fallback: se por algum motivo não veio como complete
      await OptimizeJobStore.complete(pool, jobId, result: jsonResponse);
    }
  } catch (e, stackTrace) {
    Log.e('Background optimize job $jobId failed: $e\n$stackTrace');
    await OptimizeJobStore.fail(pool, jobId, error: e.toString());
  }
}
