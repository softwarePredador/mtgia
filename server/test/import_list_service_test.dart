import 'package:test/test.dart';

import '../lib/import_card_lookup_service.dart';
import '../lib/import_list_service.dart';

void main() {
  group('parseImportLines', () {
    test('strips commander markers from card names', () {
      final result = parseImportLines([
        '1x Talrand, Sky Summoner [Commander]',
        '1 Sol Ring *CMDR*',
        '1 Arcane Signet !commander',
      ]);

      expect(result.invalidLines, isEmpty);
      expect(
        result.parsedItems.map((item) => item['name']),
        equals([
          'Talrand, Sky Summoner',
          'Sol Ring',
          'Arcane Signet',
        ]),
      );
      expect(
        result.parsedItems.map((item) => item['isCommanderTag']),
        equals([true, true, true]),
      );
    });
  });

  group('canonicalizeImportLookupName', () {
    test('maps known Portuguese Commander names to local English card names',
        () {
      expect(
        canonicalizeImportLookupName('Kaalia da Vastidão'),
        equals('kaalia of the vast'),
      );
    });

    test('maps common Portuguese deck import staples safely', () {
      expect(canonicalizeImportLookupName('Planície'), equals('plains'));
      expect(canonicalizeImportLookupName('Pântano'), equals('swamp'));
      expect(canonicalizeImportLookupName('Montanha'), equals('mountain'));
      expect(
        canonicalizeImportLookupName('Espadas em Arados'),
        equals('swords to plowshares'),
      );
    });
  });
}
