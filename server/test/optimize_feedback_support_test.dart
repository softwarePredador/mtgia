import 'package:server/ai/optimize_feedback_support.dart';
import 'package:test/test.dart';

void main() {
  group('buildOptimizeMlFeedback', () {
    test('records successful accepted additions with high score', () {
      final feedback = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: 'user-1',
        archetype: 'control',
        commanderName: 'Talrand, Sky Summoner',
        operationMode: 'optimize',
        outcomeCode: 'optimized',
        statusCode: 200,
        removals: const ['Cancel'],
        additions: const ['Arcane Signet', 'arcane signet'],
      );

      expect(feedback.shouldRecord, isTrue);
      expect(feedback.cardsAccepted, equals(const ['Arcane Signet']));
      expect(feedback.cardsRejected, isEmpty);
      expect(feedback.effectivenessScore, equals(5));
      expect(feedback.userComment, contains('outcome=optimized'));
      expect(feedback.userComment, contains('score=5'));
    });

    test('downgrades successful results with blocked or warning signals', () {
      final feedback = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: 'user-1',
        archetype: 'artifact',
        commanderName: 'Lorehold, the Historian',
        operationMode: 'optimize',
        outcomeCode: 'optimized',
        statusCode: 200,
        removals: const ['Expensive Rock'],
        additions: const ['Mana Crypt'],
        validationWarnings: const ['warning'],
        blockedByBracket: const [
          {'name': 'Mana Crypt', 'reason': 'above_bracket'},
        ],
      );

      expect(feedback.cardsAccepted, equals(const ['Mana Crypt']));
      expect(feedback.cardsRejected, equals(const ['Mana Crypt']));
      expect(feedback.effectivenessScore, equals(4));
      expect(feedback.userComment, contains('warnings=1'));
      expect(feedback.userComment, contains('blocked_bracket=1'));
    });

    test('captures rejected optimize payload as rejected cards', () {
      final feedback = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: 'user-1',
        archetype: 'midrange',
        commanderName: null,
        operationMode: 'optimize',
        outcomeCode: 'quality_rejected',
        statusCode: 422,
        removals: const ['Swords to Plowshares'],
        additions: const ['Off Color Bomb'],
        qualityError: const {'code': 'OPTIMIZE_QUALITY_REJECTED'},
      );

      expect(feedback.cardsAccepted, isEmpty);
      expect(
        feedback.cardsRejected,
        equals(const ['Swords to Plowshares', 'Off Color Bomb']),
      );
      expect(feedback.effectivenessScore, equals(2));
      expect(
          feedback.userComment, contains('quality=OPTIMIZE_QUALITY_REJECTED'));
    });

    test('scores rebuild or no-op as neutral review feedback', () {
      final rebuild = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: 'user-1',
        archetype: 'spellslinger',
        commanderName: 'Talrand, Sky Summoner',
        operationMode: 'rebuild_guided',
        outcomeCode: 'rebuild_guided',
        statusCode: 200,
        removals: const ['Cancel'],
        additions: const ['Counterspell'],
      );
      final noOp = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: 'user-1',
        archetype: 'spellslinger',
        commanderName: 'Talrand, Sky Summoner',
        operationMode: 'optimize',
        outcomeCode: 'no_action',
        statusCode: 200,
        removals: const [],
        additions: const [],
      );

      expect(rebuild.effectivenessScore, equals(3));
      expect(noOp.effectivenessScore, equals(3));
    });

    test('skips runtime recording when deck or user context is missing', () {
      final missingUser = buildOptimizeMlFeedback(
        deckId: 'deck-1',
        userId: null,
        archetype: 'control',
        commanderName: null,
        operationMode: 'optimize',
        outcomeCode: 'optimized',
        statusCode: 200,
        removals: const ['Cancel'],
        additions: const ['Counterspell'],
      );
      final missingDeck = buildOptimizeMlFeedback(
        deckId: '',
        userId: 'user-1',
        archetype: 'control',
        commanderName: null,
        operationMode: 'optimize',
        outcomeCode: 'optimized',
        statusCode: 200,
        removals: const ['Cancel'],
        additions: const ['Counterspell'],
      );

      expect(missingUser.shouldRecord, isFalse);
      expect(missingDeck.shouldRecord, isFalse);
    });
  });
}
