import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';

/// GET /conversations/unread-count
/// Retorna a contagem global de mensagens não lidas do usuário autenticado.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM direct_messages dm
        JOIN conversations c ON c.id = dm.conversation_id
        WHERE dm.read_at IS NULL
          AND dm.sender_id != @userId
          AND (c.user_a_id = @userId OR c.user_b_id = @userId)
      '''),
      parameters: {'userId': userId},
    );

    final unread = (result.first[0] as int?) ?? 0;
    return Response.json(body: {'unread': unread});
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'conversation_unread_count_route',
      extras: {'operation': 'count_unread_direct_messages'},
    );
    Log.e('[ERROR] count unread direct messages failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao contar mensagens não lidas'},
    );
  }
}
