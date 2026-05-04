import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// GET  /trades/:id           → Detalhe do trade
/// PUT  /trades/:id           → (não usado diretamente, sub-rotas respond/status)
///
/// Rotas especiais tratadas por id:
///   id == "<uuid>"   → detalhe do trade
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.get) {
    return _getTradeDetail(context, id);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getTradeDetail(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    // Buscar trade
    final tradeResult = await pool.execute(Sql.named('''
      SELECT
        t.id, t.status, t.type, t.message,
        t.payment_amount, t.payment_currency,
        t.delivery_method, t.payment_method,
        t.tracking_code, t.created_at, t.updated_at,
        s.id as sender_id, s.username as sender_username, s.display_name as sender_display_name, s.avatar_url as sender_avatar,
        s.location_state as sender_location_state, s.location_city as sender_location_city, s.trade_notes as sender_trade_notes, s.created_at as sender_created_at,
        r.id as receiver_id, r.username as receiver_username, r.display_name as receiver_display_name, r.avatar_url as receiver_avatar,
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
        receiver_shipping.avg_shipping_hours as receiver_avg_shipping_hours
      FROM trade_offers t
      JOIN users s ON s.id = t.sender_id
      JOIN users r ON r.id = t.receiver_id
      LEFT JOIN LATERAL ${_trustStatsSql('s.id')} sender_trust ON TRUE
      LEFT JOIN LATERAL ${_responseTimeSql('s.id')} sender_response ON TRUE
      LEFT JOIN LATERAL ${_shippingTimeSql('s.id')} sender_shipping ON TRUE
      LEFT JOIN LATERAL ${_trustStatsSql('r.id')} receiver_trust ON TRUE
      LEFT JOIN LATERAL ${_responseTimeSql('r.id')} receiver_response ON TRUE
      LEFT JOIN LATERAL ${_shippingTimeSql('r.id')} receiver_shipping ON TRUE
      WHERE t.id = @tradeId
    '''), parameters: {'tradeId': id});

    if (tradeResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Trade não encontrado'},
      );
    }

    final trade = tradeResult.first.toColumnMap();

    // Verificar permissão (sender ou receiver)
    if (trade['sender_id'] != userId && trade['receiver_id'] != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para ver este trade'},
      );
    }

    // Buscar items com dados da carta
    final itemsFuture = pool.execute(Sql.named('''
      SELECT
        ti.id, ti.direction, ti.quantity, ti.agreed_price,
        ti.owner_id, ti.binder_item_id,
        bi.condition, bi.is_foil,
        c.id as card_id, c.name as card_name, c.image_url as card_image_url,
        c.set_code as card_set_code, c.mana_cost as card_mana_cost,
        c.rarity as card_rarity
      FROM trade_items ti
      JOIN user_binder_items bi ON bi.id = ti.binder_item_id
      JOIN cards c ON c.id = bi.card_id
      WHERE ti.trade_offer_id = @tradeId
      ORDER BY ti.direction, c.name
    '''), parameters: {'tradeId': id});

    // Buscar mensagens (últimas 50)
    final msgsFuture = pool.execute(Sql.named('''
      SELECT
        tm.id, tm.sender_id, tm.message, tm.attachment_url, tm.attachment_type, tm.created_at,
        u.username as sender_username
      FROM trade_messages tm
      JOIN users u ON u.id = tm.sender_id
      WHERE tm.trade_offer_id = @tradeId
      ORDER BY tm.created_at ASC
      LIMIT 50
    '''), parameters: {'tradeId': id});

    // Buscar histórico de status
    final historyFuture = pool.execute(Sql.named('''
      SELECT
        tsh.id, tsh.old_status, tsh.new_status, tsh.notes, tsh.created_at,
        u.username as changed_by_username
      FROM trade_status_history tsh
      JOIN users u ON u.id = tsh.changed_by
      WHERE tsh.trade_offer_id = @tradeId
      ORDER BY tsh.created_at ASC
    '''), parameters: {'tradeId': id});

    final detailResults = await Future.wait([
      itemsFuture,
      msgsFuture,
      historyFuture,
    ]);
    final itemsResult = detailResults[0];
    final msgsResult = detailResults[1];
    final historyResult = detailResults[2];

    final myItems = <Map<String, dynamic>>[];
    final theirItems = <Map<String, dynamic>>[];
    var offeringValue = 0.0;
    var requestingValue = 0.0;

    for (final row in itemsResult) {
      final m = row.toColumnMap();
      final item = {
        'id': m['id'],
        'binder_item_id': m['binder_item_id'],
        'direction': m['direction'],
        'quantity': m['quantity'],
        'agreed_price': m['agreed_price'] != null
            ? double.tryParse(m['agreed_price'].toString())
            : null,
        'condition': m['condition'],
        'is_foil': m['is_foil'],
        'card': {
          'id': m['card_id'],
          'name': m['card_name'],
          'image_url': m['card_image_url'],
          'set_code': m['card_set_code'],
          'mana_cost': m['card_mana_cost'],
          'rarity': m['card_rarity'],
        },
      };

      final itemValue = (item['agreed_price'] as double? ?? 0) *
          ((item['quantity'] as int?) ?? 1);
      if (m['direction'] == 'offering') {
        offeringValue += itemValue;
      } else if (m['direction'] == 'requesting') {
        requestingValue += itemValue;
      }

      // Organizar pela perspectiva do viewer
      if (m['owner_id'] == userId) {
        myItems.add(item);
      } else {
        theirItems.add(item);
      }
    }

    final messages = msgsResult.map((row) {
      final m = row.toColumnMap();
      if (m['created_at'] is DateTime) {
        m['created_at'] = (m['created_at'] as DateTime).toIso8601String();
      }
      return {
        'id': m['id'],
        'sender_id': m['sender_id'],
        'sender_username': m['sender_username'],
        'message': m['message'],
        'attachment_url': m['attachment_url'],
        'attachment_type': m['attachment_type'],
        'created_at': m['created_at'],
      };
    }).toList();

    final history = historyResult.map((row) {
      final m = row.toColumnMap();
      if (m['created_at'] is DateTime) {
        m['created_at'] = (m['created_at'] as DateTime).toIso8601String();
      }
      return {
        'id': m['id'],
        'old_status': m['old_status'],
        'new_status': m['new_status'],
        'notes': m['notes'],
        'changed_by_username': m['changed_by_username'],
        'created_at': m['created_at'],
      };
    }).toList();

    // Montar response
    for (final k in ['created_at', 'updated_at']) {
      if (trade[k] is DateTime)
        trade[k] = (trade[k] as DateTime).toIso8601String();
    }
    if (trade['payment_amount'] != null) {
      trade['payment_amount'] =
          double.tryParse(trade['payment_amount'].toString());
    }

    return Response.json(body: {
      'id': trade['id'],
      'status': trade['status'],
      'type': trade['type'],
      'message': trade['message'],
      'payment_amount': trade['payment_amount'],
      'payment_currency': trade['payment_currency'],
      'payment_method': trade['payment_method'],
      'delivery_method': trade['delivery_method'],
      'tracking_code': trade['tracking_code'],
      'sender': {
        'id': trade['sender_id'],
        'username': trade['sender_username'],
        'display_name': trade['sender_display_name'],
        'avatar_url': trade['sender_avatar'],
        'trust': _buildTrustInsight(trade, 'sender_'),
      },
      'receiver': {
        'id': trade['receiver_id'],
        'username': trade['receiver_username'],
        'display_name': trade['receiver_display_name'],
        'avatar_url': trade['receiver_avatar'],
        'trust': _buildTrustInsight(trade, 'receiver_'),
      },
      'value_summary': _buildValueSummary(
        offeredValue: offeringValue,
        requestedValue: requestingValue,
        paymentAmount: trade['payment_amount'] as double?,
      ),
      'my_items': myItems,
      'their_items': theirItems,
      'messages': messages,
      'status_history': history,
      'created_at': trade['created_at'],
      'updated_at': trade['updated_at'],
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_detail_route',
      extras: {'operation': 'get_trade_detail', 'trade_id': id},
    );
    Log.e('[ERROR] get trade detail failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar trade'},
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

Map<String, dynamic> _buildValueSummary({
  required double offeredValue,
  required double requestedValue,
  required double? paymentAmount,
}) {
  const thresholdPct = 20.0;
  const thresholdAbs = 25.0;
  final payment = paymentAmount ?? 0;
  final totalOffered = offeredValue + payment;
  final diff = totalOffered - requestedValue;
  final biggest = totalOffered > requestedValue ? totalOffered : requestedValue;
  final pct = biggest > 0 ? (diff.abs() / biggest) * 100 : 0.0;
  final hasWarning =
      biggest > 0 && diff.abs() >= thresholdAbs && pct >= thresholdPct;

  return {
    'offered_value': _round2(offeredValue),
    'requested_value': _round2(requestedValue),
    'payment_amount': _round2(payment),
    'total_offered_value': _round2(totalOffered),
    'difference_abs': _round2(diff.abs()),
    'difference_pct': _round2(pct),
    'direction': diff > 0
        ? 'offer_higher'
        : diff < 0
            ? 'request_higher'
            : 'balanced',
    'threshold_pct': thresholdPct,
    'threshold_abs': thresholdAbs,
    'has_warning': hasWarning,
    'message': hasWarning
        ? (diff > 0
            ? 'A oferta total está acima do pedido. Confirme se o bônus/pagamento é intencional.'
            : 'O pedido está acima da oferta total. Combine a diferença antes de avançar.')
        : 'Resumo calculado com preços acordados dos itens e pagamento informado.',
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
