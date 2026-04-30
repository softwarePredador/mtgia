import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/notification_service.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/request_trace.dart';

/// PUT /trades/:id/respond → Aceitar ou recusar trade
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final action = body['action'] as String?;
    if (action == null || !['accept', 'decline'].contains(action)) {
      _logInvalidPayload(context, id, 'invalid_action');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'action deve ser "accept" ou "decline"'},
      );
    }

    final newStatus = action == 'accept' ? 'accepted' : 'declined';
    final notes = action == 'accept' ? 'Proposta aceita' : 'Proposta recusada';

    // Um único statement faz lock, validação, update e histórico para evitar
    // round-trips transacionais contra o PostgreSQL remoto.
    final respondResult = await pool.execute(Sql.named('''
      WITH current_trade AS (
        SELECT id, sender_id, receiver_id, status
        FROM trade_offers
        WHERE id = @id
        FOR UPDATE
      ),
      validation AS (
        SELECT
          id,
          sender_id,
          receiver_id,
          status,
          CASE
            WHEN receiver_id <> @userId THEN 'forbidden'
            WHEN status <> 'pending' THEN 'not_pending'
            ELSE 'ok'
          END AS result
        FROM current_trade
      ),
      updated AS (
        UPDATE trade_offers t
        SET status = @newStatus, updated_at = CURRENT_TIMESTAMP
        FROM validation v
        WHERE t.id = v.id AND v.result = 'ok'
        RETURNING t.id
      ),
      history AS (
        INSERT INTO trade_status_history (
          trade_offer_id,
          old_status,
          new_status,
          changed_by,
          notes
        )
        SELECT v.id, v.status, @newStatus, @userId, @notes
        FROM validation v
        JOIN updated u ON u.id = v.id
        RETURNING 1
      )
      SELECT
        COALESCE((SELECT result FROM validation), 'not_found') AS result,
        (SELECT status FROM current_trade) AS current_status,
        (SELECT sender_id FROM current_trade) AS sender_id,
        EXISTS(SELECT 1 FROM history) AS history_inserted
    '''), parameters: {
      'id': id,
      'newStatus': newStatus,
      'userId': userId,
      'notes': notes,
    });
    final respondRow = respondResult.first.toColumnMap();
    final result = respondRow['result'] as String;
    final currentStatus = respondRow['current_status'] as String?;
    final senderId = respondRow['sender_id'] as String?;

    switch (result) {
      case 'not_found':
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Trade não encontrado'},
        );
      case 'forbidden':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Apenas o destinatário pode aceitar/recusar'},
        );
      case 'not_pending':
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'error': 'Trade não está pendente (status atual: $currentStatus)'
          },
        );
    }

    // 🔔 Notificação: trade aceito/recusado → notificar o sender
    if (senderId == null) {
      Log.e(
        '[social_write] impossible_state endpoint=PUT /trades/:id/respond '
        'reason=missing_sender request_id=${_requestId(context)} '
        'user_id=$userId trade_id=$id action=$action',
      );
    } else {
      NotificationService.createFromActorDeferred(
        pool: pool,
        actorUserId: userId,
        userId: senderId,
        type: action == 'accept' ? 'trade_accepted' : 'trade_declined',
        titleBuilder: (responderName) => action == 'accept'
            ? '$responderName aceitou sua proposta de trade'
            : '$responderName recusou sua proposta de trade',
        referenceId: id,
        endpoint: 'PUT /trades/:id/respond',
        requestId: _requestId(context),
        tradeId: id,
      );
    }

    return Response.json(body: {
      'id': id,
      'status': newStatus,
      'message': action == 'accept' ? 'Trade aceito!' : 'Trade recusado.',
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_respond_route',
      extras: {'operation': 'respond_trade', 'trade_id': id},
    );
    Log.e('[ERROR] respond trade failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao responder trade'},
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
  String tradeId,
  String reason,
) {
  String userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = 'n/a';
  }
  Log.w(
    '[social_write] invalid_payload endpoint=PUT /trades/:id/respond '
    'reason=$reason request_id=${_requestId(context)} user_id=$userId '
    'trade_id=$tradeId',
  );
}
