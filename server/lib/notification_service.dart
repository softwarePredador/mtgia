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
      final inserted = await pool.execute(
        Sql.named('''
          INSERT INTO notifications (user_id, type, reference_id, title, body)
          SELECT id, @type, @referenceId, @title, @body
          FROM users
          WHERE id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
          FOR UPDATE
          RETURNING id
        '''),
        parameters: {
          'userId': userId,
          'type': type,
          'referenceId': referenceId,
          'title': title,
          'body': body,
        },
      );
      if (inserted.isEmpty) return;

      // Envia push notification em background; a gravação no banco é a fonte
      // de verdade e não deve depender da disponibilidade do FCM.
      unawaited(
        PushNotificationService.sendToUser(
          pool: pool,
          userId: userId,
          title: title,
          body: body,
          data: {
            'type': type,
            if (referenceId != null) 'reference_id': referenceId,
          },
        ),
      );
    } catch (e, st) {
      Log.e(
        '[notification_service] create_failed type=$type user_id=$userId reference_id=${referenceId ?? 'n/a'} error=$e',
      );
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
            final title = await _createFromActiveActor(
              pool: pool,
              actorUserId: actorUserId,
              userId: userId,
              type: type,
              titleBuilder: titleBuilder,
              body: body,
              referenceId: referenceId,
            );
            if (title == null) return;
            unawaited(
              PushNotificationService.sendToUser(
                pool: pool,
                userId: userId,
                actorUserId: actorUserId,
                title: title,
                body: body,
                data: {
                  'type': type,
                  if (referenceId != null) 'reference_id': referenceId,
                },
              ),
            );
          })
          .timeout(const Duration(seconds: 10))
          .then((_) {
            final durationMs =
                DateTime.now().difference(startedAt).inMilliseconds;
            if (durationMs >= 1000) {
              Log.w(
                '[social_notification] slow_deferred '
                'endpoint=$endpoint duration_ms=$durationMs request_id=$requestId '
                'actor_user_id=$actorUserId recipient_user_id=$userId '
                'reference_id=${referenceId ?? 'n/a'} trade_id=${tradeId ?? 'n/a'} '
                'conversation_id=${conversationId ?? 'n/a'} type=$type',
              );
            }
          })
          .catchError((Object error, StackTrace stackTrace) async {
            final durationMs =
                DateTime.now().difference(startedAt).inMilliseconds;
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

  static Future<String?> _createFromActiveActor({
    required Pool pool,
    required String actorUserId,
    required String userId,
    required String type,
    required String Function(String actorName) titleBuilder,
    String? body,
    String? referenceId,
  }) {
    return pool.runTx((session) async {
      final participantIds = {actorUserId, userId}.toList()..sort();
      final activeUsers = await session.execute(
        Sql.named('''
          SELECT id
          FROM users
          WHERE id = ANY(@participantIds::uuid[])
            AND deleted_at IS NULL
          ORDER BY id
          FOR UPDATE
        '''),
        parameters: {'participantIds': participantIds},
      );
      if (activeUsers.length != participantIds.length) return null;

      final actor = await session.execute(
        Sql.named('''
          SELECT username, display_name
          FROM users
          WHERE id = @actorUserId
            AND deleted_at IS NULL
        '''),
        parameters: {'actorUserId': actorUserId},
      );
      if (actor.isEmpty) return null;
      final blocked = await session.execute(
        Sql.named('''
          SELECT EXISTS (
            SELECT 1
            FROM user_blocks
            WHERE (blocker_id = @actorUserId AND blocked_id = @userId)
               OR (blocker_id = @userId AND blocked_id = @actorUserId)
          ) AS blocked
        '''),
        parameters: {'actorUserId': actorUserId, 'userId': userId},
      );
      if (blocked.first.toColumnMap()['blocked'] == true) return null;
      final row = actor.first.toColumnMap();
      final actorName =
          (row['display_name'] ?? row['username']) as String? ?? 'Alguém';
      final title = titleBuilder(actorName);

      await session.execute(
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
      return title;
    });
  }
}
