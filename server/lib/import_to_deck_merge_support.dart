class ImportToDeckMergeResult {
  final List<Map<String, dynamic>> cards;
  final bool commanderDetected;
  final bool commanderPreserved;
  final int totalCards;

  const ImportToDeckMergeResult({
    required this.cards,
    required this.commanderDetected,
    required this.commanderPreserved,
    required this.totalCards,
  });
}

int sumImportToDeckQuantities(List<Map<String, dynamic>> cards) =>
    cards.fold<int>(0, (sum, card) => sum + (card['quantity'] as int? ?? 0));

bool isCommanderImportFormat(String normalizedFormat) =>
    normalizedFormat == 'commander' || normalizedFormat == 'brawl';

ImportToDeckMergeResult mergeImportToDeckCards({
  required List<Map<String, dynamic>> importedCards,
  required List<Map<String, dynamic>> existingCards,
  bool commanderPreserved = false,
}) {
  final byId = <String, Map<String, dynamic>>{};

  for (final card in existingCards) {
    final cardId = card['card_id'] as String;
    byId[cardId] = {
      'card_id': cardId,
      'quantity': card['quantity'] as int? ?? 0,
      'is_commander': card['is_commander'] == true,
      'condition': card['condition']?.toString() ?? 'NM',
    };
  }

  for (final card in importedCards) {
    final cardId = card['card_id'] as String;
    final existing = byId[cardId];
    if (existing == null) {
      byId[cardId] = {
        'card_id': cardId,
        'quantity': card['quantity'] as int? ?? 0,
        'is_commander': card['is_commander'] == true,
        'condition': card['condition']?.toString() ?? 'NM',
      };
      continue;
    }

    byId[cardId] = {
      ...existing,
      'quantity': (existing['quantity'] as int) + (card['quantity'] as int),
      'is_commander':
          (existing['is_commander'] as bool? ?? false) ||
          (card['is_commander'] as bool? ?? false),
    };
  }

  final cards = byId.values.toList();
  return ImportToDeckMergeResult(
    cards: cards,
    commanderDetected: cards.any((card) => card['is_commander'] == true),
    commanderPreserved: commanderPreserved,
    totalCards: sumImportToDeckQuantities(cards),
  );
}

/// O tipo do `DeckReviewArtifact v1` do import em deck existente
/// (DCK-P0-03): a prévia emite, o commit confere.
const importToDeckReviewArtifactKind = 'import_to_deck';

/// A lista final do deck depois do import (DCK-P0-03): soma à lista atual
/// (merge) ou troca a lista inteira (`replace_all`). Na troca, um deck
/// Commander ou Brawl cuja lista importada não traz comandante mantém o
/// comandante atual. É a mesma regra que o import de um tiro aplicava dentro
/// da transação, agora calculada na prévia, sem escrever nada.
ImportToDeckMergeResult resolveImportToDeckFinalCards({
  required List<Map<String, dynamic>> importedCards,
  required List<Map<String, dynamic>> currentCards,
  required bool replaceAll,
  required String normalizedFormat,
}) {
  if (!replaceAll) {
    return mergeImportToDeckCards(
      importedCards: importedCards,
      existingCards: currentCards,
    );
  }
  final importHasCommander = importedCards.any(
    (card) => card['is_commander'] == true,
  );
  if (isCommanderImportFormat(normalizedFormat) && !importHasCommander) {
    final commanders = [
      for (final card in currentCards)
        if (card['is_commander'] == true) card,
    ];
    return mergeImportToDeckCards(
      importedCards: importedCards,
      existingCards: commanders,
      commanderPreserved: commanders.isNotEmpty,
    );
  }
  return mergeImportToDeckCards(
    importedCards: importedCards,
    existingCards: const [],
  );
}

/// A diferença completa entre a lista atual e a final, por `card_id`, para a
/// prévia mostrar antes de confirmar: o que entra, o que sai, o que muda de
/// quantidade, de papel (comandante) ou de condição, e os totais.
Map<String, dynamic> buildImportToDeckDiff({
  required List<Map<String, dynamic>> beforeCards,
  required List<Map<String, dynamic>> afterCards,
  Map<String, String> namesById = const {},
}) {
  Map<String, Map<String, dynamic>> byId(List<Map<String, dynamic>> cards) => {
    for (final card in cards) card['card_id'] as String: card,
  };
  int quantityOf(Map<String, dynamic> card) => card['quantity'] as int? ?? 0;
  bool commanderOf(Map<String, dynamic> card) => card['is_commander'] == true;
  String conditionOf(Map<String, dynamic> card) =>
      card['condition']?.toString() ?? 'NM';
  Map<String, dynamic> entry(Map<String, dynamic> card) => {
    'card_id': card['card_id'],
    'name': namesById[card['card_id']],
    'quantity': quantityOf(card),
    'is_commander': commanderOf(card),
    'condition': conditionOf(card),
  };

  final before = byId(beforeCards);
  final after = byId(afterCards);
  final ids = {...before.keys, ...after.keys}.toList()..sort();
  final added = <Map<String, dynamic>>[];
  final removed = <Map<String, dynamic>>[];
  final changed = <Map<String, dynamic>>[];
  var unchanged = 0;
  for (final id in ids) {
    final previous = before[id];
    final next = after[id];
    if (previous == null) {
      added.add(entry(next!));
    } else if (next == null) {
      removed.add(entry(previous));
    } else if (quantityOf(previous) != quantityOf(next) ||
        commanderOf(previous) != commanderOf(next) ||
        conditionOf(previous) != conditionOf(next)) {
      changed.add({
        'card_id': id,
        'name': namesById[id],
        'quantity_before': quantityOf(previous),
        'quantity_after': quantityOf(next),
        'is_commander_before': commanderOf(previous),
        'is_commander_after': commanderOf(next),
        'condition_before': conditionOf(previous),
        'condition_after': conditionOf(next),
      });
    } else {
      unchanged++;
    }
  }
  List<String?> commanders(Map<String, Map<String, dynamic>> cards) => [
    for (final card in cards.values)
      if (commanderOf(card)) namesById[card['card_id']] ?? card['card_id'],
  ];
  return {
    'added': added,
    'removed': removed,
    'changed': changed,
    'unchanged_count': unchanged,
    'total_before': sumImportToDeckQuantities(beforeCards),
    'total_after': sumImportToDeckQuantities(afterCards),
    'commanders_before': commanders(before),
    'commanders_after': commanders(after),
    'has_changes': added.isNotEmpty || removed.isNotEmpty || changed.isNotEmpty,
  };
}

Map<String, dynamic> buildImportToDeckSuccessBody({
  required String deckId,
  required String normalizedFormat,
  required List<Map<String, dynamic>> importedCards,
  required int totalCards,
  required List<String> notFoundLines,
  required List<Map<String, dynamic>> localizedMatches,
  required List<String> warnings,
  required bool commanderDetected,
  required bool commanderPreserved,
}) {
  return {
    'success': true,
    'deck_id': deckId,
    'cards_imported': sumImportToDeckQuantities(importedCards),
    'total_cards': totalCards,
    'not_found_lines': notFoundLines,
    'localized_matches': localizedMatches,
    'localized_matches_count': localizedMatches.length,
    'warnings': warnings,
    'commander_detected': commanderDetected,
    'missing_commander':
        isCommanderImportFormat(normalizedFormat) && !commanderDetected,
    'commander_preserved': commanderPreserved,
  };
}
