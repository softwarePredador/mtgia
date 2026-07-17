import 'package:server/deck_validation_state_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck validation state support', () {
    test('normalizes the closed state vocabulary fail-closed', () {
      expect(normalizeDeckValidationState('DRAFT'), deckValidationStateDraft);
      expect(
        normalizeDeckValidationState('validated'),
        deckValidationStateValidated,
      );
      expect(
        normalizeDeckValidationState('invented'),
        deckValidationStateUnknown,
      );
      expect(deckRequiresReview('invented'), isTrue);
      expect(deckRequiresReview('validated'), isFalse);
    });

    test('normalizes JSON and list reasons without duplicates', () {
      expect(
        normalizeDeckValidationReasons(
          '["missing_commander", "missing_commander", ""]',
        ),
        ['missing_commander'],
      );
      expect(
        normalizeDeckValidationReasons([
          ' incomplete_deck_size ',
          'strict_validation_pending',
        ]),
        ['incomplete_deck_size', 'strict_validation_pending'],
      );
      expect(normalizeDeckValidationReasons('{"not":"a-list"}'), isEmpty);
    });

    test('exposes public fields and removes internal column names', () {
      final exposed = exposeDeckValidationState({
        'id': 'deck-1',
        'validation_state': 'draft',
        'validation_reasons': '["unresolved_import_lines"]',
      });

      expect(exposed['deck_state'], 'draft');
      expect(exposed['requires_review'], isTrue);
      expect(exposed['review_reasons'], ['unresolved_import_lines']);
      expect(exposed, isNot(contains('validation_state')));
      expect(exposed, isNot(contains('validation_reasons')));
    });
  });
}
