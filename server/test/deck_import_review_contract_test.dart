import 'package:test/test.dart';

import '../lib/deck_import_review_contract.dart';

void main() {
  group('buildDeckImportReviewContract', () {
    test('marks a complete strict-valid import as validated', () {
      final contract = buildDeckImportReviewContract(
        format: 'commander',
        cardCount: 100,
        hasCommander: true,
        strictValidationPassed: true,
        notFoundLines: const [],
        warnings: const [],
      );

      expect(contract['schema_version'], deckImportValidationSchemaVersion);
      expect(contract['state'], 'validated');
      expect(contract['strict_validation_passed'], isTrue);
      expect(contract['import_complete'], isTrue);
      expect(contract['requires_review'], isFalse);
      expect(contract['review_reasons'], isEmpty);
    });

    test('preserves an incomplete Commander list as an explicit draft', () {
      final contract = buildDeckImportReviewContract(
        format: 'commander',
        cardCount: 2,
        hasCommander: true,
        strictValidationPassed: false,
        notFoundLines: const [],
        warnings: const [],
        strictValidationError:
            'Regra violada: deck commander deve ter exatamente 100 cartas (atual: 2).',
      );

      expect(contract['state'], 'draft');
      expect(contract['requires_review'], isTrue);
      expect(contract['review_reasons'], contains('incomplete_deck_size'));
      expect(contract['strict_validation_error'], contains('100 cartas'));
    });

    test('keeps unresolved or warning-bearing imports in review', () {
      final contract = buildDeckImportReviewContract(
        format: 'modern',
        cardCount: 60,
        hasCommander: false,
        strictValidationPassed: true,
        notFoundLines: const ['1 Carta Desconhecida'],
        warnings: const ['Quantidade ajustada.'],
      );

      expect(contract['state'], 'draft');
      expect(contract['strict_validation_passed'], isTrue);
      expect(contract['import_complete'], isFalse);
      expect(contract['review_reasons'], [
        'unresolved_import_lines',
        'import_warnings',
      ]);
    });

    test('reports a missing Commander separately from deck size', () {
      final contract = buildDeckImportReviewContract(
        format: 'brawl',
        cardCount: 12,
        hasCommander: false,
        strictValidationPassed: false,
        notFoundLines: const [],
        warnings: const [],
      );

      expect(contract['review_reasons'], [
        'missing_commander',
        'incomplete_deck_size',
      ]);
    });
  });
}
