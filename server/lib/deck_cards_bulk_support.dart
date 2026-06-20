int? _readPositiveInt(Object? value) {
  if (value is int) return value > 0 ? value : null;
  final parsed = int.tryParse('${value ?? ''}');
  return parsed != null && parsed > 0 ? parsed : null;
}

String _readCardId(Object? value) => value?.toString().trim() ?? '';

String normalizeDeckCardCondition(Object? value) {
  final condition = value?.toString().trim();
  return condition == null || condition.isEmpty ? 'NM' : condition;
}

List<Map<String, dynamic>> mergeBulkCardIncrementsPreservingCondition({
  required Iterable<Map<String, dynamic>> currentCards,
  required Iterable<Map<String, dynamic>> increments,
}) {
  final byId = <String, Map<String, dynamic>>{};

  for (final card in currentCards) {
    final cardId = _readCardId(card['card_id']);
    if (cardId.isEmpty) continue;
    byId[cardId] = {
      'card_id': cardId,
      'quantity': _readPositiveInt(card['quantity']) ?? 0,
      'is_commander': card['is_commander'] == true,
      'condition': normalizeDeckCardCondition(card['condition']),
    };
  }

  for (final item in increments) {
    final cardId = _readCardId(item['card_id']);
    final quantity = _readPositiveInt(item['quantity']);
    if (cardId.isEmpty || quantity == null) continue;

    final existing = byId[cardId];
    if (existing == null) {
      byId[cardId] = {
        'card_id': cardId,
        'quantity': quantity,
        'is_commander': false,
        'condition': normalizeDeckCardCondition(item['condition']),
      };
      continue;
    }

    byId[cardId] = {
      ...existing,
      'quantity': (existing['quantity'] as int) + quantity,
    };
  }

  return byId.values.toList(growable: false);
}
