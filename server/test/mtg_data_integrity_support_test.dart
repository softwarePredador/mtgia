import 'package:server/mtg_data_integrity_support.dart';
import 'package:test/test.dart';

void main() {
  group('decideColorIdentityBackfill', () {
    test('usa colors existentes como fonte deterministica', () {
      final decision = decideColorIdentityBackfill(
        colorsKnown: true,
        colors: ['u', 'R'],
      );

      expect(decision.deterministic, isTrue);
      expect(decision.identity, ['U', 'R']);
      expect(decision.sources, contains('colors'));
    });

    test('combina mana_cost e oracle_text', () {
      final decision = decideColorIdentityBackfill(
        colorsKnown: true,
        colors: const [],
        manaCost: '{2}{W}',
        oracleText: '{B}, {T}: Draw a card.',
      );

      expect(decision.deterministic, isTrue);
      expect(decision.identity, ['W', 'B']);
      expect(decision.sources, containsAll(['mana_cost', 'oracle_text']));
    });

    test('infere identidade por subtipo de land no type_line', () {
      final decision = decideColorIdentityBackfill(
        colorsKnown: true,
        colors: const [],
        typeLine: 'Land — Island Mountain',
      );

      expect(decision.deterministic, isTrue);
      expect(decision.identity, ['U', 'R']);
      expect(decision.sources, contains('type_line_land_subtype'));
    });

    test('preenche incolor quando colors vazio e nenhum simbolo existe', () {
      final decision = decideColorIdentityBackfill(
        colorsKnown: true,
        colors: const [],
        manaCost: '{3}',
        oracleText: 'Draw a card.',
        typeLine: 'Artifact',
      );

      expect(decision.deterministic, isTrue);
      expect(decision.identity, isEmpty);
      expect(decision.reason, 'explicit_empty_colors_without_identity_symbols');
    });

    test('mantem unresolved quando colors esta ausente e nao ha simbolos', () {
      final decision = decideColorIdentityBackfill(
        colorsKnown: false,
        manaCost: null,
        oracleText: 'Draw a card.',
        typeLine: 'Artifact',
      );

      expect(decision.deterministic, isFalse);
      expect(decision.reason, 'colors_missing_and_no_identity_symbols');
    });
  });

  group('normalizeMtgSetCode', () {
    test('normaliza casing e espacos', () {
      expect(normalizeMtgSetCode(' soc '), 'SOC');
      expect(normalizeMtgSetCode(''), isNull);
      expect(normalizeMtgSetCode(null), isNull);
    });
  });
}
