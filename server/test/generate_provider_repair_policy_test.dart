import 'package:server/ai/generate_provider_repair_policy.dart';
import 'package:server/generated_deck_validation_service.dart';
import 'package:test/test.dart';

void main() {
  group('AI generate provider repair policy', () {
    test('accepts a strictly valid high-coverage repair', () {
      final decision = evaluateAiGenerateProviderRepair(
        _result(
          invalidCards: const ['Imaginary Card'],
          suggested: 70,
          resolved: 69,
        ),
      );

      expect(decision.eligible, isTrue);
      expect(decision.reason, 'strictly_valid_bounded_provider_repair');
      expect(decision.removedCardCount, 1);
      expect(decision.resolvedCardRatio, closeTo(69 / 70, 0.0001));
    });

    test('rejects a repair when the final deck is invalid', () {
      final decision = evaluateAiGenerateProviderRepair(
        _result(
          errors: const ['Deck size is invalid'],
          invalidCards: const ['Imaginary Card'],
          suggested: 60,
          resolved: 59,
        ),
      );

      expect(decision.eligible, isFalse);
      expect(decision.reason, 'final_deck_failed_strict_validation');
    });

    test('rejects broad provider hallucination even if repair validates', () {
      final tooManyEntries = evaluateAiGenerateProviderRepair(
        _result(
          invalidCards: const [
            'Fake One',
            'Fake Two',
            'Fake Three',
            'Fake Four',
          ],
          suggested: 70,
          resolved: 66,
        ),
      );
      final lowCoverage = evaluateAiGenerateProviderRepair(
        _result(
          invalidCards: const ['Fake One', 'Fake Two'],
          suggested: 20,
          resolved: 16,
        ),
      );

      expect(tooManyEntries.eligible, isFalse);
      expect(tooManyEntries.reason, 'too_many_unresolved_entries');
      expect(lowCoverage.eligible, isFalse);
      expect(lowCoverage.reason, 'resolved_card_ratio_below_policy');
    });

    test('does not label an unchanged provider deck as repaired', () {
      final decision = evaluateAiGenerateProviderRepair(
        _result(suggested: 60, resolved: 60),
      );

      expect(decision.eligible, isFalse);
      expect(decision.reason, 'no_provider_repair_required');
    });
  });
}

GeneratedDeckValidationResult _result({
  List<String> errors = const [],
  List<String> invalidCards = const [],
  required int suggested,
  required int resolved,
}) {
  return GeneratedDeckValidationResult(
    generatedDeck: const {
      'cards': [
        {'name': 'Plains', 'quantity': 60},
      ],
    },
    errors: errors,
    invalidCards: invalidCards,
    suggestions: const {},
    warnings: const [],
    totalSuggestedEntries: suggested,
    totalSuggestedCards: suggested,
    totalResolvedEntries: resolved,
    totalResolvedCards: resolved,
  );
}
