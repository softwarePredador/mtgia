import 'dart:async';

import 'package:postgres/postgres.dart';

import 'logger.dart';
import 'observability.dart';
import 'push_notification_service.dart';

/// Serviço helper para criar notificações de forma consistente.
/// Usado nos handlers de follow, trade, e mensagens.
/// Agora também envia push notification via FCM (se configurado).
class NotificationService {
  /// Cria uma notificação para o usuário destino.
  /// Também envia push notification se o usuário tem FCM token.
  /// Silencioso: nunca lança exceção (erros são printados no console).
  static Future<void> create({
    required Pool pool,
    required String userId,
    required String type,
    required String title,
    String? body,
    String? referenceId,
    bool rethrowOnError = false,
  }) async {
    try {
      await pool.execute(
        Sql.named('''
          INSERT INTO notifications (user_id, type, reference_id, title, body)
          VALUES (@userId, @type, @referenceId, @title, @body)
        '''),
        parameters: {
          'userId': userId,
          'type': type,
          'referenceId': referenceId,
          'title': title,
          'body': body,
        },
      );

      // Envia push notification em background (não bloqueia)
      PushNotificationService.sendToUser(
        pool: pool,
        userId: userId,
        title: title,
        body: body,
        data: {
          'type': type,
          if (referenceId != null) 'reference_id': referenceId,
        },
      );
    } catch (e, st) {
      Log.e(
          '[notification_service] create_failed type=$type user_id=$userId reference_id=${referenceId ?? 'n/a'} error=$e');
      if (rethrowOnError) {
        Error.throwWithStackTrace(e, st);
      }
    }
  }

  static void createFromActorDeferred({
    required Pool pool,
    required String actorUserId,
    required String userId,
    required String type,
    required String Function(String actorName) titleBuilder,
    String? body,
    String? referenceId,
    required String endpoint,
    required String requestId,
    String source = 'social_notification_deferred',
    String? tradeId,
    String? conversationId,
  }) {
    final startedAt = DateTime.now();
    unawaited(
      Future<void>(() async {
        final actorName = await _resolveActorName(pool, actorUserId);
        await create(
          pool: pool,
          userId: userId,
          type: type,
          title: titleBuilder(actorName),
          body: body,
          referenceId: referenceId,
          rethrowOnError: true,
        );
      }).timeout(const Duration(seconds: 10)).then((_) {
        final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
        if (durationMs >= 1000) {
          Log.w(
            '[social_notification] slow_deferred '
            'endpoint=$endpoint duration_ms=$durationMs request_id=$requestId '
            'actor_user_id=$actorUserId recipient_user_id=$userId '
            'reference_id=${referenceId ?? 'n/a'} trade_id=${tradeId ?? 'n/a'} '
            'conversation_id=${conversationId ?? 'n/a'} type=$type',
          );
        }
      }).catchError((Object error, StackTrace stackTrace) async {
        final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
        Log.e(
          '[social_notification] deferred_failed '
          'endpoint=$endpoint duration_ms=$durationMs request_id=$requestId '
          'actor_user_id=$actorUserId recipient_user_id=$userId '
          'reference_id=${referenceId ?? 'n/a'} trade_id=${tradeId ?? 'n/a'} '
          'conversation_id=${conversationId ?? 'n/a'} type=$type error=$error',
        );
        await captureObservedException(
          error,
          stackTrace: stackTrace,
          userId: actorUserId,
          tags: {'source': source, 'endpoint': endpoint, 'type': type},
          extras: {
            'request_id': requestId,
            'recipient_user_id': userId,
            if (referenceId != null) 'reference_id': referenceId,
            if (tradeId != null) 'trade_id': tradeId,
            if (conversationId != null) 'conversation_id': conversationId,
            'duration_ms': durationMs,
          },
        );
      }),
    );
  }

  static Future<String> _resolveActorName(Pool pool, String actorUserId) async {
    final result = await pool.execute(
      Sql.named('SELECT username, display_name FROM users WHERE id = @id'),
      parameters: {'id': actorUserId},
    );
    if (result.isEmpty) {
      return 'Alguém';
    }
    final row = result.first.toColumnMap();
    return (row['display_name'] ?? row['username']) as String? ?? 'Alguém';
  }
}
