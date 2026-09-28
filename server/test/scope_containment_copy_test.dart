import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../lib/account_email_delivery_transport.dart';
import '../lib/billing/payment_provider.dart';
import '../lib/binder_item_contract.dart';
import '../lib/verified_email_middleware.dart';

/// SCOPE-P0-TRD-00, a copy que é do servidor: os e-mails, as mensagens de
/// erro que a beta alcança e o OpenAPI gerado não prometem venda, compra,
/// troca, negociação nem marketplace. A copy do app e do site é de outras
/// raias.
///
/// "Troca" também é o termo das trocas de carta do Optimize (tirar uma carta
/// do deck e pôr outra); essa copy fica fora da lista abaixo porque não fala
/// de comércio.
final _commercePromise = RegExp(
  r'troc|vend|compr|negoci|mercado|marketplace|\btrades?\b|oferec|anúnci|'
  r'anunci|pagamento|cobran|assinatura|premium|\bpro\b',
  caseSensitive: false,
);

void main() {
  test('os e-mails da conta não falam de comércio', () {
    // Com o convite da beta (BT-AUTH-006) são 3 modelos; todos são conferidos.
    expect(AccountEmailTemplate.values, hasLength(3));
    for (final template in AccountEmailTemplate.values) {
      for (final text in [
        template.subject,
        template.heading,
        template.introduction,
        template.actionLabel,
      ]) {
        expect(text, isNot(matches(_commercePromise)), reason: template.name);
      }
    }
  });

  test('as mensagens de erro da beta sobre comércio só negam', () async {
    // A recusa do fichário diz que não há troca nem venda, sem prometer.
    expect(
      binderCommerceUnavailableMessage,
      'Troca e venda de cartas não estão disponíveis nesta beta.',
    );
    // O e-mail não verificado não cita troca, conversa nem publicação.
    expect(verifiedEmailRequiredMessage, isNot(matches(_commercePromise)));
    expect(
      verifiedEmailRequiredMessage,
      isNot(matches(RegExp('convers|public', caseSensitive: false))),
    );
    // O checkout e o webhook da beta gratuita recusam, e dizem que não há
    // compra nem cobrança.
    const provider = ManaLoomPaymentProvider();
    final checkout =
        (await provider.createCheckout(
          const BillingCheckoutRequest(planName: 'pro'),
        )).body;
    expect(checkout['purchase_available'], isFalse);
    expect(checkout['billing_enabled'], isFalse);
    expect(
      checkout['message'],
      'O BrewTact está em beta gratuita. Nenhuma compra ou cobrança está '
      'disponível.',
    );
    final webhook = provider.verifyWebhook().body;
    expect(webhook['billing_enabled'], isFalse);
  });

  test('o OpenAPI gerado é só inventário: nenhum texto promete comércio', () {
    final openapi =
        jsonDecode(
              File(
                '../docs/generated/openapi.generated.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final texts = <String, String>{};
    void collect(Object? node, String path) {
      if (node is Map) {
        for (final entry in node.entries) {
          collect(entry.value, '$path/${entry.key}');
        }
      } else if (node is List) {
        for (var index = 0; index < node.length; index++) {
          collect(node[index], '$path/$index');
        }
      } else if (node is String) {
        texts[path] = node;
      }
    }

    collect(openapi['info'], '/info');
    final paths = openapi['paths'] as Map<String, dynamic>;
    for (final entry in paths.entries) {
      for (final operation in (entry.value as Map<String, dynamic>).entries) {
        final value = operation.value;
        if (value is! Map<String, dynamic>) continue;
        // O resumo é o próprio método e caminho; não há descrição livre.
        expect(
          value['summary'],
          '${operation.key.toUpperCase()} ${entry.key}',
          reason: '${operation.key} ${entry.key}',
        );
        expect(value.containsKey('description'), isFalse);
        collect(value['responses'], '${entry.key}/${operation.key}');
      }
    }
    for (final text in texts.entries) {
      expect(text.value, isNot(matches(_commercePromise)), reason: text.key);
    }
  });
}
