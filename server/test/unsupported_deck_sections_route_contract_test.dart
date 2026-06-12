import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('unsupported deck sections route contract', () {
    test('deck routes keep unsupported-section guard and friendly catch', () {
      const routePaths = [
        'routes/decks/index.dart',
        'routes/decks/[id]/index.dart',
        'routes/decks/[id]/cards/index.dart',
        'routes/decks/[id]/cards/bulk/index.dart',
        'routes/decks/[id]/cards/set/index.dart',
      ];

      for (final path in routePaths) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('validateNoUnsupportedDeckSections'),
          reason: '$path must reject unsupported sections before persistence.',
        );
        expect(
          source,
          contains('on DeckRulesException catch'),
          reason: '$path must convert DeckRulesException into a friendly 400.',
        );
      }
    });

    test('import routes expose friendly unsupported-section errors', () {
      final importSource = File('routes/import/index.dart').readAsStringSync();
      final importToDeckSource =
          File('routes/import/to-deck/index.dart').readAsStringSync();

      expect(importSource, contains('parseResult.unsupportedSectionLines'));
      expect(importSource, contains('unsupported_section_lines'));
      expect(importSource, contains('unsupportedDeckSectionsMessage'));

      expect(
        importToDeckSource,
        contains('unsupportedRawDeckSectionLabels(rawList)'),
      );
      expect(
        importToDeckSource,
        contains('parseResult.unsupportedSectionLines'),
      );
      expect(importToDeckSource, contains('unsupported_section_lines'));
      expect(
        importToDeckSource,
        isNot(contains('_unsupportedRawListSections')),
      );
    });
  });
}
