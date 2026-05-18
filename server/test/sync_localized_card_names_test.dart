import 'package:test/test.dart';

import '../bin/sync_localized_card_names.dart';

void main() {
  group('buildLocalizedNameRows', () {
    test('extracts Scryfall localized printed names for enabled languages', () {
      final rows = buildLocalizedNameRows(
        [
          {
            'id': '3894cfe6-e851-484f-bbc7-28605a48ebbc',
            'oracle_id': 'cb8d80c9-ed58-4f2d-aa8c-c383370c7f1a',
            'lang': 'pt',
            'name': 'Kaalia of the Vast',
            'printed_name': 'Kaalia da Vastidão',
            'set': 'mh3',
            'collector_number': '290',
          },
          {
            'id': 'e71c8c39-3fbb-4a42-9cf6-b3224f5a56fc',
            'oracle_id': 'cb8d80c9-ed58-4f2d-aa8c-c383370c7f1a',
            'lang': 'en',
            'name': 'Kaalia of the Vast',
          },
        ],
        langs: {'pt'},
      );

      expect(rows, hasLength(1));
      expect(rows.single.lang, equals('pt'));
      expect(rows.single.printedName, equals('Kaalia da Vastidão'));
      expect(rows.single.normalizedPrintedName, equals('kaalia da vastidao'));
      expect(rows.single.canonicalName, equals('Kaalia of the Vast'));
    });

    test('dedupes same printing/language/name rows', () {
      final rows = buildLocalizedNameRows(
        List.generate(
          2,
          (_) => {
            'id': '3894cfe6-e851-484f-bbc7-28605a48ebbc',
            'oracle_id': 'cb8d80c9-ed58-4f2d-aa8c-c383370c7f1a',
            'lang': 'pt',
            'name': 'Kaalia of the Vast',
            'printed_name': 'Kaalia da Vastidão',
          },
        ),
        langs: {'pt'},
      );

      expect(rows, hasLength(1));
    });
  });
}
