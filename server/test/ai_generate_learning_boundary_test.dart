import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI generate learning boundary guards', () {
    test(
        '/ai/generate stays reference-driven and does not read learned decks directly',
        () {
      final generateRoute =
          File('routes/ai/generate/index.dart').readAsStringSync();

      expect(
        generateRoute,
        contains('loadUsableCommanderReferenceProfile('),
      );
      expect(
        generateRoute,
        contains('loadUsableCommanderReferenceCardStats('),
      );
      expect(
        generateRoute,
        contains('loadCommanderReferenceDeckCorpusGuidance('),
      );
      expect(generateRoute, contains('loadUsageHotCards('));
      expect(generateRoute, contains('buildDeterministicReferenceDeck('));
      expect(generateRoute, contains('GeneratedDeckValidationService('));
      expect(
        generateRoute,
        contains("generationMode: 'reference_deterministic'"),
      );
      expect(generateRoute, contains('isMock: false'));

      expect(generateRoute, isNot(contains('commander_learned_decks')));
      expect(generateRoute, isNot(contains('commander_learning_snapshot')));
      expect(
        generateRoute,
        isNot(contains('promoted_learned_deck_pg')),
      );
      expect(
        generateRoute,
        isNot(contains('GET /ai/commander-learning')),
      );
    });

    test(
        '/ai/commander-learning remains the explicit learned-deck product route',
        () {
      final learningRoute = File(
        'routes/ai/commander-learning/index.dart',
      ).readAsStringSync();

      expect(learningRoute, contains('FROM commander_learned_decks'));
      expect(learningRoute, contains("'source': 'pg_commander_learned_decks'"));
      expect(
        learningRoute,
        contains("'source': 'pg_commander_learned_deck_summary'"),
      );
      expect(learningRoute, contains("'source': 'promoted_learned_deck_pg'"));
    });
  });
}
