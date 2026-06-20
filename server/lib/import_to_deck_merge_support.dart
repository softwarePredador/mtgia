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
      'is_commander': (existing['is_commander'] as bool? ?? false) ||
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
