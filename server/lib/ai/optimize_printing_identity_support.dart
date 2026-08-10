/// Indexes the concrete deck printing that may be removed for each card name.
///
/// Optimize suggestions are name-based, but apply/rollback authorization is
/// printing-id based. The selected id must therefore come from `deck_cards`,
/// never from an arbitrary global name lookup. When a deck contains multiple
/// printings of the same name, prefer a non-commander row, then the row with
/// more copies, and finally the lexicographically smallest id for stability.
Map<String, Map<String, dynamic>> indexDeckRemovalPrintingsByName(
  Iterable<Map<String, dynamic>> cards,
) {
  final result = <String, Map<String, dynamic>>{};
  for (final card in cards) {
    final name = card['name']?.toString().trim().toLowerCase() ?? '';
    final cardId = card['card_id']?.toString().trim() ?? '';
    if (name.isEmpty || cardId.isEmpty) continue;

    final existing = result[name];
    if (existing == null || _preferCandidate(card, existing)) {
      result[name] = card;
    }
  }
  return result;
}

bool _preferCandidate(
  Map<String, dynamic> candidate,
  Map<String, dynamic> existing,
) {
  final candidateCommander = candidate['is_commander'] == true;
  final existingCommander = existing['is_commander'] == true;
  if (candidateCommander != existingCommander) return !candidateCommander;

  final candidateQuantity = _quantity(candidate['quantity']);
  final existingQuantity = _quantity(existing['quantity']);
  if (candidateQuantity != existingQuantity) {
    return candidateQuantity > existingQuantity;
  }

  return candidate['card_id'].toString().compareTo(
        existing['card_id'].toString(),
      ) <
      0;
}

int _quantity(Object? value) => switch (value) {
  final int quantity => quantity,
  final num quantity => quantity.toInt(),
  final Object quantity => int.tryParse(quantity.toString()) ?? 0,
  null => 0,
};
