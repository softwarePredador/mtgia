import '../../../core/api/api_client.dart';
import '../models/deck.dart';
import '../models/deck_details.dart';
import 'deck_provider_support_common.dart';

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
  final hydratedDecks = applyCachedColorIdentitiesToDeckList(
    fetchedDecks,
    cache,
  );
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
