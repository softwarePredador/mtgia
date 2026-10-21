import 'package:server/binder_item_contract.dart';
import 'package:test/test.dart';

/// D-39 / A8: o fichário é `collection_private`, que a beta permite; marcar
/// carta para troca ou venda pertence a `trades` e `marketplace`, que ela não
/// permite. A contenção é por CAMPO, não por rota — esconder o controle no app
/// não contém nada, porque o PUT aceita qualquer cliente.
void main() {
  void expectBlocked(
    Map<String, dynamic> body, {
    required bool trades,
    required bool marketplace,
    required String code,
    required String capability,
  }) {
    expect(
      () => assertBinderCommerceFieldsAllowed(
        body,
        tradesAllowed: trades,
        marketplaceAllowed: marketplace,
      ),
      throwsA(
        isA<BinderCapabilityDisabledException>()
            .having((e) => e.code, 'code', code)
            .having((e) => e.capability, 'capability', capability),
      ),
    );
  }

  void expectAllowed(
    Map<String, dynamic> body, {
    required bool trades,
    required bool marketplace,
  }) {
    expect(
      () => assertBinderCommerceFieldsAllowed(
        body,
        tradesAllowed: trades,
        marketplaceAllowed: marketplace,
      ),
      returnsNormally,
    );
  }

  test('marcar para troca com a capability off é recusado', () {
    expectBlocked(
      {'for_trade': true},
      trades: false,
      marketplace: false,
      code: 'binder_trade_capability_disabled',
      capability: 'trades',
    );
  });

  test('marcar para venda com a capability off é recusado', () {
    expectBlocked(
      {'for_sale': true},
      trades: false,
      marketplace: false,
      code: 'binder_sale_capability_disabled',
      capability: 'marketplace',
    );
  });

  test('cada campo responde à SUA capability, não à outra', () {
    // Se as duas checagens lessem a mesma flag, um destes passaria errado.
    expectBlocked(
      {'for_trade': true},
      trades: false,
      marketplace: true,
      code: 'binder_trade_capability_disabled',
      capability: 'trades',
    );
    expectBlocked(
      {'for_sale': true},
      trades: true,
      marketplace: false,
      code: 'binder_sale_capability_disabled',
      capability: 'marketplace',
    );
  });

  test('desmarcar continua permitido com a capability off', () {
    // Quem já tem item marcado precisa conseguir desmarcar; recusar `false`
    // prenderia o usuário num estado que a beta não oferece mais.
    expectAllowed({'for_trade': false}, trades: false, marketplace: false);
    expectAllowed({'for_sale': false}, trades: false, marketplace: false);
  });

  test('corpo sem os campos de comércio não é afetado', () {
    expectAllowed(
      {'quantity': 3, 'condition': 'NM'},
      trades: false,
      marketplace: false,
    );
  });

  test('com as capabilities ligadas, marcar volta a ser permitido', () {
    expectAllowed(
      {'for_trade': true, 'for_sale': true},
      trades: true,
      marketplace: true,
    );
  });

  test('valor não-booleano não escapa pela guarda', () {
    // Medido: `readBinderBoolean` NÃO coage strings — recusa como entrada
    // malformada. Então `"true"` nunca chega a virar uma marcação de troca,
    // e a guarda não precisa tratar coerção. O teste fixa isso: se algum dia
    // `readBinderBoolean` passar a aceitar `"true"`, este caso passa a exigir
    // que seja a exceção de capability, e falha aqui avisando.
    expect(
      () => assertBinderCommerceFieldsAllowed(
        {'for_trade': 'true'},
        tradesAllowed: false,
        marketplaceAllowed: false,
      ),
      throwsA(isA<BinderItemInputException>()),
      reason: 'string não vira booleano; a recusa é de entrada, não de capability',
    );
  });
}
