import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/notification_service.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/request_trace.dart';

/// GET  /conversations/:id/messages → Listar mensagens
/// POST /conversations/:id/messages → Enviar mensagem
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getMessages(context, id),
    HttpMethod.post => _postMessage(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

// ─── GET /conversations/:id/messages ─────────────────────────
Future<Response> _getMessages(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = (int.tryParse(params['limit'] ?? '50') ?? 50).clamp(1, 100);
    final offset = (page - 1) * limit;
    final sinceRaw = params['since'];
    final since = sinceRaw != null ? DateTime.tryParse(sinceRaw) : null;

    // Verificar participação
    final convResult = await pool.execute(
      Sql.named(
          'SELECT user_a_id, user_b_id FROM conversations WHERE id = @id'),
      parameters: {'id': id},
    );
    if (convResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Conversa não encontrada'},
      );
    }
    final conv = convResult.first.toColumnMap();
    if (conv['user_a_id'] != userId && conv['user_b_id'] != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para ver esta conversa'},
      );
    }

    final int total;
    final Result msgResult;

    if (since != null) {
      // Modo incremental: retorna somente mensagens novas após `since`.
      msgResult = await pool.execute(
        Sql.named('''
          SELECT dm.id, dm.sender_id, dm.message, dm.read_at, dm.created_at,
                 u.username AS sender_username, u.display_name AS sender_display_name,
                 u.avatar_url AS sender_avatar_url
          FROM direct_messages dm
          JOIN users u ON u.id = dm.sender_id
          WHERE dm.conversation_id = @id
            AND dm.created_at > @since
          ORDER BY dm.created_at DESC
          LIMIT @lim
        '''),
        parameters: {'id': id, 'since': since.toUtc(), 'lim': limit},
      );

      // Em modo incremental o total relevante é o número retornado.
      total = msgResult.length;
    } else {
      // Count completo para paginação tradicional.
      final countFuture = pool.execute(
        Sql.named(
            'SELECT COUNT(*)::int FROM direct_messages WHERE conversation_id = @id'),
        parameters: {'id': id},
      );

      // Messages (modo tradicional)
      final msgFuture = pool.execute(
        Sql.named('''
          SELECT dm.id, dm.sender_id, dm.message, dm.read_at, dm.created_at,
                 u.username AS sender_username, u.display_name AS sender_display_name,
                 u.avatar_url AS sender_avatar_url
          FROM direct_messages dm
          JOIN users u ON u.id = dm.sender_id
          WHERE dm.conversation_id = @id
          ORDER BY dm.created_at DESC
          LIMIT @lim OFFSET @off
        '''),
        parameters: {'id': id, 'lim': limit, 'off': offset},
      );
      final queryResults = await Future.wait([countFuture, msgFuture]);
      total = (queryResults[0].first[0] as int?) ?? 0;
      msgResult = queryResults[1];
    }

    final messages = msgResult.map((row) {
      final m = row.toColumnMap();
      for (final k in ['read_at', 'created_at']) {
        if (m[k] is DateTime) m[k] = (m[k] as DateTime).toIso8601String();
      }
      return {
        'id': m['id'],
        'sender_id': m['sender_id'],
        'sender_username': m['sender_username'],
        'sender_display_name': m['sender_display_name'],
        'sender_avatar_url': m['sender_avatar_url'],
        'message': m['message'],
        'read_at': m['read_at'],
        'created_at': m['created_at'],
      };
    }).toList();

    return Response.json(body: {
      'data': messages,
      'page': page,
      'limit': limit,
      'total': total,
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'conversation_messages_route',
      extras: {
        'operation': 'list_conversation_messages',
        'conversation_id': id
      },
    );
    Log.e('[ERROR] list conversation messages failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao buscar mensagens'},
    );
  }
}

// ─── POST /conversations/:id/messages ────────────────────────
Future<Response> _postMessage(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final message = (body['message'] as String?)?.trim();
    if (message == null || message.isEmpty) {
      _logInvalidPayload(context, id, 'missing_message');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'message é obrigatório'},
      );
    }

    // Verificar participação
    final convResult = await pool.execute(
      Sql.named(
          'SELECT user_a_id, user_b_id FROM conversations WHERE id = @id'),
      parameters: {'id': id},
    );
    if (convResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Conversa não encontrada'},
      );
    }
    final conv = convResult.first.toColumnMap();
    if (conv['user_a_id'] != userId && conv['user_b_id'] != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Sem permissão para enviar mensagem nesta conversa'},
      );
    }

    // Determinar o destinatário
    final receiverId = conv['user_a_id'] == userId
        ? conv['user_b_id'] as String
        : conv['user_a_id'] as String;

    // Inserir mensagem + atualizar last_message_at em um round-trip.
    final insertResult = await pool.execute(
      Sql.named('''
        WITH inserted AS (
          INSERT INTO direct_messages (conversation_id, sender_id, message)
          VALUES (@convId, @senderId, @message)
          RETURNING id, created_at
        ),
        updated AS (
          UPDATE conversations
          SET last_message_at = (SELECT created_at FROM inserted)
          WHERE id = @convId
          RETURNING id
        )
        SELECT inserted.id, inserted.created_at
        FROM inserted, updated
      '''),
      parameters: {'convId': id, 'senderId': userId, 'message': message},
    );

    final msg = insertResult.first.toColumnMap();
    final createdAt = msg['created_at'];

    NotificationService.createFromActorDeferred(
      pool: pool,
      actorUserId: userId,
      userId: receiverId,
      type: 'direct_message',
      titleBuilder: (senderName) => 'Nova mensagem de $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      referenceId: id, // conversation id
      endpoint: 'POST /conversations/:id/messages',
      requestId: _requestId(context),
      conversationId: id,
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'id': msg['id'],
        'conversation_id': id,
        'sender_id': userId,
        'message': message,
        'created_at': createdAt is DateTime
            ? createdAt.toIso8601String()
            : createdAt?.toString(),
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'conversation_messages_route',
      extras: {'operation': 'post_conversation_message', 'conversation_id': id},
    );
    Log.e('[ERROR] post conversation message failed: $e');
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
  String conversationId,
  String reason,
) {
  String userId;
  try {
    userId = context.read<String>();
  } catch (_) {
    userId = 'n/a';
  }
  Log.w(
    '[social_write] invalid_payload endpoint=POST /conversations/:id/messages '
    'reason=$reason request_id=${_requestId(context)} user_id=$userId '
    'conversation_id=$conversationId',
  );
}
