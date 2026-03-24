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

class DeckAddCardResult {
  const DeckAddCardResult({required this.isSuccess, this.errorMessage});

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
