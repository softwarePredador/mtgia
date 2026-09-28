import 'dart:convert';

import 'package:crypto/crypto.dart';

class DeckSnapshotIdentity {
  const DeckSnapshotIdentity({required this.hash, required this.capturedAt});

  final String hash;

  /// O instante da versão do deck ([deckVersionAtSql]), não o da leitura.
  final DateTime capturedAt;
}

/// `deck_version_at` (LC-P0-05, achado 3 dos fluxos): o instante da revisão
/// atual do deck, não o da requisição. É o `created_at` do evento do ledger
/// que levou o deck à revisão de agora (DCK-P0-01), ou a criação do deck na
/// revisão 1. Ler de novo a mesma revisão devolve o mesmo instante; mudar o
/// deck muda a revisão e o instante. Deck sem data de criação (legado) fica
/// com um instante fixo, também estável.
///
/// Fragmento SQL sobre uma linha de `decks` com o apelido [alias].
String deckVersionAtSql(String alias) =>
    'COALESCE(('
    'SELECT version_event.created_at FROM deck_change_events version_event '
    'WHERE version_event.deck_id = $alias.id '
    'AND version_event.revision_after = $alias.revision'
    '), $alias.created_at, '
    "TIMESTAMPTZ '1970-01-01 00:00:00+00')";

/// Builds the stable gameplay identity of a saved deck version.
///
/// Presentation-only printing metadata is intentionally excluded. The
/// identity changes when the deck name, format, playable rows, quantities or
/// commander role change.
String buildDeckSnapshotHash({
  required String name,
  required String format,
  required Iterable<Map<String, dynamic>> cards,
}) {
  final normalized = cards
    .map(
      (card) => <String, dynamic>{
        'card_id': (card['card_id'] ?? card['id'])?.toString() ?? '',
        'quantity': _quantity(card['quantity']),
        'is_commander': card['is_commander'] == true,
      },
    )
    .toList(growable: true)..sort((left, right) {
    final idComparison = (left['card_id'] as String).compareTo(
      right['card_id'] as String,
    );
    if (idComparison != 0) return idComparison;
    final leftCommander = left['is_commander'] == true ? 0 : 1;
    final rightCommander = right['is_commander'] == true ? 0 : 1;
    return leftCommander.compareTo(rightCommander);
  });

  if (normalized.isEmpty) {
    normalized.add(const {'card_id': '', 'quantity': 0, 'is_commander': false});
  }

  final canonical = normalized
      .map(
        (card) => [
          name,
          format,
          card['card_id'],
          card['quantity'],
          card['is_commander'] == true ? '1' : '0',
        ].join('|'),
      )
      .join('\n');
  return sha256.convert(utf8.encode(canonical)).toString();
}

int _quantity(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
