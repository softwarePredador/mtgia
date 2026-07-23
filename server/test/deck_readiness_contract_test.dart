import 'package:server/deck_readiness_contract.dart';
import 'package:test/test.dart';

void main() {
  group('buildDeckReadinessContract', () {
    test('marks a complete strict-valid deck as validated', () {
      final contract = buildDeckReadinessContract(
        format: 'commander',
        cardCount: 100,
        hasCommander: true,
        strictValidationPassed: true,
      );

      expect(contract['schema_version'], deckReadinessSchemaVersion);
      expect(contract['state'], 'validated');
      expect(contract['requires_review'], isFalse);
      expect(contract['review_reasons'], isEmpty);
    });

    test('makes an empty manual deck an explicit reviewable draft', () {
      final contract = buildDeckReadinessContract(
        format: 'commander',
        cardCount: 0,
        hasCommander: false,
        strictValidationPassed: false,
        strictValidationError: 'missing commander',
      );

      expect(contract['state'], 'draft');
      expect(contract['requires_review'], isTrue);
      expect(contract['review_reasons'], [
        'missing_commander',
        'incomplete_deck_size',
      ]);
      expect(contract['strict_validation_error'], 'missing commander');
    });

    test('keeps prerequisite failures even when strict rules pass', () {
      final contract = buildDeckReadinessContract(
        format: 'modern',
        cardCount: 60,
        hasCommander: false,
        strictValidationPassed: true,
        prerequisiteReviewReasons: const ['unresolved_import_lines'],
      );

      expect(contract['state'], 'draft');
      expect(contract['review_reasons'], ['unresolved_import_lines']);
    });
  });
}
