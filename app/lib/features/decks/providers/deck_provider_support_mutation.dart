import '../../../core/api/api_client.dart';
import '../models/deck.dart';
import '../models/deck_details.dart';
import 'deck_provider_support_common.dart';
import 'deck_provider_support_generation.dart';

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
  final response = await apiClient.put('/decks/$deckId', {
    'cards': cardsPayload,
  });
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
  final cardsToAddIds = await resolveOptimizationAdditions(
    apiClient,
    cardsToAdd,
  );
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
