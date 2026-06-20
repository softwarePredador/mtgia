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

    test('import validate keeps documented softer preview behavior', () {
      final validateSource =
          File('routes/import/validate/index.dart').readAsStringSync();
      final apiContract =
          File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();

      expect(
        validateSource,
        contains('notFoundLines.addAll(parseResult.invalidLines)'),
      );
      expect(
        validateSource,
        isNot(contains('parseResult.unsupportedSectionLines.isNotEmpty')),
        reason:
            '/import/validate is a non-mutating preview; write routes own hard rejection.',
      );
      expect(
        apiContract,
        contains(
          'Preview is intentionally softer than write routes: unsupported '
          'Sideboard/Wishboard/Maybeboard/outside sections are returned through '
          '`not_found_lines`',
        ),
      );
      expect(
        apiContract,
        contains('`POST /import` and `POST /import/to-deck` reject'),
      );
    });

    test('import preview and update pass preferred format into card lookup',
        () {
      final validateSource =
          File('routes/import/validate/index.dart').readAsStringSync();
      final importToDeckSource =
          File('routes/import/to-deck/index.dart').readAsStringSync();
      final apiContract =
          File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();

      expect(validateSource, contains('preferredFormat: normalizedFormat'));
      expect(importToDeckSource, contains('preferredFormat: normalizedFormat'));
      expect(
        apiContract,
        contains(
          'All import entry points pass the normalized target format into card '
          'lookup so legal/restricted printings are preferred consistently.',
        ),
      );
    });

    test('import validate copy warnings use DeckRulesService physical key', () {
      final validateSource =
          File('routes/import/validate/index.dart').readAsStringSync();
      final lookupSource =
          File('lib/import_card_lookup_service.dart').readAsStringSync();
      final apiContract =
          File('doc/API_CONTRACTS_AND_DATA_MAP.md').readAsStringSync();

      expect(lookupSource, contains('c.oracle_id::text AS oracle_id'));
      expect(validateSource, contains("'oracle_id': cardData['oracle_id']"));
      expect(validateSource, contains(r"'oracle:$oracleId'"));
      expect(
        validateSource,
        contains(r"'name:${normalizePhysicalCardCopyName(name)}'"),
      );
      expect(
        apiContract,
        contains(
          'copy-limit warnings use the same physical copy key as '
          '`DeckRulesService`',
        ),
      );
    });
  });
}
