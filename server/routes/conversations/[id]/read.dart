import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// PUT /conversations/:id/read → Marcar mensagens como lidas
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

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
        body: {'error': 'Sem permissão'},
      );
    }
    if (conv['interaction_blocked'] == true) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'interaction_blocked'},
      );
    }

    // Marcar como lidas todas as mensagens do OUTRO usuário que ainda não foram lidas
    final result = await pool.execute(
      Sql.named('''
        UPDATE direct_messages
        SET read_at = CURRENT_TIMESTAMP
        WHERE conversation_id = @convId
          AND sender_id != @userId
          AND read_at IS NULL
          AND moderation_status = 'visible'
      '''),
      parameters: {'convId': id, 'userId': userId},
    );

    final unreadResult = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM direct_messages dm
        JOIN conversations c ON c.id = dm.conversation_id
        WHERE dm.read_at IS NULL
          AND dm.sender_id != @userId
          AND dm.moderation_status = 'visible'
          AND (c.user_a_id = @userId OR c.user_b_id = @userId)
          AND NOT EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (b.blocker_id = c.user_a_id AND b.blocked_id = c.user_b_id)
               OR (b.blocker_id = c.user_b_id AND b.blocked_id = c.user_a_id)
          )
      '''),
      parameters: {'userId': userId},
    );
    final unread = (unreadResult.first[0] as int?) ?? 0;

    return Response.json(
      body: {
        'conversation_id': id,
        'marked_read': result.affectedRows,
        'unread': unread,
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'conversation_read_route',
      extras: {'operation': 'mark_conversation_read', 'conversation_id': id},
    );
    Log.e('[ERROR] mark conversation read failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao marcar como lidas'},
    );
  }
}
