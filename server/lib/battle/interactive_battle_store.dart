import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../ai/battle_engine_config.dart';
import 'battle_job_contract.dart';
import 'battle_replay_payload_sanitizer.dart';
import 'battle_request_correlation.dart';
import 'battle_simulation_attempt_service.dart';
import 'battle_simulation_persistence_service.dart';
import 'interactive_battle_contract.dart';
import 'interactive_battle_deck_lifecycle.dart';
import 'interactive_battle_runtime_client.dart';

const interactiveBattleSelectColumns = '''
  id::text AS id,
  user_id::text AS user_id,
  status,
  state_version,
  deck_a_id::text AS deck_a_id,
  deck_b_id::text AS deck_b_id,
  deck_a_hash,
  deck_b_hash,
  request_hash,
  ttl_seconds,
  expires_at,
  last_activity_at,
  active_prompt,
  private_state,
  engine_version,
  engine_commit,
  engine_build,
  engine_process_id,
  engine_process_started_at,
  runtime_session_id,
  attempt_id::text AS attempt_id,
  replay_id::text AS replay_id,
  terminal_reason,
  error_code,
  started_at,
  finished_at,
  created_at,
  updated_at
''';

class InteractiveBattleQuotaExceededException implements Exception {
  const InteractiveBattleQuotaExceededException({
    required this.scope,
    required this.limit,
  });

  final String scope;
  final int limit;
}

class InteractiveBattleRuntimeProcessMismatchException implements Exception {
  const InteractiveBattleRuntimeProcessMismatchException();
}

class InteractiveBattleCreateCommand {
  const InteractiveBattleCreateCommand({
    required this.id,
    required this.userId,
    required this.deckA,
    required this.deckB,
    required this.requestHash,
    required this.requestPayload,
    required this.requestId,
    required this.idempotencyKey,
    required this.requestFingerprint,
    required this.ttlSeconds,
    required this.timeoutMs,
  });

  final String id;
  final String userId;
  final BattleJobDeckSnapshot deckA;
  final BattleJobDeckSnapshot deckB;
  final String requestHash;
  final Map<String, dynamic> requestPayload;
  final String requestId;
  final String idempotencyKey;
  final String requestFingerprint;
  final int ttlSeconds;
  final int timeoutMs;
}

class InteractiveBattleCreateResult {
  const InteractiveBattleCreateResult({
    required this.session,
    required this.created,
    required this.requestPayload,
  });

  final InteractiveBattleSession session;
  final bool created;
  final Map<String, dynamic> requestPayload;
}

class InteractiveBattleActionReservation {
  const InteractiveBattleActionReservation({
    required this.session,
    required this.prompt,
    required this.duplicate,
    this.alreadyAccepted = false,
  });

  final InteractiveBattleSession session;
  final InteractiveBattlePrompt? prompt;
  final bool duplicate;
  final bool alreadyAccepted;
}

class InteractiveBattleConcedeReservation {
  const InteractiveBattleConcedeReservation({
    required this.session,
    required this.duplicate,
    this.alreadyAccepted = false,
  });

  final InteractiveBattleSession session;
  final bool duplicate;
  final bool alreadyAccepted;
}

abstract interface class InteractiveBattleStoreApi {
  Future<InteractiveBattleCreateResult?> findCreate({
    required String userId,
    required String idempotencyKey,
    required String requestFingerprint,
  });

  Future<InteractiveBattleCreateResult> create(
    InteractiveBattleCreateCommand command, {
    required int perUserActiveLimit,
    required int globalActiveLimit,
  });

  Future<InteractiveBattleSession?> get(String userId, String id);

  Future<List<InteractiveBattleSession>> list(
    String userId, {
    int limit = 20,
    String? deckId,
  });

  Future<InteractiveBattleSession> applyRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
  });

  Future<InteractiveBattleSession> finalizeRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    required Map<String, dynamic>? replay,
    String? actionId,
  });

  Future<InteractiveBattleActionReservation> reserveAction({
    required String userId,
    required String id,
    required InteractiveBattleActionInput action,
  });

  Future<InteractiveBattleConcedeReservation> reserveConcede({
    required String userId,
    required String id,
    required String idempotencyKey,
    required String requestFingerprint,
  });

  Future<InteractiveBattleSession> finalizeLocal({
    required String userId,
    required String id,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  });
}

class InteractiveBattleStore implements InteractiveBattleStoreApi {
  const InteractiveBattleStore(this._pool);

  final Pool _pool;

  @override
  Future<InteractiveBattleCreateResult?> findCreate({
    required String userId,
    required String idempotencyKey,
    required String requestFingerprint,
  }) => _pool.runTx((transaction) async {
    await acquireInteractiveBattleDeckLifecycleLock(transaction);
    final existing = await transaction.execute(
      Sql.named('''
        SELECT $interactiveBattleSelectColumns,
               request_fingerprint,
               request_payload
        FROM interactive_battle_sessions
        WHERE user_id = CAST(@user_id AS uuid)
          AND idempotency_key = @idempotency_key
        LIMIT 1
        FOR UPDATE
      '''),
      parameters: {'user_id': userId, 'idempotency_key': idempotencyKey},
    );
    if (existing.isEmpty) return null;
    var row = existing.first.toColumnMap();
    _validateFrozenCreateFingerprint(row, requestFingerprint);
    row = await _repairStartingAdmission(transaction, row: row, userId: userId);
    return InteractiveBattleCreateResult(
      session: _sessionFromRow(row),
      created: false,
      requestPayload: Map<String, dynamic>.unmodifiable(
        _jsonMap(row['request_payload']),
      ),
    );
  });

  @override
  Future<InteractiveBattleCreateResult> create(
    InteractiveBattleCreateCommand command, {
    required int perUserActiveLimit,
    required int globalActiveLimit,
  }) {
    return _pool.runTx((transaction) async {
      await acquireInteractiveBattleDeckLifecycleLock(transaction);
      await transaction.execute(
        "SELECT pg_advisory_xact_lock("
        "hashtext('manaloom:interactive_battle:create:v1'))",
      );
      final existing = await transaction.execute(
        Sql.named('''
          SELECT $interactiveBattleSelectColumns,
                 request_fingerprint,
                 request_payload
          FROM interactive_battle_sessions
          WHERE user_id = CAST(@user_id AS uuid)
            AND idempotency_key = @idempotency_key
          LIMIT 1
          FOR UPDATE
        '''),
        parameters: {
          'user_id': command.userId,
          'idempotency_key': command.idempotencyKey,
        },
      );
      if (existing.isNotEmpty) {
        var row = existing.first.toColumnMap();
        _validateFrozenCreateFingerprint(row, command.requestFingerprint);
        row = await _repairStartingAdmission(
          transaction,
          row: row,
          userId: command.userId,
        );
        return InteractiveBattleCreateResult(
          session: _sessionFromRow(row),
          created: false,
          requestPayload: Map<String, dynamic>.unmodifiable(
            _jsonMap(row['request_payload']),
          ),
        );
      }

      final counts = await transaction.execute(
        Sql.named('''
          SELECT
            COUNT(*) FILTER (
              WHERE user_id = CAST(@user_id AS uuid)
            )::int AS user_active,
            COUNT(*)::int AS global_active
          FROM interactive_battle_sessions
          WHERE status IN (
            'starting',
            'running',
            'waiting_for_action',
            'action_pending'
          )
            AND expires_at > CURRENT_TIMESTAMP
        '''),
        parameters: {'user_id': command.userId},
      );
      final row = counts.first.toColumnMap();
      if (_integer(row['user_active']) >= perUserActiveLimit) {
        throw InteractiveBattleQuotaExceededException(
          scope: 'user',
          limit: perUserActiveLimit,
        );
      }
      if (_integer(row['global_active']) >= globalActiveLimit) {
        throw InteractiveBattleQuotaExceededException(
          scope: 'global',
          limit: globalActiveLimit,
        );
      }

      final lockedDecks = await transaction.execute(
        Sql.named('''
          SELECT id::text
          FROM decks
          WHERE id IN (
            CAST(@deck_a_id AS uuid),
            CAST(@deck_b_id AS uuid)
          )
          ORDER BY id
          FOR KEY SHARE
        '''),
        parameters: {
          'deck_a_id': command.deckA.id,
          'deck_b_id': command.deckB.id,
        },
      );
      if (lockedDecks.length != 2) {
        throw const InteractiveBattleNotFoundException();
      }

      final attempt = await transaction.execute(
        Sql.named('''
          INSERT INTO battle_simulation_attempts (
            user_id,
            deck_a_id,
            deck_b_id,
            simulation_type,
            test_objective,
            request_id,
            request_schema_version,
            job_request_schema_version,
            job_request_hash,
            deck_hash_schema,
            deck_a_hash,
            deck_b_hash,
            timeout_ms,
            engine,
            provenance
          )
          SELECT
            CAST(@user_id AS uuid),
            deck_a.id,
            deck_b.id,
            'interactive_coach',
            'general',
            @request_id,
            @request_schema_version,
            @request_schema_version,
            @request_hash,
            @deck_hash_schema,
            @deck_a_hash,
            @deck_b_hash,
            CAST(@timeout_ms AS integer),
            'xmage',
            @provenance::jsonb
          FROM decks deck_a
          JOIN decks deck_b ON deck_b.id = CAST(@deck_b_id AS uuid)
          WHERE deck_a.id = CAST(@deck_a_id AS uuid)
            AND deck_a.user_id = CAST(@user_id AS uuid)
            AND deck_a.deleted_at IS NULL
            AND deck_b.deleted_at IS NULL
            AND (
              deck_b.user_id = CAST(@user_id AS uuid)
              OR deck_b.is_public = TRUE
            )
          RETURNING id::text
        '''),
        parameters: {
          'user_id': command.userId,
          'deck_a_id': command.deckA.id,
          'deck_b_id': command.deckB.id,
          'request_id': command.requestId,
          'request_schema_version': interactiveBattleRequestSchema,
          'request_hash': command.requestHash,
          'deck_hash_schema': externalBattleDeckHashSchema,
          'deck_a_hash': command.deckA.hash,
          'deck_b_hash': command.deckB.hash,
          'timeout_ms': command.timeoutMs,
          'provenance': jsonEncode(
            sanitizeBattleReplayMetadata(const {
              'schema_version': battleSimulationAttemptSchema,
              'mode': 'interactive',
              'privacy': 'private_participant_view_separate_from_public_replay',
            }),
          ),
        },
      );
      if (attempt.isEmpty) {
        throw const InteractiveBattleNotFoundException();
      }
      final attemptId = attempt.first[0]?.toString();
      if (attemptId == null || attemptId.isEmpty) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_attempt_start_failed',
        );
      }

      final inserted = await transaction.execute(
        Sql.named('''
          INSERT INTO interactive_battle_sessions (
            id,
            user_id,
            deck_a_id,
            deck_b_id,
            deck_hash_schema,
            deck_a_hash,
            deck_b_hash,
            request_schema_version,
            request_hash,
            request_payload,
            idempotency_key,
            request_fingerprint,
            attempt_id,
            engine,
            status,
            state_version,
            ttl_seconds,
            expires_at
          )
          SELECT
            CAST(@id AS uuid),
            CAST(@user_id AS uuid),
            deck_a.id,
            deck_b.id,
            @deck_hash_schema,
            @deck_a_hash,
            @deck_b_hash,
            @request_schema_version,
            @request_hash,
            @request_payload::jsonb,
            @idempotency_key,
            @request_fingerprint,
            CAST(@attempt_id AS uuid),
            'xmage',
            'starting',
            0,
            CAST(@ttl_seconds AS integer),
            CURRENT_TIMESTAMP
              + CAST(@ttl_seconds AS integer) * INTERVAL '1 second'
          FROM decks deck_a
          JOIN decks deck_b ON deck_b.id = CAST(@deck_b_id AS uuid)
          WHERE deck_a.id = CAST(@deck_a_id AS uuid)
            AND deck_a.user_id = CAST(@user_id AS uuid)
            AND deck_a.deleted_at IS NULL
            AND deck_b.deleted_at IS NULL
            AND (
              deck_b.user_id = CAST(@user_id AS uuid)
              OR deck_b.is_public = TRUE
            )
          RETURNING $interactiveBattleSelectColumns
        '''),
        parameters: {
          'id': command.id,
          'user_id': command.userId,
          'deck_a_id': command.deckA.id,
          'deck_b_id': command.deckB.id,
          'deck_hash_schema': externalBattleDeckHashSchema,
          'deck_a_hash': command.deckA.hash,
          'deck_b_hash': command.deckB.hash,
          'request_schema_version': interactiveBattleRequestSchema,
          'request_hash': command.requestHash,
          'request_payload': jsonEncode(command.requestPayload),
          'idempotency_key': command.idempotencyKey,
          'request_fingerprint': command.requestFingerprint,
          'attempt_id': attemptId,
          'ttl_seconds': command.ttlSeconds,
        },
      );
      if (inserted.isEmpty) {
        throw const InteractiveBattleNotFoundException();
      }
      await _appendRecord(
        transaction,
        sessionId: command.id,
        kind: 'session_created',
        visibility: 'internal',
        stateVersion: 0,
        payload: {
          'schema_version': interactiveBattleSessionSchema,
          'deck_hash_schema': externalBattleDeckHashSchema,
          'deck_a_hash': command.deckA.hash,
          'deck_b_hash': command.deckB.hash,
          'request_hash': command.requestHash,
          'ttl_seconds': command.ttlSeconds,
        },
      );
      return InteractiveBattleCreateResult(
        session: _sessionFromRow(inserted.first.toColumnMap()),
        created: true,
        requestPayload: Map<String, dynamic>.unmodifiable(
          command.requestPayload,
        ),
      );
    });
  }

  @override
  Future<InteractiveBattleSession?> get(String userId, String id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT $interactiveBattleSelectColumns
        FROM interactive_battle_sessions
        WHERE id = CAST(@id AS uuid)
          AND user_id = CAST(@user_id AS uuid)
        LIMIT 1
      '''),
      parameters: {'id': id, 'user_id': userId},
    );
    return result.isEmpty ? null : _sessionFromRow(result.first.toColumnMap());
  }

  @override
  Future<List<InteractiveBattleSession>> list(
    String userId, {
    int limit = 20,
    String? deckId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT $interactiveBattleSelectColumns
        FROM interactive_battle_sessions
        WHERE user_id = CAST(@user_id AS uuid)
          AND (
            CAST(@deck_id AS text) IS NULL
            OR deck_a_id = CAST(@deck_id AS uuid)
          )
        ORDER BY created_at DESC, id DESC
        LIMIT @limit
      '''),
      parameters: {
        'user_id': userId,
        'deck_id': deckId,
        'limit': limit.clamp(1, 50),
      },
    );
    return result
        .map((row) => _sessionFromRow(row.toColumnMap()))
        .toList(growable: false);
  }

  @override
  Future<InteractiveBattleActionReservation> reserveAction({
    required String userId,
    required String id,
    required InteractiveBattleActionInput action,
  }) {
    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);

      final prior = await transaction.execute(
        Sql.named('''
          SELECT request_fingerprint
          FROM interactive_battle_records
          WHERE session_id = CAST(@id AS uuid)
            AND idempotency_key = @idempotency_key
          LIMIT 1
        '''),
        parameters: {'id': id, 'idempotency_key': action.idempotencyKey},
      );
      if (prior.isNotEmpty) {
        if (prior.first[0]?.toString() != action.requestFingerprint) {
          throw const InteractiveBattleIdempotencyConflictException();
        }
        return InteractiveBattleActionReservation(
          session: current,
          prompt: current.prompt,
          duplicate: true,
          alreadyAccepted: await _actionAcceptedExists(
            transaction,
            sessionId: id,
            actionId: action.idempotencyKey,
          ),
        );
      }
      if (current.status.isTerminal) {
        throw InteractiveBattleTerminalException(current);
      }
      if (current.status != InteractiveBattleStatus.waitingForAction ||
          current.prompt == null) {
        throw const InteractiveBattleStaleActionException(
          'interactive_battle_not_waiting',
        );
      }
      if (DateTime.now().toUtc().isAfter(current.expiresAt)) {
        throw const InteractiveBattleStaleActionException(
          'interactive_battle_session_expired',
        );
      }
      current.prompt!.validateAction(action);
      await _appendRecord(
        transaction,
        sessionId: id,
        kind: 'action_submitted',
        visibility: 'private_user',
        stateVersion: action.stateVersion,
        promptId: action.promptId,
        optionId: action.optionId,
        idempotencyKey: action.idempotencyKey,
        requestFingerprint: action.requestFingerprint,
        payload: {
          'schema_version': interactiveBattleActionSchema,
          'response_kind': action.responseKind.name,
          if (action.integerValue != null) 'integer_value': action.integerValue,
          if (action.multiAmountValues.isNotEmpty)
            'multi_amount_values': action.multiAmountValues,
        },
      );
      final updated = await transaction.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET status = 'action_pending',
              active_prompt_id = NULL,
              active_prompt = NULL,
              prompt_deadline_at = NULL,
              last_activity_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
            AND status = 'waiting_for_action'
            AND state_version = @state_version
            AND active_prompt_id = @prompt_id
            AND prompt_deadline_at > CURRENT_TIMESTAMP
          RETURNING $interactiveBattleSelectColumns
        '''),
        parameters: {
          'id': id,
          'user_id': userId,
          'state_version': action.stateVersion,
          'prompt_id': action.promptId,
        },
      );
      if (updated.isEmpty) {
        throw const InteractiveBattleStaleActionException(
          'interactive_battle_action_stale',
        );
      }
      return InteractiveBattleActionReservation(
        session: _sessionFromRow(updated.first.toColumnMap()),
        prompt: current.prompt,
        duplicate: false,
      );
    });
  }

  @override
  Future<InteractiveBattleConcedeReservation> reserveConcede({
    required String userId,
    required String id,
    required String idempotencyKey,
    required String requestFingerprint,
  }) {
    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);
      final prior = await transaction.execute(
        Sql.named('''
          SELECT request_fingerprint
          FROM interactive_battle_records
          WHERE session_id = CAST(@id AS uuid)
            AND idempotency_key = @idempotency_key
          LIMIT 1
        '''),
        parameters: {'id': id, 'idempotency_key': idempotencyKey},
      );
      if (prior.isNotEmpty) {
        if (prior.first[0]?.toString() != requestFingerprint) {
          throw const InteractiveBattleIdempotencyConflictException();
        }
        return InteractiveBattleConcedeReservation(
          session: current,
          duplicate: true,
          alreadyAccepted: await _actionAcceptedExists(
            transaction,
            sessionId: id,
            actionId: idempotencyKey,
          ),
        );
      }
      if (current.status.isTerminal) {
        return InteractiveBattleConcedeReservation(
          session: current,
          duplicate: true,
        );
      }
      await _appendRecord(
        transaction,
        sessionId: id,
        kind: 'concede_requested',
        visibility: 'private_user',
        stateVersion: current.stateVersion,
        idempotencyKey: idempotencyKey,
        requestFingerprint: requestFingerprint,
        payload: {
          'schema_version': interactiveBattleActionSchema,
          'action': 'concede',
        },
      );
      final updated = await transaction.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET status = 'action_pending',
              active_prompt_id = NULL,
              active_prompt = NULL,
              prompt_deadline_at = NULL,
              last_activity_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
            AND status IN (
              'starting',
              'running',
              'waiting_for_action',
              'action_pending'
            )
          RETURNING $interactiveBattleSelectColumns
        '''),
        parameters: {'id': id, 'user_id': userId},
      );
      if (updated.isEmpty) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_concede_reservation_failed',
        );
      }
      return InteractiveBattleConcedeReservation(
        session: _sessionFromRow(updated.first.toColumnMap()),
        duplicate: false,
      );
    });
  }

  @override
  Future<InteractiveBattleSession> applyRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
  }) {
    if (snapshot.status.isTerminal) {
      throw ArgumentError.value(
        snapshot.status,
        'snapshot.status',
        'Terminal snapshots require finalizeRuntimeSnapshot.',
      );
    }
    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);
      if (current.status.isTerminal) return current;
      _validateRuntimeSnapshot(current, snapshot);
      return _applyRuntimeSnapshotInTransaction(
        transaction,
        current: current,
        snapshot: snapshot,
        actionId: actionId,
      );
    });
  }

  @override
  Future<InteractiveBattleSession> finalizeRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    required Map<String, dynamic>? replay,
    String? actionId,
  }) async {
    if (!snapshot.status.isTerminal) {
      throw ArgumentError.value(
        snapshot.status,
        'snapshot.status',
        'Runtime finalization requires a terminal snapshot.',
      );
    }

    Map<String, dynamic>? sanitizedReplay;
    if (replay != null) {
      try {
        sanitizedReplay = sanitizeBattleReplayForStorage(replay);
      } on BattleReplayPayloadException {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_replay_payload_invalid',
        );
      }
    } else if (snapshot.status.requiresPersistedReplay) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_public_replay_missing',
      );
    }

    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);
      if (current.status.isTerminal) return current;
      _validateRuntimeSnapshot(current, snapshot);

      final attemptId = current.attemptId;
      if (attemptId == null) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_attempt_missing',
        );
      }

      String? replayId;
      if (sanitizedReplay != null) {
        final deckAId = current.deckAId;
        final deckBId = current.deckBId;
        if (deckAId == null || deckBId == null) {
          throw const InteractiveBattlePersistenceException(
            'interactive_battle_public_replay_missing',
          );
        }
        replayId = await _insertReplay(
          transaction,
          deckAId: deckAId,
          deckBId: deckBId,
          replay: sanitizedReplay,
        );
      }

      final result = <String, dynamic>{
        if (sanitizedReplay != null) ...sanitizedReplay,
        'status': snapshot.status.value,
        'engine': 'xmage',
        'engine_contract': 'canonical_rules_execution',
        'engine_version': snapshot.engineVersion,
        'engine_commit': snapshot.engineCommit,
        'sidecar_build_identity': snapshot.engineBuild,
        'sidecar_process_id': snapshot.engineProcessId,
        'request_schema_version': interactiveBattleRequestSchema,
        'request_hash': snapshot.requestHash,
      };
      await _finishAttemptInTransaction(
        transaction,
        current: current,
        status: snapshot.status,
        result: result,
        replayId: replayId,
        reason: snapshot.terminalReason,
        errorCode: snapshot.errorCode,
        correlationSource: sidecarEchoValidatedCorrelation,
      );
      return _applyRuntimeSnapshotInTransaction(
        transaction,
        current: current,
        snapshot: snapshot,
        actionId: actionId,
        replayId: replayId,
      );
    });
  }

  @override
  Future<InteractiveBattleSession> finalizeLocal({
    required String userId,
    required String id,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  }) {
    if (!status.isTerminal || status.requiresPersistedReplay) {
      throw ArgumentError.value(status, 'status', 'Invalid local terminal.');
    }
    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);
      if (current.status.isTerminal) return current;
      if (current.attemptId == null) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_attempt_missing',
        );
      }
      await _finishAttemptInTransaction(
        transaction,
        current: current,
        status: status,
        result: {
          'status': status.value,
          'engine': 'xmage',
          'request_schema_version': interactiveBattleRequestSchema,
          'request_hash': current.requestHash,
        },
        reason: reason,
        errorCode: errorCode,
        correlationSource: serverDispatchRecordedCorrelation,
      );
      final result = await transaction.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET status = @status,
              active_prompt_id = NULL,
              active_prompt = NULL,
              prompt_deadline_at = NULL,
              terminal_reason = @reason,
              error_code = @error_code,
              finished_at = CURRENT_TIMESTAMP,
              last_activity_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
            AND status IN (
              'starting',
              'running',
              'waiting_for_action',
              'action_pending'
            )
          RETURNING $interactiveBattleSelectColumns
        '''),
        parameters: {
          'id': id,
          'user_id': userId,
          'status': status.value,
          'reason': reason,
          'error_code': errorCode,
        },
      );
      if (result.isEmpty) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_terminal_update_failed',
        );
      }
      await _appendRecord(
        transaction,
        sessionId: id,
        kind: 'terminal',
        visibility: 'internal',
        stateVersion: current.stateVersion,
        payload: {
          'status': status.value,
          'terminal_reason': reason,
          if (errorCode != null) 'error_code': errorCode,
        },
      );
      return _sessionFromRow(result.first.toColumnMap());
    });
  }
}

void _validateFrozenCreateFingerprint(
  Map<String, dynamic> row,
  String expectedFingerprint,
) {
  final payload = _jsonMap(row['request_payload']);
  final deckA = _jsonMap(payload['deck_a']);
  final deckB = _jsonMap(payload['deck_b']);
  final deckAId = _nullableString(deckA['id']);
  final deckBId = _nullableString(deckB['id']);
  final ttlSeconds = payload['ttl_seconds'];
  final promptTimeoutSeconds = payload['prompt_timeout_seconds'];
  if (deckAId == null ||
      deckBId == null ||
      ttlSeconds is! int ||
      promptTimeoutSeconds is! int ||
      payload['expected_engine'] != 'xmage') {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_frozen_request_invalid',
    );
  }
  final actual = canonicalBattlePayloadHash({
    'schema_version': interactiveBattleRequestSchema,
    'deck_id': deckAId,
    'opponent_deck_id': deckBId,
    'ttl_seconds': ttlSeconds,
    'prompt_timeout_seconds': promptTimeoutSeconds,
    'engine': 'xmage',
  });
  if (actual != expectedFingerprint) {
    throw const InteractiveBattleIdempotencyConflictException();
  }
}

Future<Map<String, dynamic>> _repairStartingAdmission(
  TxSession transaction, {
  required Map<String, dynamic> row,
  required String userId,
}) async {
  if (row['status']?.toString() != InteractiveBattleStatus.starting.value ||
      _nullableString(row['attempt_id']) != null) {
    return row;
  }
  final requestPayload = _jsonMap(row['request_payload']);
  final requestId = _nullableString(requestPayload['request_id']);
  final sessionId = _nullableString(row['id']);
  final deckAId = _nullableString(row['deck_a_id']);
  final deckBId = _nullableString(row['deck_b_id']);
  final payloadDeckA = _jsonMap(requestPayload['deck_a']);
  final payloadDeckB = _jsonMap(requestPayload['deck_b']);
  final payloadDeckHashes = _jsonMap(requestPayload['deck_hashes']);
  if (requestId == null ||
      sessionId == null ||
      deckAId == null ||
      deckBId == null ||
      requestPayload['session_id'] != sessionId ||
      requestPayload['request_hash'] != row['request_hash'] ||
      payloadDeckA['id'] != deckAId ||
      payloadDeckB['id'] != deckBId ||
      payloadDeckHashes['deck_a'] != row['deck_a_hash'] ||
      payloadDeckHashes['deck_b'] != row['deck_b_hash'] ||
      _nullableString(row['runtime_session_id']) != null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_starting_admission_unrecoverable',
    );
  }

  final matching = await transaction.execute(
    Sql.named('''
      SELECT id::text,
             outcome,
             replay_id::text,
             simulation_type,
             test_objective,
             request_schema_version,
             job_request_schema_version,
             job_request_hash,
             deck_hash_schema,
             deck_a_id::text,
             deck_b_id::text,
             deck_a_hash,
             deck_b_hash,
             engine,
             provenance ->> 'mode' AS provenance_mode,
             (
               SELECT linked.id::text
               FROM interactive_battle_sessions linked
               WHERE linked.attempt_id = attempt.id
                 AND linked.id <> CAST(@session_id AS uuid)
               LIMIT 1
             ) AS attached_session_id
      FROM battle_simulation_attempts attempt
      WHERE attempt.user_id = CAST(@user_id AS uuid)
        AND attempt.request_id = @request_id
      ORDER BY attempt.started_at, attempt.id
      FOR UPDATE
    '''),
    parameters: {
      'user_id': userId,
      'request_id': requestId,
      'session_id': sessionId,
    },
  );
  if (matching.length > 1) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_starting_admission_ambiguous',
    );
  }
  String? attemptId;
  if (matching.isNotEmpty) {
    final attempt = matching.single.toColumnMap();
    if (attempt['outcome'] != null ||
        attempt['replay_id'] != null ||
        attempt['simulation_type'] != 'interactive_coach' ||
        attempt['test_objective'] != 'general' ||
        attempt['request_schema_version'] != interactiveBattleRequestSchema ||
        attempt['job_request_schema_version'] !=
            interactiveBattleRequestSchema ||
        attempt['job_request_hash'] != row['request_hash'] ||
        attempt['deck_hash_schema'] != externalBattleDeckHashSchema ||
        attempt['deck_a_id']?.toString() != deckAId ||
        attempt['deck_b_id']?.toString() != deckBId ||
        attempt['deck_a_hash'] != row['deck_a_hash'] ||
        attempt['deck_b_hash'] != row['deck_b_hash'] ||
        attempt['engine'] != 'xmage' ||
        attempt['provenance_mode'] != 'interactive' ||
        attempt['attached_session_id'] != null) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_starting_admission_corrupt',
      );
    }
    attemptId = _nullableString(attempt['id']);
  }
  if (attemptId == null) {
    final inserted = await transaction.execute(
      Sql.named('''
        INSERT INTO battle_simulation_attempts (
          user_id,
          deck_a_id,
          deck_b_id,
          simulation_type,
          test_objective,
          request_id,
          request_schema_version,
          job_request_schema_version,
          job_request_hash,
          deck_hash_schema,
          deck_a_hash,
          deck_b_hash,
          timeout_ms,
          engine,
          provenance
        ) VALUES (
          CAST(@user_id AS uuid),
          CAST(@deck_a_id AS uuid),
          CAST(@deck_b_id AS uuid),
          'interactive_coach',
          'general',
          @request_id,
          @request_schema_version,
          @request_schema_version,
          @request_hash,
          @deck_hash_schema,
          @deck_a_hash,
          @deck_b_hash,
          CAST(@timeout_ms AS integer),
          'xmage',
          @provenance::jsonb
        )
        RETURNING id::text
      '''),
      parameters: {
        'user_id': userId,
        'deck_a_id': deckAId,
        'deck_b_id': deckBId,
        'request_id': requestId,
        'request_schema_version': interactiveBattleRequestSchema,
        'request_hash': row['request_hash']?.toString(),
        'deck_hash_schema': externalBattleDeckHashSchema,
        'deck_a_hash': row['deck_a_hash']?.toString(),
        'deck_b_hash': row['deck_b_hash']?.toString(),
        'timeout_ms': _integer(row['ttl_seconds']) * 1000,
        'provenance': jsonEncode(
          sanitizeBattleReplayMetadata(const {
            'schema_version': battleSimulationAttemptSchema,
            'mode': 'interactive',
            'reconciled_starting_admission': true,
            'privacy': 'private_participant_view_separate_from_public_replay',
          }),
        ),
      },
    );
    attemptId = inserted.isEmpty ? null : _nullableString(inserted.first[0]);
  }
  if (attemptId == null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_attempt_start_failed',
    );
  }

  final repaired = await transaction.execute(
    Sql.named('''
      UPDATE interactive_battle_sessions
      SET attempt_id = CAST(@attempt_id AS uuid),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
        AND status = 'starting'
        AND attempt_id IS NULL
      RETURNING $interactiveBattleSelectColumns,
                request_fingerprint,
                request_payload
    '''),
    parameters: {'id': sessionId, 'user_id': userId, 'attempt_id': attemptId},
  );
  if (repaired.isEmpty) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_attempt_attach_failed',
    );
  }
  return repaired.first.toColumnMap();
}

void _validateRuntimeSnapshot(
  InteractiveBattleSession current,
  InteractiveBattleRuntimeSnapshot snapshot,
) {
  if (snapshot.requestHash != current.requestHash) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_runtime_correlation_rejected',
    );
  }
  if (current.runtimeSessionId != null &&
      current.runtimeSessionId != snapshot.runtimeSessionId) {
    throw const InteractiveBattleRuntimeProcessMismatchException();
  }
  if (current.engineProcessId != null &&
      current.engineProcessId != snapshot.engineProcessId) {
    throw const InteractiveBattleRuntimeProcessMismatchException();
  }
  if (snapshot.stateVersion < current.stateVersion) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_runtime_state_regressed',
    );
  }
}

Future<String> _insertReplay(
  TxSession transaction, {
  required String deckAId,
  required String deckBId,
  required Map<String, dynamic> replay,
}) async {
  final winnerDeckId = canonicalBattleWinnerDeckId(
    result: replay,
    deckAId: deckAId,
    deckBId: deckBId,
  );
  final payload = <String, dynamic>{
    ...replay,
    'type': 'interactive_coach',
    'winner_deck_id': winnerDeckId,
  };
  final turnsPlayed = (replay['turns'] as num?)?.toInt();
  final inserted = await transaction.execute(
    Sql.named('''
      INSERT INTO battle_simulations (
        deck_a_id,
        deck_b_id,
        game_log,
        simulation_type,
        metrics,
        winner_deck_id,
        turns_played
      ) VALUES (
        CAST(@deck_a_id AS uuid),
        CAST(@deck_b_id AS uuid),
        @game_log::jsonb,
        'interactive_coach',
        @metrics::jsonb,
        CAST(@winner_deck_id AS uuid),
        @turns_played
      )
      RETURNING id::text
    '''),
    parameters: {
      'deck_a_id': deckAId,
      'deck_b_id': deckBId,
      'game_log': jsonEncode(payload),
      'metrics': jsonEncode(
        battleSimulationMetricsForStorage(replay, winnerDeckId: winnerDeckId),
      ),
      'winner_deck_id': winnerDeckId,
      'turns_played': turnsPlayed,
    },
  );
  final replayId = inserted.isEmpty ? null : _nullableString(inserted.first[0]);
  if (replayId == null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_replay_save_failed',
    );
  }
  return replayId;
}

Future<void> _finishAttemptInTransaction(
  TxSession transaction, {
  required InteractiveBattleSession current,
  required InteractiveBattleStatus status,
  required Map<String, dynamic> result,
  required String correlationSource,
  String? replayId,
  String? reason,
  String? errorCode,
}) async {
  final attemptId = current.attemptId;
  if (attemptId == null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_attempt_missing',
    );
  }
  final identity = battleSimulationIdentityFromResult(result);
  final provenance = sanitizeBattleReplayMetadata({
    'interactive_session_terminal': true,
    if (result['status'] != null) 'engine_status': result['status'],
  });
  final updated = await transaction.execute(
    Sql.named('''
      UPDATE battle_simulation_attempts
      SET outcome = @outcome,
          replay_id = CAST(@replay_id AS uuid),
          outcome_reason = @reason,
          error_code = @error_code,
          engine = COALESCE(@engine, engine),
          engine_version = COALESCE(@engine_version, engine_version),
          engine_commit = COALESCE(@engine_commit, engine_commit),
          engine_build = COALESCE(@engine_build, engine_build),
          engine_process_id = COALESCE(
            @engine_process_id,
            engine_process_id
          ),
          request_schema_version = @request_schema_version,
          request_hash = @request_hash,
          engine_request_correlation_source = @correlation_source,
          events_truncated = @events_truncated,
          snapshots_truncated = @snapshots_truncated,
          provenance = provenance || @provenance::jsonb,
          finished_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@attempt_id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
        AND outcome IS NULL
        AND job_request_hash = @job_request_hash
        AND deck_a_hash = @deck_a_hash
        AND deck_b_hash = @deck_b_hash
        AND deck_a_id IS NOT DISTINCT FROM CAST(@deck_a_id AS uuid)
        AND deck_b_id IS NOT DISTINCT FROM CAST(@deck_b_id AS uuid)
      RETURNING id::text
    '''),
    parameters: {
      'attempt_id': attemptId,
      'user_id': current.userId,
      'outcome': _attemptOutcome(status).value,
      'replay_id': replayId,
      'reason': sanitizeBattleReplayText(reason),
      'error_code': sanitizeBattleReplayText(errorCode),
      'engine': identity['engine'],
      'engine_version': identity['engineVersion'],
      'engine_commit': identity['engineCommit'],
      'engine_build': identity['engineBuild'],
      'engine_process_id': identity['engineProcessId'],
      'request_schema_version': interactiveBattleRequestSchema,
      'request_hash': current.requestHash,
      'correlation_source': correlationSource,
      'events_truncated': identity['eventsTruncated'],
      'snapshots_truncated': identity['snapshotsTruncated'],
      'provenance': jsonEncode(provenance),
      'job_request_hash': current.requestHash,
      'deck_a_hash': current.deckAHash,
      'deck_b_hash': current.deckBHash,
      'deck_a_id': current.deckAId,
      'deck_b_id': current.deckBId,
    },
  );
  if (updated.isEmpty) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_attempt_finish_failed',
    );
  }
}

BattleSimulationAttemptOutcome _attemptOutcome(
  InteractiveBattleStatus status,
) => switch (status) {
  InteractiveBattleStatus.completed => BattleSimulationAttemptOutcome.completed,
  InteractiveBattleStatus.censored => BattleSimulationAttemptOutcome.censored,
  InteractiveBattleStatus.timeout ||
  InteractiveBattleStatus.expired => BattleSimulationAttemptOutcome.timeout,
  InteractiveBattleStatus.conceded ||
  InteractiveBattleStatus.abandoned => BattleSimulationAttemptOutcome.cancelled,
  InteractiveBattleStatus.persistenceError =>
    BattleSimulationAttemptOutcome.persistenceError,
  _ => BattleSimulationAttemptOutcome.engineError,
};

Future<InteractiveBattleSession> _applyRuntimeSnapshotInTransaction(
  TxSession transaction, {
  required InteractiveBattleSession current,
  required InteractiveBattleRuntimeSnapshot snapshot,
  String? actionId,
  String? replayId,
}) async {
  if (snapshot.status.requiresPersistedReplay && replayId == null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_terminal_replay_missing',
    );
  }
  final prompt = snapshot.prompt;
  final result = await transaction.execute(
    Sql.named('''
      UPDATE interactive_battle_sessions
      SET runtime_session_id = @runtime_session_id,
          engine_version = @engine_version,
          engine_commit = @engine_commit,
          engine_build = @engine_build,
          engine_process_id = @engine_process_id,
          engine_process_started_at = @engine_process_started_at,
          status = @status,
          state_version = @state_version,
          active_prompt_id = @active_prompt_id,
          active_prompt = @active_prompt::jsonb,
          private_state = @private_state::jsonb,
          prompt_deadline_at = @prompt_deadline_at,
          last_activity_at = @last_activity_at,
          replay_id = CAST(@replay_id AS uuid),
          terminal_reason = @terminal_reason,
          error_code = @error_code,
          started_at = COALESCE(started_at, CURRENT_TIMESTAMP),
          finished_at = CASE
            WHEN @terminal THEN CURRENT_TIMESTAMP
            ELSE NULL
          END,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
        AND status IN (
          'starting',
          'running',
          'waiting_for_action',
          'action_pending'
        )
      RETURNING $interactiveBattleSelectColumns
    '''),
    parameters: {
      'id': current.id,
      'user_id': current.userId,
      'runtime_session_id': snapshot.runtimeSessionId,
      'engine_version': snapshot.engineVersion,
      'engine_commit': snapshot.engineCommit,
      'engine_build': snapshot.engineBuild,
      'engine_process_id': snapshot.engineProcessId,
      'engine_process_started_at': snapshot.engineProcessStartedAt,
      'status': snapshot.status.value,
      'state_version': snapshot.stateVersion,
      'active_prompt_id': prompt?.id,
      'active_prompt': prompt == null ? null : jsonEncode(prompt.toJson()),
      'private_state': jsonEncode(snapshot.privateState),
      'prompt_deadline_at': prompt?.deadlineAt,
      'last_activity_at': snapshot.lastActivityAt,
      'replay_id': replayId,
      'terminal_reason': snapshot.terminalReason,
      'error_code': snapshot.errorCode,
      'terminal': snapshot.status.isTerminal,
    },
  );
  if (result.isEmpty) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_runtime_update_failed',
    );
  }

  if (current.runtimeSessionId == null) {
    await _appendRecord(
      transaction,
      sessionId: current.id,
      kind: 'runtime_started',
      visibility: 'internal',
      stateVersion: snapshot.stateVersion,
      payload: {
        'engine': 'xmage',
        'engine_version': snapshot.engineVersion,
        'engine_commit': snapshot.engineCommit,
        'engine_build': snapshot.engineBuild,
        'engine_process_id': snapshot.engineProcessId,
        'engine_process_started_at':
            snapshot.engineProcessStartedAt.toUtc().toIso8601String(),
      },
    );
  }
  final stateChanged =
      snapshot.stateVersion != current.stateVersion ||
      jsonEncode(snapshot.privateState) != jsonEncode(current.privateState);
  if (stateChanged) {
    await _appendRecord(
      transaction,
      sessionId: current.id,
      kind: 'private_state',
      visibility: 'private_user',
      stateVersion: snapshot.stateVersion,
      payload: snapshot.privateState,
    );
  }
  if (prompt != null && prompt.id != current.prompt?.id) {
    await _appendRecord(
      transaction,
      sessionId: current.id,
      kind: 'prompt_opened',
      visibility: 'private_user',
      stateVersion: prompt.stateVersion,
      promptId: prompt.id,
      payload: prompt.toJson(),
    );
  }
  await _reconcileAcceptedActionReceipts(
    transaction,
    current: current,
    snapshot: snapshot,
    fallbackActionId: actionId,
  );
  if (snapshot.status.isTerminal) {
    await _appendRecord(
      transaction,
      sessionId: current.id,
      kind: 'terminal',
      visibility: 'internal',
      stateVersion: snapshot.stateVersion,
      payload: {
        'status': snapshot.status.value,
        'terminal_reason': snapshot.terminalReason,
        if (snapshot.errorCode != null) 'error_code': snapshot.errorCode,
      },
    );
    if (replayId != null) {
      await _appendRecord(
        transaction,
        sessionId: current.id,
        kind: 'replay_linked',
        visibility: 'public_replay_ref',
        stateVersion: snapshot.stateVersion,
        payload: {'replay_id': replayId, 'attempt_id': current.attemptId},
      );
    }
  }
  return _sessionFromRow(result.first.toColumnMap());
}

Future<bool> _actionAcceptedExists(
  TxSession transaction, {
  required String sessionId,
  required String actionId,
}) async {
  final existing = await transaction.execute(
    Sql.named('''
      SELECT 1
      FROM interactive_battle_records
      WHERE session_id = CAST(@session_id AS uuid)
        AND record_kind = 'action_accepted'
        AND payload ->> 'action_id' = @action_id
      LIMIT 1
    '''),
    parameters: {'session_id': sessionId, 'action_id': actionId},
  );
  return existing.isNotEmpty;
}

Future<void> _reconcileAcceptedActionReceipts(
  TxSession transaction, {
  required InteractiveBattleSession current,
  required InteractiveBattleRuntimeSnapshot snapshot,
  String? fallbackActionId,
}) async {
  final receipts = snapshot.acceptedActionReceipts;
  if (receipts == null) {
    if (fallbackActionId != null) {
      await _acceptRecordedAction(
        transaction,
        current: current,
        actionId: fallbackActionId,
        receipt: null,
        fallbackStateVersion: snapshot.stateVersion,
      );
    }
    return;
  }

  final seen = <String>{};
  for (final receipt in receipts) {
    if (!interactiveBattleIdempotencyPattern.hasMatch(receipt.actionId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(receipt.requestFingerprint) ||
        !const {'response', 'concede'}.contains(receipt.kind) ||
        receipt.acceptedStateVersion < 0 ||
        receipt.acceptedStateVersion > snapshot.stateVersion ||
        !seen.add(receipt.actionId)) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_action_receipt_invalid',
      );
    }
    await _acceptRecordedAction(
      transaction,
      current: current,
      actionId: receipt.actionId,
      receipt: receipt,
      fallbackStateVersion: snapshot.stateVersion,
    );
  }
}

Future<void> _acceptRecordedAction(
  TxSession transaction, {
  required InteractiveBattleSession current,
  required String actionId,
  required InteractiveBattleAcceptedActionReceipt? receipt,
  required int fallbackStateVersion,
}) async {
  if (await _actionAcceptedExists(
    transaction,
    sessionId: current.id,
    actionId: actionId,
  )) {
    return;
  }
  final submitted = await transaction.execute(
    Sql.named('''
      SELECT record_kind, state_version, request_fingerprint
      FROM interactive_battle_records
      WHERE session_id = CAST(@session_id AS uuid)
        AND idempotency_key = @action_id
        AND record_kind IN ('action_submitted', 'concede_requested')
      LIMIT 1
    '''),
    parameters: {'session_id': current.id, 'action_id': actionId},
  );
  if (submitted.isEmpty) {
    if (receipt?.kind == 'concede' &&
        actionId == 'system-expire-${current.id}') {
      return;
    }
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_action_receipt_unmatched',
    );
  }
  final row = submitted.single.toColumnMap();
  final recordKind = row['record_kind']?.toString();
  final recordStateVersion = _integer(row['state_version']);
  final recordFingerprint = row['request_fingerprint']?.toString();
  final expectedKind =
      recordKind == 'action_submitted'
          ? 'response'
          : recordKind == 'concede_requested'
          ? 'concede'
          : null;
  if (expectedKind == null || recordFingerprint == null) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_action_receipt_unmatched',
    );
  }

  if (receipt != null) {
    final expectedReceiptFingerprint =
        expectedKind == 'response'
            ? recordFingerprint
            : canonicalBattlePayloadHash({
              'schema_version': interactiveBattleActionSchema,
              'action_id': actionId,
            });
    final durableFingerprintValid =
        expectedKind == 'response' ||
        recordFingerprint ==
            interactiveBattleConcedeFingerprint(
              sessionId: current.id,
              idempotencyKey: actionId,
            );
    if (receipt.kind != expectedKind ||
        receipt.requestFingerprint != expectedReceiptFingerprint ||
        receipt.acceptedStateVersion < recordStateVersion ||
        !durableFingerprintValid) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_action_receipt_mismatch',
      );
    }
  }

  final acceptedStateVersion =
      receipt?.acceptedStateVersion ?? recordStateVersion;
  if (acceptedStateVersion > fallbackStateVersion) {
    throw const InteractiveBattlePersistenceException(
      'interactive_battle_action_receipt_mismatch',
    );
  }
  await _appendRecord(
    transaction,
    sessionId: current.id,
    kind: 'action_accepted',
    visibility: 'private_user',
    stateVersion: acceptedStateVersion,
    payload: {
      'schema_version': interactiveBattleActionSchema,
      'action_id': actionId,
      'request_fingerprint': recordFingerprint,
      'accepted_state_version': acceptedStateVersion,
      'kind': expectedKind,
    },
  );
}

Future<Map<String, dynamic>?> _selectForUpdate(
  TxSession transaction, {
  required String userId,
  required String id,
}) async {
  final selected = await transaction.execute(
    Sql.named('''
      SELECT $interactiveBattleSelectColumns
      FROM interactive_battle_sessions
      WHERE id = CAST(@id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
      LIMIT 1
      FOR UPDATE
    '''),
    parameters: {'id': id, 'user_id': userId},
  );
  return selected.isEmpty ? null : selected.first.toColumnMap();
}

Future<void> _appendRecord(
  TxSession transaction, {
  required String sessionId,
  required String kind,
  required String visibility,
  required int stateVersion,
  required Map<String, dynamic> payload,
  String? promptId,
  String? optionId,
  String? idempotencyKey,
  String? requestFingerprint,
}) async {
  await transaction.execute(
    Sql.named('''
      INSERT INTO interactive_battle_records (
        session_id,
        sequence,
        record_kind,
        visibility,
        state_version,
        prompt_id,
        option_id,
        idempotency_key,
        request_fingerprint,
        payload
      )
      SELECT
        CAST(@session_id AS uuid),
        COALESCE(MAX(sequence), -1) + 1,
        @record_kind,
        @visibility,
        @state_version,
        @prompt_id,
        @option_id,
        @idempotency_key,
        @request_fingerprint,
        @payload::jsonb
      FROM interactive_battle_records
      WHERE session_id = CAST(@session_id AS uuid)
    '''),
    parameters: {
      'session_id': sessionId,
      'record_kind': kind,
      'visibility': visibility,
      'state_version': stateVersion,
      'prompt_id': promptId,
      'option_id': optionId,
      'idempotency_key': idempotencyKey,
      'request_fingerprint': requestFingerprint,
      'payload': jsonEncode(payload),
    },
  );
}

InteractiveBattleSession _sessionFromRow(Map<String, dynamic> row) {
  final promptMap = _jsonMap(row['active_prompt']);
  final privateState = _jsonMap(row['private_state']);
  return InteractiveBattleSession(
    id: _rowString(row, 'id'),
    userId: _rowString(row, 'user_id'),
    status: parseInteractiveBattleStatus(row['status']),
    stateVersion: _integer(row['state_version']),
    deckAId: _nullableString(row['deck_a_id']),
    deckBId: _nullableString(row['deck_b_id']),
    deckAHash: _rowString(row, 'deck_a_hash'),
    deckBHash: _rowString(row, 'deck_b_hash'),
    requestHash: _rowString(row, 'request_hash'),
    ttlSeconds: _integer(row['ttl_seconds']),
    expiresAt: _dateTime(row['expires_at']),
    lastActivityAt: _dateTime(row['last_activity_at']),
    createdAt: _dateTime(row['created_at']),
    updatedAt: _dateTime(row['updated_at']),
    privateState: privateState,
    prompt: promptMap.isEmpty ? null : InteractiveBattlePrompt.parse(promptMap),
    engineVersion: _nullableString(row['engine_version']),
    engineCommit: _nullableString(row['engine_commit']),
    engineBuild: _nullableString(row['engine_build']),
    engineProcessId: _nullableString(row['engine_process_id']),
    engineProcessStartedAt: _nullableDateTime(row['engine_process_started_at']),
    runtimeSessionId: _nullableString(row['runtime_session_id']),
    attemptId: _nullableString(row['attempt_id']),
    replayId: _nullableString(row['replay_id']),
    terminalReason: _nullableString(row['terminal_reason']),
    errorCode: _nullableString(row['error_code']),
    startedAt: _nullableDateTime(row['started_at']),
    finishedAt: _nullableDateTime(row['finished_at']),
  );
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return decoded.map((key, entry) => MapEntry(key.toString(), entry));
    }
  }
  return <String, dynamic>{};
}

String _rowString(Map<String, dynamic> row, String key) =>
    row[key]?.toString().trim() ?? '';

String? _nullableString(Object? value) {
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? null : parsed;
}

int _integer(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

DateTime _dateTime(Object? value) =>
    _nullableDateTime(value) ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _nullableDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc();
}
