import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('persisted deck validation state routes', () {
    test('import persists the review result in the same transaction', () {
      final source = File('routes/import/index.dart').readAsStringSync();

      expect(source, contains('pool.runTx'));
      expect(source, contains('buildDeckImportReviewContract'));
      expect(source, contains('SET validation_state = @validationState'));
      expect(source, contains('validation_reasons = CAST'));
      expect(source, contains('validation_updated_at = CURRENT_TIMESTAMP'));
      expect(source, contains('exposeDeckValidationState(deckMap)'));
    });

    test('list and detail expose persisted state without internal names', () {
      final listSource = File('routes/decks/index.dart').readAsStringSync();
      final detailSource =
          File('routes/decks/[id]/index.dart').readAsStringSync();

      for (final source in [listSource, detailSource]) {
        expect(source, contains('hasDeckValidationStateColumns'));
        expect(source, contains('validation_updated_at'));
        expect(source, contains('exposeDeckValidationState'));
      }
    });

    test('strict validation persists both success and failure states', () {
      final source =
          File('routes/decks/[id]/validate/index.dart').readAsStringSync();

      expect(source, contains('deckValidationMarkSuccessSql'));
      expect(source, contains('deckValidationMarkFailureSql'));
      expect(source, contains('on DeckRulesException catch (error)'));
      expect(source, isNot(contains('await pool.execute(')));
      expect(source, contains("statusCode: HttpStatus.internalServerError"));
    });

    test('route tree contains no helper endpoint for this contract', () {
      expect(
        File('routes/import/_deck_import_review_contract.dart').existsSync(),
        isFalse,
      );
      expect(File('lib/deck_import_review_contract.dart').existsSync(), isTrue);
      expect(
        File('lib/deck_validation_state_support.dart').existsSync(),
        isTrue,
      );
    });
  });
}
