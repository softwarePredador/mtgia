import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('binder route contract source guards', () {
    test('list route returns stable card-entry fields used by app binder UI',
        () {
      final source = File('routes/binder/index.dart').readAsStringSync();

      expect(source, contains("'quantity': cols['quantity']"));
      expect(source, contains("'condition': cols['condition']"));
      expect(source, contains("'is_foil': cols['is_foil']"));
      expect(source, contains("'for_trade': cols['for_trade']"));
      expect(source, contains("'for_sale': cols['for_sale']"));
      expect(source, contains("'set_code': cols['card_set_code']"));
      expect(source, contains("'rarity': cols['card_rarity']"));
    });

    test('mutation route validates quantity, condition and list type', () {
      final createSource = File('routes/binder/index.dart').readAsStringSync();
      final updateSource =
          File('routes/binder/[id]/index.dart').readAsStringSync();

      expect(createSource, contains('Quantidade deve ser >= 1'));
      expect(updateSource, contains('Quantidade deve ser >= 1'));
      expect(createSource, contains('Condição inválida'));
      expect(updateSource, contains('Condição inválida'));
      expect(createSource, contains('list_type inválido'));
      expect(updateSource, contains('list_type inválido'));
    });
  });
}
