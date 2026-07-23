import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'distributed_rate_limiter.dart';

const socialReportReasons = <String>{
  'spam',
  'abuse',
  'scam',
  'inappropriate',
  'copyright',
  'other',
};

const socialReportTargetTypes = <String>{
  'deck',
  'comment',
  'profile',
  'binder_item',
  'message',
  'trade_message',
};

class SocialSafetyException implements Exception {
  const SocialSafetyException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class SocialInteractionPolicy {
  const SocialInteractionPolicy({
    required this.blocked,
    required this.allowed,
    required this.visibility,
  });

  final bool blocked;
  final bool allowed;
  final String visibility;
}

class SocialSafetyService {
  const SocialSafetyService(this.pool);

  final Pool pool;

  Future<bool> isInteractionBlocked(String firstUserId, String secondUserId) {
    if (firstUserId == secondUserId) return Future.value(false);
    return pool
        .execute(
          Sql.named('''
        SELECT EXISTS (
          SELECT 1
          FROM user_blocks
          WHERE (blocker_id = CAST(@first AS uuid)
                 AND blocked_id = CAST(@second AS uuid))
             OR (blocker_id = CAST(@second AS uuid)
                 AND blocked_id = CAST(@first AS uuid))
        ) AS blocked
      '''),
          parameters: {'first': firstUserId, 'second': secondUserId},
        )
        .then((result) => result.first.toColumnMap()['blocked'] == true);
  }

  Future<SocialInteractionPolicy> interactionPolicy({
    required String actorUserId,
    required String targetUserId,
    required String channel,
  }) async {
    if (!{'message', 'trade'}.contains(channel)) {
      throw ArgumentError.value(channel, 'channel');
    }
    final visibilityColumn =
        channel == 'message' ? 'message_visibility' : 'trade_visibility';
    final result = await pool.execute(
      Sql.named('''
        SELECT
          u.$visibilityColumn AS visibility,
          EXISTS (
            SELECT 1
            FROM user_blocks b
            WHERE (b.blocker_id = CAST(@actor AS uuid)
                   AND b.blocked_id = CAST(@target AS uuid))
               OR (b.blocker_id = CAST(@target AS uuid)
                   AND b.blocked_id = CAST(@actor AS uuid))
          ) AS blocked,
          EXISTS (
            SELECT 1
            FROM user_follows f
            WHERE f.follower_id = CAST(@actor AS uuid)
              AND f.following_id = CAST(@target AS uuid)
          ) AS follows_target
        FROM users u
        WHERE u.id = CAST(@target AS uuid)
          AND u.deleted_at IS NULL
      '''),
      parameters: {'actor': actorUserId, 'target': targetUserId},
    );
    if (result.isEmpty) {
      throw const SocialSafetyException(
        'target_not_found',
        'Usuario nao encontrado.',
      );
    }
    final row = result.first.toColumnMap();
    final visibility = row['visibility']?.toString() ?? 'none';
    final blocked = row['blocked'] == true;
    final allowed =
        !blocked &&
        (visibility == 'everyone' ||
            (visibility == 'followers' && row['follows_target'] == true));
    return SocialInteractionPolicy(
      blocked: blocked,
      allowed: allowed,
      visibility: visibility,
    );
  }

  Future<Map<String, dynamic>> blockUser({
    required String actorUserId,
    required String targetUserId,
    String? reason,
    String? requestId,
  }) async {
    if (actorUserId == targetUserId) {
      throw const SocialSafetyException(
        'self_block',
        'Nao e possivel bloquear a si mesmo.',
      );
    }
    final cleanReason = reason?.trim();
    return pool.runTx((session) async {
      final participantIds = <String>[actorUserId, targetUserId]..sort();
      final users = await session.execute(
        Sql.named('''
          SELECT id
          FROM users
          WHERE id = ANY(@ids::uuid[])
            AND deleted_at IS NULL
          ORDER BY id
          FOR UPDATE
        '''),
        parameters: {'ids': participantIds},
      );
      if (users.length != 2) {
        throw const SocialSafetyException(
          'target_not_found',
          'Usuario nao encontrado.',
        );
      }

      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO user_blocks (blocker_id, blocked_id, reason)
          VALUES (
            CAST(@actor AS uuid),
            CAST(@target AS uuid),
            @reason
          )
          ON CONFLICT (blocker_id, blocked_id) DO NOTHING
          RETURNING created_at
        '''),
        parameters: {
          'actor': actorUserId,
          'target': targetUserId,
          'reason':
              cleanReason == null || cleanReason.isEmpty ? null : cleanReason,
        },
      );

      await session.execute(
        Sql.named('''
          DELETE FROM user_follows
          WHERE (follower_id = CAST(@actor AS uuid)
                 AND following_id = CAST(@target AS uuid))
             OR (follower_id = CAST(@target AS uuid)
                 AND following_id = CAST(@actor AS uuid))
        '''),
        parameters: {'actor': actorUserId, 'target': targetUserId},
      );

      await session.execute(
        Sql.named('''
          DELETE FROM notifications n
          WHERE n.user_id = ANY(@ids::uuid[])
            AND (
              (
                n.type = 'new_follower'
                AND n.reference_id = ANY(@ids::uuid[])
              )
              OR (
                n.type = 'direct_message'
                AND n.reference_id IN (
                  SELECT c.id
                  FROM conversations c
                  WHERE (c.user_a_id = CAST(@actor AS uuid)
                         AND c.user_b_id = CAST(@target AS uuid))
                     OR (c.user_a_id = CAST(@target AS uuid)
                         AND c.user_b_id = CAST(@actor AS uuid))
                )
              )
              OR (
                n.type LIKE 'trade_%'
                AND n.reference_id IN (
                  SELECT t.id
                  FROM trade_offers t
                  WHERE (t.sender_id = CAST(@actor AS uuid)
                         AND t.receiver_id = CAST(@target AS uuid))
                     OR (t.sender_id = CAST(@target AS uuid)
                         AND t.receiver_id = CAST(@actor AS uuid))
                )
              )
            )
        '''),
        parameters: {
          'ids': participantIds,
          'actor': actorUserId,
          'target': targetUserId,
        },
      );

      if (inserted.isNotEmpty) {
        await session.execute(
          Sql.named('''
            INSERT INTO user_block_events (
              actor_user_id, target_user_id, action, reason, request_id
            )
            VALUES (
              CAST(@actor AS uuid),
              CAST(@target AS uuid),
              'blocked',
              @reason,
              @requestId
            )
          '''),
          parameters: {
            'actor': actorUserId,
            'target': targetUserId,
            'reason':
                cleanReason == null || cleanReason.isEmpty ? null : cleanReason,
            'requestId': requestId,
          },
        );
      }

      return {
        'blocked': true,
        'created': inserted.isNotEmpty,
        'target_user_id': targetUserId,
        if (inserted.isNotEmpty)
          'created_at': _dateString(inserted.first.toColumnMap()['created_at']),
      };
    });
  }

  Future<Map<String, dynamic>> unblockUser({
    required String actorUserId,
    required String targetUserId,
    String? requestId,
  }) async {
    return pool.runTx((session) async {
      final deleted = await session.execute(
        Sql.named('''
          DELETE FROM user_blocks
          WHERE blocker_id = CAST(@actor AS uuid)
            AND blocked_id = CAST(@target AS uuid)
          RETURNING blocker_id
        '''),
        parameters: {'actor': actorUserId, 'target': targetUserId},
      );
      if (deleted.isNotEmpty) {
        await session.execute(
          Sql.named('''
            INSERT INTO user_block_events (
              actor_user_id, target_user_id, action, request_id
            )
            VALUES (
              CAST(@actor AS uuid),
              CAST(@target AS uuid),
              'unblocked',
              @requestId
            )
          '''),
          parameters: {
            'actor': actorUserId,
            'target': targetUserId,
            'requestId': requestId,
          },
        );
      }
      return {
        'blocked': false,
        'removed': deleted.isNotEmpty,
        'target_user_id': targetUserId,
      };
    });
  }

  Future<List<Map<String, dynamic>>> listBlockedUsers(
    String actorUserId,
  ) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          u.id,
          u.username,
          u.display_name,
          u.avatar_url,
          b.reason,
          b.created_at
        FROM user_blocks b
        JOIN users u ON u.id = b.blocked_id
        WHERE b.blocker_id = CAST(@actor AS uuid)
          AND u.deleted_at IS NULL
        ORDER BY b.created_at DESC
      '''),
      parameters: {'actor': actorUserId},
    );
    return result
        .map((row) {
          final map = row.toColumnMap();
          return {
            'id': map['id']?.toString(),
            'username': map['username'],
            'display_name': map['display_name'],
            'avatar_url': map['avatar_url'],
            'reason': map['reason'],
            'blocked_at': _dateString(map['created_at']),
          };
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> reportContent({
    required String reporterUserId,
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
    Map<String, dynamic> evidence = const {},
  }) async {
    final normalizedTargetType = targetType.trim().toLowerCase();
    final normalizedReason = reason.trim().toLowerCase();
    final normalizedTargetId = targetId.trim();
    if (!socialReportTargetTypes.contains(normalizedTargetType)) {
      throw const SocialSafetyException(
        'invalid_target_type',
        'Tipo de alvo invalido.',
      );
    }
    if (!socialReportReasons.contains(normalizedReason)) {
      throw const SocialSafetyException(
        'invalid_reason',
        'Motivo de denuncia invalido.',
      );
    }
    if (normalizedTargetId.isEmpty) {
      throw const SocialSafetyException(
        'invalid_target',
        'Alvo da denuncia e obrigatorio.',
      );
    }

    final allowed = await DistributedRateLimiter(
      pool: pool,
      bucket: 'content-report',
      maxRequests: 10,
      windowSeconds: 3600,
    ).isAllowed('user:$reporterUserId');
    if (!allowed) {
      throw const SocialSafetyException(
        'rate_limited',
        'Limite de denuncias atingido. Tente novamente mais tarde.',
      );
    }

    final ownerId = await _reportableTargetOwner(
      reporterUserId: reporterUserId,
      targetType: normalizedTargetType,
      targetId: normalizedTargetId,
    );
    if (ownerId == null) {
      throw const SocialSafetyException(
        'target_not_found',
        'Conteudo nao encontrado ou indisponivel.',
      );
    }
    if (ownerId == reporterUserId) {
      throw const SocialSafetyException(
        'self_report',
        'Nao e possivel denunciar o proprio conteudo.',
      );
    }

    try {
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO content_reports (
            reporter_user_id,
            target_type,
            target_id,
            reason,
            details,
            evidence
          )
          VALUES (
            CAST(@reporter AS uuid),
            @targetType,
            @targetId,
            @reason,
            @details,
            CAST(@evidence AS jsonb)
          )
          RETURNING
            id, target_type, target_id, reason, status, priority,
            sla_due_at, created_at
        '''),
        parameters: {
          'reporter': reporterUserId,
          'targetType': normalizedTargetType,
          'targetId': normalizedTargetId,
          'reason': normalizedReason,
          'details': details.trim(),
          'evidence': jsonEncode(evidence),
        },
      );
      return _reportRow(result.first);
    } on ServerException catch (error) {
      if (error.code == '23505') {
        throw const SocialSafetyException(
          'duplicate_report',
          'Ja existe uma denuncia ativa para este conteudo.',
        );
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listModerationQueue({
    String status = 'open',
    int limit = 50,
    int offset = 0,
  }) async {
    const allowedStatuses = {
      'open',
      'reviewing',
      'resolved',
      'dismissed',
      'appealed',
    };
    if (!allowedStatuses.contains(status)) {
      throw const SocialSafetyException(
        'invalid_status',
        'Estado de moderacao invalido.',
      );
    }
    final result = await pool.execute(
      Sql.named('''
        SELECT
          r.id,
          r.reporter_user_id,
          reporter.username AS reporter_username,
          r.target_type,
          r.target_id,
          r.reason,
          r.details,
          r.status,
          r.priority,
          r.evidence,
          r.sla_due_at,
          r.resolution,
          r.resolution_action,
          r.created_at,
          r.updated_at,
          r.reviewed_at,
          r.reviewed_by,
          (r.sla_due_at < CURRENT_TIMESTAMP
           AND r.status IN ('open', 'reviewing', 'appealed')) AS overdue
        FROM content_reports r
        LEFT JOIN users reporter ON reporter.id = r.reporter_user_id
        WHERE r.status = @status
        ORDER BY r.priority ASC, r.sla_due_at ASC, r.created_at ASC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        'status': status,
        'limit': limit.clamp(1, 100),
        'offset': offset < 0 ? 0 : offset,
      },
    );
    return result.map(_moderationQueueRow).toList(growable: false);
  }

  Future<Map<String, dynamic>> moderateReport({
    required String reportId,
    required String action,
    required String rationale,
    String? moderatorUserId,
    String? requestId,
    Map<String, dynamic> evidence = const {},
  }) async {
    const actions = {
      'start_review',
      'dismiss',
      'hide',
      'remove',
      'restrict',
      'restore',
    };
    if (!actions.contains(action)) {
      throw const SocialSafetyException(
        'invalid_action',
        'Acao de moderacao invalida.',
      );
    }
    final cleanRationale = rationale.trim();
    if (cleanRationale.length < 5) {
      throw const SocialSafetyException(
        'invalid_rationale',
        'Justificativa de moderacao e obrigatoria.',
      );
    }

    return pool.runTx((session) async {
      final result = await session.execute(
        Sql.named('''
          SELECT *
          FROM content_reports
          WHERE id = CAST(@reportId AS uuid)
          FOR UPDATE
        '''),
        parameters: {'reportId': reportId},
      );
      if (result.isEmpty) {
        throw const SocialSafetyException(
          'report_not_found',
          'Denuncia nao encontrada.',
        );
      }
      final report = result.first.toColumnMap();
      final targetType = report['target_type'] as String;
      final targetId = report['target_id'] as String;
      final stateEvidence = <String, dynamic>{
        ...evidence,
        'previous_state': await _applyModerationAction(
          session,
          targetType: targetType,
          targetId: targetId,
          action: action,
          reportId: reportId,
        ),
      };

      final nextStatus = switch (action) {
        'start_review' => 'reviewing',
        'dismiss' => 'dismissed',
        'restore' => 'resolved',
        _ => 'resolved',
      };
      final resolutionAction = switch (action) {
        'dismiss' || 'start_review' || 'restore' => 'none',
        _ => action,
      };

      await session.execute(
        Sql.named('''
          UPDATE content_reports
          SET status = @status,
              resolution = @rationale,
              resolution_action = @resolutionAction,
              reviewed_at = CASE
                WHEN @status IN ('resolved', 'dismissed')
                  THEN CURRENT_TIMESTAMP
                ELSE reviewed_at
              END,
              reviewed_by = COALESCE(
                CAST(@moderator AS uuid),
                reviewed_by
              ),
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@reportId AS uuid)
        '''),
        parameters: {
          'status': nextStatus,
          'rationale': cleanRationale,
          'resolutionAction': resolutionAction,
          'moderator': moderatorUserId,
          'reportId': reportId,
        },
      );
      await session.execute(
        Sql.named('''
          INSERT INTO moderation_actions (
            report_id,
            moderator_user_id,
            action,
            rationale,
            evidence,
            request_id
          )
          VALUES (
            CAST(@reportId AS uuid),
            CAST(@moderator AS uuid),
            @action,
            @rationale,
            CAST(@evidence AS jsonb),
            @requestId
          )
        '''),
        parameters: {
          'reportId': reportId,
          'moderator': moderatorUserId,
          'action': action,
          'rationale': cleanRationale,
          'evidence': jsonEncode(stateEvidence),
          'requestId': requestId,
        },
      );

      final updated = await session.execute(
        Sql.named('''
          SELECT
            id, target_type, target_id, reason, status, priority,
            sla_due_at, created_at, updated_at, resolution, resolution_action
          FROM content_reports
          WHERE id = CAST(@reportId AS uuid)
        '''),
        parameters: {'reportId': reportId},
      );
      return _reportRow(updated.first);
    });
  }

  Future<Map<String, dynamic>> appealReport({
    required String reportId,
    required String appellantUserId,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.length < 10 || cleanReason.length > 2000) {
      throw const SocialSafetyException(
        'invalid_appeal_reason',
        'A apelacao deve ter entre 10 e 2000 caracteres.',
      );
    }
    try {
      return pool.runTx((session) async {
        final report = await session.execute(
          Sql.named('''
            SELECT id, target_type, target_id, status
            FROM content_reports
            WHERE id = CAST(@reportId AS uuid)
            FOR UPDATE
          '''),
          parameters: {'reportId': reportId},
        );
        if (report.isEmpty) {
          throw const SocialSafetyException(
            'report_not_found',
            'Denuncia nao encontrada.',
          );
        }
        final row = report.first.toColumnMap();
        if (!{'resolved', 'dismissed'}.contains(row['status'])) {
          throw const SocialSafetyException(
            'appeal_not_available',
            'Esta denuncia ainda nao pode ser apelada.',
          );
        }
        final owner = await _targetOwnerInSession(
          session,
          targetType: row['target_type'] as String,
          targetId: row['target_id'] as String,
        );
        if (owner != appellantUserId) {
          throw const SocialSafetyException(
            'appeal_forbidden',
            'Somente o autor do conteudo pode apelar.',
          );
        }
        final appeal = await session.execute(
          Sql.named('''
            INSERT INTO content_report_appeals (
              report_id, appellant_user_id, reason
            )
            VALUES (
              CAST(@reportId AS uuid),
              CAST(@appellant AS uuid),
              @reason
            )
            RETURNING id, report_id, status, created_at
          '''),
          parameters: {
            'reportId': reportId,
            'appellant': appellantUserId,
            'reason': cleanReason,
          },
        );
        await session.execute(
          Sql.named('''
            UPDATE content_reports
            SET status = 'appealed', updated_at = CURRENT_TIMESTAMP
            WHERE id = CAST(@reportId AS uuid)
          '''),
          parameters: {'reportId': reportId},
        );
        final appealRow = appeal.first.toColumnMap();
        return {
          'id': appealRow['id']?.toString(),
          'report_id': appealRow['report_id']?.toString(),
          'status': appealRow['status'],
          'created_at': _dateString(appealRow['created_at']),
        };
      });
    } on ServerException catch (error) {
      if (error.code == '23505') {
        throw const SocialSafetyException(
          'duplicate_appeal',
          'Ja existe uma apelacao ativa para esta denuncia.',
        );
      }
      rethrow;
    }
  }

  Future<String?> _reportableTargetOwner({
    required String reporterUserId,
    required String targetType,
    required String targetId,
  }) async {
    if (targetType == 'message') {
      final result = await pool.execute(
        Sql.named('''
          SELECT dm.sender_id AS owner_id
          FROM direct_messages dm
          JOIN conversations c ON c.id = dm.conversation_id
          WHERE dm.id = CAST(@target AS uuid)
            AND dm.moderation_status = 'visible'
            AND (
              c.user_a_id = CAST(@reporter AS uuid)
              OR c.user_b_id = CAST(@reporter AS uuid)
            )
          LIMIT 1
        '''),
        parameters: {'target': targetId, 'reporter': reporterUserId},
      );
      return result.isEmpty
          ? null
          : result.first.toColumnMap()['owner_id']?.toString();
    }
    if (targetType == 'trade_message') {
      final result = await pool.execute(
        Sql.named('''
          SELECT tm.sender_id AS owner_id
          FROM trade_messages tm
          JOIN trade_offers t ON t.id = tm.trade_offer_id
          WHERE tm.id = CAST(@target AS uuid)
            AND tm.moderation_status = 'visible'
            AND (
              t.sender_id = CAST(@reporter AS uuid)
              OR t.receiver_id = CAST(@reporter AS uuid)
            )
          LIMIT 1
        '''),
        parameters: {'target': targetId, 'reporter': reporterUserId},
      );
      return result.isEmpty
          ? null
          : result.first.toColumnMap()['owner_id']?.toString();
    }
    return pool.runTx(
      (session) => _targetOwnerInSession(
        session,
        targetType: targetType,
        targetId: targetId,
      ),
    );
  }

  Future<String?> _targetOwnerInSession(
    Session session, {
    required String targetType,
    required String targetId,
  }) async {
    final query = switch (targetType) {
      'deck' =>
        'SELECT user_id AS owner_id FROM decks '
            'WHERE id = CAST(@target AS uuid) AND deleted_at IS NULL',
      'comment' =>
        'SELECT user_id AS owner_id FROM deck_comments '
            "WHERE id = CAST(@target AS uuid) AND status <> 'deleted'",
      'profile' =>
        'SELECT id AS owner_id FROM users '
            'WHERE id = CAST(@target AS uuid) AND deleted_at IS NULL',
      'binder_item' =>
        'SELECT user_id AS owner_id FROM user_binder_items '
            'WHERE id = CAST(@target AS uuid)',
      'message' =>
        'SELECT sender_id AS owner_id FROM direct_messages '
            'WHERE id = CAST(@target AS uuid)',
      'trade_message' =>
        'SELECT sender_id AS owner_id FROM trade_messages '
            'WHERE id = CAST(@target AS uuid)',
      _ => throw StateError('Unsupported target type $targetType'),
    };
    final result = await session.execute(
      Sql.named(query),
      parameters: {'target': targetId},
    );
    return result.isEmpty
        ? null
        : result.first.toColumnMap()['owner_id']?.toString();
  }

  Future<Map<String, dynamic>> _applyModerationAction(
    Session session, {
    required String targetType,
    required String targetId,
    required String action,
    required String reportId,
  }) async {
    if (action == 'start_review' || action == 'dismiss') return const {};
    if (action == 'restore') {
      return _restoreModeratedTarget(
        session,
        targetType: targetType,
        targetId: targetId,
        reportId: reportId,
      );
    }

    final previous = <String, dynamic>{};
    switch (targetType) {
      case 'deck':
        final current = await session.execute(
          Sql.named(
            'SELECT is_public FROM decks WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous['is_public'] =
            current.first.toColumnMap()['is_public'] == true;
        await session.execute(
          Sql.named(
            'UPDATE decks SET is_public = FALSE '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
      case 'comment':
        final current = await session.execute(
          Sql.named(
            'SELECT status FROM deck_comments '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous['status'] = current.first.toColumnMap()['status'];
        await session.execute(
          Sql.named(
            "UPDATE deck_comments SET status = @status, "
            'updated_at = CURRENT_TIMESTAMP '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {
            'target': targetId,
            'status': action == 'remove' ? 'deleted' : 'hidden',
          },
        );
      case 'profile':
        final current = await session.execute(
          Sql.named(
            'SELECT profile_visibility FROM users '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous['profile_visibility'] =
            current.first.toColumnMap()['profile_visibility'];
        await session.execute(
          Sql.named(
            "UPDATE users SET profile_visibility = 'private', "
            'updated_at = CURRENT_TIMESTAMP '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
      case 'binder_item':
        final current = await session.execute(
          Sql.named(
            'SELECT for_trade, for_sale FROM user_binder_items '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous.addAll(current.first.toColumnMap());
        await session.execute(
          Sql.named(
            'UPDATE user_binder_items '
            'SET for_trade = FALSE, for_sale = FALSE, '
            'updated_at = CURRENT_TIMESTAMP '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
      case 'message':
        final current = await session.execute(
          Sql.named(
            'SELECT moderation_status FROM direct_messages '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous['moderation_status'] =
            current.first.toColumnMap()['moderation_status'];
        await session.execute(
          Sql.named(
            "UPDATE direct_messages SET moderation_status = 'removed' "
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
      case 'trade_message':
        final current = await session.execute(
          Sql.named(
            'SELECT moderation_status FROM trade_messages '
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
        if (current.isEmpty) break;
        previous['moderation_status'] =
            current.first.toColumnMap()['moderation_status'];
        await session.execute(
          Sql.named(
            "UPDATE trade_messages SET moderation_status = 'removed' "
            'WHERE id = CAST(@target AS uuid)',
          ),
          parameters: {'target': targetId},
        );
    }
    return previous;
  }

  Future<Map<String, dynamic>> _restoreModeratedTarget(
    Session session, {
    required String targetType,
    required String targetId,
    required String reportId,
  }) async {
    final action = await session.execute(
      Sql.named('''
        SELECT evidence
        FROM moderation_actions
        WHERE report_id = CAST(@reportId AS uuid)
          AND action IN ('hide', 'remove', 'restrict')
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'reportId': reportId},
    );
    if (action.isEmpty) return const {};
    final rawEvidence = action.first.toColumnMap()['evidence'];
    final evidence =
        rawEvidence is Map
            ? rawEvidence.cast<String, dynamic>()
            : jsonDecode(rawEvidence.toString()) as Map<String, dynamic>;
    final previous =
        (evidence['previous_state'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    switch (targetType) {
      case 'deck':
        if (previous['is_public'] is bool) {
          await session.execute(
            Sql.named(
              'UPDATE decks SET is_public = @value '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {'target': targetId, 'value': previous['is_public']},
          );
        }
      case 'comment':
        if (previous['status'] is String) {
          await session.execute(
            Sql.named(
              'UPDATE deck_comments SET status = @value, '
              'updated_at = CURRENT_TIMESTAMP '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {'target': targetId, 'value': previous['status']},
          );
        }
      case 'profile':
        if (previous['profile_visibility'] is String) {
          await session.execute(
            Sql.named(
              'UPDATE users SET profile_visibility = @value, '
              'updated_at = CURRENT_TIMESTAMP '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {
              'target': targetId,
              'value': previous['profile_visibility'],
            },
          );
        }
      case 'binder_item':
        if (previous['for_trade'] is bool && previous['for_sale'] is bool) {
          await session.execute(
            Sql.named(
              'UPDATE user_binder_items '
              'SET for_trade = @forTrade, for_sale = @forSale, '
              'updated_at = CURRENT_TIMESTAMP '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {
              'target': targetId,
              'forTrade': previous['for_trade'],
              'forSale': previous['for_sale'],
            },
          );
        }
      case 'message':
        if (previous['moderation_status'] is String) {
          await session.execute(
            Sql.named(
              'UPDATE direct_messages SET moderation_status = @value '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {
              'target': targetId,
              'value': previous['moderation_status'],
            },
          );
        }
      case 'trade_message':
        if (previous['moderation_status'] is String) {
          await session.execute(
            Sql.named(
              'UPDATE trade_messages SET moderation_status = @value '
              'WHERE id = CAST(@target AS uuid)',
            ),
            parameters: {
              'target': targetId,
              'value': previous['moderation_status'],
            },
          );
        }
    }
    return previous;
  }

  Map<String, dynamic> _reportRow(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id']?.toString(),
      'target_type': map['target_type'],
      'target_id': map['target_id'],
      'reason': map['reason'],
      'status': map['status'],
      'priority': map['priority'],
      'sla_due_at': _dateString(map['sla_due_at']),
      'created_at': _dateString(map['created_at']),
      if (map.containsKey('updated_at'))
        'updated_at': _dateString(map['updated_at']),
      if (map['resolution'] != null) 'resolution': map['resolution'],
      if (map['resolution_action'] != null)
        'resolution_action': map['resolution_action'],
    };
  }

  Map<String, dynamic> _moderationQueueRow(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id']?.toString(),
      'reporter_user_id': map['reporter_user_id']?.toString(),
      'reporter_username': map['reporter_username'],
      'target_type': map['target_type'],
      'target_id': map['target_id'],
      'reason': map['reason'],
      'details': map['details'],
      'status': map['status'],
      'priority': map['priority'],
      'evidence': map['evidence'],
      'sla_due_at': _dateString(map['sla_due_at']),
      'overdue': map['overdue'] == true,
      'resolution': map['resolution'],
      'resolution_action': map['resolution_action'],
      'created_at': _dateString(map['created_at']),
      'updated_at': _dateString(map['updated_at']),
      'reviewed_at': _dateString(map['reviewed_at']),
      'reviewed_by': map['reviewed_by']?.toString(),
    };
  }
}

String? _dateString(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return value.toString();
}
