import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// PUT /notifications/:id/read → Marcar uma notificação como lida
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(
      Sql.named('''
        UPDATE notifications
        SET read_at = CURRENT_TIMESTAMP
        WHERE id = @id AND user_id = @userId AND read_at IS NULL
      '''),
      parameters: {'id': id, 'userId': userId},
    );

    if (result.affectedRows == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Notificação não encontrada ou já lida'},
      );
    }

    return Response.json(body: {'ok': true});
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'notification_read_route',
      extras: {'operation': 'mark_notification_read', 'notification_id': id},
    );
    Log.e('[ERROR] mark notification read failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao marcar como lida'},
    );
  }
}
