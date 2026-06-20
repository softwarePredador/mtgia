import 'dart:io';

import 'package:server/deck_cards_bulk_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck cards bulk support', () {
    test('preserves existing conditions while applying increments', () {
      final merged = mergeBulkCardIncrementsPreservingCondition(
        currentCards: const [
          {
            'card_id': 'sol-ring',
            'quantity': 1,
            'is_commander': false,
            'condition': 'LP',
          },
          {
            'card_id': 'commander-1',
            'quantity': 1,
            'is_commander': true,
            'condition': 'HP',
          },
        ],
        increments: const [
          {'card_id': 'sol-ring', 'quantity': 2, 'is_commander': false},
          {'card_id': 'new-card', 'quantity': 1, 'is_commander': false},
        ],
      );

      final byId = {
        for (final card in merged) card['card_id'] as String: card,
      };

      expect(byId['sol-ring']?['quantity'], 3);
      expect(byId['sol-ring']?['condition'], 'LP');
      expect(byId['commander-1']?['is_commander'], isTrue);
      expect(byId['commander-1']?['condition'], 'HP');
      expect(byId['new-card']?['quantity'], 1);
      expect(byId['new-card']?['condition'], 'NM');
    });

    test('normalizes blank conditions to NM', () {
      final merged = mergeBulkCardIncrementsPreservingCondition(
        currentCards: const [
          {
            'card_id': 'mind-stone',
            'quantity': 1,
            'is_commander': false,
            'condition': '',
          },
        ],
        increments: const [],
      );

      expect(merged.single['condition'], 'NM');
    });

    test('bulk route keeps condition column through delete and reinsert', () {
      final source =
          File('routes/decks/[id]/cards/bulk/index.dart').readAsStringSync();

      expect(
        source,
        contains('mergeBulkCardIncrementsPreservingCondition'),
      );
      expect(
        source,
        contains(
          'SELECT card_id::text, quantity::int, is_commander, condition',
        ),
      );
      expect(
        source,
        contains(
          'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)',
        ),
      );
      expect(source, contains("params[pCond] = card['condition'] ?? 'NM'"));
    });
  });
}
