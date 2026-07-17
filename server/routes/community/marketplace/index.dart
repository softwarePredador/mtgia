import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// GET /community/marketplace → Busca global de cartas para troca/venda
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
    final offset = (page - 1) * limit;

    // Filtros
    final search = params['search']?.trim();
    final condition = params['condition'];
    final forTrade = params['for_trade'];
    final forSale = params['for_sale'];
    final setCode = params['set_code'];
    final rarity = params['rarity'];

    final whereClauses = <String>[
      '(bi.for_trade = TRUE OR bi.for_sale = TRUE)',
      'u.deleted_at IS NULL',
    ];
    final sqlParams = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      whereClauses.add('c.name ILIKE @search');
      sqlParams['search'] = '%$search%';
    }

    final validConditions = {'NM', 'LP', 'MP', 'HP', 'DMG'};
    if (condition != null &&
        validConditions.contains(condition.toUpperCase())) {
      whereClauses.add('bi.condition = @condition');
      sqlParams['condition'] = condition.toUpperCase();
    }

    if (forTrade == 'true') {
      whereClauses.add('bi.for_trade = TRUE');
    }
    if (forSale == 'true') {
      whereClauses.add('bi.for_sale = TRUE');
    }

    if (setCode != null && setCode.isNotEmpty) {
      whereClauses.add('c.set_code = @setCode');
      sqlParams['setCode'] = setCode.toLowerCase();
    }
    if (rarity != null && rarity.isNotEmpty) {
      whereClauses.add('c.rarity = @rarity');
      sqlParams['rarity'] = rarity.toLowerCase();
    }

    final where = whereClauses.join(' AND ');
    final needsCardJoinForCount =
        search != null && search.isNotEmpty ||
        setCode != null && setCode.isNotEmpty ||
        rarity != null && rarity.isNotEmpty;

    // Count total. Avoid the cards join on the unfiltered marketplace path;
    // card filters still use the join because their predicates live on cards.
    final countFuture = pool.execute(
      Sql.named(
        needsCardJoinForCount
            ? '''
              SELECT COUNT(*) as cnt
              FROM user_binder_items bi
              JOIN cards c ON c.id = bi.card_id
              JOIN users u ON u.id = bi.user_id
              WHERE $where
            '''
            : '''
              SELECT COUNT(*) as cnt
              FROM user_binder_items bi
              JOIN users u ON u.id = bi.user_id
              WHERE $where
            ''',
      ),
      parameters: sqlParams,
    );

    // Items com dados do dono e da carta
    final itemsFuture = pool.execute(
      Sql.named('''
      SELECT bi.id, bi.card_id, bi.quantity, bi.condition, bi.is_foil,
             bi.for_trade, bi.for_sale, bi.price, bi.currency, bi.notes,
              bi.user_id, bi.language, bi.list_type,
              c.name AS card_name, c.image_url AS card_image_url,
              c.set_code AS card_set_code, c.mana_cost AS card_mana_cost,
              c.rarity AS card_rarity, c.type_line AS card_type_line,
              c.is_reserved AS card_is_reserved,
              c.price AS card_reference_price,
              ph.history_points AS price_history_points,
              ph.latest_price AS price_latest_price,
              ph.previous_price AS price_previous_price,
              ph.latest_date AS price_latest_date,
              ph.previous_date AS price_previous_date,
              u.username AS owner_username, u.display_name AS owner_display_name,
              u.avatar_url AS owner_avatar_url,
              u.location_state AS owner_location_state,
              u.location_city AS owner_location_city,
              u.trade_notes AS owner_trade_notes,
              u.created_at AS owner_created_at,
              trust.completed_trades AS owner_completed_trades,
              trust.cancelled_trades AS owner_cancelled_trades,
              trust.declined_trades AS owner_declined_trades,
              trust.disputed_trades AS owner_disputed_trades,
              response.avg_response_hours AS owner_avg_response_hours,
              shipping.avg_shipping_hours AS owner_avg_shipping_hours
      FROM user_binder_items bi
      JOIN cards c ON c.id = bi.card_id
      JOIN users u ON u.id = bi.user_id
      LEFT JOIN LATERAL (
        SELECT
          COUNT(*)::int AS history_points,
          (array_agg(price_usd ORDER BY price_date DESC))[1] AS latest_price,
          (array_agg(price_usd ORDER BY price_date DESC))[2] AS previous_price,
          (array_agg(price_date ORDER BY price_date DESC))[1] AS latest_date,
          (array_agg(price_date ORDER BY price_date DESC))[2] AS previous_date
        FROM (
          SELECT price_date, price_usd
          FROM price_history
          WHERE card_id = c.id AND price_usd IS NOT NULL
          ORDER BY price_date DESC
          LIMIT 2
        ) recent_prices
      ) ph ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_trades,
          COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_trades,
          COUNT(*) FILTER (WHERE status = 'declined')::int AS declined_trades,
          COUNT(*) FILTER (WHERE status = 'disputed')::int AS disputed_trades
        FROM trade_offers t
        WHERE t.sender_id = u.id OR t.receiver_id = u.id
      ) trust ON TRUE
      LEFT JOIN LATERAL (
        SELECT ROUND(
          AVG(EXTRACT(EPOCH FROM (first_response.created_at - t.created_at)) / 3600)::numeric,
          1
        ) AS avg_response_hours
        FROM trade_offers t
        JOIN LATERAL (
          SELECT created_at
          FROM trade_status_history h
          WHERE h.trade_offer_id = t.id
            AND h.new_status IN ('accepted', 'declined')
          ORDER BY h.created_at ASC
          LIMIT 1
        ) first_response ON TRUE
        WHERE t.receiver_id = u.id
      ) response ON TRUE
      LEFT JOIN LATERAL (
        SELECT ROUND(
          AVG(EXTRACT(EPOCH FROM (shipped.created_at - accepted.created_at)) / 3600)::numeric,
          1
        ) AS avg_shipping_hours
        FROM trade_status_history shipped
        JOIN trade_status_history accepted
          ON accepted.trade_offer_id = shipped.trade_offer_id
         AND accepted.new_status = 'accepted'
        WHERE shipped.changed_by = u.id
          AND shipped.new_status = 'shipped'
      ) shipping ON TRUE
      WHERE $where
      ORDER BY bi.created_at DESC
      LIMIT @limit OFFSET @offset
    '''),
      parameters: {...sqlParams, 'limit': limit, 'offset': offset},
    );

    final queryResults = await Future.wait([countFuture, itemsFuture]);
    final countResult = queryResults[0];
    final result = queryResults[1];
    final total = countResult.first[0] as int? ?? 0;

    final items =
        result.map((row) {
          final cols = row.toColumnMap();
          return {
            'id': cols['id'],
            'card': {
              'id': cols['card_id'],
              'name': cols['card_name'],
              'image_url': cols['card_image_url'],
              'set_code': cols['card_set_code'],
              'mana_cost': cols['card_mana_cost'],
              'rarity': cols['card_rarity'],
              'type_line': cols['card_type_line'],
              'is_reserved': cols['card_is_reserved'] == true,
            },
            'quantity': cols['quantity'],
            'condition': cols['condition'],
            'is_foil': cols['is_foil'],
            'for_trade': cols['for_trade'],
            'for_sale': cols['for_sale'],
            'price':
                cols['price'] != null
                    ? double.tryParse(cols['price'].toString())
                    : null,
            'currency': cols['currency'],
            'notes': cols['notes'],
            'language': cols['language'],
            'list_type': cols['list_type'] ?? 'have',
            'price_insight': _buildPriceInsight(cols),
            'owner': {
              'id': cols['user_id'],
              'username': cols['owner_username'],
              'display_name': cols['owner_display_name'],
              'avatar_url': cols['owner_avatar_url'],
              'location_state': cols['owner_location_state'],
              'location_city': cols['owner_location_city'],
              'trade_notes': cols['owner_trade_notes'],
              'trust': _buildTrustInsight(cols, 'owner_'),
            },
          };
        }).toList();

    return Response.json(
      body: {'data': items, 'page': page, 'limit': limit, 'total': total},
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'community_marketplace_route',
      extras: {'operation': 'list_marketplace'},
    );
    Log.e('[ERROR] marketplace list failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar marketplace'},
    );
  }
}

Map<String, dynamic> _buildPriceInsight(Map<String, dynamic> cols) {
  final reference = _toDouble(cols['card_reference_price']);
  final latest = _toDouble(cols['price_latest_price']);
  final previous = _toDouble(cols['price_previous_price']);
  final historyPoints = _toInt(cols['price_history_points']);
  final advertised = _toDouble(cols['price']);

  final trend = <String, dynamic>{
    'status': 'insufficient_data',
    'direction': 'flat',
    'latest_price': latest,
    'previous_price': previous,
    'latest_date': _dateString(cols['price_latest_date']),
    'previous_date': _dateString(cols['price_previous_date']),
    'message':
        'Dados insuficientes: são necessários pelo menos 2 pontos em price_history.',
  };

  if (historyPoints >= 2 &&
      latest != null &&
      previous != null &&
      previous > 0) {
    final change = latest - previous;
    final pct = (change / previous) * 100;
    trend
      ..['status'] = 'available'
      ..['direction'] =
          change > 0
              ? 'up'
              : change < 0
              ? 'down'
              : 'flat'
      ..['change_abs'] = _round2(change)
      ..['change_pct'] = _round2(pct)
      ..remove('message');
  }

  const thresholdPct = 35.0;
  const thresholdAbs = 5.0;
  final comparison = <String, dynamic>{
    'status': 'insufficient_data',
    'direction': 'unknown',
    'threshold_pct': thresholdPct,
    'threshold_abs': thresholdAbs,
    'message':
        'Comparação indisponível: falta preço anunciado ou referência interna.',
  };

  if (advertised != null && reference != null && reference > 0) {
    final diff = advertised - reference;
    final pct = (diff / reference) * 100;
    final isAlert = diff.abs() >= thresholdAbs && pct.abs() >= thresholdPct;
    comparison
      ..['direction'] =
          diff > 0
              ? 'above_reference'
              : diff < 0
              ? 'below_reference'
              : 'near_reference'
      ..['difference_abs'] = _round2(diff.abs())
      ..['difference_pct'] = _round2(pct.abs())
      ..['status'] =
          isAlert ? (diff > 0 ? 'alert_high' : 'alert_low') : 'within_range'
      ..['message'] =
          isAlert
              ? (diff > 0
                  ? 'Preço anunciado bem acima da referência interna; confirme condição, idioma e acordo.'
                  : 'Preço anunciado bem abaixo da referência interna; confirme se não há erro no anúncio.')
              : 'Preço anunciado próximo da referência interna disponível.';
  }

  return {
    'reference_price': reference,
    'reference_currency': 'USD',
    'history_points': historyPoints,
    'trend': trend,
    'comparison': comparison,
  };
}

Map<String, dynamic> _buildTrustInsight(
  Map<String, dynamic> cols,
  String prefix,
) {
  final completed = _toInt(cols['${prefix}completed_trades']);
  final cancelled = _toInt(cols['${prefix}cancelled_trades']);
  final declined = _toInt(cols['${prefix}declined_trades']);
  final disputed = _toInt(cols['${prefix}disputed_trades']);
  final totalSignals = completed + cancelled + declined + disputed;
  final createdAt = cols['${prefix}created_at'];
  final isNewAccount =
      createdAt is DateTime &&
      DateTime.now().toUtc().difference(createdAt.toUtc()).inDays < 30;
  final profileIncomplete =
      (cols['${prefix}display_name'] == null ||
          cols['${prefix}display_name'].toString().trim().isEmpty) ||
      (cols['${prefix}location_state'] == null ||
          cols['${prefix}location_state'].toString().trim().isEmpty) ||
      (cols['${prefix}location_city'] == null ||
          cols['${prefix}location_city'].toString().trim().isEmpty) ||
      (cols['${prefix}trade_notes'] == null ||
          cols['${prefix}trade_notes'].toString().trim().isEmpty);

  return {
    'completed_trades': completed,
    'cancelled_trades': cancelled,
    'declined_trades': declined,
    'disputed_trades': disputed,
    'avg_response_hours': _toDouble(cols['${prefix}avg_response_hours']),
    'avg_shipping_hours': _toDouble(cols['${prefix}avg_shipping_hours']),
    'is_new_account': isNewAccount,
    'profile_incomplete': profileIncomplete,
    'has_insufficient_history': totalSignals < 3,
  };
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

String? _dateString(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String().substring(0, 10);
  final text = value.toString();
  return text.length >= 10 ? text.substring(0, 10) : text;
}
