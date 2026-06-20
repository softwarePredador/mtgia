import 'package:server/deck_recommendations_power_level_support.dart';
import 'package:test/test.dart';

void main() {
  group('recommendations fallback bracket power level', () {
    test('keeps partial decks in bracket 1', () {
      expect(
        estimateRecommendationBracketPowerLevel(
          totalCards: 39,
          rampCount: 12,
          drawCount: 10,
          removalCount: 8,
          averageCmc: 2.2,
        ),
        1,
      );
    });

    test('maps average complete decks to bracket 2', () {
      expect(
        estimateRecommendationBracketPowerLevel(
          totalCards: 100,
          rampCount: 8,
          drawCount: 7,
          removalCount: 5,
          averageCmc: 3.1,
        ),
        2,
      );
    });

    test('maps solid engines to bracket 3', () {
      expect(
        estimateRecommendationBracketPowerLevel(
          totalCards: 100,
          rampCount: 10,
          drawCount: 8,
          removalCount: 6,
          averageCmc: 3.0,
        ),
        3,
      );
    });

    test('maps efficient high-density decks to bracket 4', () {
      expect(
        estimateRecommendationBracketPowerLevel(
          totalCards: 100,
          rampCount: 12,
          drawCount: 10,
          removalCount: 6,
          averageCmc: 2.7,
        ),
        4,
      );
    });
  });
}
