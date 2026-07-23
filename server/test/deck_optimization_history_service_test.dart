import 'package:server/decks/deck_optimization_history_service.dart';
import 'package:test/test.dart';

void main() {
  group('DeckOptimizationHistoryService', () {
    test('builds an order-independent condition-aware deck signature', () {
      final first = <Map<String, dynamic>>[
        {
          'card_id': 'card-b',
          'quantity': 2,
          'is_commander': false,
          'condition': 'lp',
        },
        {'card_id': 'card-a', 'quantity': 1, 'is_commander': true},
      ];
      final reordered = <Map<String, dynamic>>[
        {
          'card_id': 'card-a',
          'quantity': 1,
          'is_commander': true,
          'condition': 'NM',
        },
        {
          'card_id': 'card-b',
          'quantity': 2,
          'is_commander': false,
          'condition': 'LP',
        },
      ];

      expect(
        DeckOptimizationHistoryService.buildDeckSignature(first),
        DeckOptimizationHistoryService.buildDeckSignature(reordered),
      );
      expect(
        DeckOptimizationHistoryService.buildDeckSignature(first),
        'card-a:1:NM|card-b:2:LP',
      );
    });

    test('stores full reversible snapshots around an apply event', () {
      final normalized =
          DeckOptimizationHistoryService.normalizeMutationContext(
            const {
              'type': 'optimization_apply',
              'source': 'optimize_preview',
              'mode': 'optimize',
              'removals': [
                {'card_id': 'old-card'},
              ],
              'additions': [
                {'card_id': 'new-card'},
              ],
              'before_snapshot': {'average_cmc': 3.2},
              'after_snapshot': {'average_cmc': 9.9},
            },
            beforeCardsPayload: const [
              {
                'card_id': 'old-card',
                'quantity': 1,
                'is_commander': false,
                'condition': 'NM',
              },
            ],
            afterCardsPayload: const [
              {
                'card_id': 'new-card',
                'quantity': 1,
                'is_commander': false,
                'condition': 'NM',
              },
            ],
            beforeValidation: const {
              'validation_state': 'validated',
              'validation_reasons': <String>[],
              'validation_updated_at': '2026-07-22T08:00:00.000Z',
            },
            afterValidation: const {
              'validation_state': 'validated',
              'validation_reasons': <String>[],
              'validation_updated_at': '2026-07-22T08:05:00.000Z',
            },
            beforeDeckMetadata: const {'archetype': null, 'bracket': null},
            afterDeckMetadata: const {'archetype': 'control', 'bracket': 2},
            authoritativeAfterAnalysis: const {
              'average_cmc': 3.0,
              'source': 'postgres_persisted_card_catalog',
              'analysis_scope': 'accepted_changes_only',
            },
          );

      final before = normalized['before_snapshot'] as Map;
      final after = normalized['after_snapshot'] as Map;
      expect(before['signature'], 'old-card:1:NM');
      expect(after['signature'], 'new-card:1:NM');
      expect((before['cards'] as List), hasLength(1));
      expect((after['cards'] as List), hasLength(1));
      expect((before['analysis'] as Map)['average_cmc'], 3.2);
      expect((after['analysis'] as Map)['average_cmc'], 3.0);
      expect(
        (after['analysis'] as Map)['source'],
        'postgres_persisted_card_catalog',
      );
      expect((before['metadata'] as Map)['archetype'], isNull);
      expect((after['metadata'] as Map)['bracket'], 2);
      expect(((before['validation'] as Map)['validation_state']), 'validated');
    });

    test('extracts only normalized cards from a rollback snapshot', () {
      final cards = DeckOptimizationHistoryService.cardsFromSnapshot({
        'cards': [
          {'card_id': 'card-2', 'quantity': 1, 'condition': ''},
          {'card_id': '', 'quantity': 1},
          {'card_id': 'card-1', 'quantity': 0},
        ],
      });

      expect(cards, [
        {
          'card_id': 'card-2',
          'quantity': 1,
          'is_commander': false,
          'condition': 'NM',
        },
      ]);
    });
  });
}
