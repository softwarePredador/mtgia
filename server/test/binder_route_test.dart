import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('binder route contract source guards', () {
    test(
      'list route returns stable card-entry fields used by app binder UI',
      () {
        final source = File('routes/binder/index.dart').readAsStringSync();

        expect(source, contains("'quantity': cols['quantity']"));
        expect(source, contains("'condition': cols['condition']"));
        expect(source, contains("'is_foil': cols['is_foil']"));
        expect(source, contains("'for_trade': cols['for_trade']"));
        expect(source, contains("'for_sale': cols['for_sale']"));
        expect(source, contains("'set_code': cols['card_set_code']"));
        expect(source, contains("'rarity': cols['card_rarity']"));
        expect(source, contains("'owned_quantity': cols['owned_quantity']"));
        expect(
          source,
          contains("'allocated_quantity': cols['allocated_quantity']"),
        );
        expect(source, contains("'free_quantity': cols['free_quantity']"));
        expect(
          source,
          contains("'missing_quantity': cols['missing_quantity']"),
        );
        expect(
          source,
          contains("'available_quantity': cols['available_quantity']"),
        );
      },
    );

    test('mutation route validates quantity, condition and list type', () {
      final createSource = File('routes/binder/index.dart').readAsStringSync();
      final updateSource =
          File('routes/binder/[id]/index.dart').readAsStringSync();
      final contractSource =
          File('lib/binder_item_contract.dart').readAsStringSync();

      expect(createSource, contains('readBinderQuantity'));
      expect(updateSource, contains('readBinderQuantity'));
      expect(createSource, contains('readBinderCondition'));
      expect(updateSource, contains('readBinderCondition'));
      expect(createSource, contains('readBinderLanguage'));
      expect(updateSource, contains('readBinderLanguage'));
      expect(contractSource, contains('binder_quantity_invalid'));
      expect(contractSource, contains('binder_condition_invalid'));
      expect(contractSource, contains('binder_list_type_invalid'));
      expect(contractSource, contains('binder_language_invalid'));
    });

    test('physical identity creation is race-safe and language-aware', () {
      final source = File('routes/binder/index.dart').readAsStringSync();

      expect(source, contains('ON CONFLICT ('));
      expect(
        source,
        contains(
          'user_id, card_id, condition, is_foil, language, list_type',
        ),
      );
      expect(source, contains('binder_item_identity_conflict'));
    });

    test('committed binder items are locked before update or delete', () {
      final source =
          File('routes/binder/[id]/index.dart').readAsStringSync();

      expect(source, contains('pool.runTx'));
      expect(source, contains('FOR UPDATE'));
      expect(source, contains('binder_item_committed'));
      expect(source, contains('committed_trade_quantity'));
      expect(source, contains("'pending', 'accepted', 'shipped'"));
    });
  });
}
