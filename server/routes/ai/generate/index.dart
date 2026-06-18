import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../lib/ai_generate_job.dart';
import '../../../lib/ai_generate_internal_url_support.dart';
import '../../../lib/ai_generate_performance_support.dart';
import '../../../lib/ai/commander_reference_card_stats_support.dart';
import '../../../lib/ai/commander_reference_deck_corpus_support.dart';
import '../../../lib/ai/commander_reference_generate_fallback_support.dart';
import '../../../lib/ai/commander_learned_deck_support.dart';
import '../../../lib/ai/commander_reference_profile_support.dart';
import '../../../lib/ai/deck_learning_event_support.dart';
import '../../../lib/ai/functional_card_tags.dart';
import '../../../lib/color_identity.dart';
import '../../../lib/generated_deck_validation_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/import_card_lookup_service.dart';
import '../../../lib/internal_ai_request_token.dart';
import '../../../lib/logger.dart';
import '../../../lib/meta/meta_deck_format_support.dart';
import '../../../lib/meta/meta_deck_reference_support.dart';
import '../../../lib/observability.dart';
import '../../../lib/openai_runtime_config.dart';

const _aiGenerateReferencePromptPolicyVersion =
    'ai_generate_reference_prompt_v6';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final prompt = body['prompt'] as String?;
    final format = body['format'] as String? ?? 'Commander';

    if (prompt == null || prompt.isEmpty) {
      return badRequest('Prompt is required');
    }

    if (isAiGenerateAsyncRequested(body)) {
      return _startAiGenerateAsyncJob(
        context: context,
        body: body,
        prompt: prompt,
        format: format,
      );
    }

    final totalStopwatch = Stopwatch()..start();
    final timings = <String, int>{};
    final bracket = body['bracket'];
    final requestedCommanderName = body['commander_name']?.toString().trim();
    final pool = context.read<Pool>();

    Map<String, dynamic>? referenceProfile;
    var referenceCardStats = const <CommanderReferenceCardStat>[];
    var unresolvedReferenceCards = const <String>[];
    var archetypeReferenceStats = const <CommanderReferenceCardStat>[];
    var archetypeSourceCommanderNames = const <String>[];
    var archetypeCommanderColorIdentity = const <String>[];
    CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance;
    final referenceProfileStopwatch = Stopwatch()..start();
    try {
      referenceProfile = await loadUsableCommanderReferenceProfile(
        pool: pool,
        commanderName: requestedCommanderName,
      );
      if (referenceProfile != null) {
        final statsLoad = await loadUsableCommanderReferenceCardStats(
          pool: pool,
          commanderName: requestedCommanderName,
        );
        referenceCardStats = statsLoad.stats;
        unresolvedReferenceCards = statsLoad.unresolvedCardNames;
        referenceDeckCorpusGuidance =
            await loadCommanderReferenceDeckCorpusGuidance(
          pool: pool,
          commanderName: requestedCommanderName,
        );
      } else {
        final archetypeStatsLoad =
            await loadCompatibleCommanderReferenceArchetypeStats(
          pool: pool,
          commanderName: requestedCommanderName,
          prompt: prompt,
        );
        archetypeReferenceStats = archetypeStatsLoad.stats;
        archetypeSourceCommanderNames = archetypeStatsLoad.sourceCommanderNames;
        archetypeCommanderColorIdentity =
            archetypeStatsLoad.commanderColorIdentity;
      }
    } catch (error) {
      Log.w(
        'Commander reference profile/card stats unavailable; continuing legacy generate path. '
        'error=$error',
      );
    }

    var usageHotCardsPrompt = '';
    var usageHotCards = const <Map<String, dynamic>>[];
    var promotedLearnedCardNames = const <String>[];
    CommanderLearnedDeckInput? activeLearnedDeck;
    if (requestedCommanderName != null && requestedCommanderName.isNotEmpty) {
      try {
        usageHotCards = await loadUsageHotCards(
          pool: pool,
          commanderName: requestedCommanderName,
          limit: usageHotCardsGenerationCandidateLimit,
        );
        usageHotCardsPrompt = buildUsageHotCardsPrompt(usageHotCards);
      } catch (_) {}
      try {
        activeLearnedDeck = await loadActiveCommanderLearnedDeck(
          pool: pool,
          commanderName: requestedCommanderName,
        );
        promotedLearnedCardNames =
            activeCommanderLearnedDeckCardNames(activeLearnedDeck);
      } catch (_) {}
    }
    timings['reference_profile_ms'] =
        referenceProfileStopwatch.elapsedMilliseconds;

    final referenceProfileVersion = _buildReferenceGenerateCacheVersion(
      referenceProfile: referenceProfile,
      referenceCardStats: referenceCardStats,
      referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
      archetypeReferenceStats: archetypeReferenceStats,
    );
    final referenceGuidanceEnabled =
        referenceProfile != null || archetypeReferenceStats.isNotEmpty;
    final cacheKey = buildAiGenerateCacheKey(
      prompt: prompt,
      format: format,
      bracket: bracket,
      commanderName: referenceGuidanceEnabled ? requestedCommanderName : null,
      referenceProfileVersion: referenceProfileVersion,
    );

    final cacheLookupStopwatch = Stopwatch()..start();
    final cachedBody = readAiGenerateCache(cacheKey);
    timings['cache_lookup_ms'] = cacheLookupStopwatch.elapsedMilliseconds;
    if (cachedBody != null) {
      timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
      return Response.json(
        body: withAiGenerateRuntimeMetadata(
          payload: cachedBody,
          cacheKey: cacheKey,
          cacheHit: true,
          timings: timings,
        ),
      );
    }

    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
    final aiConfig = OpenAiRuntimeConfig(env);
    final apiKey = env['OPENAI_API_KEY'];
    final cacheTtl = Duration(
      seconds: aiConfig.intFor(
        key: 'AI_GENERATE_CACHE_TTL_SECONDS',
        fallback: 600,
        devFallback: 600,
        stagingFallback: 900,
        prodFallback: 600,
        min: 30,
        max: 3600,
      ),
    );

    if (apiKey == null || apiKey.isEmpty) {
      final mockBody = await _buildMockGenerateResponse(
        pool: pool,
        prompt: prompt,
        format: format,
        requestedCommanderName: requestedCommanderName,
        referenceProfile: referenceProfile,
        referenceCardStats: referenceCardStats,
        unresolvedReferenceCards: unresolvedReferenceCards,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        activeLearnedDeck: activeLearnedDeck,
        promotedLearnedCardNames: promotedLearnedCardNames,
        archetypeReferenceStats: archetypeReferenceStats,
        archetypeSourceCommanderNames: archetypeSourceCommanderNames,
        archetypeCommanderColorIdentity: archetypeCommanderColorIdentity,
        usageHotCards: usageHotCards,
        warningCode: 'openai_api_key_missing',
        warningMessage:
            'OPENAI_API_KEY nao configurada. Retornando deck mock para desenvolvimento.',
      );
      timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
      final responseBody = withAiGenerateRuntimeMetadata(
        payload: mockBody,
        cacheKey: cacheKey,
        cacheHit: false,
        timings: timings,
      );
      if (_aiGenerateBodyIsValidWithoutInvalidCards(mockBody)) {
        writeAiGenerateCache(
          cacheKey: cacheKey,
          payload: responseBody,
          ttl: const Duration(seconds: 120),
        );
      }
      return Response.json(body: responseBody);
    }

    if (_shouldUseReferenceGuidedDeterministicFastPath(
      format: format,
      referenceProfile: referenceProfile,
      referenceCardStats: referenceCardStats,
      referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
    )) {
      final fastPathStopwatch = Stopwatch()..start();
      final deterministicBody = await _buildMockGenerateResponse(
        pool: pool,
        prompt: prompt,
        format: format,
        requestedCommanderName: requestedCommanderName,
        referenceProfile: referenceProfile,
        referenceCardStats: referenceCardStats,
        unresolvedReferenceCards: unresolvedReferenceCards,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        activeLearnedDeck: activeLearnedDeck,
        archetypeReferenceStats: archetypeReferenceStats,
        archetypeSourceCommanderNames: archetypeSourceCommanderNames,
        archetypeCommanderColorIdentity: archetypeCommanderColorIdentity,
        usageHotCards: usageHotCards,
        isMock: false,
        generationMode: 'reference_deterministic',
      );
      timings['reference_deterministic_ms'] =
          fastPathStopwatch.elapsedMilliseconds;
      timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
      final responseBody = withAiGenerateRuntimeMetadata(
        payload: deterministicBody,
        cacheKey: cacheKey,
        cacheHit: false,
        timings: timings,
      );
      if (_aiGenerateBodyIsValidWithoutInvalidCards(deterministicBody)) {
        writeAiGenerateCache(
          cacheKey: cacheKey,
          payload: responseBody,
          ttl: cacheTtl,
        );
        return Response.json(body: responseBody);
      }
    }

    var metaContext = '';
    Map<String, dynamic>? metaReferenceContext;

    final metaStopwatch = Stopwatch()..start();
    try {
      final metaKeywordPatterns = prompt
          .split(' ')
          .where((word) => word.length > 3)
          .map((word) => word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''))
          .where((word) => word.isNotEmpty)
          .map((word) => '%$word%')
          .toSet()
          .toList();

      final normalizedFormat = format.trim().toLowerCase();
      final isCommanderFormat =
          normalizedFormat == 'commander' || normalizedFormat == 'edh';
      final commanderMetaScope = isCommanderFormat
          ? resolveCommanderMetaScopeFromPromptText(prompt)
          : null;
      final shouldUseMeta = metaKeywordPatterns.isNotEmpty &&
          (!isCommanderFormat || commanderMetaScope != null);
      final metaFormats = shouldUseMeta
          ? metaDeckFormatCodesForDeckFormat(
              format,
              commanderScope: commanderMetaScope ?? 'competitive_commander',
            )
          : const <String>[];

      if (metaFormats.isNotEmpty) {
        final metaCandidates = await queryMetaDeckReferenceCandidates(
          pool: pool,
          formatCodes: metaFormats,
          keywordPatterns: metaKeywordPatterns,
          limit: 200,
        );
        final metaSelection = selectMetaDeckReferenceCandidates(
          candidates: metaCandidates,
          keywordPatterns: metaKeywordPatterns,
          commanderScope: commanderMetaScope,
          deckLimit: 3,
          priorityCardLimit: 14,
          preferExternalCompetitive:
              commanderMetaScope == 'competitive_commander',
        );

        if (metaSelection.hasReferences) {
          metaContext = buildMetaDeckEvidenceText(
            metaSelection,
            maxPriorityCards: 12,
            maxReferences: 3,
          );
          metaReferenceContext = buildMetaDeckEvidencePayload(
            metaSelection,
            maxPriorityCards: 12,
            maxReferences: 3,
          );
        }
      }
    } catch (error) {
      print('[ERROR] handler: $error');
      Log.w('Erro ao buscar contexto do meta: $error');
    } finally {
      timings['meta_context_ms'] = metaStopwatch.elapsedMilliseconds;
    }

    const systemPromptPrefix = '''
You are a world-class Magic: The Gathering deck builder and Level 3 judge.
Your goal is to build a competitive, consistent, and fully legal deck for the format
provided by the user.
Think like a judge verifying legality and a pro player maximizing consistency.

Return ONLY a JSON object (no markdown). Use this schema:
{
  "commander": { "name": "Exact English card name" },
  "cards": [
    { "name": "Exact English card name", "quantity": 1 }
  ]
}

Format-specific rules:

Commander (EDH):
1. Commander is REQUIRED. Choose a LEGAL commander:
   - typically a legendary creature, OR
   - a card that explicitly says it "can be your commander", OR
   - other commander-legal card types allowed by the rules (e.g., some Vehicles/Spacecraft with power/toughness).
2. You may choose TWO commanders only if they have a compatible partner-style ability
   (partner, partner with, friends forever, choose a Background, Doctor's companion). Never more than 2 commanders.
3. Total must be exactly 100 cards including the commander(s).
4. Only 1 copy of each card except basic lands (singleton rule). Copy limits are by English card NAME across printings.
5. ALL cards must respect the combined commander color identity.
6. Do NOT include banned cards in the Commander format.
7. Do NOT include commander cards inside the "cards" list.
8. Starting life is 40.

Brawl:
1. Commander required (legendary creature or planeswalker, or a card that says it can be your commander).
2. Total must be exactly 60 cards including the commander.
3. Singleton (1 copy except basics).
4. Cards must be Standard-legal and respect the commander's color identity.

Standard/Pioneer/Modern/Legacy/Vintage/Pauper:
1. Minimum 60 cards in the main deck.
2. Maximum 4 copies of any non-basic-land card.
3. Include 22-26 lands depending on curve.
4. No commander field needed; set commander to null.
5. Respect the ban list for the specific format.
6. Pauper: commons only. Vintage: restricted list applies.

Deck construction guidelines:
- Include a functional mana base.
- For Commander: 35-38 lands, 10-12 ramp, 10+ draw, 8-10 removal, 3-4 wipes.
- For 60-card formats: 22-26 lands, 4+ removal, adequate draw.
- Include 2-3 distinct win conditions.
- Keep the mana curve smooth.
- Prioritize instant-speed interaction when available.
- Use exact real card names in English.
''';

    final referenceProfilePrompt = referenceProfile != null
        ? [
            buildCommanderReferenceProfilePrompt(referenceProfile),
            buildCommanderReferenceCardStatsPrompt(
              referenceCardStats,
              compact: shouldUseCompactCommanderReferenceCorpusPrompt(
                referenceDeckCorpusGuidance,
              ),
              priorityCardNames: commanderReferenceCorpusCoreCardNames(
                referenceDeckCorpusGuidance,
              ),
            ),
            buildCommanderReferenceDeckCorpusPrompt(
              referenceDeckCorpusGuidance,
            ),
            if (usageHotCardsPrompt.isNotEmpty) usageHotCardsPrompt,
          ].where((line) => line.trim().isNotEmpty).join('\n')
        : archetypeReferenceStats.isNotEmpty
            ? buildCommanderReferenceArchetypeStatsPrompt(
                commanderName: requestedCommanderName ?? '',
                stats: archetypeReferenceStats,
                sourceCommanderNames: archetypeSourceCommanderNames,
              )
            : '';

    final userMessage = '''
Build a deck based on this description: "$prompt".
Format: $format.

$referenceProfilePrompt

$metaContext
''';

    final normalizedFormat = normalizeAiGenerateFormat(format);
    final openAiTimeoutSelection = selectAiGenerateOpenAiTimeout(
      config: aiConfig,
      normalizedFormat: normalizedFormat,
      referenceGuidanceEnabled: referenceGuidanceEnabled,
    );
    final openAiTimeout = openAiTimeoutSelection.timeout;
    timings['openai_timeout_ms'] = openAiTimeout.inMilliseconds;
    final maxTokens = aiConfig.intFor(
      key: 'OPENAI_MAX_TOKENS_GENERATE',
      fallback: normalizedFormat == 'commander' ? 3400 : 2200,
      devFallback: normalizedFormat == 'commander' ? 3400 : 2200,
      stagingFallback: normalizedFormat == 'commander' ? 3400 : 2200,
      prodFallback: normalizedFormat == 'commander' ? 3800 : 2600,
      min: 800,
      max: 6000,
    );

    http.Response response;
    final openAiStopwatch = Stopwatch()..start();
    try {
      response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': aiConfig.modelFor(
                key: 'OPENAI_MODEL_GENERATE',
                fallback: 'gpt-4o-mini',
                devFallback: 'gpt-4o-mini',
                stagingFallback: 'gpt-4o-mini',
                prodFallback: 'gpt-4o-mini',
              ),
              'messages': [
                {
                  'role': 'system',
                  'content': '$systemPromptPrefix\nFormat: "$format".',
                },
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': aiConfig.temperatureFor(
                key: 'OPENAI_TEMP_GENERATE',
                fallback: 0.4,
                devFallback: 0.45,
                stagingFallback: 0.4,
                prodFallback: 0.35,
              ),
              'max_tokens': maxTokens,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(openAiTimeout);
    } on TimeoutException {
      timings['openai_ms'] = openAiStopwatch.elapsedMilliseconds;
      Log.w(
        'AI generate OpenAI timeout; using deterministic fallback. '
        'format=$format timeout_ms=${openAiTimeout.inMilliseconds} '
        'timeout_key=${openAiTimeoutSelection.envKey} '
        'reference_guidance=${openAiTimeoutSelection.referenceGuidanceBudget}',
      );
      final fallbackBody = await _buildMockGenerateResponse(
        pool: pool,
        prompt: prompt,
        format: format,
        requestedCommanderName: requestedCommanderName,
        referenceProfile: referenceProfile,
        referenceCardStats: referenceCardStats,
        unresolvedReferenceCards: unresolvedReferenceCards,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        activeLearnedDeck: activeLearnedDeck,
        archetypeReferenceStats: archetypeReferenceStats,
        archetypeSourceCommanderNames: archetypeSourceCommanderNames,
        archetypeCommanderColorIdentity: archetypeCommanderColorIdentity,
        usageHotCards: usageHotCards,
        warningCode: 'openai_timeout_deterministic_fallback',
        warningMessage:
            'A geracao demorou mais que o limite configurado. Retornando fallback deterministico valido para manter o fluxo create/validate/optimize.',
      );
      timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
      final responseBody = withAiGenerateRuntimeMetadata(
        payload: {
          ...fallbackBody,
          'ai_generation_timed_out': true,
        },
        cacheKey: cacheKey,
        cacheHit: false,
        timings: timings,
      );

      if (_aiGenerateBodyIsValidWithoutInvalidCards(fallbackBody)) {
        writeAiGenerateCache(
          cacheKey: cacheKey,
          payload: responseBody,
          ttl: const Duration(seconds: 120),
        );
        return Response.json(body: responseBody);
      }

      return Response.json(
        statusCode: 422,
        body: {
          'error': 'Generated fallback deck failed validation',
          ...responseBody,
        },
      );
    } finally {
      timings['openai_ms'] = openAiStopwatch.elapsedMilliseconds;
    }

    if (response.statusCode != 200) {
      if (aiConfig.shouldUseFallbackForInvalidApiKey(
        statusCode: response.statusCode,
        responseBody: response.body,
      )) {
        final mockBody = await _buildMockGenerateResponse(
          pool: pool,
          prompt: prompt,
          format: format,
          requestedCommanderName: requestedCommanderName,
          referenceProfile: referenceProfile,
          referenceCardStats: referenceCardStats,
          unresolvedReferenceCards: unresolvedReferenceCards,
          referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
          activeLearnedDeck: activeLearnedDeck,
          archetypeReferenceStats: archetypeReferenceStats,
          archetypeSourceCommanderNames: archetypeSourceCommanderNames,
          archetypeCommanderColorIdentity: archetypeCommanderColorIdentity,
          usageHotCards: usageHotCards,
          warningCode: 'openai_api_key_invalid_dev_fallback',
          warningMessage:
              'OPENAI_API_KEY invalida no ambiente atual. Retornando deck mock para manter o fluxo local utilizavel.',
        );
        timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
        final responseBody = withAiGenerateRuntimeMetadata(
          payload: mockBody,
          cacheKey: cacheKey,
          cacheHit: false,
          timings: timings,
        );
        if (_aiGenerateBodyIsValidWithoutInvalidCards(mockBody)) {
          writeAiGenerateCache(
            cacheKey: cacheKey,
            payload: responseBody,
            ttl: const Duration(seconds: 120),
          );
        }
        return Response.json(body: responseBody);
      }

      return apiError(
        response.statusCode,
        'OpenAI API Error: ${response.body}',
      );
    }

    final decodeStopwatch = Stopwatch()..start();
    dynamic aiData;
    try {
      aiData = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return apiError(502, 'OpenAI returned invalid JSON');
    } finally {
      timings['decode_ms'] = decodeStopwatch.elapsedMilliseconds;
    }

    if (aiData is! Map ||
        aiData['choices'] is! List ||
        (aiData['choices'] as List).isEmpty) {
      return apiError(502, 'OpenAI response missing choices');
    }

    final firstChoice = (aiData['choices'] as List).first;
    final message = firstChoice is Map ? firstChoice['message'] : null;
    final contentRaw = message is Map ? message['content'] : null;
    if (contentRaw is! String || contentRaw.trim().isEmpty) {
      return apiError(502, 'OpenAI returned empty content');
    }

    var content =
        contentRaw.replaceAll('```json', '').replaceAll('```', '').trim();

    Map<String, dynamic> deckList;
    try {
      deckList = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return apiError(502, 'OpenAI returned invalid deck JSON');
    }
    final commanderRaw = deckList['commander'];
    var cards =
        (deckList['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    String? commanderName;
    if (commanderRaw is Map && commanderRaw['name'] != null) {
      commanderName = commanderRaw['name'] as String;
    } else if (commanderRaw is String && commanderRaw.trim().isNotEmpty) {
      commanderName = commanderRaw;
    }

    final referenceCommanderName =
        referenceProfile?['commander']?.toString().trim();
    if (referenceProfile != null &&
        referenceCommanderName != null &&
        referenceCommanderName.isNotEmpty &&
        normalizeCommanderReferenceName(commanderName ?? '') !=
            normalizeCommanderReferenceName(referenceCommanderName)) {
      Log.w(
        'AI generate ignored reference commander; forcing '
        '$referenceCommanderName before validation.',
      );
      commanderName = referenceCommanderName;
    }

    if (referenceProfile != null && commanderName != null) {
      final identityFilterStopwatch = Stopwatch()..start();
      cards = await _filterAndRefillReferenceGeneratedCards(
        pool: pool,
        format: format,
        cards: cards,
        commanderName: commanderName,
        referenceProfile: referenceProfile,
        referenceCardStats: referenceCardStats,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        usageHotCardNames: usageHotCardCanonicalNames(usageHotCards),
        activeLearnedDeck: activeLearnedDeck,
        promotedLearnedCardNames: promotedLearnedCardNames,
      );
      timings['reference_identity_filter_ms'] =
          identityFilterStopwatch.elapsedMilliseconds;
    }

    final validationService = GeneratedDeckValidationService(
      PostgresGeneratedDeckRepository(pool, preferredFormat: format),
    );
    final validationStopwatch = Stopwatch()..start();
    final validation = await validationService.validate(
      format: format,
      cards: cards,
      commanderName: commanderName,
    );
    timings['validation_ms'] = validationStopwatch.elapsedMilliseconds;

    final generatedCardNames = cards
        .map((card) => card['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    Map<String, dynamic>? referenceDeckEvaluation;
    if (referenceProfile != null) {
      final generatedDeckForEvaluation = validation.generatedDeck;
      final evaluationCards = (generatedDeckForEvaluation['cards'] as List?)
              ?.whereType<Map>()
              .map((card) => card['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      final evaluationMetadata = await loadReferenceEvaluationCardMetadata(
        pool: pool,
        cardNames: evaluationCards,
      );
      referenceDeckEvaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: generatedDeckForEvaluation,
        profile: referenceProfile,
        stats: referenceCardStats,
        cardMetadataByName: evaluationMetadata,
      ).toJson();
    }
    final referenceDeckCorpusDiagnostics = _buildReferenceDeckCorpusDiagnostics(
      generatedDeck: validation.generatedDeck,
      guidance: referenceDeckCorpusGuidance,
    );

    final responseBody = <String, dynamic>{
      'prompt': prompt,
      'format': format,
      'generated_deck': validation.generatedDeck,
      'meta_context_used': metaContext.isNotEmpty,
      'stats': {
        'total_suggested': validation.totalSuggestedEntries,
        'total_suggested_cards': validation.totalSuggestedCards,
        'valid_cards': validation.totalResolvedEntries,
        'valid_total_cards': validation.totalResolvedCards,
        'invalid_cards': validation.invalidCards.length,
      },
      'validation': validation.validationSummary(),
      'semantic_layer_v2': _buildSemanticLayerV2GenerateSummary(
        validation.generatedDeck,
      ),
      if (referenceProfile != null)
        'diagnostics': buildCommanderReferenceDiagnostics(
          referenceProfile,
          cardStatsDiagnostics: buildCommanderReferenceCardStatsDiagnostics(
            stats: referenceCardStats,
            unresolvedCardNames: unresolvedReferenceCards,
          ),
          referenceDeckCorpusDiagnostics: referenceDeckCorpusDiagnostics,
          referenceDeckEvaluation: referenceDeckEvaluation,
        ),
      if (referenceProfile == null && archetypeReferenceStats.isNotEmpty)
        'diagnostics': buildCommanderReferenceArchetypeStatsDiagnostics(
          stats: archetypeReferenceStats,
          sourceCommanderNames: archetypeSourceCommanderNames,
          commanderColorIdentity: archetypeCommanderColorIdentity,
        ),
      if (metaReferenceContext != null && metaReferenceContext.isNotEmpty)
        'meta_reference_context':
            augmentMetaDeckEvidencePayloadWithOutputMatches(
          metaReferenceContext,
          outputCardNames: generatedCardNames,
        ),
    };

    // Fire-and-forget: loga deck gerado para aprendizado (mesmo nao salvo)
    if (format.toLowerCase() == 'commander' && validation.isValid) {
      unawaited(
        logGeneratedDeckForLearning(
          pool: pool,
          responseBody: responseBody,
          source: 'ai_generated',
        ),
      );
    }

    if (validation.invalidCards.isNotEmpty || validation.warnings.isNotEmpty) {
      responseBody['warnings'] = {
        'invalid_cards': validation.invalidCards,
        'messages': validation.warnings,
        'suggestions': validation.suggestions,
      };
    }

    if (!validation.isValid || validation.invalidCards.isNotEmpty) {
      Log.w(
        'AI generate returned invalid or unresolved deck; using deterministic '
        'fallback. format=$format errors=${validation.errors.join(' | ')} '
        'invalid_cards=${validation.invalidCards.length}',
      );

      final fallbackWarningCode = validation.isValid
          ? 'ai_generate_invalid_card_fallback'
          : 'ai_generate_validation_fallback';
      final fallbackWarningMessage = validation.isValid
          ? 'A geracao principal retornou cartas nao resolvidas. Retornando fallback deterministico valido para manter o fluxo create/validate/optimize.'
          : 'A geracao principal retornou um deck invalido. Retornando fallback deterministico valido para manter o fluxo create/validate/optimize.';
      final fallbackBody = await _buildMockGenerateResponse(
        pool: pool,
        prompt: prompt,
        format: format,
        requestedCommanderName: requestedCommanderName,
        referenceProfile: referenceProfile,
        referenceCardStats: referenceCardStats,
        unresolvedReferenceCards: unresolvedReferenceCards,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        activeLearnedDeck: activeLearnedDeck,
        archetypeReferenceStats: archetypeReferenceStats,
        archetypeSourceCommanderNames: archetypeSourceCommanderNames,
        archetypeCommanderColorIdentity: archetypeCommanderColorIdentity,
        usageHotCards: usageHotCards,
        warningCode: fallbackWarningCode,
        warningMessage: fallbackWarningMessage,
      );

      if (_aiGenerateBodyIsValidWithoutInvalidCards(fallbackBody)) {
        fallbackBody['ai_generation_repaired_by_fallback'] = true;
        fallbackBody['original_validation_errors'] = validation.errors;
        if (validation.invalidCards.isNotEmpty) {
          fallbackBody['original_invalid_cards_count'] =
              validation.invalidCards.length;
        }
        timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
        final validFallbackBody = withAiGenerateRuntimeMetadata(
          payload: fallbackBody,
          cacheKey: cacheKey,
          cacheHit: false,
          timings: timings,
        );
        writeAiGenerateCache(
          cacheKey: cacheKey,
          payload: validFallbackBody,
          ttl: const Duration(seconds: 120),
        );
        return Response.json(body: validFallbackBody);
      }

      return Response.json(
        statusCode: 422,
        body: {
          'error': 'Generated deck failed validation',
          ...responseBody,
        },
      );
    }

    timings['total_ms'] = totalStopwatch.elapsedMilliseconds;
    final finalBody = withAiGenerateRuntimeMetadata(
      payload: responseBody,
      cacheKey: cacheKey,
      cacheHit: false,
      timings: timings,
    );
    writeAiGenerateCache(
      cacheKey: cacheKey,
      payload: finalBody,
      ttl: cacheTtl,
    );
    return Response.json(body: finalBody);
  } catch (error, stackTrace) {
    print('[ERROR] Failed to generate deck: $error');
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'ai_generate'},
    );
    return internalServerError('Failed to generate deck');
  }
}

Future<Response> _startAiGenerateAsyncJob({
  required RequestContext context,
  required Map<String, dynamic> body,
  required String prompt,
  required String format,
}) async {
  final pool = context.read<Pool>();
  String? userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = null;
  }
  if (userId == null || userId.isEmpty) {
    return unauthorized('Authentication required');
  }
  final authenticatedUserId = userId;

  final requestStopwatch = Stopwatch()..start();
  final referenceCacheVersion = await _resolveReferenceGenerateCacheVersion(
    pool: pool,
    commanderName: body['commander_name']?.toString(),
    prompt: prompt,
  );
  final cacheKey = buildAiGenerateCacheKey(
    prompt: prompt,
    format: format,
    bracket: body['bracket'],
    commanderName: referenceCacheVersion == null
        ? null
        : body['commander_name']?.toString(),
    referenceProfileVersion: referenceCacheVersion,
  );
  final jobId = await AiGenerateJobStore.create(
    pool: pool,
    cacheKey: cacheKey,
    format: format,
    userId: authenticatedUserId,
  );

  final syncPayload = buildAiGenerateSyncPayloadForAsyncJob(body);
  final authorization = context.request.headers['authorization'];
  final internalGenerateUrl = _resolveInternalGenerateUrl(context.request);

  unawaited(
    runZonedGuarded(
      () => _processAiGenerateAsyncJob(
        pool: pool,
        jobId: jobId,
        internalGenerateUrl: internalGenerateUrl,
        syncPayload: syncPayload,
        authorization: authorization,
      ),
      (error, stackTrace) {
        Log.e('Background ai_generate job $jobId crashed: $error\n$stackTrace');
        unawaited(
          AiGenerateJobStore.fail(
            pool,
            jobId,
            error: 'Falha interna ao processar geracao async.',
          ),
        );
      },
    ),
  );

  return Response.json(
    statusCode: HttpStatus.accepted,
    body: {
      'job_id': jobId,
      'status': 'pending',
      'message':
          'Geracao iniciada em background. Consulte o progresso via polling.',
      'poll_url': '/ai/generate/jobs/$jobId',
      'poll_interval_ms': 1000,
      'total_stages': 4,
      'cache': {
        'hit': false,
        'cache_key': cacheKey,
      },
      'timings': {
        'accepted_ms': requestStopwatch.elapsedMilliseconds,
      },
    },
  );
}

String? _buildReferenceGenerateCacheVersion({
  required Map<String, dynamic>? referenceProfile,
  required List<CommanderReferenceCardStat> referenceCardStats,
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  List<CommanderReferenceCardStat> archetypeReferenceStats = const [],
}) {
  if (referenceProfile == null) {
    final statsVersion = commanderReferenceCardStatsCacheVersion(
      archetypeReferenceStats,
    );
    return statsVersion?.replaceFirst(
      'reference_card_stats_v1:',
      'archetype_reference_v1:',
    );
  }
  final profileVersion =
      commanderReferenceProfileCacheVersion(referenceProfile);
  final statsVersion = commanderReferenceCardStatsCacheVersion(
    referenceCardStats,
  );
  final corpusVersion = commanderReferenceDeckCorpusCacheVersion(
    referenceDeckCorpusGuidance,
  );
  return [
    _aiGenerateReferencePromptPolicyVersion,
    profileVersion,
    if (statsVersion != null) statsVersion,
    if (corpusVersion != null) corpusVersion,
  ].join(':');
}

Future<String?> _resolveReferenceGenerateCacheVersion({
  required Pool pool,
  required String? commanderName,
  required String prompt,
}) async {
  try {
    final profile = await loadUsableCommanderReferenceProfile(
      pool: pool,
      commanderName: commanderName,
    );
    if (profile == null) {
      final archetypeStatsLoad =
          await loadCompatibleCommanderReferenceArchetypeStats(
        pool: pool,
        commanderName: commanderName,
        prompt: prompt,
      );
      return _buildReferenceGenerateCacheVersion(
        referenceProfile: null,
        referenceCardStats: const [],
        archetypeReferenceStats: archetypeStatsLoad.stats,
      );
    }
    final statsLoad = await loadUsableCommanderReferenceCardStats(
      pool: pool,
      commanderName: commanderName,
    );
    final corpusGuidance = await loadCommanderReferenceDeckCorpusGuidance(
      pool: pool,
      commanderName: commanderName,
    );
    return _buildReferenceGenerateCacheVersion(
      referenceProfile: profile,
      referenceCardStats: statsLoad.stats,
      referenceDeckCorpusGuidance: corpusGuidance,
    );
  } catch (error) {
    Log.w(
      'Commander reference cache version unavailable for async generate; '
      'using legacy cache key. error=$error',
    );
    return null;
  }
}

Future<void> _processAiGenerateAsyncJob({
  required Pool pool,
  required String jobId,
  required Uri internalGenerateUrl,
  required Map<String, dynamic> syncPayload,
  required String? authorization,
}) async {
  await AiGenerateJobStore.progress(
    pool,
    jobId,
    stage: 'Preparando geracao',
    stageNumber: 1,
  );

  final stopwatch = Stopwatch()..start();
  await AiGenerateJobStore.progress(
    pool,
    jobId,
    stage: 'Gerando e validando deck',
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
          internalGenerateUrl,
          headers: headers,
          body: jsonEncode(syncPayload),
        )
        .timeout(const Duration(minutes: 3));
  } on TimeoutException {
    await AiGenerateJobStore.fail(
      pool,
      jobId,
      error: 'Tempo limite excedido ao gerar deck async.',
    );
    return;
  }

  await AiGenerateJobStore.progress(
    pool,
    jobId,
    stage: 'Persistindo resultado',
    stageNumber: 3,
  );

  Map<String, dynamic> resultBody;
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    resultBody = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? decoded.cast<String, dynamic>()
            : <String, dynamic>{'value': decoded};
  } catch (_) {
    await AiGenerateJobStore.fail(
      pool,
      jobId,
      error: 'Generate async recebeu resposta invalida do executor interno.',
    );
    return;
  }

  resultBody['async'] = {
    'job_id': jobId,
    'completed_ms': stopwatch.elapsedMilliseconds,
    'result_status_code': response.statusCode,
  };

  if (response.statusCode == HttpStatus.ok ||
      response.statusCode == HttpStatus.unprocessableEntity) {
    await AiGenerateJobStore.complete(
      pool,
      jobId,
      statusCode: response.statusCode,
      result: resultBody,
    );
    return;
  }

  await AiGenerateJobStore.fail(
    pool,
    jobId,
    error: resultBody['error']?.toString() ?? 'Falha ao gerar deck async.',
  );
}

Map<String, dynamic>? _buildReferenceDeckCorpusDiagnostics({
  required Map<String, dynamic> generatedDeck,
  required CommanderReferenceDeckCorpusGuidance? guidance,
}) {
  final diagnostics = guidance?.toDiagnostics();
  if (diagnostics == null) return null;
  final evaluation = evaluateGeneratedDeckAgainstReferenceCorpusPackages(
    generatedDeck: generatedDeck,
    guidance: guidance,
  );
  if (evaluation == null) return diagnostics;
  return {
    ...diagnostics,
    'reference_deck_corpus_evaluation': evaluation,
  };
}

Uri _resolveInternalGenerateUrl(Request request) {
  return resolveAiGenerateInternalUrl(
    headers: request.headers,
    requestUri: request.uri,
    configuredBaseUrl: Platform.environment['AI_GENERATE_INTERNAL_BASE_URL'],
    fallbackPort: Platform.environment['PORT']?.trim(),
  );
}

bool _shouldUseReferenceGuidedDeterministicFastPath({
  required String format,
  required Map<String, dynamic>? referenceProfile,
  required List<CommanderReferenceCardStat> referenceCardStats,
  required CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
}) {
  final normalizedFormat = normalizeAiGenerateFormat(format);
  if (normalizedFormat != 'commander') return false;
  if (referenceProfile == null) return false;
  final resolvedReferenceStats =
      referenceCardStats.where((stat) => !stat.unresolved).length;
  return resolvedReferenceStats >= 20 &&
      shouldUseCompactCommanderReferenceCorpusPrompt(
        referenceDeckCorpusGuidance,
      );
}

bool _aiGenerateBodyIsValidWithoutInvalidCards(Map<String, dynamic> body) {
  final validation = body['validation'];
  if (validation is! Map || validation['is_valid'] != true) return false;

  final validationInvalidCards = validation['invalid_cards'];
  if (validationInvalidCards is Iterable && validationInvalidCards.isNotEmpty) {
    return false;
  }

  final stats = body['stats'];
  if (stats is Map) {
    final invalidCount = _aiGenerateIntValue(stats['invalid_cards']);
    if (invalidCount > 0) return false;
  }

  final warnings = body['warnings'];
  if (warnings is Map) {
    final warningInvalidCards = warnings['invalid_cards'];
    if (warningInvalidCards is Iterable && warningInvalidCards.isNotEmpty) {
      return false;
    }
  }

  return true;
}

int _aiGenerateIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Future<List<Map<String, dynamic>>> _filterAndRefillReferenceGeneratedCards({
  required Pool pool,
  required String format,
  required List<Map<String, dynamic>> cards,
  required String commanderName,
  required Map<String, dynamic> referenceProfile,
  required List<CommanderReferenceCardStat> referenceCardStats,
  required CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<String> promotedLearnedCardNames = const [],
  List<String> usageHotCardNames = const [],
}) async {
  final normalizedFormat = normalizeAiGenerateFormat(format);
  if (normalizedFormat != 'commander' && normalizedFormat != 'brawl') {
    return cards;
  }

  final lookupNames = <String>{commanderName};
  for (final card in cards) {
    final name = card['name']?.toString().trim();
    if (name == null || name.isEmpty) continue;
    lookupNames.add(name);
    lookupNames.addAll(commanderReferenceCardLookupAliases(name));
  }
  final resolvedCardsByName = lookupNames.isEmpty
      ? <String, Map<String, dynamic>>{}
      : await resolveImportCardNames(
          pool,
          [
            for (final name in lookupNames) {'name': name}
          ],
          preferredFormat: format,
        );
  final normalizedResolvedCardsByName = resolvedCardsByName.map(
    (key, value) => MapEntry(normalizeCommanderReferenceCardName(key), value),
  );

  final filtered = filterReferenceGeneratedCardsByCommanderIdentity(
    profile: referenceProfile,
    commanderName: commanderName,
    cards: cards,
    resolvedCardsByName: normalizedResolvedCardsByName,
  ).cards;

  final targetMainQuantity = normalizedFormat == 'brawl' ? 59 : 99;
  final currentQuantity = _generatedMainQuantity(filtered);
  if (currentQuantity >= targetMainQuantity) {
    return filtered;
  }

  final fillerDeck = buildDeterministicReferenceDeck(
    profile: referenceProfile,
    referenceCardStats: referenceCardStats,
    referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
    activeLearnedDeck: activeLearnedDeck,
    promotedLearnedCardNames: promotedLearnedCardNames,
    usageHotCardNames: usageHotCardNames,
    targetMainQuantity: targetMainQuantity,
  );
  final filled = filtered.map(Map<String, dynamic>.from).toList();
  final seen = filled
      .map((card) => normalizeCommanderReferenceCardName(
            card['name']?.toString() ?? '',
          ))
      .where((name) => name.isNotEmpty)
      .toSet();
  var missing = targetMainQuantity - currentQuantity;
  final fillerCards =
      (fillerDeck['cards'] as List?)?.whereType<Map>() ?? const <Map>[];
  for (final rawCard in fillerCards) {
    if (missing <= 0) break;
    final name = rawCard['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final normalizedName = normalizeCommanderReferenceCardName(name);
    if (normalizedName == normalizeCommanderReferenceCardName(commanderName)) {
      continue;
    }
    final isBasic = basicLandNames.contains(normalizedName);
    if (!isBasic && !seen.add(normalizedName)) continue;
    final quantityRaw = rawCard['quantity'];
    final quantity = quantityRaw is int
        ? quantityRaw
        : int.tryParse(quantityRaw?.toString() ?? '') ?? 1;
    if (quantity <= 0) continue;
    final addQuantity = quantity > missing ? missing : quantity;
    filled.add({'name': name, 'quantity': addQuantity});
    missing -= addQuantity;
  }
  return filled;
}

int _generatedMainQuantity(List<Map<String, dynamic>> cards) {
  var total = 0;
  for (final card in cards) {
    final quantityRaw = card['quantity'];
    final quantity = quantityRaw is int
        ? quantityRaw
        : int.tryParse(quantityRaw?.toString() ?? '') ?? 1;
    if (quantity > 0) total += quantity;
  }
  return total;
}

Future<Map<String, dynamic>> _buildMockGenerateResponse({
  required Pool pool,
  required String prompt,
  required String format,
  String? requestedCommanderName,
  Map<String, dynamic>? referenceProfile,
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  List<String> unresolvedReferenceCards = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<CommanderReferenceCardStat> archetypeReferenceStats = const [],
  List<String> archetypeSourceCommanderNames = const [],
  List<String> archetypeCommanderColorIdentity = const [],
  List<String> promotedLearnedCardNames = const [],
  List<Map<String, dynamic>> usageHotCards = const [],
  String? warningCode,
  String? warningMessage,
  bool isMock = true,
  String generationMode = 'mock_fallback',
}) async {
  final usageHotCardNames = usageHotCardCanonicalNames(usageHotCards);
  final referenceDeterministicDeck = referenceProfile == null
      ? null
      : buildDeterministicReferenceDeckResult(
          profile: referenceProfile,
          referenceCardStats: referenceCardStats,
          referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
          activeLearnedDeck: activeLearnedDeck,
          promotedLearnedCardNames: promotedLearnedCardNames,
          usageHotCardNames: usageHotCardNames,
        );
  final mockDeck = await _mockGeneratedDeck(
    pool,
    format,
    requestedCommanderName: requestedCommanderName,
    referenceProfile: referenceProfile,
    referenceCardStats: referenceCardStats,
    referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
    activeLearnedDeck: activeLearnedDeck,
    promotedLearnedCardNames: promotedLearnedCardNames,
    usageHotCardNames: usageHotCardNames,
  );

  String? commanderName;
  final commanderRaw = mockDeck['commander'];
  if (commanderRaw is Map && commanderRaw['name'] != null) {
    commanderName = commanderRaw['name']?.toString();
  }

  final cardsRaw = (mockDeck['cards'] as List?) ?? const [];
  final cards = <Map<String, dynamic>>[];
  for (final item in cardsRaw) {
    if (item is Map) {
      cards.add(item.cast<String, dynamic>());
    }
  }

  try {
    final validationService = GeneratedDeckValidationService(
      PostgresGeneratedDeckRepository(pool, preferredFormat: format),
    );

    final validation = await validationService.validate(
      format: format,
      cards: cards,
      commanderName: commanderName,
    );

    final warnings = <String, dynamic>{
      if (warningCode != null) 'code': warningCode,
      if (warningMessage != null) 'message': warningMessage,
      if (validation.warnings.isNotEmpty) 'messages': validation.warnings,
      if (validation.invalidCards.isNotEmpty)
        'invalid_cards': validation.invalidCards,
      if (validation.suggestions.isNotEmpty)
        'suggestions': validation.suggestions,
    };

    Map<String, dynamic>? referenceDeckEvaluation;
    if (referenceProfile != null) {
      final evaluationCards = (validation.generatedDeck['cards'] as List?)
              ?.whereType<Map>()
              .map((card) => card['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      final evaluationMetadata = await loadReferenceEvaluationCardMetadata(
        pool: pool,
        cardNames: evaluationCards,
      );
      referenceDeckEvaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: validation.generatedDeck,
        profile: referenceProfile,
        stats: referenceCardStats,
        cardMetadataByName: evaluationMetadata,
      ).toJson();
    }
    final referenceDeckCorpusDiagnostics = _buildReferenceDeckCorpusDiagnostics(
      generatedDeck: validation.generatedDeck,
      guidance: referenceDeckCorpusGuidance,
    );

    return {
      'prompt': prompt,
      'format': format,
      'generated_deck': validation.generatedDeck,
      'meta_context_used': false,
      'is_mock': isMock,
      'generation_mode': generationMode,
      'stats': {
        'total_suggested': validation.totalSuggestedEntries,
        'total_suggested_cards': validation.totalSuggestedCards,
        'valid_cards': validation.totalResolvedEntries,
        'valid_total_cards': validation.totalResolvedCards,
        'invalid_cards': validation.invalidCards.length,
      },
      'validation': validation.validationSummary(),
      'semantic_layer_v2': _buildSemanticLayerV2GenerateSummary(
        validation.generatedDeck,
      ),
      if (referenceProfile != null)
        'diagnostics': buildCommanderReferenceDiagnostics(
          referenceProfile,
          cardStatsDiagnostics: buildCommanderReferenceCardStatsDiagnostics(
            stats: referenceCardStats,
            unresolvedCardNames: unresolvedReferenceCards,
          ),
          referenceDeckCorpusDiagnostics: referenceDeckCorpusDiagnostics,
          referenceDeckEvaluation: referenceDeckEvaluation,
          referenceDeterministicDeckDiagnostics:
              referenceDeterministicDeck?.toDiagnosticsJson(),
        ),
      if (referenceProfile == null && archetypeReferenceStats.isNotEmpty)
        'diagnostics': buildCommanderReferenceArchetypeStatsDiagnostics(
          stats: archetypeReferenceStats,
          sourceCommanderNames: archetypeSourceCommanderNames,
          commanderColorIdentity: archetypeCommanderColorIdentity,
        ),
      if (warnings.isNotEmpty) 'warnings': warnings,
    };
  } catch (e) {
    return {
      'prompt': prompt,
      'format': format,
      'generated_deck': mockDeck,
      'meta_context_used': false,
      'is_mock': isMock,
      'generation_mode': generationMode,
      'stats': {
        'total_suggested': (mockDeck['cards'] as List?)?.length ?? 0,
        'valid_cards': (mockDeck['cards'] as List?)?.length ?? 0,
        'invalid_cards': 0,
      },
      'validation': {
        'is_valid': false,
        'errors': ['Falha ao validar deck mock: $e'],
        'invalid_cards': const <String>[],
        'suggestions': const <String, List<String>>{},
        'warnings': const <String>[],
      },
      if (referenceProfile != null)
        'diagnostics': buildCommanderReferenceDiagnostics(
          referenceProfile,
          cardStatsDiagnostics: buildCommanderReferenceCardStatsDiagnostics(
            stats: referenceCardStats,
            unresolvedCardNames: unresolvedReferenceCards,
          ),
          referenceDeckCorpusDiagnostics: _buildReferenceDeckCorpusDiagnostics(
            generatedDeck: mockDeck,
            guidance: referenceDeckCorpusGuidance,
          ),
          referenceDeterministicDeckDiagnostics:
              referenceDeterministicDeck?.toDiagnosticsJson(),
        ),
      if (referenceProfile == null && archetypeReferenceStats.isNotEmpty)
        'diagnostics': buildCommanderReferenceArchetypeStatsDiagnostics(
          stats: archetypeReferenceStats,
          sourceCommanderNames: archetypeSourceCommanderNames,
          commanderColorIdentity: archetypeCommanderColorIdentity,
        ),
      if (warningCode != null || warningMessage != null)
        'warnings': {
          if (warningCode != null) 'code': warningCode,
          if (warningMessage != null) 'message': warningMessage,
        },
    };
  }
}

Map<String, dynamic> _buildSemanticLayerV2GenerateSummary(
  Map<String, dynamic> generatedDeck,
) {
  final cards = (generatedDeck['cards'] as List?)
          ?.whereType<Map>()
          .map((card) => card.cast<String, dynamic>())
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  if (cards.isEmpty) {
    return {
      'schema_version': semanticLayerV2SchemaVersion,
      'mode': 'shadow',
      'coverage': {
        'card_rows': 0,
        'tagged_rows': 0,
        'unknown_rows': 0,
      },
      'role_counts': const <String, int>{},
      'note':
          'Semantic v2 is additive and does not replace Commander Reference validation.',
    };
  }

  var taggedRows = 0;
  final counts = <String, int>{};
  for (final card in cards) {
    final name = card['name']?.toString() ?? '';
    final semantic = inferSemanticCardAnalysisV2(
      name: name,
      typeLine: card['type_line']?.toString() ?? '',
      oracleText: card['oracle_text']?.toString() ?? '',
      manaCost: card['mana_cost']?.toString(),
      cmc: card['cmc'],
    );
    if (semantic.tags.isNotEmpty) taggedRows++;
    for (final tag in semantic.tags) {
      counts[tag.tag] = (counts[tag.tag] ?? 0) + 1;
    }
  }

  return {
    'schema_version': semanticLayerV2SchemaVersion,
    'mode': 'shadow',
    'coverage': {
      'card_rows': cards.length,
      'tagged_rows': taggedRows,
      'unknown_rows': cards.length - taggedRows,
    },
    'role_counts': counts,
    'note':
        'Semantic v2 is additive and does not replace Commander Reference validation.',
  };
}

Future<Map<String, dynamic>> _mockGeneratedDeck(
  Pool pool,
  String format, {
  String? requestedCommanderName,
  Map<String, dynamic>? referenceProfile,
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<String> promotedLearnedCardNames = const [],
  List<String> usageHotCardNames = const [],
}) async {
  final normalized = format.trim().toLowerCase();

  if (normalized == 'commander' || normalized == 'edh') {
    if (referenceProfile != null) {
      return _mockReferenceProfileDeck(
        referenceProfile,
        referenceCardStats: referenceCardStats,
        referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
        activeLearnedDeck: activeLearnedDeck,
        promotedLearnedCardNames: promotedLearnedCardNames,
        usageHotCardNames: usageHotCardNames,
      );
    }
    final requestedCommander = requestedCommanderName?.trim();
    if (requestedCommander != null && requestedCommander.isNotEmpty) {
      final resolved = await resolveImportCardNames(
        pool,
        [
          {'name': requestedCommander}
        ],
        preferredFormat: 'commander',
      );
      final card = _bestResolvedCommanderCard(
        requestedCommander: requestedCommander,
        resolved: resolved,
      );
      if (card != null) {
        final colors = resolveCardColorIdentity(
          colorIdentity: _stringIterable(card['color_identity']),
          colors: _stringIterable(card['colors']),
          oracleText: card['oracle_text']?.toString(),
          manaCost: card['mana_cost']?.toString(),
        ).toList()
          ..sort();
        return {
          'commander': {'name': card['name']?.toString() ?? requestedCommander},
          'cards': _buildBasicLandMockCards(
            total: 99,
            colors: colors.isEmpty ? const ['W'] : colors,
          ),
        };
      }
    }

    return {
      'commander': {'name': 'Isamaru, Hound of Konda'},
      'cards': [
        {'name': 'Plains', 'quantity': 99},
      ],
    };
  }

  if (normalized == 'brawl') {
    final resolved = await _pickMockBrawlCommander(pool);
    final commanderName = resolved?['name'] as String?;
    final colors = (resolved?['colors'] as List?)
            ?.map((e) => e.toString().trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        const <String>[];

    final fallbackCommander = commanderName ?? 'Isamaru, Hound of Konda';

    return {
      'commander': {'name': fallbackCommander},
      'cards': _buildBasicLandMockCards(total: 59, colors: colors),
    };
  }

  // 60-card formats: keep it simple and always legal by using only basic lands.
  return {
    'cards': _buildBasicLandMockCards(
      total: 60,
      colors: const ['W', 'U', 'B', 'R', 'G'],
    ),
  };
}

Map<String, dynamic> _mockReferenceProfileDeck(
  Map<String, dynamic> profile, {
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<String> promotedLearnedCardNames = const [],
  List<String> usageHotCardNames = const [],
}) {
  final commanderName =
      (profile['commander'] ?? profile['commander_name'] ?? '')
          .toString()
          .trim();
  if (commanderName.isEmpty) {
    return {
      'commander': {'name': 'Isamaru, Hound of Konda'},
      'cards': [
        {'name': 'Plains', 'quantity': 99},
      ],
    };
  }
  return buildDeterministicReferenceDeck(
    profile: profile,
    referenceCardStats: referenceCardStats,
    referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
    activeLearnedDeck: activeLearnedDeck,
    promotedLearnedCardNames: promotedLearnedCardNames,
    usageHotCardNames: usageHotCardNames,
  );
}

Map<String, dynamic>? _bestResolvedCommanderCard({
  required String requestedCommander,
  required Map<String, Map<String, dynamic>> resolved,
}) {
  if (resolved.isEmpty) return null;
  for (final entry in resolved.entries) {
    if (normalizeCommanderReferenceCardName(entry.key) ==
        normalizeCommanderReferenceCardName(requestedCommander)) {
      return entry.value;
    }
  }
  return resolved.values.first;
}

Iterable<String> _stringIterable(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString());
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((item) => item.trim());
  }
  return const [];
}

List<Map<String, dynamic>> _buildBasicLandMockCards({
  required int total,
  required List<String> colors,
}) {
  if (total <= 0) return const [];

  final colorToBasic = <String, String>{
    'W': 'Plains',
    'U': 'Island',
    'B': 'Swamp',
    'R': 'Mountain',
    'G': 'Forest',
  };

  final selectedBasics = <String>[];
  for (final color in colors) {
    final land = colorToBasic[color.toUpperCase()];
    if (land != null) selectedBasics.add(land);
  }

  final basics = selectedBasics.isNotEmpty ? selectedBasics : const ['Wastes'];
  final per = (total / basics.length).floor();
  final cards = <Map<String, dynamic>>[];

  for (final land in basics) {
    cards.add({'name': land, 'quantity': per});
  }

  var current = cards.fold<int>(0, (sum, c) => sum + (c['quantity'] as int));
  var i = 0;
  while (current < total) {
    cards[i % basics.length]['quantity'] =
        (cards[i % basics.length]['quantity'] as int) + 1;
    current++;
    i++;
  }

  return cards;
}

Future<Map<String, dynamic>?> _pickMockBrawlCommander(Pool pool) async {
  try {
    // Prefer commanders explicitly marked as legal in brawl.
    final result = await pool.execute(
      Sql.named('''
        SELECT c.name, c.color_identity
        FROM cards c
        JOIN card_legalities cl ON cl.card_id = c.id
        WHERE cl.format = 'brawl'
          AND cl.status = 'legal'
          AND lower(c.type_line) LIKE '%legendary%'
          AND lower(c.type_line) LIKE '%creature%'
          AND array_length(c.color_identity, 1) > 0
        ORDER BY RANDOM()
        LIMIT 1
      '''),
    );

    if (result.isNotEmpty) {
      final row = result.first;
      final name = row[0] as String?;
      final colorIdentityRaw = row[1] as List?;
      if (name != null && name.trim().isNotEmpty) {
        return {
          'name': name.trim(),
          'colors': colorIdentityRaw?.map((e) => e.toString()).toList() ??
              const <String>[],
        };
      }
    }

    // If the DB doesn't have brawl legalities populated, pick any multi-colored
    // legendary creature to keep the mock flow usable.
    final fallback = await pool.execute(
      Sql.named('''
        SELECT c.name, c.color_identity
        FROM cards c
        WHERE lower(c.type_line) LIKE '%legendary%'
          AND lower(c.type_line) LIKE '%creature%'
          AND array_length(c.color_identity, 1) > 0
        ORDER BY RANDOM()
        LIMIT 1
      '''),
    );

    if (fallback.isNotEmpty) {
      final row = fallback.first;
      final name = row[0] as String?;
      final colorIdentityRaw = row[1] as List?;
      if (name != null && name.trim().isNotEmpty) {
        return {
          'name': name.trim(),
          'colors': colorIdentityRaw?.map((e) => e.toString()).toList() ??
              const <String>[],
        };
      }
    }
  } catch (e) {
    Log.w('Falha ao escolher comandante mock para brawl: $e');
  }

  return null;
}
