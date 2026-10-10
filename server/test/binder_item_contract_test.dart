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

  /// Matriz mista de troca e venda (D-39): cada oferta responde à SUA
  /// capability. A beta fecha as duas, e o kill switch das rotas só prova a
  /// matriz toda fechada ou toda aberta; nessas duas pontas uma checagem que
  /// lesse a capability errada passaria. Aqui uma fica aberta e a outra
  /// fechada, então trocar `trades` por `marketplace` (ou o contrário) em
  /// qualquer uma das três checagens derruba um caso.
  group('binder commerce mixed capability matrix', () {
    bool Function(String capability) onlyOpen(String open) =>
        (capability) => capability == open;

    Matcher refusedAs(String field, String capability) => throwsA(
      isA<BinderCommerceUnavailableException>()
          .having((error) => error.field, 'field', field)
          .having((error) => error.capability, 'capability', capability),
    );

    test('marketplace open alone still refuses a trade offer', () {
      final isAllowed = onlyOpen('marketplace');

      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: true,
          forSale: null,
          price: null,
          isAllowed: isAllowed,
        ),
        refusedAs('for_trade', 'trades'),
      );
      // A oferta de venda, que é desta capability, continua passando.
      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: false,
          forSale: true,
          price: 7.0,
          isAllowed: isAllowed,
        ),
        returnsNormally,
      );
    });

    test('trades open alone still refuses a sale offer', () {
      final isAllowed = onlyOpen('trades');

      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: null,
          forSale: true,
          price: null,
          isAllowed: isAllowed,
        ),
        refusedAs('for_sale', 'marketplace'),
      );
      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: true,
          forSale: false,
          price: null,
          isAllowed: isAllowed,
        ),
        returnsNormally,
      );
    });

    // D-90: é assim que o app tira uma oferta antiga com tudo fechado. O PUT é
    // parcial, então o app manda `false`/`null` explícitos e o servidor os aceita.
    test('all closed still accepts false/null, which is how an offer is cleared',
        () {
      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: false,
          forSale: false,
          price: null,
          isAllowed: (_) => false,
        ),
        returnsNormally,
      );
    });

    test('trades open alone still refuses a sale price', () {
      expect(
        () => ensureBinderCommerceAllowed(
          forTrade: true,
          forSale: null,
          price: 7.0,
          isAllowed: onlyOpen('trades'),
        ),
        refusedAs('price', 'marketplace'),
      );
    });
  });
}
