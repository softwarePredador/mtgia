import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../../lib/pricing_contract.dart';

const _priceFetchTimeout = Duration(seconds: 4);

/// POST /decks/:id/pricing
///
/// Calcula um custo estimado do deck em USD.
///
/// `cards.price_usd` é canônico. `cards.price` permanece somente como
/// compatibilidade legada. Ausência de preço continua `null`, nunca zero.
///
/// Body opcional:
/// { "force": true, "refresh_missing": true }
Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = context.read<String>();
  final pool = context.read<Pool>();

  final body = await context.request.json().catchError(
    (_) => const <String, dynamic>{},
  );
  final force = body is Map ? (body['force'] == true) : false;
  final refreshMissing = body is Map ? body['refresh_missing'] != false : true;

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
          c.scryfall_id::text,
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
    var refreshedCopies = 0;
    var failedRefreshRows = 0;

    // Coleta cartas que precisam buscar preço (sem preço ou force=true)
    final cardsToFetch = <Map<String, dynamic>>[];

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

      // Se force=true ou não tem preço, marca para buscar
      // Removido check de isStale para não buscar automaticamente preços antigos
      // O cron já atualiza diariamente
      if (force || (refreshMissing && price == null)) {
        final oracleId = (m['scryfall_id'] as String?)?.trim();
        if (oracleId != null && oracleId.isNotEmpty) {
          cardsToFetch.add(m);
        }
      }

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

    // Se force=true ou tem cartas sem preço, busca em paralelo (máx 10 por vez)
    if (cardsToFetch.isNotEmpty) {
      // Limita a 10 buscas para não demorar muito
      final toFetch = cardsToFetch.take(10).toList();

      final futures = toFetch.map((m) async {
        final oracleId = (m['scryfall_id'] as String?)?.trim();
        final setCode = (m['set_code'] as String?)?.trim();
        if (oracleId == null || oracleId.isEmpty) return;

        double? fetched;
        try {
          fetched = await _fetchUsdPriceFromScryfall(
            idOrOracleId: oracleId,
            setCode: setCode,
          );
        } catch (_) {
          failedRefreshRows++;
          return;
        }
        if (fetched != null) {
          try {
            await pool.execute(
              Sql.named('''
                UPDATE cards
                SET price_usd = @price,
                    price = @price,
                    price_source = @source,
                    price_updated_at = NOW()
                WHERE id = @id
              '''),
              parameters: {
                'price': fetched,
                'source': pricingSourceScryfall,
                'id': m['card_id'],
              },
            );
          } catch (_) {
            failedRefreshRows++;
            return;
          }

          // Atualiza o item na lista
          final idx = items.indexWhere((i) => i['card_id'] == m['card_id']);
          if (idx >= 0) {
            final qty = items[idx]['quantity'] as int;
            final oldPrice = readNullablePrice(items[idx]['unit_price_usd']);

            items[idx]['unit_price_usd'] = fetched;
            items[idx]['line_total_usd'] = fetched * qty;
            items[idx]['price_source'] = pricingSourceScryfall;
            items[idx]['price_updated_at'] =
                DateTime.now().toUtc().toIso8601String();
            refreshedCopies += qty;

            // Ajusta totais
            if (oldPrice == null) {
              missing -= qty;
              pricedCopies += qty;
              total += fetched * qty;
            } else {
              total = total - oldPrice * qty + fetched * qty;
            }
          }
        } else {
          failedRefreshRows++;
        }
      });

      // Executa em paralelo
      await Future.wait(futures);
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
    final requestedRefreshRows = cardsToFetch.take(10).length;
    final deferredRefreshRows = cardsToFetch.length - requestedRefreshRows;
    final cacheStatus =
        requestedRefreshRows == 0
            ? 'cached'
            : failedRefreshRows == 0 && deferredRefreshRows == 0
            ? 'refreshed'
            : refreshedCopies > 0
            ? 'partial_refresh'
            : 'stale_or_missing';

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
        'cache_status': cacheStatus,
        'refreshed_price_cards': refreshedCopies,
        'failed_refresh_rows': failedRefreshRows,
        'deferred_refresh_rows': deferredRefreshRows,
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

Future<double?> _fetchUsdPriceFromScryfall({
  required String idOrOracleId,
  String? setCode,
}) async {
  // 1) Tenta como Card ID (se for).
  {
    final uri = Uri.parse('https://api.scryfall.com/cards/$idOrOracleId');
    final response = await http
        .get(uri, headers: _scryfallHeaders)
        .timeout(_priceFetchTimeout);
    if (response.statusCode == 200) {
      return _parseUsdPriceFromCardJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
  }

  // 2/3) Busca por oracleid (o nosso caso atual).
  final queries = <String>[
    if ((setCode ?? '').trim().isNotEmpty)
      'oracleid:$idOrOracleId set:${setCode!.trim()}',
    'oracleid:$idOrOracleId',
  ];

  for (final q in queries) {
    final uri = Uri.https('api.scryfall.com', '/cards/search', {
      'q': q,
      'unique': 'prints',
      'order': 'released',
      'dir': 'desc',
    });
    final response = await http
        .get(uri, headers: _scryfallHeaders)
        .timeout(_priceFetchTimeout);
    if (response.statusCode != 200) continue;
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = (json['data'] as List?)?.whereType<Map>().toList() ?? const [];
    if (data.isEmpty) continue;
    final first = data.first.cast<String, dynamic>();
    final price = _parseUsdPriceFromCardJson(first);
    if (price != null) return price;
  }

  return null;
}

double? _parseUsdPriceFromCardJson(Map<String, dynamic> json) {
  final prices = (json['prices'] as Map?)?.cast<String, dynamic>();
  if (prices == null) return null;
  return readNullablePrice(prices['usd']);
}

const _scryfallHeaders = {
  'Accept': 'application/json',
  'User-Agent': 'ManaLoom/1.0 (pricing refresh)',
};

String? _isoDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.tryParse(value.toString())?.toUtc().toIso8601String();
}
