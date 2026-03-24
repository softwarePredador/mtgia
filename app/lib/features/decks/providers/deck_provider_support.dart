import 'dart:convert';

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
