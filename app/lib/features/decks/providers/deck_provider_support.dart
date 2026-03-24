import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../models/deck.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/deck_details.dart';

class DeckAiFlowException implements Exception {
  DeckAiFlowException({
    required this.message,
    required this.code,
    required this.payload,
    this.outcomeCode,
  });

  final String message;
  final String code;
  final String? outcomeCode;
  final Map<String, dynamic> payload;

  Map<String, dynamic> get qualityError =>
      (payload['quality_error'] is Map)
          ? (payload['quality_error'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  Map<String, dynamic> get nextAction =>
      (payload['next_action'] is Map)
          ? (payload['next_action'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  Map<String, dynamic> get deckState =>
      (payload['deck_state'] is Map)
          ? (payload['deck_state'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};

  bool get isNeedsRepair =>
      outcomeCode == 'needs_repair' || code == 'OPTIMIZE_NEEDS_REPAIR';

  bool get isNearPeak => outcomeCode == 'near_peak';

  bool get isNoSafeUpgradeFound =>
      outcomeCode == 'no_safe_upgrade_found' ||
      code == 'OPTIMIZE_NO_SAFE_SWAPS' ||
      code == 'OPTIMIZE_NO_ACTIONABLE_SWAPS';

  @override
  String toString() => message;
}

class DeckDetailsFetchState {
  const DeckDetailsFetchState({
    required this.selectedDeck,
    required this.errorMessage,
    required this.statusCode,
  });

  final DeckDetails? selectedDeck;
  final String? errorMessage;
  final int? statusCode;
}

class DeckListFetchState {
  const DeckListFetchState({required this.decks, required this.errorMessage});

  final List<Deck>? decks;
  final String? errorMessage;
}

class DeckDeleteResult {
  const DeckDeleteResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckDeleteState {
  const DeckDeleteState({
    required this.decks,
    required this.selectedDeck,
  });

  final List<Deck> decks;
  final DeckDetails? selectedDeck;
}

class DeckAddCardResult {
  const DeckAddCardResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckMutationResult {
  const DeckMutationResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckCreateResult {
  const DeckCreateResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

class DeckAiAnalysisPayload {
  const DeckAiAnalysisPayload({
    required this.raw,
    required this.synergyScore,
    required this.strengths,
    required this.weaknesses,
  });

  final Map<String, dynamic> raw;
  final int? synergyScore;
  final String? strengths;
  final String? weaknesses;
}

class DeckColorIdentityEnrichmentResult {
  const DeckColorIdentityEnrichmentResult({
    required this.detailsByDeckId,
    required this.failedDeckIds,
  });

  final Map<String, DeckDetails> detailsByDeckId;
  final List<String> failedDeckIds;
}

class DeckListHydrationResult {
  const DeckListHydrationResult({
    required this.decks,
    required this.missingColorIdentityDecks,
  });

  final List<Deck> decks;
  final List<Deck> missingColorIdentityDecks;
}

class DeckColorIdentityApplyResult {
  const DeckColorIdentityApplyResult({
    required this.decks,
    required this.cachedDetails,
    required this.enrichedCount,
  });

  final List<Deck> decks;
  final List<DeckDetails> cachedDetails;
  final int enrichedCount;
}

class OptimizeDeckRequestResult {
  const OptimizeDeckRequestResult._({
    required this.isAsync,
    this.result,
    this.jobId,
    this.pollIntervalMs,
    this.totalStages,
  });

  const OptimizeDeckRequestResult.completed(Map<String, dynamic> result)
    : this._(isAsync: false, result: result);

  const OptimizeDeckRequestResult.async({
    required String jobId,
    required int pollIntervalMs,
    required int totalStages,
  }) : this._(
         isAsync: true,
         jobId: jobId,
         pollIntervalMs: pollIntervalMs,
         totalStages: totalStages,
       );

  final bool isAsync;
  final Map<String, dynamic>? result;
  final String? jobId;
  final int? pollIntervalMs;
  final int? totalStages;
}

class RebuildDeckRequestResult {
  const RebuildDeckRequestResult({
    required this.payload,
    this.draftDeckId,
  });

  final Map<String, dynamic> payload;
  final String? draftDeckId;
}

class DeckPersistResult {
  const DeckPersistResult({
    required this.validation,
    required this.elapsedMilliseconds,
  });

  final Map<String, dynamic> validation;
  final int elapsedMilliseconds;
}

class OptimizeJobPollResult {
  const OptimizeJobPollResult.completed(this.result)
    : isCompleted = true,
      stage = null,
      stageNumber = null,
      totalStages = null;

  const OptimizeJobPollResult.pending({
    required this.stage,
    required this.stageNumber,
    required this.totalStages,
  }) : isCompleted = false,
       result = null;

  final bool isCompleted;
  final Map<String, dynamic>? result;
  final String? stage;
  final int? stageNumber;
  final int? totalStages;
}

class NamedOptimizationApplyResult {
  const NamedOptimizationApplyResult({
    required this.currentCards,
    required this.skippedForIdentity,
    required this.hasStructuralChange,
  });

  final Map<String, Map<String, dynamic>> currentCards;
  final List<String> skippedForIdentity;
  final bool hasStructuralChange;
}

class NamedOptimizationPayloadResult {
  const NamedOptimizationPayloadResult({
    required this.cardsPayload,
    required this.skippedForIdentity,
  });

  final List<Map<String, dynamic>> cardsPayload;
  final List<String> skippedForIdentity;
}

Map<String, Map<String, dynamic>> buildCurrentCardsMap(DeckDetails deck) {
  final currentCards = <String, Map<String, dynamic>>{};

  for (final commander in deck.commander) {
    currentCards[commander.id] = {
      'card_id': commander.id,
      'quantity': commander.quantity,
      'is_commander': true,
    };
  }

  for (final entry in deck.mainBoard.entries) {
    for (final card in entry.value) {
      if (!card.isCommander) {
        currentCards[card.id] = {
          'card_id': card.id,
          'quantity': card.quantity,
          'is_commander': false,
        };
      }
    }
  }

  return currentCards;
}

DeckDetails? readFreshDeckDetailsFromCache({
  required Map<String, DeckDetails> cache,
  required Map<String, DateTime> cacheTimes,
  required String deckId,
  required Duration cacheDuration,
}) {
  final cachedDeck = cache[deckId];
  if (cachedDeck == null) return null;
  final cacheTime = cacheTimes[deckId];
  if (cacheTime == null) return null;
  if (DateTime.now().difference(cacheTime) >= cacheDuration) return null;
  return cachedDeck;
}

void storeDeckDetailsInCache({
  required Map<String, DeckDetails> cache,
  required Map<String, DateTime> cacheTimes,
  required DeckDetails deck,
}) {
  cache[deck.id] = deck;
  cacheTimes[deck.id] = DateTime.now();
}

List<Deck> syncDeckColorIdentityToList(
  List<Deck> decks,
  String deckId,
  List<String> colorIdentity,
) {
  if (colorIdentity.isEmpty) return decks;
  return decks
      .map(
        (deck) =>
            deck.id == deckId && deck.colorIdentity.isEmpty
                ? deck.copyWith(colorIdentity: colorIdentity)
                : deck,
      )
      .toList();
}

List<Deck> applyCachedColorIdentitiesToDeckList(
  List<Deck> decks,
  Map<String, DeckDetails> cache,
) {
  return decks.map((deck) {
    if (deck.colorIdentity.isNotEmpty) return deck;
    final cached = cache[deck.id];
    if (cached == null || cached.colorIdentity.isEmpty) return deck;
    return deck.copyWith(colorIdentity: cached.colorIdentity);
  }).toList();
}

DeckListHydrationResult buildDeckListHydrationResult(
  List<Deck> fetchedDecks,
  Map<String, DeckDetails> cache,
) {
  final hydratedDecks = applyCachedColorIdentitiesToDeckList(fetchedDecks, cache);
  return DeckListHydrationResult(
    decks: hydratedDecks,
    missingColorIdentityDecks: decksMissingColorIdentity(hydratedDecks),
  );
}

List<Deck> decksMissingColorIdentity(List<Deck> decks) {
  return decks
      .where((deck) => deck.colorIdentity.isEmpty && deck.cardCount > 0)
      .toList();
}

DeckDetailsFetchState parseDeckDetailsResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    return DeckDetailsFetchState(
      selectedDeck: DeckDetails.fromJson(response.data as Map<String, dynamic>),
      errorMessage: null,
      statusCode: 200,
    );
  }

  if (response.statusCode == 401) {
    final data = response.data;
    final message =
        (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Sessão expirada. Faça login novamente.';
    return DeckDetailsFetchState(
      selectedDeck: null,
      errorMessage: message,
      statusCode: 401,
    );
  }

  return DeckDetailsFetchState(
    selectedDeck: null,
    errorMessage: 'Erro ao carregar detalhes do deck: ${response.statusCode}',
    statusCode: response.statusCode,
  );
}

Future<DeckDetailsFetchState> fetchDeckDetailsRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.get('/decks/$deckId');
  return parseDeckDetailsResponse(response);
}

DeckListFetchState parseDeckListResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = response.data as List<dynamic>;
    return DeckListFetchState(
      decks:
          data
              .map((json) => Deck.fromJson(json as Map<String, dynamic>))
              .toList(),
      errorMessage: null,
    );
  }

  if (response.statusCode == 401) {
    return const DeckListFetchState(
      decks: null,
      errorMessage: 'Sessão expirada. Faça login novamente.',
    );
  }

  return DeckListFetchState(
    decks: null,
    errorMessage: 'Erro ao carregar decks: ${response.statusCode}',
  );
}

Future<DeckListFetchState> fetchDeckListRequest(ApiClient apiClient) async {
  final response = await apiClient.get('/decks');
  return parseDeckListResponse(response);
}

Future<DeckColorIdentityEnrichmentResult> fetchMissingDeckColorIdentities(
  ApiClient apiClient,
  List<Deck> decks,
) async {
  final detailsByDeckId = <String, DeckDetails>{};
  final failedDeckIds = <String>[];

  for (final deck in decks) {
    try {
      final state = await fetchDeckDetailsRequest(apiClient, deck.id);
      final details = state.selectedDeck;
      if (details != null && details.colorIdentity.isNotEmpty) {
        detailsByDeckId[deck.id] = details;
      }
    } catch (_) {
      failedDeckIds.add(deck.id);
    }
  }

  return DeckColorIdentityEnrichmentResult(
    detailsByDeckId: detailsByDeckId,
    failedDeckIds: failedDeckIds,
  );
}

DeckColorIdentityApplyResult applyDeckColorIdentityEnrichment(
  List<Deck> decks,
  DeckColorIdentityEnrichmentResult result,
) {
  var nextDecks = decks;
  final cachedDetails = <DeckDetails>[];

  for (final details in result.detailsByDeckId.values) {
    cachedDetails.add(details);
    nextDecks = syncDeckColorIdentityToList(
      nextDecks,
      details.id,
      details.colorIdentity,
    );
  }

  return DeckColorIdentityApplyResult(
    decks: nextDecks,
    cachedDetails: cachedDetails,
    enrichedCount: cachedDetails.length,
  );
}

DeckDeleteResult parseDeleteDeckResponse(ApiResponse response) {
  if (response.statusCode == 200 || response.statusCode == 204) {
    return const DeckDeleteResult(isSuccess: true);
  }
  return DeckDeleteResult(
    isSuccess: false,
    errorMessage: 'Erro ao deletar deck: ${response.statusCode}',
  );
}

Future<DeckDeleteResult> deleteDeckRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.delete('/decks/$deckId');
  return parseDeleteDeckResponse(response);
}

DeckDeleteState applyDeckDeletionToState(
  List<Deck> decks,
  DeckDetails? selectedDeck,
  String deckId,
) {
  return DeckDeleteState(
    decks: decks.where((deck) => deck.id != deckId).toList(),
    selectedDeck:
        selectedDeck != null && selectedDeck.id == deckId ? null : selectedDeck,
  );
}

DeckCreateResult parseCreateDeckResponse(ApiResponse response) {
  if (response.statusCode == 200 || response.statusCode == 201) {
    return const DeckCreateResult(isSuccess: true);
  }
  return DeckCreateResult(
    isSuccess: false,
    errorMessage: extractApiError(
      response.data,
      fallback: 'Erro ao criar deck: ${response.statusCode}',
    ),
  );
}

Future<DeckCreateResult> createDeckRequest(
  ApiClient apiClient, {
  required String name,
  required String format,
  String? description,
  required bool isPublic,
  required List<Map<String, dynamic>> cards,
}) async {
  final response = await apiClient.post('/decks', {
    'name': name,
    'format': format,
    'description': description,
    'is_public': isPublic,
    'cards': cards,
  });
  return parseCreateDeckResponse(response);
}

DeckAddCardResult parseAddCardResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    return const DeckAddCardResult(isSuccess: true);
  }

  var message = 'Erro ao adicionar carta: ${response.statusCode}';
  if (response.data is Map && response.data['error'] != null) {
    message = response.data['error'].toString();
  }
  return DeckAddCardResult(isSuccess: false, errorMessage: message);
}

Future<DeckAddCardResult> addCardToDeckRequest(
  ApiClient apiClient, {
  required String deckId,
  required String cardId,
  required int quantity,
  required bool isCommander,
  required String condition,
}) async {
  final response = await apiClient.post('/decks/$deckId/cards', {
    'card_id': cardId,
    'quantity': quantity,
    'is_commander': isCommander,
    'condition': condition,
  });
  return parseAddCardResponse(response);
}

Future<DeckMutationResult> addCardsBulkRequest(
  ApiClient apiClient, {
  required String deckId,
  required List<Map<String, dynamic>> cards,
}) async {
  final response = await apiClient.post('/decks/$deckId/cards/bulk', {
    'cards': cards,
  });
  return parseDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao adicionar em lote',
  );
}

DeckMutationResult parseDeckMutationResponse(
  ApiResponse response, {
  required String fallbackMessage,
}) {
  if (response.statusCode == 200) {
    return const DeckMutationResult(isSuccess: true);
  }

  final data = response.data;
  final message =
      (data is Map && data['error'] != null)
          ? data['error'].toString()
          : '$fallbackMessage: ${response.statusCode}';
  return DeckMutationResult(isSuccess: false, errorMessage: message);
}

Future<DeckMutationResult> removeCardFromDeckRequest(
  ApiClient apiClient, {
  required String deckId,
  required List<Map<String, dynamic>> cardsPayload,
}) async {
  final response = await apiClient.put('/decks/$deckId', {'cards': cardsPayload});
  return parseDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao remover carta',
  );
}

Future<DeckMutationResult> setDeckCardQuantityRequest(
  ApiClient apiClient, {
  required String deckId,
  required String cardId,
  required int quantity,
  required bool replaceSameName,
  required String condition,
}) async {
  final response = await apiClient.post('/decks/$deckId/cards/set', {
    'card_id': cardId,
    'quantity': quantity,
    'replace_same_name': replaceSameName,
    'condition': condition,
  });
  return parseDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao atualizar carta',
  );
}

List<Deck> incrementDeckCardCount(
  List<Deck> decks,
  String deckId, {
  required int delta,
}) {
  return decks
      .map(
        (deck) =>
            deck.id == deckId
                ? deck.copyWith(cardCount: deck.cardCount + delta)
                : deck,
      )
      .toList();
}

DeckAiAnalysisPayload parseDeckAiAnalysisResponse(ApiResponse response) {
  if (response.statusCode != 200) {
    final data = response.data;
    final msg =
        (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Falha ao analisar deck: ${response.statusCode}';
    throw Exception(msg);
  }

  final data = (response.data as Map).cast<String, dynamic>();
  return DeckAiAnalysisPayload(
    raw: data,
    synergyScore: data['synergy_score'] as int?,
    strengths: data['strengths'] as String?,
    weaknesses: data['weaknesses'] as String?,
  );
}

Future<DeckAiAnalysisPayload> refreshAiAnalysisRequest(
  ApiClient apiClient,
  String deckId, {
  required bool force,
}) async {
  final response = await apiClient.post('/decks/$deckId/ai-analysis', {
    'force': force,
  });
  return parseDeckAiAnalysisResponse(response);
}

List<Map<String, dynamic>> parseOptimizationOptionsResponse(
  ApiResponse response,
) {
  if (response.statusCode == 200) {
    final data = response.data as Map<String, dynamic>;
    return (data['options'] as List).cast<Map<String, dynamic>>();
  }
  throw Exception('Falha ao buscar opções: ${response.statusCode}');
}

Future<List<Map<String, dynamic>>> fetchOptimizationOptionsRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.post('/ai/archetypes', {'deck_id': deckId});
  return parseOptimizationOptionsResponse(response);
}

Map<String, dynamic> parseDeckValidationResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    return (response.data as Map).cast<String, dynamic>();
  }

  if (response.data is Map) {
    final body = (response.data as Map).cast<String, dynamic>();
    if (body['ok'] == false) return body;
  }
  throw Exception('Falha ao validar deck: ${response.statusCode}');
}

Future<Map<String, dynamic>> validateDeckRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.post('/decks/$deckId/validate', {});
  return parseDeckValidationResponse(response);
}

Future<DeckPersistResult> persistDeckCardsPayloadWithValidation(
  ApiClient apiClient, {
  required String deckId,
  required List<Map<String, dynamic>> cardsPayload,
}) async {
  final stopwatch = Stopwatch()..start();
  await persistDeckCardsPayloadRequest(
    apiClient,
    deckId: deckId,
    cardsPayload: cardsPayload,
  );
  stopwatch.stop();
  final validation = await validateDeckRequest(apiClient, deckId);
  return DeckPersistResult(
    validation: validation,
    elapsedMilliseconds: stopwatch.elapsedMilliseconds,
  );
}

Map<String, dynamic> parseDeckPricingResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    return (response.data as Map).cast<String, dynamic>();
  }
  final data = response.data;
  final msg =
      (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Falha ao calcular custo: ${response.statusCode}';
  throw Exception(msg);
}

Future<Map<String, dynamic>> fetchDeckPricingRequest(
  ApiClient apiClient,
  String deckId, {
  required bool force,
}) async {
  final response = await apiClient.post('/decks/$deckId/pricing', {
    'force': force,
  });
  return parseDeckPricingResponse(response);
}

void ensureSuccessfulDeckMutationResponse(
  ApiResponse response, {
  required String fallbackMessage,
}) {
  if (response.statusCode == 200) {
    return;
  }
  final data = response.data;
  final msg =
      (data is Map && data['error'] != null)
          ? data['error'].toString()
          : '$fallbackMessage: ${response.statusCode}';
  throw Exception(msg);
}

Future<void> persistDeckCardsPayloadRequest(
  ApiClient apiClient, {
  required String deckId,
  required List<Map<String, dynamic>> cardsPayload,
}) async {
  final response = await apiClient.put('/decks/$deckId', {
    'cards': cardsPayload,
  });
  ensureSuccessfulDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao atualizar deck',
  );
}

Future<void> updateDeckDescriptionRequest(
  ApiClient apiClient, {
  required String deckId,
  required String description,
}) async {
  final response = await apiClient.put('/decks/$deckId', {
    'description': description,
  });
  ensureSuccessfulDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao atualizar descrição',
  );
}

Future<void> updateDeckStrategyRequest(
  ApiClient apiClient, {
  required String deckId,
  required String archetype,
  required int bracket,
}) async {
  final response = await apiClient.put('/decks/$deckId', {
    'archetype': archetype,
    'bracket': bracket,
  });
  ensureSuccessfulDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao salvar estratégia',
  );
}

Future<void> replaceCardEditionRequest(
  ApiClient apiClient, {
  required String deckId,
  required String oldCardId,
  required String newCardId,
}) async {
  final response = await apiClient.post('/decks/$deckId/cards/replace', {
    'old_card_id': oldCardId,
    'new_card_id': newCardId,
  });
  ensureSuccessfulDeckMutationResponse(
    response,
    fallbackMessage: 'Falha ao trocar edição',
  );
}

DeckDetails? applyAiAnalysisToSelectedDeck(
  DeckDetails? selectedDeck,
  String deckId, {
  required int? synergyScore,
  required String? strengths,
  required String? weaknesses,
}) {
  if (selectedDeck == null || selectedDeck.id != deckId) {
    return selectedDeck;
  }
  return selectedDeck.copyWith(
    synergyScore: synergyScore,
    strengths: strengths,
    weaknesses: weaknesses,
  );
}

List<Deck> applyAiAnalysisToDeckList(
  List<Deck> decks,
  String deckId, {
  required int? synergyScore,
  required String? strengths,
  required String? weaknesses,
}) {
  return decks
      .map(
        (deck) =>
            deck.id == deckId
                ? deck.copyWith(
                  synergyScore: synergyScore,
                  strengths: strengths,
                  weaknesses: weaknesses,
                )
                : deck,
      )
      .toList();
}

Set<String>? getCommanderIdentitySet(DeckDetails? deck) {
  if (deck == null) return null;
  if (deck.commander.isEmpty) return null;
  final commander = deck.commander.first;
  final identity =
      commander.colorIdentity.isNotEmpty
          ? commander.colorIdentity
          : commander.colors;
  return identity.map((e) => e.toUpperCase()).toSet();
}

List<Map<String, dynamic>> extractCardSearchResults(dynamic responseData) {
  if (responseData is Map && responseData['data'] is List) {
    return (responseData['data'] as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  if (responseData is List) {
    return responseData
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  return const <Map<String, dynamic>>[];
}

Future<List<T>> resolveCardNamesInParallel<T>({
  required List<String> cardNames,
  required Future<T?> Function(String cardName) resolver,
}) async {
  final results = await Future.wait(cardNames.map(resolver));
  return results.whereType<T>().toList();
}

Map<String, dynamic> asDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

DeckAiFlowException buildDeckAiFlowException(
  dynamic data, {
  required String fallbackMessage,
  required String fallbackCode,
}) {
  final payload = asDynamicMap(data);
  final qualityError = asDynamicMap(payload['quality_error']);
  final message =
      payload['error']?.toString() ??
      qualityError['message']?.toString() ??
      fallbackMessage;
  final code = qualityError['code']?.toString() ?? fallbackCode;
  final outcomeCode = payload['outcome_code']?.toString();
  return DeckAiFlowException(
    message: message,
    code: code,
    outcomeCode: outcomeCode,
    payload: payload,
  );
}

Future<void> saveOptimizeDebugSnapshot({
  Map<String, dynamic>? request,
  Map<String, dynamic>? response,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (request != null) {
      await prefs.setString(
        'debug_last_ai_optimize_request',
        jsonEncode(request),
      );
    }
    if (response != null) {
      await prefs.setString(
        'debug_last_ai_optimize_response',
        jsonEncode(response),
      );
    }
    await prefs.setString(
      'debug_last_ai_optimize_at',
      DateTime.now().toIso8601String(),
    );
  } catch (_) {
    // Silencioso: não deve quebrar fluxo do app.
  }
}

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
    await saveOptimizeDebugSnapshot(response: {
      'statusCode': 422,
      'data': data,
    });
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

  await saveOptimizeDebugSnapshot(response: {
    'statusCode': response.statusCode,
    'data': response.data,
  });
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
        fallbackCode:
            qualityError['code']?.toString() ?? 'OPTIMIZE_JOB_FAILED',
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

List<Map<String, dynamic>> buildOptimizedCardPayload({
  required DeckDetails deck,
  required List<Map<String, dynamic>> removalsDetailed,
  required List<Map<String, dynamic>> additionsDetailed,
}) {
  final currentCards = <String, Map<String, dynamic>>{};
  final commanderIds = <String>{};

  for (final commander in deck.commander) {
    commanderIds.add(commander.id);
    currentCards[commander.id] = {
      'card_id': commander.id,
      'quantity': 1,
      'is_commander': true,
    };
  }

  for (final entry in deck.mainBoard.entries) {
    for (final card in entry.value) {
      if (commanderIds.contains(card.id)) continue;
      currentCards[card.id] = {
        'card_id': card.id,
        'quantity': card.quantity,
        'is_commander': false,
      };
    }
  }

  for (final removal in removalsDetailed) {
    final cardId = removal['card_id'] as String?;
    if (cardId == null) continue;
    if (!currentCards.containsKey(cardId)) continue;
    final existing = currentCards[cardId]!;
    final qty = (existing['quantity'] as int) - 1;
    if (qty <= 0) {
      currentCards.remove(cardId);
    } else {
      currentCards[cardId] = {...existing, 'quantity': qty};
    }
  }

  final format = deck.format.toLowerCase();
  final isCommander = format == 'commander' || format == 'brawl';
  final defaultLimit = isCommander ? 1 : 4;
  const basicLandNames = {
    'plains',
    'island',
    'swamp',
    'mountain',
    'forest',
    'wastes',
    'snow-covered plains',
    'snow-covered island',
    'snow-covered swamp',
    'snow-covered mountain',
    'snow-covered forest',
  };

  for (final addition in additionsDetailed) {
    final cardId = addition['card_id'] as String?;
    if (cardId == null || cardId.isEmpty) continue;

    final isBasicFromServer = addition['is_basic_land'] as bool? ?? false;
    final typeLine = ((addition['type_line'] as String?) ?? '').toLowerCase();
    final cardName = ((addition['name'] as String?) ?? '').toLowerCase().trim();
    final isBasicLand =
        isBasicFromServer ||
        typeLine.contains('basic land') ||
        basicLandNames.contains(cardName);
    final limit = isBasicLand ? 99 : defaultLimit;

    if (currentCards.containsKey(cardId)) {
      final existing = currentCards[cardId]!;
      final newQty = (existing['quantity'] as int) + 1;
      if (newQty <= limit) {
        currentCards[cardId] = {...existing, 'quantity': newQty};
      }
    } else {
      currentCards[cardId] = {
        'card_id': cardId,
        'quantity': 1,
        'is_commander': false,
      };
    }
  }

  return currentCards.values.toList();
}

Map<String, int> buildRemovalCounts(List<String> cardIds) {
  final removalCounts = <String, int>{};
  for (final id in cardIds) {
    removalCounts[id] = (removalCounts[id] ?? 0) + 1;
  }
  return removalCounts;
}

Set<String> buildCurrentCardSnapshot(
  Map<String, Map<String, dynamic>> currentCards,
) {
  return currentCards.values
      .map((c) => '${c['card_id']}::${c['quantity']}::${c['is_commander']}')
      .toSet();
}

void applyRemovalCountsToCurrentCards({
  required Map<String, Map<String, dynamic>> currentCards,
  required Map<String, int> removalCounts,
}) {
  for (final idToRemove in removalCounts.keys) {
    if (!currentCards.containsKey(idToRemove)) continue;
    final existing = currentCards[idToRemove]!;
    final currentQty = existing['quantity'] as int? ?? 0;
    final removeQty = removalCounts[idToRemove] ?? 0;
    final newQty = currentQty - removeQty;

    if (newQty <= 0) {
      currentCards.remove(idToRemove);
    } else {
      currentCards[idToRemove] = {...existing, 'quantity': newQty};
    }
  }
}

bool isCardWithinCommanderIdentity(
  Map<String, dynamic> card, {
  required Set<String>? commanderIdentity,
}) {
  if (commanderIdentity == null) return true;
  final identity =
      (card['color_identity'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  return identity.every((c) => commanderIdentity.contains(c.toUpperCase()));
}

int applyAdditionsToCurrentCards({
  required Map<String, Map<String, dynamic>> currentCards,
  required List<Map<String, dynamic>> cardsToAdd,
  required String format,
  required Set<String>? commanderIdentity,
}) {
  final normalizedFormat = format.toLowerCase();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';
  final defaultLimit = isCommander ? 1 : 4;
  var applied = 0;

  for (final cardToAdd in cardsToAdd) {
    final cardId = cardToAdd['card_id'] as String?;
    if (cardId == null || cardId.isEmpty) continue;

    if (!isCardWithinCommanderIdentity(
      cardToAdd,
      commanderIdentity: commanderIdentity,
    )) {
      continue;
    }

    final typeLine = (cardToAdd['type_line'] as String? ?? '').toLowerCase();
    final isBasicLand = typeLine.contains('basic land');
    final limit = isBasicLand ? 99 : defaultLimit;

    if (currentCards.containsKey(cardId)) {
      final existing = currentCards[cardId]!;
      final newQuantity = (existing['quantity'] as int? ?? 0) + 1;
      if (newQuantity <= limit) {
        currentCards[cardId] = {...existing, 'quantity': newQuantity};
        applied++;
      }
      continue;
    }

    currentCards[cardId] = cardToAdd;
    applied++;
  }

  return applied;
}

NamedOptimizationApplyResult buildNamedOptimizationApplyResult({
  required DeckDetails deck,
  required List<String> cardsToRemoveIds,
  required List<Map<String, dynamic>> cardsToAddIds,
}) {
  final currentCards = buildCurrentCardsMap(deck);
  final beforeSnapshot = buildCurrentCardSnapshot(currentCards);

  final removalCounts = buildRemovalCounts(cardsToRemoveIds);
  applyRemovalCountsToCurrentCards(
    currentCards: currentCards,
    removalCounts: removalCounts,
  );

  final normalizedFormat = deck.format.toLowerCase();
  final isCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';
  final commanderIdentity = isCommander ? getCommanderIdentitySet(deck) : null;

  final skippedForIdentity =
      cardsToAddIds
          .where(
            (card) =>
                !isCardWithinCommanderIdentity(
                  card,
                  commanderIdentity: commanderIdentity,
                ),
          )
          .map((card) => card['card_id'])
          .whereType<String>()
          .toList();

  applyAdditionsToCurrentCards(
    currentCards: currentCards,
    cardsToAdd: cardsToAddIds,
    format: normalizedFormat,
    commanderIdentity: commanderIdentity,
  );

  final afterSnapshot = buildCurrentCardSnapshot(currentCards);

  return NamedOptimizationApplyResult(
    currentCards: currentCards,
    skippedForIdentity: skippedForIdentity,
    hasStructuralChange:
        beforeSnapshot.length != afterSnapshot.length ||
        !beforeSnapshot.containsAll(afterSnapshot),
  );
}

Future<NamedOptimizationPayloadResult> buildNamedOptimizationPayload(
  ApiClient apiClient, {
  required DeckDetails deck,
  required List<String> cardsToRemove,
  required List<String> cardsToAdd,
}) async {
  final cardsToAddIds = await resolveOptimizationAdditions(apiClient, cardsToAdd);
  final cardsToRemoveIds = await resolveOptimizationRemovals(
    apiClient,
    cardsToRemove,
  );

  if (cardsToAdd.isNotEmpty && cardsToAddIds.isEmpty) {
    throw Exception(
      'Nenhuma das cartas sugeridas para adicionar foi encontrada no banco. Tente novamente.',
    );
  }
  if (cardsToRemove.isNotEmpty && cardsToRemoveIds.isEmpty) {
    throw Exception(
      'Nenhuma das cartas sugeridas para remover foi encontrada no banco. Tente novamente.',
    );
  }

  final applyResult = buildNamedOptimizationApplyResult(
    deck: deck,
    cardsToRemoveIds: cardsToRemoveIds,
    cardsToAddIds: cardsToAddIds,
  );

  if (!applyResult.hasStructuralChange) {
    throw Exception('Nenhuma mudança aplicável foi encontrada para este deck.');
  }

  return NamedOptimizationPayloadResult(
    cardsPayload: applyResult.currentCards.values.toList(),
    skippedForIdentity: applyResult.skippedForIdentity,
  );
}

Map<String, dynamic> buildImportDeckRequestBody({
  required String name,
  required String format,
  required String list,
  String? description,
  String? commander,
}) {
  return {
    'name': name,
    'format': format,
    'list': list,
    if (description != null && description.isNotEmpty)
      'description': description,
    if (commander != null && commander.isNotEmpty) 'commander': commander,
  };
}

Map<String, dynamic> parseImportDeckResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'deck': data['deck'],
      'cards_imported': data['cards_imported'] ?? 0,
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ??
        'Erro ao importar deck: ${response.statusCode}',
    'not_found_lines':
        (data['not_found'] is List)
            ? List<String>.from(data['not_found'])
            : const <String>[],
  };
}

Future<Map<String, dynamic>> importDeckFromListRequest(
  ApiClient apiClient, {
  required String name,
  required String format,
  required String list,
  String? description,
  String? commander,
}) async {
  final response = await apiClient.post(
    '/import',
    buildImportDeckRequestBody(
      name: name,
      format: format,
      list: list,
      description: description,
      commander: commander,
    ),
  );
  return parseImportDeckResponse(response);
}

Map<String, dynamic> buildConnectionFailureResult(Object error) {
  return {'success': false, 'error': 'Erro de conexão: $error'};
}

Map<String, dynamic> buildExportConnectionFailureResult(Object error) {
  return {'error': 'Erro de conexão: $error'};
}

Future<Map<String, dynamic>> runConnectionSafeMapRequest(
  Future<Map<String, dynamic>> Function() operation,
) async {
  try {
    return await operation();
  } catch (error) {
    return buildConnectionFailureResult(error);
  }
}

Map<String, dynamic> parseValidateImportListResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'found_cards': data['found_cards'] ?? const <dynamic>[],
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error': data['error']?.toString() ?? 'Erro ao validar lista',
  };
}

Future<Map<String, dynamic>> validateImportListRequest(
  ApiClient apiClient, {
  required String format,
  required String list,
}) async {
  final response = await apiClient.post('/import/validate', {
    'format': format,
    'list': list,
  });
  return parseValidateImportListResponse(response);
}

Map<String, dynamic> buildImportToDeckRequestBody({
  required String deckId,
  required String list,
  required bool replaceAll,
}) {
  return {'deck_id': deckId, 'list': list, 'replace_all': replaceAll};
}

Map<String, dynamic> parseImportToDeckResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'cards_imported': data['cards_imported'] ?? 0,
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ?? 'Erro ao importar: ${response.statusCode}',
    'not_found_lines':
        (data['not_found_lines'] is List)
            ? List<String>.from(data['not_found_lines'])
            : const <String>[],
  };
}

Future<Map<String, dynamic>> importListToDeckRequest(
  ApiClient apiClient, {
  required String deckId,
  required String list,
  required bool replaceAll,
}) async {
  final response = await apiClient.post(
    '/import/to-deck',
    buildImportToDeckRequestBody(
      deckId: deckId,
      list: list,
      replaceAll: replaceAll,
    ),
  );
  return parseImportToDeckResponse(response);
}

DeckDetails? applyDeckVisibilityToSelectedDeck(
  DeckDetails? selectedDeck,
  String deckId, {
  required bool isPublic,
}) {
  if (selectedDeck == null || selectedDeck.id != deckId) {
    return selectedDeck;
  }
  return selectedDeck.copyWith(isPublic: isPublic);
}

List<Deck> applyDeckVisibilityToDeckList(
  List<Deck> decks,
  String deckId, {
  required bool isPublic,
}) {
  return decks
      .map(
        (deck) => deck.id == deckId ? deck.copyWith(isPublic: isPublic) : deck,
      )
      .toList();
}

Map<String, dynamic> parseDeckExportResponse(ApiResponse response) {
  if (response.statusCode == 200 && response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }
  return {'error': 'Falha ao exportar deck: ${response.statusCode}'};
}

Future<bool> togglePublicRequest(
  ApiClient apiClient, {
  required String deckId,
  required bool isPublic,
}) async {
  final response = await apiClient.put('/decks/$deckId', {
    'is_public': isPublic,
  });
  return response.statusCode == 200;
}

Future<Map<String, dynamic>> exportDeckAsTextRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.get('/decks/$deckId/export');
  return parseDeckExportResponse(response);
}

Map<String, dynamic> parseCopyPublicDeckResponse(ApiResponse response) {
  if (response.statusCode == 201) {
    final data = asDynamicMap(response.data);
    return {'success': true, 'deck': data['deck']};
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ??
        'Falha ao copiar deck: ${response.statusCode}',
  };
}

Future<Map<String, dynamic>> copyPublicDeckRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.post('/community/decks/$deckId', {});
  return parseCopyPublicDeckResponse(response);
}

String extractApiError(dynamic data, {required String fallback}) {
  if (data is Map) {
    final error = data['error'] ?? data['message'];
    if (error != null) {
      final text = error.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  return fallback;
}

Future<List<Map<String, dynamic>>> normalizeCreateDeckCards(
  ApiClient apiClient,
  List<Map<String, dynamic>> cards,
) async {
  if (cards.isEmpty) return const [];

  final aggregatedByCardId = <String, Map<String, dynamic>>{};
  final aggregatedByName = <String, Map<String, dynamic>>{};

  for (final card in cards) {
    final quantity = (card['quantity'] as int?) ?? 1;
    final isCommander = (card['is_commander'] as bool?) ?? false;
    final cardId = (card['card_id'] as String?)?.trim();
    final name = (card['name'] as String?)?.trim();

    if (cardId != null && cardId.isNotEmpty) {
      final key = '$cardId::$isCommander';
      final existing = aggregatedByCardId[key];
      if (existing == null) {
        aggregatedByCardId[key] = {
          'card_id': cardId,
          'quantity': quantity,
          'is_commander': isCommander,
        };
      } else {
        aggregatedByCardId[key] = {
          ...existing,
          'quantity': (existing['quantity'] as int) + quantity,
        };
      }
      continue;
    }

    if (name == null || name.isEmpty) {
      throw Exception('Cada carta precisa de card_id ou name.');
    }

    final key = '${name.toLowerCase()}::$isCommander';
    final existing = aggregatedByName[key];
    if (existing == null) {
      aggregatedByName[key] = {
        'name': name,
        'quantity': quantity,
        'is_commander': isCommander,
      };
    } else {
      aggregatedByName[key] = {
        ...existing,
        'quantity': (existing['quantity'] as int) + quantity,
      };
    }
  }

  final normalized =
      aggregatedByCardId.values
          .map((card) => Map<String, dynamic>.from(card))
          .toList();

  if (aggregatedByName.isEmpty) {
    return normalized;
  }

  final names =
      aggregatedByName.values
          .map((card) => (card['name'] as String).trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

  if (names.isEmpty) return normalized;

  final response = await apiClient.post('/cards/resolve/batch', {
    'names': names,
  });

  if (response.statusCode != 200 || response.data is! Map) {
    throw Exception(
      extractApiError(
        response.data,
        fallback: 'Falha ao resolver cartas antes de criar o deck.',
      ),
    );
  }

  final payload = response.data as Map<String, dynamic>;
  final resolvedList = (payload['data'] as List?) ?? const [];
  final unresolvedList = (payload['unresolved'] as List?) ?? const [];
  final ambiguousList = (payload['ambiguous'] as List?) ?? const [];

  final cardIdByInputName = <String, String>{};
  for (final item in resolvedList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    final cardId = item['card_id']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    if (cardId == null || cardId.isEmpty) continue;
    cardIdByInputName[inputName.toLowerCase()] = cardId;
  }

  final unresolvedNames =
      unresolvedList
          .map((item) => item.toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet();
  final ambiguousNames = <String>{};

  for (final item in ambiguousList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    final candidates =
        (item['candidates'] as List?)
            ?.map((candidate) => candidate.toString().trim())
            .where((candidate) => candidate.isNotEmpty)
            .toList() ??
        const <String>[];
    if (candidates.isEmpty) {
      ambiguousNames.add(inputName);
    } else {
      ambiguousNames.add('$inputName (${candidates.join(', ')})');
    }
  }

  for (final card in aggregatedByName.values) {
    final name = (card['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    final cardId = cardIdByInputName[name.toLowerCase()];
    if (cardId == null || cardId.isEmpty) {
      unresolvedNames.add(name);
      continue;
    }

    normalized.add({
      'card_id': cardId,
      'quantity': card['quantity'] ?? 1,
      'is_commander': card['is_commander'] ?? false,
    });
  }

  if (unresolvedNames.isNotEmpty || ambiguousNames.isNotEmpty) {
    final sortedNames =
        {...unresolvedNames, ...ambiguousNames}.toList()..sort();
    throw Exception(
      'Nao foi possivel resolver todas as cartas antes de criar o deck: '
      '${sortedNames.join(', ')}.',
    );
  }

  return normalized;
}

Future<Map<String, dynamic>> generateDeckFromPrompt(
  ApiClient apiClient, {
  required String prompt,
  required String format,
}) async {
  final response = await apiClient.post('/ai/generate', {
    'prompt': prompt,
    'format': format,
  });

  if (response.statusCode == 200) {
    return response.data as Map<String, dynamic>;
  }

  final data = response.data;
  final message =
      data is Map<String, dynamic>
          ? (data['error'] as String? ??
              data['message'] as String? ??
              'Falha ao gerar deck')
          : 'Falha ao gerar deck';
  throw Exception('$message (${response.statusCode})');
}

Future<Map<String, dynamic>?> searchFirstCardByName(
  ApiClient apiClient,
  String cardName,
) async {
  final encoded = Uri.encodeQueryComponent(cardName);
  final searchResponse = await apiClient.get('/cards?name=$encoded&limit=1');

  if (searchResponse.statusCode != 200) {
    return null;
  }

  final results = extractCardSearchResults(searchResponse.data);
  if (results.isEmpty) {
    return null;
  }

  return results.first;
}

Future<List<Map<String, dynamic>>> resolveOptimizationAdditions(
  ApiClient apiClient,
  List<String> cardsToAdd,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a adicionar...');
  return resolveCardNamesInParallel<Map<String, dynamic>>(
    cardNames: cardsToAdd,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug('  ✅ Encontrado: $cardName -> ${card['id']}');
          return {
            'card_id': card['id'],
            'quantity': 1,
            'is_commander': false,
            'type_line': card['type_line'] ?? '',
            'color_identity':
                (card['color_identity'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[],
          };
        }
        AppLogger.debug('  ❌ Não encontrado: $cardName');
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}

Future<List<String>> resolveOptimizationRemovals(
  ApiClient apiClient,
  List<String> cardsToRemove,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a remover...');
  return resolveCardNamesInParallel<String>(
    cardNames: cardsToRemove,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando para remover: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug(
            '  ✅ Encontrado para remoção: $cardName -> ${card['id']}',
          );
          return card['id'] as String;
        }
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}
