import 'dart:convert';

import 'package:crypto/crypto.dart';

class DeckSnapshotIdentity {
  const DeckSnapshotIdentity({required this.hash, required this.capturedAt});

  final String hash;
  final DateTime capturedAt;
}

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
