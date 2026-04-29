import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';

/// GET /notifications/count → Contagem de não lidas
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int FROM notifications
        WHERE user_id = @userId AND read_at IS NULL
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
      source: 'notifications_count_route',
      extras: {'operation': 'count_unread_notifications'},
    );
    Log.e('[ERROR] count unread notifications failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao contar notificações'},
    );
  }
}
