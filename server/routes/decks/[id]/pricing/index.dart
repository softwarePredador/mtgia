import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/pricing_contract.dart';

/// POST /decks/:id/pricing
///
/// Calcula um custo estimado do deck em USD com o preço que está no banco.
///
/// `cards.price_usd` é canônico. `cards.price` permanece somente como
/// compatibilidade legada. Ausência de preço continua `null`, nunca zero.
///
/// Os preços vêm do catálogo, que o job diário do `BT-CAT-01` atualiza (D-35 e
/// D-62). A rota não chama a Scryfall e não escreve em `cards`; a única escrita
/// é o snapshot de preço do próprio deck (`decks.pricing_*`).
///
/// O corpo é ignorado: `force` e `refresh_missing`, que buscavam preço na
/// Scryfall a pedido do usuário, continuam aceitos e não têm efeito.
Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  try {
    final deckResult = await pool.execute(
      Sql.named('''
        SELECT id
        FROM decks
        WHERE id = @deckId AND user_id = @userId
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    if (deckResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Deck not found.'},
      );
    }

    final rows = await pool.execute(
      Sql.named('''
        SELECT
          dc.card_id::text,
          dc.quantity::int,
          dc.is_commander,
          c.name,
          c.set_code,
          c.price_usd,
          c.price,
          c.price_source,
          c.price_updated_at
        FROM deck_cards dc
        JOIN cards c ON c.id = dc.card_id
        WHERE dc.deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );

    final items = <Map<String, dynamic>>[];
    var total = 0.0;
    var missing = 0;
    var pricedCopies = 0;
    var totalCopies = 0;

    for (final r in rows) {
      final m = r.toColumnMap();
      final qty = (m['quantity'] as int?) ?? 0;
      totalCopies += qty;
      final canonicalPrice = readNullablePrice(m['price_usd']);
      final legacyPrice = readNullablePrice(m['price']);
      final price = canonicalPrice ?? legacyPrice;
      final source =
          price == null
              ? pricingSourceUnknown
              : normalizePriceSource(
                m['price_source'],
                legacyFallback: canonicalPrice == null,
              );

      if (price == null) {
        missing += qty;
      } else {
        pricedCopies += qty;
        total += price * qty;
      }

      items.add({
        'card_id': m['card_id'],
        'name': m['name'],
        'set_code': m['set_code'],
        'quantity': qty,
        'is_commander': m['is_commander'] == true,
        'unit_price_usd': price,
        'line_total_usd': price == null ? null : (price * qty),
        'price_currency': pricingCurrencyUsd,
        'price_source': source,
        'price_updated_at': _isoDate(m['price_updated_at']),
      });
    }

    final knownTotal = nullableKnownTotal(
      total: total,
      pricedCopies: pricedCopies,
    );
    final coverageStatus = pricingCoverageStatus(
      pricedCopies: pricedCopies,
      totalCopies: totalCopies,
    );
    final priceSource = aggregatePriceSources(
      items.map((item) => item['price_source']),
    );

    // Salva snapshot no deck (para exibir sem recalcular). Um deck sem nenhum
    // preço conhecido grava total NULL, não 0.
    final snapshotResult = await pool.execute(
      Sql.named('''
        UPDATE decks
        SET pricing_currency = @currency,
            pricing_total = @total,
            pricing_missing_cards = @missing,
            pricing_source = @source,
            pricing_updated_at = NOW()
        WHERE id = @deckId AND user_id = @userId
        RETURNING pricing_updated_at
      '''),
      parameters: {
        'currency': pricingCurrencyUsd,
        'total': knownTotal,
        'missing': missing,
        'source': priceSource,
        'deckId': deckId,
        'userId': userId,
      },
    );
    final pricingUpdatedAt =
        snapshotResult.isEmpty
            ? DateTime.now().toUtc().toIso8601String()
            : _isoDate(snapshotResult.first[0]);

    return Response.json(
      body: {
        'deck_id': deckId,
        'currency': pricingCurrencyUsd,
        'estimated_total_usd': knownTotal,
        'missing_price_cards': missing,
        'known_price_cards': pricedCopies,
        'total_cards': totalCopies,
        'pricing_status': coverageStatus,
        'price_source': priceSource,
        'pricing_updated_at': pricingUpdatedAt,
        // O preço é sempre o do catálogo. Os contadores de busca na Scryfall
        // ficam no contrato, com zero, para não quebrar quem os lê.
        'cache_status': 'cached',
        'refreshed_price_cards': 0,
        'failed_refresh_rows': 0,
        'deferred_refresh_rows': 0,
        'items': items,
      },
    );
  } catch (e) {
    print('[ERROR] Failed to price deck: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to price deck'},
    );
  }
}

String? _isoDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.tryParse(value.toString())?.toUtc().toIso8601String();
}
