import 'dart:io';

import 'package:server/ai/commander_reference_generate_fallback_support.dart';
import 'package:test/test.dart';

void main() {
  group('AI generate learning boundary guards', () {
    test(
        '/ai/generate has no direct learned-deck SQL but can use learned-deck evidence',
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
      expect(generateRoute, contains('loadActiveCommanderLearnedDeck('));
      expect(
        generateRoute,
        contains('activeCommanderLearnedDeckCardNames(activeLearnedDeck)'),
      );
      expect(generateRoute, contains('buildDeterministicReferenceDeck('));
      expect(generateRoute, contains('GeneratedDeckValidationService('));
      expect(
        generateRoute,
        contains("generationMode: 'reference_deterministic'"),
      );
      expect(generateRoute, contains('isMock: false'));
      expect(
        generateRoute,
        contains('activeLearnedDeck: activeLearnedDeck'),
      );
      expect(
        generateRoute,
        contains('promotedLearnedCardNames: promotedLearnedCardNames'),
      );

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

    test('deterministic generate source precedence names learned deck first',
        () {
      expect(
        deterministicReferenceDeckSourcePrecedence,
        equals([
          'active_learned_deck',
          'reference_card_stats',
          'reference_corpus_packages',
          'profile_expected_packages',
          'usage_hot_cards',
          'deterministic_fallback',
        ]),
      );
    });

    test('coherent generate response exposes deterministic source diagnostics',
        () {
      final generateRoute =
          File('routes/ai/generate/index.dart').readAsStringSync();
      final primaryResponseStart = generateRoute.indexOf(
        'final referenceDeterministicDeckDiagnostics = referenceProfile == null',
      );
      final fallbackHelperStart = generateRoute
          .indexOf('Future<Map<String, dynamic>> _buildMockGenerateResponse');

      expect(primaryResponseStart, greaterThanOrEqualTo(0));
      expect(fallbackHelperStart, greaterThan(primaryResponseStart));
      final primaryResponseSegment = generateRoute.substring(
        primaryResponseStart,
        fallbackHelperStart,
      );

      expect(
        primaryResponseSegment,
        contains('referenceDeterministicDeckDiagnostics'),
      );
      expect(
        primaryResponseSegment,
        contains('buildDeterministicReferenceDeckResult('),
      );
      expect(primaryResponseSegment, contains('toDiagnosticsJson()'));
    });

    test('generate fallback preserves original validation quality evidence',
        () {
      final generateRoute =
          File('routes/ai/generate/index.dart').readAsStringSync();

      expect(
        generateRoute,
        contains("'original_validation_quality_evidence'"),
      );
      expect(
        generateRoute,
        contains('validation.qualityEvidenceSummary()'),
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
