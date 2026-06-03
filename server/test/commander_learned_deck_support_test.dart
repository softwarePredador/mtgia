import 'dart:io';

import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander learned deck support', () {
    test('parses raw Hermes learned deck payload into idempotent PG input', () {
      final input = parseCommanderLearnedDeckInput({
        'id': 82,
        'commander': 'Lorehold, the Historian',
        'deck_name': 'Lorehold Best-of Learned No Premium Mox 2026-06-02',
        'source_url': 'manual-import:f3d63c68be1f3fa7',
        'archetype': 'fast-mana-copy-combo-big-spells-no-premium-mox',
        'card_list': '1 Lorehold, the Historian\n1 Sol Ring\n2 Mountain',
        'score': 136.5,
        'metadata': {'hermes_active_deck_id': 6},
      });

      expect(input.sourceSystem, equals('hermes'));
      expect(input.sourceRef, equals('learned_deck:82'));
      expect(input.commanderNameNormalized, equals('lorehold, the historian'));
      expect(input.cardCount, equals(4));
      expect(input.cards.map((card) => card.name), contains('Sol Ring'));
      expect(input.metadata['hermes_learned_deck_id'], equals(82));
      expect(input.metadata['hermes_active_deck_id'], equals(6));
      expect(input.isActive, isTrue);
    });

    test('route prefers promoted learned deck before deterministic fallback',
        () {
      final route =
          File('routes/ai/commander-reference/index.dart').readAsStringSync();
      final promotedIndex =
          route.indexOf('_buildPromotedCommanderLearningDeck');
      final fallbackIndex = route.indexOf('_buildReferenceLearningDeck');

      expect(promotedIndex, greaterThanOrEqualTo(0));
      expect(fallbackIndex, greaterThanOrEqualTo(0));
      expect(promotedIndex, lessThan(fallbackIndex));
      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
    });

    test('dedicated route exposes promoted learned deck payload', () {
      final route =
          File('routes/ai/commander-learning/index.dart').readAsStringSync();

      expect(route, contains('commander_learned_decks'));
      expect(route, contains("'source': 'pg_commander_learned_decks'"));
      expect(route, contains("'recommended_deck': recommendedDeck"));
      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
    });
  });
}
