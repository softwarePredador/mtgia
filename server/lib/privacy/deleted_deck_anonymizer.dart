/// Anonimização do deck de quem excluiu a conta dentro do replay de outra
/// pessoa (D-23: simulações de terceiros contra o deck público de quem saiu
/// ficam com quem as rodou, sem apontar para quem saiu).
library;

/// Texto que ocupa o lugar do UUID do deck apagado.
const deletedDeckPlaceholderId = 'deck-removido';

/// Texto que ocupa o lugar do nome do deck apagado.
const deletedDeckPlaceholderName = 'Deck removido';

const _deckObjectIdKeys = {'id', 'deck_id'};
const _deckObjectNameKeys = {'name', 'deck_name'};

final _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}',
);

/// Devolve [value] (JSON decodificado) sem os decks de [deletedDeckIds]:
/// todo UUID desses decks vira [deletedDeckPlaceholderId] e, no objeto que
/// representa um deles (chave `id` ou `deck_id`), o nome vira
/// [deletedDeckPlaceholderName]. Cartas, eventos e os demais decks ficam como
/// estão.
Object? anonymizeDeletedDeckReferences(
  Object? value,
  Iterable<String> deletedDeckIds,
) {
  final ids = {for (final id in deletedDeckIds) id.toLowerCase()};
  if (ids.isEmpty) return value;

  bool isDeletedDeck(Object? id) =>
      id is String && ids.contains(id.trim().toLowerCase());

  Object? walk(Object? node) {
    if (node is Map) {
      final isDeckObject = _deckObjectIdKeys.any(
        (key) => isDeletedDeck(node[key]),
      );
      return <String, dynamic>{
        for (final MapEntry(key: key, value: entry) in node.entries)
          key.toString():
              isDeckObject && _deckObjectNameKeys.contains(key)
                  ? deletedDeckPlaceholderName
                  : walk(entry),
      };
    }
    if (node is List) return [for (final item in node) walk(item)];
    if (node is String) {
      return node.replaceAllMapped(
        _uuidPattern,
        (match) =>
            ids.contains(match[0]!.toLowerCase())
                ? deletedDeckPlaceholderId
                : match[0]!,
      );
    }
    return node;
  }

  return walk(value);
}
