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
    final tradeResult = await pool.execute(Sql.named('''
      SELECT sender_id, receiver_id FROM trade_offers WHERE id = @id
    '''), parameters: {'id': id});

    if (tradeResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Trade não encontrado'},
      );
    }

    final trade = tradeResult.first.toColumnMap();
    if (trade['sender_id'] != userId && trade['receiver_id'] != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para ver mensagens deste trade'},
      );
    }

    final countResult = await pool.execute(Sql.named('''
      SELECT COUNT(*) as total FROM trade_messages WHERE trade_offer_id = @id
    '''), parameters: {'id': id});
    final total = countResult.first.toColumnMap()['total'] as int;

    final msgResult = await pool.execute(Sql.named('''
      SELECT tm.id, tm.sender_id, u.username AS sender_username,
             u.display_name AS sender_display_name, u.avatar_url AS sender_avatar,
             tm.message, tm.attachment_url, tm.attachment_type,
             tm.created_at
      FROM trade_messages tm
      JOIN users u ON u.id = tm.sender_id
      WHERE tm.trade_offer_id = @id
      ORDER BY tm.created_at ASC
      LIMIT @lim OFFSET @off
    '''), parameters: {'id': id, 'lim': safeLimit, 'off': offset});

    final messages = msgResult.map((row) {
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

    return Response.json(body: {
      'data': messages,
      'page': safePage,
      'limit': safeLimit,
      'total': total,
    });
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

    // Verificar trade e participação
    final tradeResult = await pool.execute(Sql.named('''
      SELECT sender_id, receiver_id, status FROM trade_offers WHERE id = @id
    '''), parameters: {'id': id});

    if (tradeResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Trade não encontrado'},
      );
    }

    final trade = tradeResult.first.toColumnMap();
    if (trade['sender_id'] != userId && trade['receiver_id'] != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para enviar mensagens neste trade'},
      );
    }

    // Não permitir mensagens em trades finalizados (declined/cancelled)
    final closedStatuses = ['declined', 'cancelled'];
    if (closedStatuses.contains(trade['status'])) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': 'Não é possível enviar mensagens em trade ${trade['status']}'
        },
      );
    }

    final insertResult = await pool.execute(Sql.named('''
      INSERT INTO trade_messages (trade_offer_id, sender_id, message, attachment_url, attachment_type)
      VALUES (@tradeId, @userId, @message, @attachmentUrl, @attachmentType)
      RETURNING id, created_at
    '''), parameters: {
      'tradeId': id,
      'userId': userId,
      'message': message?.trim(),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    });

    final row = insertResult.first.toColumnMap();

    // 🔔 Notificação: mensagem no trade → notificar a outra parte
    final recipientId = trade['sender_id'] == userId
        ? trade['receiver_id'] as String
        : trade['sender_id'] as String;
    NotificationService.createFromActorDeferred(
      pool: pool,
      actorUserId: userId,
      userId: recipientId,
      type: 'trade_message',
      titleBuilder: (senderName) => '$senderName enviou mensagem no trade',
      body: message != null && message.length > 100
          ? '${message.substring(0, 100)}...'
          : message,
      referenceId: id,
      endpoint: 'POST /trades/:id/messages',
      requestId: _requestId(context),
      tradeId: id,
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'id': row['id'],
        'trade_offer_id': id,
        'sender_id': userId,
        'message': message?.trim(),
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
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
    '[social_write] invalid_payload endpoint=POST /trades/:id/messages '
    'reason=$reason request_id=${_requestId(context)} user_id=$userId '
    'trade_id=$tradeId',
  );
}
