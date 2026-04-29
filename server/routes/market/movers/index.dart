import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:server/market_movers.dart';

/// GET /market/movers
///
/// Retorna as cartas com maior variação de preço (gainers e losers)
/// comparando o preço de hoje com o de ontem.
///
/// Query params:
///   - limit: número de cartas por categoria (default: 20, max: 50)
///   - min_price: preço mínimo para filtrar penny stocks (default: 1.00)
///
/// Response:
/// {
///   "date": "2026-02-09",
///   "previous_date": "2026-02-08",
///   "gainers": [ { card_id, name, set_code, image_url, price_today, price_yesterday, change_usd, change_pct } ],
///   "losers":  [ ... ],
///   "total_tracked": 12345
/// }
final _marketMoversCache = MarketMoversCache();

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: '{"error":"Method not allowed"}');
  }

  final pool = context.read<Pool>();
  final params = context.request.uri.queryParameters;
  final limit = normalizeMarketMoversLimit(params['limit']);
  final minPrice = normalizeMarketMoversMinPrice(params['min_price']);

  final cached = _marketMoversCache.get(limit, minPrice);
  if (cached != null) {
    return Response.json(body: cached);
  }

  try {
    final payload = await _fetchMarketMovers(pool, limit, minPrice)
        .timeout(marketMoversQueryTimeout);
    _marketMoversCache.set(limit, minPrice, payload);
    return Response.json(body: payload);
  } on TimeoutException catch (e) {
    print('[WARN] Timeout ao buscar market movers: $e');
    final stale = _marketMoversCache.get(limit, minPrice, allowStale: true);
    if (stale != null) {
      return Response.json(body: stale);
    }
    return Response.json(
      body: buildMarketMoversPayload(
        date: null,
        previousDate: null,
        gainers: const [],
        losers: const [],
        totalTracked: 0,
        message: 'Dados de mercado temporariamente indisponíveis.',
      ),
    );
  } catch (e) {
    print('[ERROR] Erro ao buscar market movers: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro ao buscar market movers'},
    );
  }
}

Future<Map<String, dynamic>> _fetchMarketMovers(
  Pool pool,
  int limit,
  double minPrice,
) async {
  final summaryResult = await pool.execute(Sql.named(marketMoversSummarySql));
  if (summaryResult.isEmpty) {
    return buildMarketMoversPayload(
      date: null,
      previousDate: null,
      gainers: const [],
      losers: const [],
      totalTracked: 0,
      message:
          'Dados insuficientes. São necessários pelo menos 2 dias de histórico de preços.',
    );
  }

  final summary = summaryResult.first;
  final today = dateStringOrNull(summary[0]);
  final previous = dateStringOrNull(summary[1]);
  final totalTracked = toInt(summary[2]);

  if (today == null || previous == null) {
    return buildMarketMoversPayload(
      date: today,
      previousDate: null,
      gainers: const [],
      losers: const [],
      totalTracked: 0,
      message:
          'Dados insuficientes. São necessários pelo menos 2 dias de histórico de preços.',
    );
  }

  final queryParams = {
    'today': today,
    'previous': previous,
    'min_price': minPrice,
    'limit': limit,
  };

  final gainersResult = await pool.execute(
    Sql.named(marketMoversGainersSql),
    parameters: queryParams,
  );
  final losersResult = await pool.execute(
    Sql.named(marketMoversLosersSql),
    parameters: queryParams,
  );

  List<Map<String, dynamic>> mapRows(Result rows) {
    return rows
        .map((row) => buildMarketMoverRow((index) => row[index]))
        .toList();
  }

  return buildMarketMoversPayload(
    date: today,
    previousDate: previous,
    gainers: mapRows(gainersResult),
    losers: mapRows(losersResult),
    totalTracked: totalTracked,
  );
}
