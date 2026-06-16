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

    test('parses bullets, comments, collection suffixes and duplicate names',
        () {
      final cards = parseCommanderLearnedDeckCards('''
1 Korvold, Fae-Cursed King
2 Forest
- 1 Sol Ring # ramp
1 Command Tower (CMM) 123
''');

      expect(
        cards.map((card) => (card.name, card.quantity)).toList(),
        containsAll([
          ('Korvold, Fae-Cursed King', 1),
          ('Forest', 2),
          ('Sol Ring', 1),
          ('Command Tower', 1),
        ]),
      );
    });

    test('validates Commander 100-card learned deck gate', () {
      final main = List.generate(99, (index) => '1 Learned Card $index');
      final input = parseCommanderLearnedDeckInput({
        'id': 82,
        'commander': 'Lorehold, the Historian',
        'card_list': ['1 Lorehold, the Historian', ...main].join('\n'),
        'card_count': 100,
      });

      final validation = validateCommanderLearnedDeckInput(input);

      expect(validation.ok, isTrue);
      expect(validation.parsedCardCount, equals(100));
      expect(validation.commanderQuantity, equals(1));
      expect(validation.mainQuantity, equals(99));
      expect(validation.blockers, isEmpty);
    });

    test('blocks learned deck import when count or commander slot is invalid',
        () {
      final input = parseCommanderLearnedDeckInput({
        'id': 83,
        'commander': 'Lorehold, the Historian',
        'card_list': '1 Sol Ring\n1 Mountain',
        'card_count': 100,
      });

      final validation = validateCommanderLearnedDeckInput(input);

      expect(validation.ok, isFalse);
      expect(
        validation.blockers.join('\n'),
        contains('card_count declarado (100) difere do total parseado (2)'),
      );
      expect(
        validation.blockers.join('\n'),
        contains('exatamente 1 comandante'),
      );
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
      expect(route, contains('commander_learning_snapshot'));
      expect(route, contains("'source': 'pg_commander_learning_snapshot'"));
      expect(route, contains("'source': 'pg_commander_learned_decks'"));
      expect(route, contains("'commanders': activeDecks"));
      expect(route, contains("'recommended_deck': recommendedDeck"));
      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
      expect(route, contains("'source_confidence': _sourceConfidence"));
      expect(route, contains("'win_conditions': _winConditions"));
      expect(route, contains("'role_summary': _roleSummary"));
      expect(route, isNot(contains("'metadata': learnedDeck.metadata")));
      expect(route, isNot(contains("'metadata': deck.metadata")));
    });

    test('commander reference does not expose raw learned deck metadata', () {
      final route =
          File('routes/ai/commander-reference/index.dart').readAsStringSync();

      expect(route, contains("'source': 'promoted_learned_deck_pg'"));
      expect(route, isNot(contains("'metadata': learnedDeck['metadata']")));
    });

    test('commander learning route stays auth-only in AI middleware', () {
      final middleware = File('routes/ai/_middleware.dart').readAsStringSync();

      expect(middleware, contains("'/ai/commander-learning'"));
      expect(middleware, contains('authOnlyHandler'));
      expect(middleware, contains('costlyAiHandler'));
      expect(
        middleware.indexOf("'/ai/commander-learning'"),
        lessThan(middleware.indexOf('return costlyAiHandler(context)')),
      );
    });
  });
}
