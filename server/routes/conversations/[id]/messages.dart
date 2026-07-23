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
      Sql.named('''
        SELECT
          c.user_a_id,
          c.user_b_id,
          EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (b.blocker_id = c.user_a_id AND b.blocked_id = c.user_b_id)
               OR (b.blocker_id = c.user_b_id AND b.blocked_id = c.user_a_id)
          ) AS interaction_blocked
        FROM conversations c
        WHERE c.id = @id
      '''),
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
    if (conv['interaction_blocked'] == true) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {
          'error': 'interaction_blocked',
          'message': 'Esta conversa nao esta disponivel.',
        },
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
            AND dm.moderation_status = 'visible'
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
          "SELECT COUNT(*)::int FROM direct_messages "
          "WHERE conversation_id = @id AND moderation_status = 'visible'",
        ),
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
            AND dm.moderation_status = 'visible'
          ORDER BY dm.created_at DESC
          LIMIT @lim OFFSET @off
        '''),
        parameters: {'id': id, 'lim': limit, 'off': offset},
      );
      final queryResults = await Future.wait([countFuture, msgFuture]);
      total = (queryResults[0].first[0] as int?) ?? 0;
      msgResult = queryResults[1];
    }

    final messages =
        msgResult.map((row) {
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

    return Response.json(
      body: {'data': messages, 'page': page, 'limit': limit, 'total': total},
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'conversation_messages_route',
      extras: {
        'operation': 'list_conversation_messages',
        'conversation_id': id,
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
    final clientRequestId =
        body['client_request_id']?.toString().trim().isEmpty == true
            ? null
            : body['client_request_id']?.toString().trim();
    if (message == null || message.isEmpty) {
      _logInvalidPayload(context, id, 'missing_message');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'message é obrigatório'},
      );
    }
    if (clientRequestId != null &&
        (clientRequestId.length < 8 ||
            clientRequestId.length > 128 ||
            !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(clientRequestId))) {
      _logInvalidPayload(context, id, 'invalid_client_request_id');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': 'invalid_client_request_id',
          'message': 'client_request_id invalido.',
        },
      );
    }

    // Verificar participação
    final convResult = await pool.execute(
      Sql.named(
        'SELECT user_a_id, user_b_id FROM conversations WHERE id = @id',
      ),
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
    final receiverId =
        conv['user_a_id'] == userId
            ? conv['user_b_id'] as String
            : conv['user_a_id'] as String;

    // Trava os participantes ativos antes do insert. Se a exclusão de uma das
    // contas vencer a corrida, nenhuma mensagem nova é persistida.
    final sendResult = await pool.runTx((session) async {
      final participants = <String>[userId, receiverId]..sort();
      final activeUsers = await session.execute(
        Sql.named('''
          SELECT id
          FROM users
          WHERE id = ANY(@participantIds::uuid[])
            AND deleted_at IS NULL
          ORDER BY id
          FOR UPDATE
        '''),
        parameters: {'participantIds': participants},
      );
      if (activeUsers.length != 2) return null;

      final policy = await session.execute(
        Sql.named('''
          SELECT
            target.message_visibility,
            EXISTS (
              SELECT 1
              FROM user_follows f
              WHERE f.follower_id = @senderId
                AND f.following_id = @receiverId
            ) AS sender_follows,
            EXISTS (
              SELECT 1
              FROM user_blocks b
              WHERE (b.blocker_id = @senderId AND b.blocked_id = @receiverId)
                 OR (b.blocker_id = @receiverId AND b.blocked_id = @senderId)
            ) AS interaction_blocked
          FROM users target
          WHERE target.id = @receiverId
        '''),
        parameters: {'senderId': userId, 'receiverId': receiverId},
      );
      final policyRow = policy.first.toColumnMap();
      final visibility = policyRow['message_visibility'] as String;
      if (policyRow['interaction_blocked'] == true) {
        return <String, dynamic>{'error': 'interaction_blocked'};
      }
      if (visibility == 'none' ||
          (visibility == 'followers' && policyRow['sender_follows'] != true)) {
        return <String, dynamic>{'error': 'messages_not_allowed'};
      }

      final result = await session.execute(
        Sql.named('''
          WITH upserted AS (
            INSERT INTO direct_messages (
              conversation_id,
              sender_id,
              message,
              client_request_id
            )
            VALUES (@convId, @senderId, @message, @clientRequestId)
            ON CONFLICT (sender_id, client_request_id)
              WHERE client_request_id IS NOT NULL
            DO UPDATE SET client_request_id = EXCLUDED.client_request_id
            RETURNING
              id,
              created_at,
              message,
              client_request_id,
              (xmax = 0) AS inserted
          ),
          updated AS (
            UPDATE conversations
            SET last_message_at = (SELECT created_at FROM upserted)
            WHERE id = @convId
              AND (SELECT inserted FROM upserted)
            RETURNING id
          )
          SELECT
            id,
            created_at,
            message,
            client_request_id,
            inserted
          FROM upserted
        '''),
        parameters: {
          'convId': id,
          'senderId': userId,
          'message': message,
          'clientRequestId': clientRequestId,
        },
      );
      final row = result.first.toColumnMap();
      if (row['message'] != message) {
        return <String, dynamic>{'error': 'idempotency_conflict'};
      }
      return <String, dynamic>{'message': row};
    });
    if (sendResult == null) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'error': 'recipient_unavailable',
          'message': 'O destinatário não está mais disponível.',
        },
      );
    }
    if (sendResult['error'] case final error?) {
      final status =
          error == 'idempotency_conflict'
              ? HttpStatus.conflict
              : HttpStatus.forbidden;
      return Response.json(
        statusCode: status,
        body: {
          'error': error,
          'message':
              error == 'idempotency_conflict'
                  ? 'A chave de retry ja foi usada com outro conteudo.'
                  : 'Esta conversa nao aceita novas mensagens.',
        },
      );
    }

    final msg = sendResult['message']! as Map<String, dynamic>;
    final createdAt = msg['created_at'];
    final inserted = msg['inserted'] == true;

    if (inserted) {
      NotificationService.createFromActorDeferred(
        pool: pool,
        actorUserId: userId,
        userId: receiverId,
        type: 'direct_message',
        titleBuilder: (senderName) => 'Nova mensagem de $senderName',
        body:
            message.length > 100 ? '${message.substring(0, 100)}...' : message,
        referenceId: id, // conversation id
        endpoint: 'POST /conversations/:id/messages',
        requestId: _requestId(context),
        conversationId: id,
      );
    }

    return Response.json(
      statusCode: inserted ? HttpStatus.created : HttpStatus.ok,
      body: {
        'id': msg['id'],
        'conversation_id': id,
        'sender_id': userId,
        'message': message,
        'client_request_id': msg['client_request_id'],
        'idempotent_replay': !inserted,
        'created_at':
            createdAt is DateTime
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
