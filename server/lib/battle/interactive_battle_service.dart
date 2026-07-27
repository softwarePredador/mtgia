import 'dart:math';

import 'package:postgres/postgres.dart';

import '../ai/battle_engine_config.dart';
import 'battle_job_contract.dart';
import 'battle_job_store.dart';
import 'battle_request_correlation.dart';
import 'battle_simulation_attempt_service.dart';
import 'battle_simulation_persistence_service.dart';
import 'interactive_battle_contract.dart';
import 'interactive_battle_runtime_client.dart';
import 'interactive_battle_store.dart';

class InteractiveBattlePersistenceResult {
  const InteractiveBattlePersistenceResult({
    required this.attemptId,
    this.replayId,
  });

  final String attemptId;
  final String? replayId;
}

abstract interface class InteractiveBattlePersistence {
  Future<String> startAttempt({
    required String userId,
    required String deckAId,
    required String deckBId,
    required String requestId,
    required String requestHash,
    required String deckAHash,
    required String deckBHash,
    required int timeoutMs,
  });

  Future<String> persistReplay({
    required String deckAId,
    required String deckBId,
    required Map<String, dynamic> replay,
  });

  Future<void> finishAttempt({
    required String attemptId,
    required String userId,
    required InteractiveBattleStatus status,
    required Map<String, dynamic> result,
    String? replayId,
    String? reason,
    String? errorCode,
  });
}

class PostgresInteractiveBattlePersistence
    implements InteractiveBattlePersistence {
  const PostgresInteractiveBattlePersistence(this._pool);

  final Pool _pool;

  @override
  Future<String> startAttempt({
    required String userId,
    required String deckAId,
    required String deckBId,
    required String requestId,
    required String requestHash,
    required String deckAHash,
    required String deckBHash,
    required int timeoutMs,
  }) async {
    final result = await BattleSimulationAttemptService(_pool).start(
      userId: userId,
      deckAId: deckAId,
      deckBId: deckBId,
      simulationType: 'interactive_coach',
      requestId: requestId,
      requestSchemaVersion: interactiveBattleRequestSchema,
      jobRequestSchemaVersion: interactiveBattleRequestSchema,
      jobRequestHash: requestHash,
      deckHashSchema: externalBattleDeckHashSchema,
      deckAHash: deckAHash,
      deckBHash: deckBHash,
      timeoutMs: timeoutMs,
      engine: 'xmage',
      provenance: const {
        'mode': 'interactive',
        'privacy': 'private_participant_view_separate_from_public_replay',
      },
    );
    final attemptId = result.handle?.id;
    if (!result.isStarted || attemptId == null) {
      throw InteractiveBattlePersistenceException(
        result.errorCode ?? 'interactive_battle_attempt_start_failed',
      );
    }
    return attemptId;
  }

  @override
  Future<String> persistReplay({
    required String deckAId,
    required String deckBId,
    required Map<String, dynamic> replay,
  }) async {
    final result = await BattleSimulationPersistenceService(_pool).save(
      deckAId: deckAId,
      deckBId: deckBId,
      type: 'interactive_coach',
      result: replay,
    );
    final replayId = result.replayId;
    if (!result.isSaved || replayId == null) {
      throw InteractiveBattlePersistenceException(
        result.errorCode ?? 'interactive_battle_replay_save_failed',
      );
    }
    return replayId;
  }

  @override
  Future<void> finishAttempt({
    required String attemptId,
    required String userId,
    required InteractiveBattleStatus status,
    required Map<String, dynamic> result,
    String? replayId,
    String? reason,
    String? errorCode,
  }) async {
    final outcome = switch (status) {
      InteractiveBattleStatus.completed =>
        BattleSimulationAttemptOutcome.completed,
      InteractiveBattleStatus.censored =>
        BattleSimulationAttemptOutcome.censored,
      InteractiveBattleStatus.timeout ||
      InteractiveBattleStatus.expired => BattleSimulationAttemptOutcome.timeout,
      InteractiveBattleStatus.conceded || InteractiveBattleStatus.abandoned =>
        BattleSimulationAttemptOutcome.cancelled,
      InteractiveBattleStatus.persistenceError =>
        BattleSimulationAttemptOutcome.persistenceError,
      _ => BattleSimulationAttemptOutcome.engineError,
    };
    final finished = await BattleSimulationAttemptService(_pool).finish(
      attempt: BattleSimulationAttemptHandle(id: attemptId, userId: userId),
      outcome: outcome,
      replayId: replayId,
      reason: reason,
      errorCode: errorCode,
      engineRequestSchemaVersion: interactiveBattleRequestSchema,
      engineRequestHash: result['request_hash']?.toString(),
      engineRequestCorrelationSource: sidecarEchoValidatedCorrelation,
      result: result,
      provenance: const {'interactive_session_terminal': true},
    );
    if (!finished.isFinished) {
      throw InteractiveBattlePersistenceException(
        finished.errorCode ?? 'interactive_battle_attempt_finish_failed',
      );
    }
  }
}

class InteractiveBattleService {
  const InteractiveBattleService({
    required InteractiveBattleConfiguration configuration,
    required InteractiveBattleStoreApi store,
    required BattleJobStoreApi deckStore,
    required InteractiveBattleRuntime runtime,
    required InteractiveBattlePersistence persistence,
  }) : _configuration = configuration,
       _store = store,
       _deckStore = deckStore,
       _runtime = runtime,
       _persistence = persistence;

  final InteractiveBattleConfiguration _configuration;
  final InteractiveBattleStoreApi _store;
  final BattleJobStoreApi _deckStore;
  final InteractiveBattleRuntime _runtime;
  final InteractiveBattlePersistence _persistence;

  Future<InteractiveBattleCreateResult> create({
    required String userId,
    required InteractiveBattleCreateInput input,
  }) async {
    _requireEnabled();
    final deckA = await _deckStore.loadDeckSnapshot(
      userId: userId,
      deckId: input.deckId,
      allowPublic: false,
    );
    final deckB = await _deckStore.loadDeckSnapshot(
      userId: userId,
      deckId: input.opponentDeckId,
      allowPublic: true,
    );
    if (deckA == null || deckB == null) {
      throw const InteractiveBattleNotFoundException();
    }
    _validateCommanderDeck(deckA, field: 'deck_id');
    _validateCommanderDeck(deckB, field: 'opponent_deck_id');

    final id = generateBattleJobUuid();
    final requestId = 'interactive-${id.replaceAll('-', '')}';
    final requestPayload = <String, dynamic>{
      'schema_version': interactiveBattleRequestSchema,
      'request_id': requestId,
      'session_id': id,
      'expected_engine': 'xmage',
      'expected_engine_version': _configuration.identity.version,
      'expected_engine_commit': _configuration.identity.commit,
      'ai_profile': _configuration.identity.aiProfile,
      'ttl_seconds': input.ttlSeconds,
      'prompt_timeout_seconds': input.promptTimeoutSeconds,
      'max_turns': 100,
      'deck_a': deckA.payload,
      'deck_b': deckB.payload,
      'deck_hashes': {
        'schema_version': externalBattleDeckHashSchema,
        'algorithm': 'sha256',
        'deck_a': deckA.hash,
        'deck_b': deckB.hash,
      },
    };
    final requestHash = canonicalBattlePayloadHash(requestPayload);
    requestPayload['request_hash'] = requestHash;
    final created = await _store.create(
      InteractiveBattleCreateCommand(
        id: id,
        userId: userId,
        deckA: deckA,
        deckB: deckB,
        requestHash: requestHash,
        requestPayload: requestPayload,
        idempotencyKey: input.idempotencyKey,
        requestFingerprint: interactiveBattleCreateFingerprint(
          input: input,
          deckAHash: deckA.hash,
          deckBHash: deckB.hash,
        ),
        ttlSeconds: input.ttlSeconds,
      ),
      perUserActiveLimit: _configuration.maximumActivePerUser,
      globalActiveLimit: max(
        _configuration.maximumActiveGlobal,
        _configuration.maximumActivePerUser,
      ),
    );
    if (!created.created) return created;

    String? attemptId;
    try {
      attemptId = await _persistence.startAttempt(
        userId: userId,
        deckAId: deckA.id,
        deckBId: deckB.id,
        requestId: requestId,
        requestHash: requestHash,
        deckAHash: deckA.hash,
        deckBHash: deckB.hash,
        timeoutMs: input.ttlSeconds * 1000,
      );
      await _store.attachAttempt(userId: userId, id: id, attemptId: attemptId);
      final snapshot = await _runtime.create(requestPayload);
      final session = await _applySnapshot(
        userId: userId,
        session: created.session,
        snapshot: snapshot,
        attemptId: attemptId,
      );
      return InteractiveBattleCreateResult(session: session, created: true);
    } on InteractiveBattleRuntimeException catch (error) {
      await _finishFailedAttempt(
        userId: userId,
        attemptId: attemptId,
        status:
            error.processLost
                ? InteractiveBattleStatus.processLost
                : InteractiveBattleStatus.engineError,
        reason:
            error.processLost
                ? 'interactive_runtime_process_lost_during_start'
                : 'interactive_runtime_start_failed',
        errorCode: error.code,
      );
      final session = await _store.terminalize(
        userId: userId,
        id: id,
        status:
            error.processLost
                ? InteractiveBattleStatus.processLost
                : InteractiveBattleStatus.engineError,
        reason:
            error.processLost
                ? 'interactive_runtime_process_lost_during_start'
                : 'interactive_runtime_start_failed',
        errorCode: error.code,
      );
      throw InteractiveBattleStartException(session, error.code);
    } on InteractiveBattlePersistenceException catch (error) {
      await _finishFailedAttempt(
        userId: userId,
        attemptId: attemptId,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_persistence_failed_during_start',
        errorCode: error.code,
      );
      final session = await _store.terminalize(
        userId: userId,
        id: id,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_persistence_failed_during_start',
        errorCode: error.code,
      );
      throw InteractiveBattleStartException(session, error.code);
    }
  }

  Future<List<InteractiveBattleSession>> list(
    String userId, {
    int limit = 20,
    String? deckId,
  }) {
    _requireEnabled();
    return _store.list(userId, limit: limit, deckId: deckId);
  }

  Future<InteractiveBattleSession> get(String userId, String id) async {
    _requireEnabled();
    final session = await _owned(userId, id);
    if (session.status.isTerminal) return session;
    if (DateTime.now().toUtc().isAfter(session.expiresAt)) {
      await _bestEffortConcede(
        session,
        actionId: 'system-expire-${session.id}',
      );
      await _finishFailedAttempt(
        userId: userId,
        attemptId: session.attemptId,
        status: InteractiveBattleStatus.expired,
        reason: 'interactive_session_ttl_expired',
      );
      return _store.terminalize(
        userId: userId,
        id: id,
        status: InteractiveBattleStatus.expired,
        reason: 'interactive_session_ttl_expired',
      );
    }
    final runtimeId = session.runtimeSessionId;
    if (runtimeId == null) return session;
    try {
      final snapshot = await _runtime.read(runtimeId);
      return _applySnapshot(
        userId: userId,
        session: session,
        snapshot: snapshot,
        attemptId: session.attemptId,
      );
    } on InteractiveBattleRuntimeProcessMismatchException {
      return _processLost(userId, session);
    } on InteractiveBattleRuntimeException catch (error) {
      if (error.processLost) return _processLost(userId, session);
      rethrow;
    }
  }

  Future<InteractiveBattleSession> respond({
    required String userId,
    required String id,
    required InteractiveBattleActionInput action,
  }) async {
    _requireEnabled();
    final reservation = await _store.reserveAction(
      userId: userId,
      id: id,
      action: action,
    );
    if (reservation.duplicate) {
      return get(userId, id);
    }
    final runtimeId = reservation.session.runtimeSessionId;
    if (runtimeId == null) {
      return _processLost(userId, reservation.session);
    }
    try {
      final snapshot = await _runtime.respond(runtimeId, action);
      return _applySnapshot(
        userId: userId,
        session: reservation.session,
        snapshot: snapshot,
        actionId: action.idempotencyKey,
        attemptId: reservation.session.attemptId,
      );
    } on InteractiveBattleRuntimeProcessMismatchException {
      return _processLost(userId, reservation.session);
    } on InteractiveBattleRuntimeException catch (error) {
      if (error.processLost) {
        return _processLost(userId, reservation.session);
      }
      if (error.code == 'runtime_action_stale') {
        try {
          await get(userId, id);
        } on Object {
          // The client still receives a deterministic stale-action conflict.
        }
        throw const InteractiveBattleStaleActionException(
          'interactive_battle_action_stale',
        );
      }
      rethrow;
    }
  }

  Future<InteractiveBattleSession> concede({
    required String userId,
    required String id,
    required String idempotencyKey,
  }) async {
    _requireEnabled();
    if (!interactiveBattleIdempotencyPattern.hasMatch(idempotencyKey)) {
      throw const InteractiveBattleValidationException(
        'interactive_battle_idempotency_invalid',
        'Idempotency-Key é obrigatório e inválido.',
      );
    }
    final fingerprint = interactiveBattleConcedeFingerprint(
      sessionId: id,
      idempotencyKey: idempotencyKey,
    );
    final reservation = await _store.reserveConcede(
      userId: userId,
      id: id,
      idempotencyKey: idempotencyKey,
      requestFingerprint: fingerprint,
    );
    if (reservation.session.status.isTerminal) return reservation.session;
    if (reservation.duplicate) return get(userId, id);
    final runtimeId = reservation.session.runtimeSessionId;
    if (runtimeId == null) {
      return _processLost(userId, reservation.session);
    }
    try {
      final snapshot = await _runtime.concede(
        runtimeId,
        actionId: idempotencyKey,
      );
      return _applySnapshot(
        userId: userId,
        session: reservation.session,
        snapshot: snapshot,
        actionId: idempotencyKey,
        attemptId: reservation.session.attemptId,
      );
    } on InteractiveBattleRuntimeException catch (error) {
      if (error.processLost) {
        return _processLost(userId, reservation.session);
      }
      rethrow;
    }
  }

  Future<InteractiveBattleSession> _applySnapshot({
    required String userId,
    required InteractiveBattleSession session,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
    String? attemptId,
  }) async {
    if (snapshot.requestHash != session.requestHash) {
      await _finishFailedAttempt(
        userId: userId,
        attemptId: attemptId ?? session.attemptId,
        status: InteractiveBattleStatus.engineError,
        reason: 'interactive_runtime_correlation_rejected',
        errorCode: 'interactive_battle_runtime_correlation_rejected',
      );
      return _store.terminalize(
        userId: userId,
        id: session.id,
        status: InteractiveBattleStatus.engineError,
        reason: 'interactive_runtime_correlation_rejected',
        errorCode: 'interactive_battle_runtime_correlation_rejected',
      );
    }
    if (!snapshot.status.isTerminal) {
      return _store.applyRuntimeSnapshot(
        userId: userId,
        id: session.id,
        snapshot: snapshot,
        actionId: actionId,
        attemptId: attemptId,
      );
    }

    final effectiveAttemptId = attemptId ?? session.attemptId;
    if (effectiveAttemptId == null) {
      return _store.terminalize(
        userId: userId,
        id: session.id,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_attempt_missing_at_terminal',
        errorCode: 'interactive_battle_attempt_missing',
      );
    }
    String? replayId;
    try {
      if (snapshot.status == InteractiveBattleStatus.completed ||
          snapshot.status == InteractiveBattleStatus.censored) {
        final sourceReplay = snapshot.publicReplay;
        if (sourceReplay == null ||
            session.deckAId == null ||
            session.deckBId == null) {
          throw const InteractiveBattlePersistenceException(
            'interactive_battle_public_replay_missing',
          );
        }
        final replay = Map<String, dynamic>.from(sourceReplay);
        replay['request_schema_version'] = interactiveBattleRequestSchema;
        replay['request_hash'] = snapshot.requestHash;
        replay['engine'] = 'xmage';
        replay['engine_version'] = snapshot.engineVersion;
        replay['engine_commit'] = snapshot.engineCommit;
        replay['sidecar_build_identity'] = snapshot.engineBuild;
        replay['sidecar_process_id'] = snapshot.engineProcessId;
        replayId = await _persistence.persistReplay(
          deckAId: session.deckAId!,
          deckBId: session.deckBId!,
          replay: replay,
        );
      }
      final result = <String, dynamic>{
        if (snapshot.publicReplay != null) ...snapshot.publicReplay!,
        'status': snapshot.status.value,
        'engine': 'xmage',
        'engine_version': snapshot.engineVersion,
        'engine_commit': snapshot.engineCommit,
        'sidecar_build_identity': snapshot.engineBuild,
        'sidecar_process_id': snapshot.engineProcessId,
        'request_schema_version': interactiveBattleRequestSchema,
        'request_hash': snapshot.requestHash,
      };
      await _persistence.finishAttempt(
        attemptId: effectiveAttemptId,
        userId: userId,
        status: snapshot.status,
        result: result,
        replayId: replayId,
        reason: snapshot.terminalReason,
        errorCode: snapshot.errorCode,
      );
      return _store.applyRuntimeSnapshot(
        userId: userId,
        id: session.id,
        snapshot: snapshot,
        actionId: actionId,
        attemptId: effectiveAttemptId,
        replayId: replayId,
      );
    } on InteractiveBattlePersistenceException catch (error) {
      await _finishFailedAttempt(
        userId: userId,
        attemptId: effectiveAttemptId,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_terminal_persistence_failed',
        errorCode: error.code,
      );
      return _store.terminalize(
        userId: userId,
        id: session.id,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_terminal_persistence_failed',
        errorCode: error.code,
      );
    }
  }

  Future<InteractiveBattleSession> _processLost(
    String userId,
    InteractiveBattleSession session,
  ) async {
    await _finishFailedAttempt(
      userId: userId,
      attemptId: session.attemptId,
      status: InteractiveBattleStatus.processLost,
      reason: 'interactive_runtime_process_lost',
      errorCode: 'interactive_battle_runtime_process_lost',
    );
    return _store.terminalize(
      userId: userId,
      id: session.id,
      status: InteractiveBattleStatus.processLost,
      reason: 'interactive_runtime_process_lost',
      errorCode: 'interactive_battle_runtime_process_lost',
    );
  }

  Future<void> _bestEffortConcede(
    InteractiveBattleSession session, {
    required String actionId,
  }) async {
    final runtimeId = session.runtimeSessionId;
    if (runtimeId == null) return;
    try {
      await _runtime.concede(runtimeId, actionId: actionId);
    } on Object {
      // Expiry remains terminal even when the transient runtime is gone.
    }
  }

  Future<void> _finishFailedAttempt({
    required String userId,
    required String? attemptId,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  }) async {
    if (attemptId == null) return;
    try {
      await _persistence.finishAttempt(
        attemptId: attemptId,
        userId: userId,
        status: status,
        result: {
          'status': status.value,
          'engine': 'xmage',
          'request_schema_version': interactiveBattleRequestSchema,
        },
        reason: reason,
        errorCode: errorCode,
      );
    } on Object {
      // The session transition still records the persistence failure path.
    }
  }

  Future<InteractiveBattleSession> _owned(String userId, String id) async {
    final session = await _store.get(userId, id);
    if (session == null) throw const InteractiveBattleNotFoundException();
    return session;
  }

  void _requireEnabled() {
    if (!_configuration.enabled) {
      throw const InteractiveBattleDisabledException();
    }
  }
}

class InteractiveBattleStartException implements Exception {
  const InteractiveBattleStartException(this.session, this.code);

  final InteractiveBattleSession session;
  final String code;
}

void _validateCommanderDeck(
  BattleJobDeckSnapshot deck, {
  required String field,
}) {
  var count = 0;
  var commanders = 0;
  for (final card in deck.cards) {
    final quantity = card['quantity'];
    if (quantity is! int || quantity < 1) {
      throw InteractiveBattleValidationException(
        'interactive_battle_deck_invalid',
        '$field contém quantidade inválida.',
      );
    }
    count += quantity;
    if (card['is_commander'] == true) commanders += quantity;
  }
  if (count != 100 || commanders != 1) {
    throw InteractiveBattleValidationException(
      'interactive_battle_deck_invalid',
      '$field precisa ter exatamente 100 cartas e um comandante.',
    );
  }
}
