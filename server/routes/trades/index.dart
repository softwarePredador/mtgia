import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/notification_service.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';
import '../../lib/request_trace.dart';

/// GET  /trades  → Listar trades do usuário
/// POST /trades  → Criar proposta de trade
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.get) return _listTrades(context);
  if (method == HttpMethod.post) return _createTrade(context);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

// ─── POST /trades ───────────────────────────────────────────────
Future<Response> _createTrade(RequestContext context) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final receiverId = body['receiver_id'] as String?;
    final type = body['type'] as String? ?? 'trade';
    final message = body['message'] as String?;
    final myItems =
        (body['my_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final requestedItems =
        (body['requested_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final paymentAmount = body['payment_amount'];
    final paymentMethod = body['payment_method'] as String?;

    // Validações básicas
    if (receiverId == null || receiverId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'receiver_id é obrigatório'},
      );
    }
    if (receiverId == userId) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Não é possível fazer trade consigo mesmo'},
      );
    }
    if (!['trade', 'sale', 'mixed'].contains(type)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Tipo inválido. Use: trade, sale, mixed'},
      );
    }
    if (paymentMethod != null &&
        !['pix', 'cash', 'transfer', 'other'].contains(paymentMethod)) {
      _logInvalidPayload(context, 'POST /trades', 'invalid_payment_method');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': 'payment_method inválido. Use: pix, cash, transfer, other'
        },
      );
    }
    if (myItems.isEmpty && requestedItems.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'A proposta deve ter pelo menos 1 item'},
      );
    }
    if (type == 'trade' && (myItems.isEmpty || requestedItems.isEmpty)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Troca pura exige itens de ambos os lados'},
      );
    }

    final parsedMyItems = _parseTradeItems(myItems, 'my_items');
    if (parsedMyItems.error != null) {
      _logInvalidPayload(context, 'POST /trades', parsedMyItems.error!);
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': parsedMyItems.error},
      );
    }
    final parsedRequestedItems =
        _parseTradeItems(requestedItems, 'requested_items');
    if (parsedRequestedItems.error != null) {
      _logInvalidPayload(context, 'POST /trades', parsedRequestedItems.error!);
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': parsedRequestedItems.error},
      );
    }

    final validationResult = await pool.execute(Sql.named('''
      WITH checks AS (
        SELECT
          EXISTS(SELECT 1 FROM users WHERE id = @receiverId) AS receiver_exists,
          (
            SELECT COUNT(*)::int
            FROM user_binder_items
            WHERE id = ANY(@myIds::uuid[]) AND user_id = @userId
          ) AS my_found,
          (
            SELECT COUNT(*)::int
            FROM user_binder_items
            WHERE id = ANY(@myIds::uuid[])
              AND user_id = @userId
              AND (for_trade = TRUE OR for_sale = TRUE)
          ) AS my_available,
          (
            SELECT COUNT(*)::int
            FROM user_binder_items
            WHERE id = ANY(@requestedIds::uuid[]) AND user_id = @receiverId
          ) AS requested_found,
          (
            SELECT COUNT(*)::int
            FROM user_binder_items
            WHERE id = ANY(@requestedIds::uuid[])
              AND user_id = @receiverId
              AND (for_trade = TRUE OR for_sale = TRUE)
          ) AS requested_available
      )
      SELECT * FROM checks
    '''), parameters: {
      'receiverId': receiverId,
      'userId': userId,
      'myIds': parsedMyItems.uniqueIds,
      'requestedIds': parsedRequestedItems.uniqueIds,
    });
    final validation = validationResult.first.toColumnMap();
    if (validation['receiver_exists'] != true) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Usuário destinatário não encontrado'},
      );
    }
    if ((validation['my_found'] as int) != parsedMyItems.uniqueIds.length) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Um ou mais itens não pertencem a você ou não existem'},
      );
    }
    if ((validation['my_available'] as int) != parsedMyItems.uniqueIds.length) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Um ou mais itens não estão marcados para troca/venda'},
      );
    }
    if ((validation['requested_found'] as int) !=
        parsedRequestedItems.uniqueIds.length) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'Um ou mais itens não pertencem ao destinatário ou não existem'
        },
      );
    }
    if ((validation['requested_available'] as int) !=
        parsedRequestedItems.uniqueIds.length) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'Um ou mais itens do destinatário não estão disponíveis para troca/venda'
        },
      );
    }

    // Criar trade, itens e histórico em um único round-trip ao PostgreSQL remoto.
    final tradeResult = await pool.runTx((session) async {
      final result = await session.execute(Sql.named('''
        WITH offer AS (
          INSERT INTO trade_offers (
            sender_id,
            receiver_id,
            type,
            message,
            payment_amount,
            payment_method
          )
          VALUES (
            @senderId,
            @receiverId,
            @type,
            @message,
            @paymentAmount,
            @paymentMethod
          )
          RETURNING id, status, type, message, payment_amount, payment_currency, created_at
        ),
        offering_items AS (
          INSERT INTO trade_items (
            trade_offer_id,
            binder_item_id,
            owner_id,
            direction,
            quantity,
            agreed_price
          )
          SELECT
            offer.id,
            item.binder_item_id,
            @senderId,
            'offering',
            item.quantity,
            item.agreed_price
          FROM offer
          JOIN LATERAL jsonb_to_recordset(@myItems::jsonb) AS item(
            binder_item_id uuid,
            quantity int,
            agreed_price numeric
          ) ON TRUE
          RETURNING 1
        ),
        requesting_items AS (
          INSERT INTO trade_items (
            trade_offer_id,
            binder_item_id,
            owner_id,
            direction,
            quantity,
            agreed_price
          )
          SELECT
            offer.id,
            item.binder_item_id,
            @receiverId,
            'requesting',
            item.quantity,
            item.agreed_price
          FROM offer
          JOIN LATERAL jsonb_to_recordset(@requestedItems::jsonb) AS item(
            binder_item_id uuid,
            quantity int,
            agreed_price numeric
          ) ON TRUE
          RETURNING 1
        ),
        history AS (
          INSERT INTO trade_status_history (
            trade_offer_id,
            old_status,
            new_status,
            changed_by,
            notes
          )
          SELECT offer.id, NULL, 'pending', @senderId, 'Proposta criada'
          FROM offer
          RETURNING 1
        )
        SELECT
          offer.id,
          offer.status,
          offer.type,
          offer.message,
          offer.payment_amount,
          offer.payment_currency,
          offer.created_at,
          (SELECT COUNT(*)::int FROM offering_items) AS my_items_count,
          (SELECT COUNT(*)::int FROM requesting_items) AS requested_items_count
        FROM offer, history
      '''), parameters: {
        'senderId': userId,
        'receiverId': receiverId,
        'type': type,
        'message': message,
        'paymentAmount': paymentAmount != null
            ? double.tryParse(paymentAmount.toString())
            : null,
        'paymentMethod': paymentMethod,
        'myItems': jsonEncode(parsedMyItems.rows),
        'requestedItems': jsonEncode(parsedRequestedItems.rows),
      });
      final offer = result.first.toColumnMap();
      final tradeId = offer['id'] as String;

      if (offer['created_at'] is DateTime) {
        offer['created_at'] =
            (offer['created_at'] as DateTime).toIso8601String();
      }

      return {
        'id': tradeId,
        'status': offer['status'],
        'type': offer['type'],
        'message': offer['message'],
        'payment_amount': offer['payment_amount'] != null
            ? double.tryParse(offer['payment_amount'].toString())
            : null,
        'payment_currency': offer['payment_currency'],
        'my_items_count': offer['my_items_count'],
        'requested_items_count': offer['requested_items_count'],
        'created_at': offer['created_at'],
      };
    });

    NotificationService.createFromActorDeferred(
      pool: pool,
      actorUserId: userId,
      userId: receiverId,
      type: 'trade_offer_received',
      titleBuilder: (senderName) => '$senderName enviou uma proposta de trade',
      body: message,
      referenceId: tradeResult['id'] as String?,
      endpoint: 'POST /trades',
      requestId: _requestId(context),
      tradeId: tradeResult['id'] as String?,
    );

    return Response.json(statusCode: HttpStatus.created, body: tradeResult);
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trades_route',
      extras: {'operation': 'create_trade'},
    );
    Log.e('[ERROR] create trade failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao criar trade'},
    );
  }
}

String _requestId(RequestContext context) {
  try {
    return context.read<RequestTrace>().requestId;
  } catch (_) {
    return context.request.headers['x-request-id'] ?? 'n/a';
  }
}

void _logInvalidPayload(
  RequestContext context,
  String endpoint,
  String reason,
) {
  String userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = 'n/a';
  }
  Log.w(
    '[social_write] invalid_payload endpoint=$endpoint reason=$reason '
    'request_id=${_requestId(context)} user_id=$userId',
  );
}

_ParsedTradeItems _parseTradeItems(
  List<Map<String, dynamic>> items,
  String fieldName,
) {
  final rows = <Map<String, dynamic>>[];
  final ids = <String>[];

  for (final item in items) {
    final binderItemId = item['binder_item_id'] as String?;
    if (binderItemId == null || binderItemId.isEmpty) {
      return _ParsedTradeItems.error(
        'binder_item_id obrigatório em $fieldName',
      );
    }

    final quantityRaw = item['quantity'];
    final quantity = quantityRaw == null
        ? 1
        : quantityRaw is int
            ? quantityRaw
            : int.tryParse(quantityRaw.toString());
    if (quantity == null || quantity < 1) {
      return _ParsedTradeItems.error('quantity inválida em $fieldName');
    }

    final priceRaw = item['agreed_price'];
    final agreedPrice =
        priceRaw == null ? null : double.tryParse(priceRaw.toString());
    if (priceRaw != null && agreedPrice == null) {
      return _ParsedTradeItems.error('agreed_price inválido em $fieldName');
    }

    ids.add(binderItemId);
    rows.add({
      'binder_item_id': binderItemId,
      'quantity': quantity,
      'agreed_price': agreedPrice,
    });
  }

  return _ParsedTradeItems(rows: rows, uniqueIds: ids.toSet().toList());
}

class _ParsedTradeItems {
  const _ParsedTradeItems({
    required this.rows,
    required this.uniqueIds,
    this.error,
  });

  factory _ParsedTradeItems.error(String error) {
    return _ParsedTradeItems(rows: const [], uniqueIds: const [], error: error);
  }

  final List<Map<String, dynamic>> rows;
  final List<String> uniqueIds;
  final String? error;
}

// ─── GET /trades ────────────────────────────────────────────────
Future<Response> _listTrades(RequestContext context) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;

    final status = params['status'];
    final role = params['role'] ?? 'all'; // sender, receiver, all
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 50);
    final offset = (page - 1) * limit;

    final whereParts = <String>[];
    final filterParams = <String, dynamic>{'userId': userId};

    // Role filter
    if (role == 'sender') {
      whereParts.add('t.sender_id = @userId');
    } else if (role == 'receiver') {
      whereParts.add('t.receiver_id = @userId');
    } else {
      whereParts.add('(t.sender_id = @userId OR t.receiver_id = @userId)');
    }

    // Status filter
    if (status != null && status.isNotEmpty) {
      whereParts.add('t.status = @status');
      filterParams['status'] = status;
    }

    final where = whereParts.join(' AND ');

    // Count
    final countFuture = pool.execute(
      Sql.named('SELECT COUNT(*)::int FROM trade_offers t WHERE $where'),
      parameters: filterParams,
    );

    // Fetch
    final tradesFuture = pool.execute(Sql.named('''
      SELECT
        t.id, t.status, t.type, t.message,
        t.payment_amount, t.payment_currency,
        t.tracking_code, t.delivery_method,
        t.created_at, t.updated_at,
        s.id as sender_id, s.username as sender_username, s.display_name as sender_display_name,
        s.location_state as sender_location_state, s.location_city as sender_location_city, s.trade_notes as sender_trade_notes, s.created_at as sender_created_at,
        r.id as receiver_id, r.username as receiver_username, r.display_name as receiver_display_name,
        r.location_state as receiver_location_state, r.location_city as receiver_location_city, r.trade_notes as receiver_trade_notes, r.created_at as receiver_created_at,
        sender_trust.completed_trades as sender_completed_trades,
        sender_trust.cancelled_trades as sender_cancelled_trades,
        sender_trust.declined_trades as sender_declined_trades,
        sender_trust.disputed_trades as sender_disputed_trades,
        sender_response.avg_response_hours as sender_avg_response_hours,
        sender_shipping.avg_shipping_hours as sender_avg_shipping_hours,
        receiver_trust.completed_trades as receiver_completed_trades,
        receiver_trust.cancelled_trades as receiver_cancelled_trades,
        receiver_trust.declined_trades as receiver_declined_trades,
        receiver_trust.disputed_trades as receiver_disputed_trades,
        receiver_response.avg_response_hours as receiver_avg_response_hours,
        receiver_shipping.avg_shipping_hours as receiver_avg_shipping_hours,
        (SELECT COUNT(*) FROM trade_items ti WHERE ti.trade_offer_id = t.id AND ti.direction = 'offering')::int as offering_count,
        (SELECT COUNT(*) FROM trade_items ti WHERE ti.trade_offer_id = t.id AND ti.direction = 'requesting')::int as requesting_count,
        (SELECT COUNT(*) FROM trade_messages tm WHERE tm.trade_offer_id = t.id)::int as message_count
      FROM trade_offers t
      JOIN users s ON s.id = t.sender_id
      JOIN users r ON r.id = t.receiver_id
      LEFT JOIN LATERAL ${_trustStatsSql('s.id')} sender_trust ON TRUE
      LEFT JOIN LATERAL ${_responseTimeSql('s.id')} sender_response ON TRUE
      LEFT JOIN LATERAL ${_shippingTimeSql('s.id')} sender_shipping ON TRUE
      LEFT JOIN LATERAL ${_trustStatsSql('r.id')} receiver_trust ON TRUE
      LEFT JOIN LATERAL ${_responseTimeSql('r.id')} receiver_response ON TRUE
      LEFT JOIN LATERAL ${_shippingTimeSql('r.id')} receiver_shipping ON TRUE
      WHERE $where
      ORDER BY t.updated_at DESC
      LIMIT @lim OFFSET @off
    '''), parameters: {...filterParams, 'lim': limit, 'off': offset});

    final queryResults = await Future.wait([countFuture, tradesFuture]);
    final countResult = queryResults[0];
    final result = queryResults[1];
    final total = (countResult.first[0] as int?) ?? 0;

    final trades = result.map((row) {
      final m = row.toColumnMap();
      for (final k in ['created_at', 'updated_at']) {
        if (m[k] is DateTime) m[k] = (m[k] as DateTime).toIso8601String();
      }
      if (m['payment_amount'] != null) {
        m['payment_amount'] = double.tryParse(m['payment_amount'].toString());
      }
      return {
        'id': m['id'],
        'status': m['status'],
        'type': m['type'],
        'message': m['message'],
        'payment_amount': m['payment_amount'],
        'payment_currency': m['payment_currency'],
        'tracking_code': m['tracking_code'],
        'delivery_method': m['delivery_method'],
        'sender': {
          'id': m['sender_id'],
          'username': m['sender_username'],
          'display_name': m['sender_display_name'],
          'trust': _buildTrustInsight(m, 'sender_'),
        },
        'receiver': {
          'id': m['receiver_id'],
          'username': m['receiver_username'],
          'display_name': m['receiver_display_name'],
          'trust': _buildTrustInsight(m, 'receiver_'),
        },
        'offering_count': m['offering_count'],
        'requesting_count': m['requesting_count'],
        'message_count': m['message_count'],
        'created_at': m['created_at'],
        'updated_at': m['updated_at'],
      };
    }).toList();

    return Response.json(body: {
      'data': trades,
      'page': page,
      'limit': limit,
      'total': total,
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trades_route',
      extras: {'operation': 'list_trades'},
    );
    Log.e('[ERROR] list trades failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao listar trades'},
    );
  }
}

String _trustStatsSql(String userSql) => '''
(
  SELECT
    COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_trades,
    COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_trades,
    COUNT(*) FILTER (WHERE status = 'declined')::int AS declined_trades,
    COUNT(*) FILTER (WHERE status = 'disputed')::int AS disputed_trades
  FROM trade_offers t2
  WHERE t2.sender_id = $userSql OR t2.receiver_id = $userSql
)
''';

String _responseTimeSql(String userSql) => '''
(
  SELECT ROUND(
    AVG(EXTRACT(EPOCH FROM (first_response.created_at - t2.created_at)) / 3600)::numeric,
    1
  ) AS avg_response_hours
  FROM trade_offers t2
  JOIN LATERAL (
    SELECT created_at
    FROM trade_status_history h
    WHERE h.trade_offer_id = t2.id
      AND h.new_status IN ('accepted', 'declined')
    ORDER BY h.created_at ASC
    LIMIT 1
  ) first_response ON TRUE
  WHERE t2.receiver_id = $userSql
)
''';

String _shippingTimeSql(String userSql) => '''
(
  SELECT ROUND(
    AVG(EXTRACT(EPOCH FROM (shipped.created_at - accepted.created_at)) / 3600)::numeric,
    1
  ) AS avg_shipping_hours
  FROM trade_status_history shipped
  JOIN trade_status_history accepted
    ON accepted.trade_offer_id = shipped.trade_offer_id
   AND accepted.new_status = 'accepted'
  WHERE shipped.changed_by = $userSql
    AND shipped.new_status = 'shipped'
)
''';

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
  final isNewAccount = createdAt is DateTime &&
      DateTime.now().toUtc().difference(createdAt.toUtc()).inDays < 30;
  final profileIncomplete = (cols['${prefix}display_name'] == null ||
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
