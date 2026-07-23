import 'package:server/binder_item_contract.dart';
import 'package:test/test.dart';

void main() {
  group('binder item input contract', () {
    test('normalizes physical identity without changing playable identity', () {
      expect(readBinderCondition('lp'), 'LP');
      expect(readBinderLanguage('PT_BR'), 'pt-br');
      expect(readBinderListType(' HAVE '), 'have');
      expect(
        readBinderCardId('00000000-0000-4000-8000-000000000001'),
        '00000000-0000-4000-8000-000000000001',
      );
    });

    test('accepts only positive integral quantities', () {
      expect(readBinderQuantity(null), 1);
      expect(readBinderQuantity(3), 3);
      expect(readBinderQuantity(3.0), 3);
      for (final value in [0, -1, 1.5, '2', true]) {
        expect(
          () => readBinderQuantity(value),
          throwsA(
            isA<BinderItemInputException>().having(
              (error) => error.code,
              'code',
              'binder_quantity_invalid',
            ),
          ),
        );
      }
    });

    test('rejects malformed physical metadata and negative prices', () {
      expect(
        () => readBinderLanguage('portuguese'),
        throwsA(isA<BinderItemInputException>()),
      );
      expect(
        () => readBinderCondition('mint'),
        throwsA(isA<BinderItemInputException>()),
      );
      expect(
        () => readBinderBoolean('true'),
        throwsA(isA<BinderItemInputException>()),
      );
      expect(
        () => readBinderPrice(-0.01),
        throwsA(isA<BinderItemInputException>()),
      );
    });
  });
}
