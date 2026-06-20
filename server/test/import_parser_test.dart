import 'package:test/test.dart';

import '../lib/basic_land_utils.dart' as basic_lands;
import '../lib/import_card_lookup_service.dart';
import '../lib/import_list_service.dart';

void main() {
  group('normalizeImportLines', () {
    test('accepts raw decklist text', () {
      expect(
        normalizeImportLines('1 Sol Ring\n4 Lightning Bolt'),
        equals(['1 Sol Ring', '4 Lightning Bolt']),
      );
    });

    test('accepts list objects with supported quantity and name keys', () {
      expect(
        normalizeImportLines([
          {'quantity': 4, 'name': 'Lightning Bolt'},
          {'amount': 3, 'card': 'Counterspell'},
          {'qtd': 2, 'card_name': 'Brainstorm'},
          {'name': 'Sol Ring'},
          {'quantity': 1, 'name': ''},
        ]),
        equals([
          '4 Lightning Bolt',
          '3 Counterspell',
          '2 Brainstorm',
          '1 Sol Ring',
        ]),
      );
    });

    test('rejects unsupported list payload types', () {
      expect(() => normalizeImportLines(42), throwsFormatException);
    });
  });

  group('parseImportLines', () {
    test('parses common decklist line formats through the real parser', () {
      final result = parseImportLines([
        '1x Sol Ring',
        '4 Lightning Bolt',
        '1x Command Tower (cmm)',
        '1x Sol Ring (cmm) *F*',
        "1x Urza's Saga",
        '24 Island',
        "1x Atraxa, Praetors' Voice",
        '  4x   Lightning Bolt  ',
      ]);

      expect(result.invalidLines, isEmpty);
      expect(
        result.parsedItems
            .map((item) => [item['quantity'], item['name']])
            .toList(),
        equals([
          [1, 'Sol Ring'],
          [4, 'Lightning Bolt'],
          [1, 'Command Tower'],
          [1, 'Sol Ring'],
          [1, "Urza's Saga"],
          [24, 'Island'],
          [1, "Atraxa, Praetors' Voice"],
          [4, 'Lightning Bolt'],
        ]),
      );
    });

    test('keeps collector numbers for lookup fallback cleanup', () {
      final result = parseImportLines(['1x Forest 96']);

      expect(result.invalidLines, isEmpty);
      expect(result.parsedItems.single['name'], equals('Forest 96'));
      expect(cleanImportLookupKey('Forest 96'), equals('Forest'));
    });

    test('strips commander markers and keeps commander intent separate', () {
      final result = parseImportLines([
        '1x Atraxa, Praetors\' Voice [commander]',
        '1 Chulane, Teller of Tales *cmdr*',
        '1 Edgar Markov !commander',
        '1 Commanding Presence',
      ]);

      expect(result.invalidLines, isEmpty);
      expect(
        result.parsedItems.map((item) => item['name']).toList(),
        equals([
          "Atraxa, Praetors' Voice",
          'Chulane, Teller of Tales',
          'Edgar Markov',
          'Commanding Presence',
        ]),
      );
      expect(
        result.parsedItems.map((item) => item['isCommanderTag']).toList(),
        equals([true, true, true, false]),
      );
    });

    test('ignores empty lines and reports malformed quantity lines', () {
      final result = parseImportLines([
        '',
        '   \t  ',
        'x4 Sol Ring',
        'Sol Ring',
        '1 Arcane Signet',
      ]);

      expect(result.parsedItems.map((item) => item['name']), ['Arcane Signet']);
      expect(result.invalidLines, equals(['x4 Sol Ring', 'Sol Ring']));
    });

    test('rejects unsupported sections instead of parsing them as main deck',
        () {
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

  group('lookup support functions', () {
    test(
        'cleans collector suffixes without touching names that contain numbers',
        () {
      expect(cleanImportLookupKey('Forest 96'), equals('Forest'));
      expect(cleanImportLookupKey('Island 123'), equals('Island'));
      expect(cleanImportLookupKey('Mountain   42'), equals('Mountain'));
      expect(cleanImportLookupKey('Sword of Fire and Ice'),
          equals('Sword of Fire and Ice'));
      expect(cleanImportLookupKey('Sol Ring'), equals('Sol Ring'));
    });

    test('maps split and DFC face names through shared lookup helpers', () {
      expect(
        splitImportLookupPatternsForName('Fire'),
        unorderedEquals(['fire // %', '% // fire']),
      );
      expect(
        splitImportLookupPatternsForName('Ice'),
        unorderedEquals(['ice // %', '% // ice']),
      );
      expect(
        splitImportLookupAliasesForDbName('Wear // Tear'),
        unorderedEquals(['wear // tear', 'wear', 'tear']),
      );
    });

    test('uses real basic-land classifier for import copy-limit exemptions',
        () {
      expect(
        basic_lands.isBasicLandCard(
          name: 'Forest',
          typeLine: 'Basic Land - Forest',
        ),
        isTrue,
      );
      expect(
        basic_lands.isBasicLandCard(
          name: 'Temple Garden',
          typeLine: 'Land - Forest Plains',
        ),
        isFalse,
      );
    });
  });
}
