import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/notification_service.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

/// PUT /trades/:id/respond → Aceitar ou recusar trade
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final action = body['action'] as String?;
    if (action == null || !['accept', 'decline'].contains(action)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'action deve ser "accept" ou "decline"'},
      );
    }

    final newStatus = action == 'accept' ? 'accepted' : 'declined';

    // Atomic: UPDATE ... WHERE status = 'pending' evita race condition (TOCTOU)
    late final String senderId;
    final success = await pool.runTx((session) async {
      // UPDATE atômico: só altera se status ainda é 'pending' E user é o receiver
      final updateResult = await session.execute(Sql.named('''
        UPDATE trade_offers
        SET status = @newStatus, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id AND status = 'pending' AND receiver_id = @userId
        RETURNING sender_id
      '''), parameters: {'id': id, 'newStatus': newStatus, 'userId': userId});

      if (updateResult.isEmpty) return false;
      senderId = updateResult.first.toColumnMap()['sender_id'] as String;

      await session.execute(Sql.named('''
        INSERT INTO trade_status_history (trade_offer_id, old_status, new_status, changed_by, notes)
        VALUES (@id, 'pending', @newStatus, @userId, @notes)
      '''), parameters: {
        'id': id,
        'newStatus': newStatus,
        'userId': userId,
        'notes': action == 'accept' ? 'Proposta aceita' : 'Proposta recusada',
      });
      return true;
    });

    if (success != true) {
      // Determinar motivo: trade não existe, user não é receiver, ou status mudou
      final check = await pool.execute(
        Sql.named('SELECT receiver_id, status FROM trade_offers WHERE id = @id'),
        parameters: {'id': id},
      );
      if (check.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'error': 'Trade não encontrado'},
        );
      }
      final row = check.first.toColumnMap();
      if (row['receiver_id'] != userId) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Apenas o destinatário pode aceitar/recusar'},
        );
      }
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Trade não está pendente (status atual: ${row['status']})'},
      );
    }

    // 🔔 Notificação: trade aceito/recusado → notificar o sender
    final responderInfo = await pool.execute(
      Sql.named('SELECT username, display_name FROM users WHERE id = @id'),
      parameters: {'id': userId},
    );
    final responderName = responderInfo.isNotEmpty
        ? (responderInfo.first.toColumnMap()['display_name'] ??
            responderInfo.first.toColumnMap()['username']) as String
        : 'Alguém';
    await NotificationService.create(
      pool: pool,
      userId: senderId,
      type: action == 'accept' ? 'trade_accepted' : 'trade_declined',
      title: action == 'accept'
          ? '$responderName aceitou sua proposta de trade'
          : '$responderName recusou sua proposta de trade',
      referenceId: id,
    );

    return Response.json(body: {
      'id': id,
      'status': newStatus,
      'message': action == 'accept' ? 'Trade aceito!' : 'Trade recusado.',
    });
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'trade_respond_route',
      extras: {'operation': 'respond_trade', 'trade_id': id},
    );
    Log.e('[ERROR] respond trade failed: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro interno ao responder trade'},
    );
  }
}
