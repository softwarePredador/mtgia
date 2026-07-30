import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../ai/battle_engine_config.dart';
import 'battle_job_contract.dart';
import 'interactive_battle_contract.dart';
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
    required this.idempotencyKey,
    required this.requestFingerprint,
    required this.ttlSeconds,
  });

  final String id;
  final String userId;
  final BattleJobDeckSnapshot deckA;
  final BattleJobDeckSnapshot deckB;
  final String requestHash;
  final Map<String, dynamic> requestPayload;
  final String idempotencyKey;
  final String requestFingerprint;
  final int ttlSeconds;
}

class InteractiveBattleCreateResult {
  const InteractiveBattleCreateResult({
    required this.session,
    required this.created,
  });

  final InteractiveBattleSession session;
  final bool created;
}

class InteractiveBattleActionReservation {
  const InteractiveBattleActionReservation({
    required this.session,
    required this.prompt,
    required this.duplicate,
  });

  final InteractiveBattleSession session;
  final InteractiveBattlePrompt? prompt;
  final bool duplicate;
}

class InteractiveBattleConcedeReservation {
  const InteractiveBattleConcedeReservation({
    required this.session,
    required this.duplicate,
  });

  final InteractiveBattleSession session;
  final bool duplicate;
}

abstract interface class InteractiveBattleStoreApi {
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

  Future<InteractiveBattleSession> attachAttempt({
    required String userId,
    required String id,
    required String attemptId,
  });

  Future<InteractiveBattleSession> applyRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
    String? attemptId,
    String? replayId,
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

  Future<InteractiveBattleSession> terminalize({
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
  Future<InteractiveBattleCreateResult> create(
    InteractiveBattleCreateCommand command, {
    required int perUserActiveLimit,
    required int globalActiveLimit,
  }) {
    return _pool.runTx((transaction) async {
      await transaction.execute(
        "SELECT pg_advisory_xact_lock("
        "hashtext('manaloom:interactive_battle:create:v1'))",
      );
      final existing = await transaction.execute(
        Sql.named('''
          SELECT $interactiveBattleSelectColumns, request_fingerprint
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
        final row = existing.first.toColumnMap();
        if (row['request_fingerprint']?.toString() !=
            command.requestFingerprint) {
          throw const InteractiveBattleIdempotencyConflictException();
        }
        return InteractiveBattleCreateResult(
          session: _sessionFromRow(row),
          created: false,
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
  Future<InteractiveBattleSession> attachAttempt({
    required String userId,
    required String id,
    required String attemptId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE interactive_battle_sessions
        SET attempt_id = CAST(@attempt_id AS uuid),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = CAST(@id AS uuid)
          AND user_id = CAST(@user_id AS uuid)
          AND attempt_id IS NULL
          AND status = 'starting'
        RETURNING $interactiveBattleSelectColumns
      '''),
      parameters: {'id': id, 'user_id': userId, 'attempt_id': attemptId},
    );
    if (result.isEmpty) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_attempt_attach_failed',
      );
    }
    return _sessionFromRow(result.first.toColumnMap());
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
    String? attemptId,
    String? replayId,
  }) {
    return _pool.runTx((transaction) async {
      final selected = await _selectForUpdate(
        transaction,
        userId: userId,
        id: id,
      );
      if (selected == null) throw const InteractiveBattleNotFoundException();
      final current = _sessionFromRow(selected);
      if (current.status.isTerminal) return current;
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
      if (snapshot.status.requiresPersistedReplay &&
          (attemptId == null || replayId == null)) {
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
              attempt_id = COALESCE(
                CAST(@attempt_id AS uuid),
                attempt_id
              ),
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
          'id': id,
          'user_id': userId,
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
          'attempt_id': attemptId,
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
          sessionId: id,
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
          sessionId: id,
          kind: 'private_state',
          visibility: 'private_user',
          stateVersion: snapshot.stateVersion,
          payload: snapshot.privateState,
        );
      }
      if (prompt != null && prompt.id != current.prompt?.id) {
        await _appendRecord(
          transaction,
          sessionId: id,
          kind: 'prompt_opened',
          visibility: 'private_user',
          stateVersion: prompt.stateVersion,
          promptId: prompt.id,
          payload: prompt.toJson(),
        );
      }
      if (actionId != null) {
        await _appendRecord(
          transaction,
          sessionId: id,
          kind: 'action_accepted',
          visibility: 'private_user',
          stateVersion: snapshot.stateVersion,
          payload: {
            'schema_version': interactiveBattleActionSchema,
            'action_id': actionId,
          },
        );
      }
      if (snapshot.status.isTerminal) {
        await _appendRecord(
          transaction,
          sessionId: id,
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
            sessionId: id,
            kind: 'replay_linked',
            visibility: 'public_replay_ref',
            stateVersion: snapshot.stateVersion,
            payload: {
              'replay_id': replayId,
              if (attemptId != null) 'attempt_id': attemptId,
            },
          );
        }
      }
      return _sessionFromRow(result.first.toColumnMap());
    });
  }

  @override
  Future<InteractiveBattleSession> terminalize({
    required String userId,
    required String id,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  }) {
    if (!status.isTerminal ||
        status == InteractiveBattleStatus.completed ||
        status == InteractiveBattleStatus.censored) {
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
