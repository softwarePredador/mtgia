import 'dart:io';

import 'package:server/binder_import_contract.dart';
import 'package:test/test.dart';

void main() {
  const cardA = '00000000-0000-4000-8000-000000000001';
  const cardB = '00000000-0000-4000-8000-000000000002';

  Map<String, dynamic> item({
    String inputId = 'line-1',
    String cardId = cardA,
    int quantity = 2,
    String condition = 'lp',
    bool isFoil = false,
    String language = 'PT_BR',
    String listType = 'have',
    int? baseline,
    int? target,
  }) => {
    'input_id': inputId,
    'card_id': cardId,
    'quantity': quantity,
    'condition': condition,
    'is_foil': isFoil,
    'language': language,
    'list_type': listType,
    if (baseline != null) 'baseline_quantity': baseline,
    if (target != null) 'target_quantity': target,
  };

  group('binder import input contract', () {
    test('normalizes a reviewed physical identity', () {
      final parsed =
          readBinderImportItems([item()], requireApplyPlan: false).single;

      expect(parsed.cardId, cardA);
      expect(parsed.quantity, 2);
      expect(parsed.condition, 'LP');
      expect(parsed.language, 'pt-br');
      expect(parsed.listType, 'have');
      expect(parsed.identityKey, '$cardA|LP|false|pt-br|have');
    });

    test('requires target to equal baseline plus reviewed quantity', () {
      final parsed =
          readBinderImportItems([
            item(baseline: 3, target: 5),
          ], requireApplyPlan: true).single;
      expect(parsed.baselineQuantity, 3);
      expect(parsed.targetQuantity, 5);

      expect(
        () => readBinderImportItems([
          item(baseline: 3, target: 6),
        ], requireApplyPlan: true),
        throwsA(
          isA<BinderImportInputException>().having(
            (error) => error.code,
            'code',
            'binder_import_plan_mismatch',
          ),
        ),
      );
    });

    test('rejects duplicate physical identities and oversized batches', () {
      expect(
        () => readBinderImportItems([
          item(),
          item(inputId: 'line-2'),
        ], requireApplyPlan: false),
        throwsA(
          isA<BinderImportInputException>().having(
            (error) => error.code,
            'code',
            'binder_import_identity_duplicate',
          ),
        ),
      );

      expect(
        () => readBinderImportItems(
          List.generate(
            binderImportMaxItems + 1,
            (index) => item(
              inputId: 'line-$index',
              cardId: index.isEven ? cardA : cardB,
            ),
          ),
          requireApplyPlan: false,
        ),
        throwsA(
          isA<BinderImportInputException>().having(
            (error) => error.code,
            'code',
            'binder_import_items_limit_exceeded',
          ),
        ),
      );
    });

    test('validates stable batch and input identifiers', () {
      expect(readBinderImportBatchId('collection-1700000000-a1'), isNotEmpty);
      expect(
        () => readBinderImportBatchId('contains spaces'),
        throwsA(isA<BinderImportInputException>()),
      );
      expect(
        () => readBinderImportItems([
          item(inputId: 'bad input'),
        ], requireApplyPlan: false),
        throwsA(isA<BinderImportInputException>()),
      );
    });
  });

  group('binder import route source guards', () {
    test('preview is read-only and exposes an explicit apply plan', () {
      final source =
          File('routes/binder/import/preview/index.dart').readAsStringSync();

      expect(source, isNot(contains('INSERT INTO user_binder_items')));
      expect(source, isNot(contains('UPDATE user_binder_items')));
      expect(source, contains("'baseline_quantity': baseline"));
      expect(source, contains("'target_quantity': target"));
      expect(source, contains("'action': baseline == 0 ? 'create' : 'update'"));
      expect(source, contains('collection_availability_snapshot'));
    });

    test('apply uses compare-and-set semantics and replay detection', () {
      final source =
          File('routes/binder/import/apply/index.dart').readAsStringSync();

      expect(source, contains('pool.runTx'));
      expect(source, contains('FOR UPDATE'));
      expect(source, contains('currentQuantity == item.targetQuantity'));
      expect(source, contains('currentQuantity != item.baselineQuantity'));
      expect(source, contains("'status': 'unchanged'"));
      expect(source, contains("'partial_failure': applied > 0 && failed > 0"));
      expect(source, contains("'replay_safe': true"));
    });
  });
}
