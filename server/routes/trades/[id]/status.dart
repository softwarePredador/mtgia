import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/notification_service.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/request_trace.dart';

/// PUT /trades/:id/status → Atualizar status de entrega
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final newStatus = body['status'] as String?;
    final deliveryMethod = body['delivery_method'] as String?;
    final trackingCode = body['tracking_code'] as String?;
    final notes = body['notes'] as String?;

    if (newStatus == null || newStatus.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'status é obrigatório'},
      );
    }

    if (![
      'shipped',
      'delivered',
      'completed',
      'cancelled',
      'disputed',
    ].contains(newStatus)) {
      _logInvalidPayload(context, id, 'invalid_status');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'Status inválido. Use: shipped, delivered, completed, cancelled, disputed',
        },
      );
    }
    if (deliveryMethod != null &&
        ![
          'correios',
          'motoboy',
          'pessoalmente',
          'outro',
        ].contains(deliveryMethod)) {
      _logInvalidPayload(context, id, 'invalid_delivery_method');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'delivery_method inválido. Use: correios, motoboy, pessoalmente, outro',
        },
      );
    }

    // Validar transições de estado (checagem prévia para mensagem de erro amigável)
    final validTransitions = <String, List<String>>{
      'accepted': ['shipped', 'cancelled', 'disputed'],
      'shipped': ['delivered', 'cancelled', 'disputed'],
      'delivered': ['completed', 'disputed'],
      'pending': ['cancelled'],
    };

    // A ordem de lock é users -> trade, igual à exclusão de conta. Assim não
    // há transição nova depois de um participante ser anonimizado.
    final statusResult = await pool.runTx((session) async {
      final participants = await session.execute(
        Sql.named('''
          SELECT sender_id, receiver_id
          FROM trade_offers
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );
      if (participants.isNotEmpty) {
        final participant = participants.first.toColumnMap();
        final participantIds = <String>[
          participant['sender_id'] as String,
          participant['receiver_id'] as String,
        ]..sort();
        final activeUsers = await session.execute(
          Sql.named('''
            SELECT id
            FROM users
            WHERE id = ANY(@participantIds::uuid[])
              AND deleted_at IS NULL
            ORDER BY id
            FOR UPDATE
          '''),
          parameters: {'participantIds': participantIds},
        );
        if (activeUsers.length != 2) return null;
      }

      return session.execute(
        Sql.named('''
      WITH current_trade AS (
        SELECT id, sender_id, receiver_id, status, type
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
          type,
          CASE
            WHEN sender_id <> @userId AND receiver_id <> @userId
              THEN 'forbidden'
            WHEN NOT (
              (status = 'accepted' AND @newStatus IN ('shipped', 'cancelled', 'disputed'))
              OR (status = 'shipped' AND @newStatus IN ('delivered', 'cancelled', 'disputed'))
              OR (status = 'delivered' AND @newStatus IN ('completed', 'disputed'))
              OR (status = 'pending' AND @newStatus = 'cancelled')
            )
              THEN 'invalid_transition'
            WHEN @newStatus = 'shipped'
              AND COALESCE(type, 'trade') = 'sale'
              AND receiver_id <> @userId
              THEN 'only_receiver_ship_sale'
            WHEN @newStatus = 'delivered'
              AND COALESCE(type, 'trade') = 'sale'
              AND sender_id <> @userId
              THEN 'only_sender_deliver_sale'
            ELSE 'ok'
          END AS result
        FROM current_trade
      ),
      updated AS (
        UPDATE trade_offers t
        SET
          status = @newStatus,
          updated_at = CURRENT_TIMESTAMP,
          delivery_method = COALESCE(@deliveryMethod, t.delivery_method),
          tracking_code = COALESCE(@trackingCode, t.tracking_code)
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
        SELECT
          v.id,
          v.status,
          @newStatus,
          @userId,
          @notes
        FROM validation v
        JOIN updated u ON u.id = v.id
        RETURNING 1
      )
      SELECT
        COALESCE((SELECT result FROM validation), 'not_found') AS result,
        (SELECT status FROM current_trade) AS current_status,
        (SELECT sender_id FROM current_trade) AS sender_id,
        (SELECT receiver_id FROM current_trade) AS receiver_id,
        (SELECT type FROM current_trade) AS type,
        EXISTS(SELECT 1 FROM history) AS history_inserted
    '''),
        parameters: {
          'id': id,
          'userId': userId,
          'newStatus': newStatus,
          'deliveryMethod': deliveryMethod,
          'trackingCode': trackingCode,
          'notes': notes ?? 'Status atualizado para $newStatus',
        },
      );
    });
    if (statusResult == null) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'participant_unavailable',
          'message': 'Um participante não está mais disponível.',
        },
      );
    }
    final statusRow = statusResult.first.toColumnMap();
    final updated = statusRow['result'] as String;
    final currentStatus = statusRow['current_status'] as String?;
    final senderId = statusRow['sender_id'] as String?;
    final receiverId = statusRow['receiver_id'] as String?;
    final isSender = senderId == userId;

    // Tratar resultado da transação
    switch (updated) {
      case 'not_found':
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Trade não encontrado'},
        );
      case 'forbidden':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Sem permissão para atualizar este trade'},
        );
      case 'invalid_transition':
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'error': 'Transição inválida: $currentStatus → $newStatus',
            'allowed_transitions': validTransitions[currentStatus] ?? [],
          },
        );
      case 'only_sender_ship':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Apenas o remetente pode marcar como enviado'},
        );
      case 'only_receiver_deliver':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Apenas o destinatário pode confirmar recebimento'},
        );
      case 'only_receiver_ship_sale':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'error':
                'Em vendas, apenas o vendedor (quem recebeu a proposta) pode marcar como enviado',
          },
        );
      case 'only_sender_deliver_sale':
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'error':
                'Em vendas, apenas o comprador (quem criou a proposta) pode confirmar recebimento',
          },
        );
    }

    // 🔔 Notificação: status do trade atualizado → notificar a outra parte
    final notifyType =
        'trade_$newStatus'; // trade_shipped, trade_delivered, trade_completed
    final validNotifTypes = [
      'trade_shipped',
      'trade_delivered',
      'trade_completed',
    ];
    if (validNotifTypes.contains(notifyType)) {
      final notifyUserId = isSender ? receiverId : senderId;
      if (notifyUserId == null) {
        Log.e(
          '[social_write] impossible_state endpoint=PUT /trades/:id/status '
          'reason=missing_notify_user request_id=${_requestId(context)} '
          'user_id=$userId trade_id=$id',
        );
      } else {
        final statusLabels = {
          'trade_shipped': 'marcou o trade como enviado',
          'trade_delivered': 'confirmou o recebimento do trade',
          'trade_completed': 'finalizou o trade',
        };
        NotificationService.createFromActorDeferred(
          pool: pool,
          actorUserId: userId,
          userId: notifyUserId,
          type: notifyType,
          titleBuilder:
              (changerName) => '$changerName ${statusLabels[notifyType]}',
          referenceId: id,
          endpoint: 'PUT /trades/:id/status',
          requestId: _requestId(context),
          tradeId: id,
        );
      }
    }

    return Response.json(
      body: {
        'id': id,
        'old_status': currentStatus,
        'status': newStatus,
        'message': 'Status atualizado para $newStatus',
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_status_route',
      extras: {'operation': 'update_trade_status', 'trade_id': id},
    );
    Log.e('[ERROR] update trade status failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao atualizar status'},
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

void _logInvalidPayload(RequestContext context, String tradeId, String reason) {
  String userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = 'n/a';
  }
  Log.w(
    '[social_write] invalid_payload endpoint=PUT /trades/:id/status '
    'reason=$reason request_id=${_requestId(context)} user_id=$userId '
    'trade_id=$tradeId',
  );
}
