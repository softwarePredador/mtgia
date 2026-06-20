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

    test('rejects sideboard section instead of parsing it as main deck', () {
      final result = parseImportLines([
        '1 Talrand, Sky Summoner [Commander]',
        '99 Island',
        'Sideboard:',
        '1 Blue Elemental Blast',
      ]);

      expect(
        result.parsedItems.map((item) => item['name']),
        equals(['Talrand, Sky Summoner', 'Island']),
      );
      expect(result.invalidLines, contains('Sideboard:'));
      expect(result.invalidLines, contains('1 Blue Elemental Blast'));
      expect(result.unsupportedSectionLines, contains('Sideboard:'));
      expect(
        result.unsupportedSectionLines,
        contains('1 Blue Elemental Blast'),
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

    test('normalizes localized lookup names accent-insensitively', () {
      expect(
        normalizeLocalizedImportName(' Dragão Pira Funesta 123 '),
        equals('dragao pira funesta'),
      );
      expect(
        staticLocalizedImportAliasTarget('Kaalia da Vastidão'),
        equals('kaalia of the vast'),
      );
    });
  });

  group('split import lookup fallback', () {
    test('queries both front-face and back-face split card patterns', () {
      expect(
        splitImportLookupPatternsForName('Fire'),
        unorderedEquals(['fire // %', '% // fire']),
      );
      expect(
        splitImportLookupPatternsForName('Ice'),
        unorderedEquals(['ice // %', '% // ice']),
      );
      expect(
        splitImportLookupPatternsForName('Wear // Tear'),
        unorderedEquals(['wear // %', '% // wear', 'tear // %', '% // tear']),
      );
    });

    test('indexes all faces from a split card database name', () {
      expect(
        splitImportLookupAliasesForDbName('Fire // Ice'),
        unorderedEquals(['fire // ice', 'fire', 'ice']),
      );
      expect(
        splitImportLookupAliasesForDbName('Wear // Tear'),
        unorderedEquals(['wear // tear', 'wear', 'tear']),
      );
    });

    test('resolves back-face-only split card imports from split aliases', () {
      final fireIce = <String, dynamic>{
        'id': 'fire-ice-id',
        'name': 'Fire // Ice',
      };
      final wearTear = <String, dynamic>{
        'id': 'wear-tear-id',
        'name': 'Wear // Tear',
      };
      final foundCardsMap = <String, Map<String, dynamic>>{};

      for (final alias in splitImportLookupAliasesForDbName('Fire // Ice')) {
        foundCardsMap[alias] = fireIce;
      }
      for (final alias in splitImportLookupAliasesForDbName('Wear // Tear')) {
        foundCardsMap[alias] = wearTear;
      }

      expect(findResolvedImportCard(foundCardsMap, 'Ice'), same(fireIce));
      expect(findResolvedImportCard(foundCardsMap, 'Tear'), same(wearTear));
    });
  });

  group('card identity bridge schema', () {
    test('normalizes canonical and localized names without replacing card id',
        () {
      final view = createCardIdentityBridgeViewSql.toLowerCase();

      expect(view, contains('create or replace view card_identity_bridge'));
      expect(view, contains('c.id as card_id'));
      expect(view, contains('c.oracle_id'));
      expect(view, contains('c.scryfall_id'));
      expect(view, contains('normalized_canonical_name'));
      expect(view, contains('normalized_lookup_name'));
      expect(view, contains('from cards c'));
      expect(view, contains('from card_localized_names l'));
      expect(view, contains('union all'));
      expect(view, contains('match_priority'));
      expect(view, isNot(contains('insert into cards')));
      expect(view, isNot(contains('update cards')));
      expect(view, isNot(contains('delete from cards')));
    });
  });
}
