import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';

/// PUT /notifications/read-all → Marcar todas as notificações como lidas
Future<Response> onRequest(RequestContext context) async {
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
        WHERE user_id = @userId AND read_at IS NULL
      '''),
      parameters: {'userId': userId},
    );

    return Response.json(body: {
      'marked_read': result.affectedRows,
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'notifications_read_all_route',
      extras: {'operation': 'mark_all_notifications_read'},
    );
    Log.e('[ERROR] mark all notifications read failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao marcar todas como lidas'},
    );
  }
}
