import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/notification_service.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/request_trace.dart';

/// GET /trades/:id/messages → Listar mensagens do trade
/// POST /trades/:id/messages → Enviar mensagem no trade
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getMessages(context, id),
    HttpMethod.post => _postMessage(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getMessages(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
    final safeLimit = limit.clamp(1, 200);
    final safePage = page < 1 ? 1 : page;
    final offset = (safePage - 1) * safeLimit;

    // Verificar que o usuário participa do trade
    final tradeResult = await pool.execute(
      Sql.named('''
      SELECT
        t.sender_id,
        t.receiver_id,
        EXISTS (
          SELECT 1
          FROM user_blocks b
          WHERE (b.blocker_id = t.sender_id AND b.blocked_id = t.receiver_id)
             OR (b.blocker_id = t.receiver_id AND b.blocked_id = t.sender_id)
        ) AS interaction_blocked
      FROM trade_offers t
      WHERE t.id = @id
    '''),
      parameters: {'id': id},
    );

    if (tradeResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Trade não encontrado'},
      );
    }

    final trade = tradeResult.first.toColumnMap();
    final senderId = trade['sender_id'] as String;
    final receiverId = trade['receiver_id'] as String;
    if (senderId != userId && receiverId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para ver mensagens deste trade'},
      );
    }
    if (trade['interaction_blocked'] == true) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'interaction_blocked'},
      );
    }

    final countResult = await pool.execute(
      Sql.named('''
      SELECT COUNT(*) as total
      FROM trade_messages
      WHERE trade_offer_id = @id
        AND moderation_status = 'visible'
    '''),
      parameters: {'id': id},
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final msgResult = await pool.execute(
      Sql.named('''
      SELECT tm.id, tm.sender_id, u.username AS sender_username,
             u.display_name AS sender_display_name, u.avatar_url AS sender_avatar,
             tm.message, tm.attachment_url, tm.attachment_type,
             tm.created_at
      FROM trade_messages tm
      JOIN users u ON u.id = tm.sender_id
      WHERE tm.trade_offer_id = @id
        AND tm.moderation_status = 'visible'
      ORDER BY tm.created_at ASC
      LIMIT @lim OFFSET @off
    '''),
      parameters: {'id': id, 'lim': safeLimit, 'off': offset},
    );

    final messages =
        msgResult.map((row) {
          final m = row.toColumnMap();
          return {
            'id': m['id'],
            'sender_id': m['sender_id'],
            'sender_username': m['sender_username'],
            'sender_display_name': m['sender_display_name'],
            'sender_avatar': m['sender_avatar'],
            'message': m['message'],
            'attachment_url': m['attachment_url'],
            'attachment_type': m['attachment_type'],
            'created_at': m['created_at']?.toString(),
          };
        }).toList();

    return Response.json(
      body: {
        'data': messages,
        'page': safePage,
        'limit': safeLimit,
        'total': total,
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_messages_route',
      extras: {'operation': 'list_trade_messages', 'trade_id': id},
    );
    Log.e('[ERROR] list trade messages failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar mensagens'},
    );
  }
}

Future<Response> _postMessage(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final message = body['message'] as String?;
    final attachmentUrl = body['attachment_url'] as String?;
    final attachmentType = body['attachment_type'] as String?;
    final clientRequestId =
        body['client_request_id']?.toString().trim().isEmpty == true
            ? null
            : body['client_request_id']?.toString().trim();

    if ((message == null || message.trim().isEmpty) && attachmentUrl == null) {
      _logInvalidPayload(context, id, 'missing_message_or_attachment');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'message ou attachment_url é obrigatório'},
      );
    }

    // Validar attachment_type (se fornecido)
    const validAttachmentTypes = ['receipt', 'tracking', 'photo', 'other'];
    if (attachmentType != null &&
        !validAttachmentTypes.contains(attachmentType)) {
      _logInvalidPayload(context, id, 'invalid_attachment_type');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'attachment_type inválido. Use: ${validAttachmentTypes.join(', ')}',
        },
      );
    }
    if (clientRequestId != null &&
        (clientRequestId.length < 8 ||
            clientRequestId.length > 128 ||
            !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(clientRequestId))) {
      _logInvalidPayload(context, id, 'invalid_client_request_id');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'invalid_client_request_id'},
      );
    }

    // Verificar trade e participação
    final tradeResult = await pool.execute(
      Sql.named('''
      SELECT
        t.sender_id,
        t.receiver_id,
        t.status,
        EXISTS (
          SELECT 1
          FROM user_blocks b
          WHERE (b.blocker_id = t.sender_id AND b.blocked_id = t.receiver_id)
             OR (b.blocker_id = t.receiver_id AND b.blocked_id = t.sender_id)
        ) AS interaction_blocked
      FROM trade_offers t
      WHERE t.id = @id
    '''),
      parameters: {'id': id},
    );

    if (tradeResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Trade não encontrado'},
      );
    }

    final trade = tradeResult.first.toColumnMap();
    final senderId = trade['sender_id'] as String;
    final receiverId = trade['receiver_id'] as String;
    if (senderId != userId && receiverId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para enviar mensagens neste trade'},
      );
    }
    if (trade['interaction_blocked'] == true) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'interaction_blocked'},
      );
    }

    // Não permitir mensagens em trades finalizados (declined/cancelled)
    final closedStatuses = ['declined', 'cancelled'];
    if (closedStatuses.contains(trade['status'])) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error':
              'Não é possível enviar mensagens em trade ${trade['status']}',
        },
      );
    }

    final sendResult = await pool.runTx((session) async {
      final participantIds = <String>[senderId, receiverId]..sort();
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

      final blocked = await session.execute(
        Sql.named('''
          SELECT EXISTS (
            SELECT 1
            FROM user_blocks
            WHERE (blocker_id = @senderId AND blocked_id = @receiverId)
               OR (blocker_id = @receiverId AND blocked_id = @senderId)
          ) AS blocked
        '''),
        parameters: {'senderId': senderId, 'receiverId': receiverId},
      );
      if (blocked.first.toColumnMap()['blocked'] == true) {
        return <String, dynamic>{'error': 'interaction_blocked'};
      }

      final result = await session.execute(
        Sql.named('''
        INSERT INTO trade_messages (
          trade_offer_id,
          sender_id,
          message,
          attachment_url,
          attachment_type,
          client_request_id
        )
        VALUES (
          @tradeId,
          @userId,
          @message,
          @attachmentUrl,
          @attachmentType,
          @clientRequestId
        )
        ON CONFLICT (sender_id, client_request_id)
          WHERE client_request_id IS NOT NULL
        DO UPDATE SET client_request_id = EXCLUDED.client_request_id
        RETURNING
          id,
          created_at,
          message,
          attachment_url,
          attachment_type,
          client_request_id,
          (xmax = 0) AS inserted
      '''),
        parameters: {
          'tradeId': id,
          'userId': userId,
          'message': message?.trim(),
          'attachmentUrl': attachmentUrl,
          'attachmentType': attachmentType,
          'clientRequestId': clientRequestId,
        },
      );
      final row = result.first.toColumnMap();
      if (row['message'] != message?.trim() ||
          row['attachment_url'] != attachmentUrl ||
          row['attachment_type'] != attachmentType) {
        return <String, dynamic>{'error': 'idempotency_conflict'};
      }
      return <String, dynamic>{'message': row};
    });
    if (sendResult == null) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'participant_unavailable',
          'message': 'Um participante não está mais disponível.',
        },
      );
    }
    if (sendResult['error'] case final error?) {
      return Response.json(
        statusCode:
            error == 'idempotency_conflict'
                ? HttpStatus.conflict
                : HttpStatus.forbidden,
        body: {'error': error},
      );
    }

    final row = sendResult['message']! as Map<String, dynamic>;
    final inserted = row['inserted'] == true;

    // 🔔 Notificação: mensagem no trade → notificar a outra parte
    final recipientId = senderId == userId ? receiverId : senderId;
    if (inserted) {
      NotificationService.createFromActorDeferred(
        pool: pool,
        actorUserId: userId,
        userId: recipientId,
        type: 'trade_message',
        titleBuilder: (senderName) => '$senderName enviou mensagem no trade',
        body:
            message != null && message.length > 100
                ? '${message.substring(0, 100)}...'
                : message,
        referenceId: id,
        endpoint: 'POST /trades/:id/messages',
        requestId: _requestId(context),
        tradeId: id,
      );
    }

    return Response.json(
      statusCode: inserted ? HttpStatus.created : HttpStatus.ok,
      body: {
        'id': row['id'],
        'trade_offer_id': id,
        'sender_id': userId,
        'message': message?.trim(),
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
        'client_request_id': row['client_request_id'],
        'idempotent_replay': !inserted,
        'created_at': row['created_at']?.toString(),
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_messages_route',
      extras: {'operation': 'post_trade_message', 'trade_id': id},
    );
    Log.e('[ERROR] post trade message failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao enviar mensagem'},
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
    '[social_write] invalid_payload endpoint=POST /trades/:id/messages '
    'reason=$reason request_id=${_requestId(context)} user_id=$userId '
    'trade_id=$tradeId',
  );
}
