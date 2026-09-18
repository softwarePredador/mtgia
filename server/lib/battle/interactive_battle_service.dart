import 'dart:math';

import '../ai/battle_engine_config.dart';
import 'battle_deck_admission.dart';
import 'battle_job_contract.dart';
import 'battle_job_store.dart';
import 'battle_request_correlation.dart';
import 'interactive_battle_contract.dart';
import 'interactive_battle_runtime_client.dart';
import 'interactive_battle_store.dart';

class InteractiveBattleService {
  const InteractiveBattleService({
    required InteractiveBattleConfiguration configuration,
    required InteractiveBattleStoreApi store,
    required BattleJobStoreApi deckStore,
    required InteractiveBattleRuntime runtime,
  }) : _configuration = configuration,
       _store = store,
       _deckStore = deckStore,
       _runtime = runtime;

  final InteractiveBattleConfiguration _configuration;
  final InteractiveBattleStoreApi _store;
  final BattleJobStoreApi _deckStore;
  final InteractiveBattleRuntime _runtime;

  Future<InteractiveBattleCreateResult> create({
    required String userId,
    required InteractiveBattleCreateInput input,
  }) async {
    _requireEnabled();
    final requestFingerprint = interactiveBattleCreateFingerprint(input: input);
    var created = await _store.findCreate(
      userId: userId,
      idempotencyKey: input.idempotencyKey,
      requestFingerprint: requestFingerprint,
    );
    if (created == null) {
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
        'expected_engine_patch_commit': _configuration.identity.patchCommit,
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
      created = await _store.create(
        InteractiveBattleCreateCommand(
          id: id,
          userId: userId,
          deckA: deckA,
          deckB: deckB,
          requestHash: requestHash,
          requestPayload: requestPayload,
          requestId: requestId,
          idempotencyKey: input.idempotencyKey,
          requestFingerprint: requestFingerprint,
          ttlSeconds: input.ttlSeconds,
          timeoutMs: input.ttlSeconds * 1000,
        ),
        perUserActiveLimit: _configuration.maximumActivePerUser,
        globalActiveLimit: max(
          _configuration.maximumActiveGlobal,
          _configuration.maximumActivePerUser,
        ),
      );
    }
    if (!created.created &&
        (created.session.status != InteractiveBattleStatus.starting ||
            created.session.runtimeSessionId != null)) {
      return created;
    }

    try {
      final attemptId = created.session.attemptId;
      if (attemptId == null) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_attempt_missing',
        );
      }
      final snapshot = await _runtime.create(created.requestPayload);
      final session = await _applySnapshot(
        userId: userId,
        session: created.session,
        snapshot: snapshot,
        attemptId: attemptId,
      );
      return InteractiveBattleCreateResult(
        session: session,
        created: created.created,
        requestPayload: created.requestPayload,
      );
    } on InteractiveBattleRuntimeException catch (error) {
      if (error.retryable && !error.processLost) {
        throw InteractiveBattleStartException(created.session, error.code);
      }
      final session = await _store.finalizeLocal(
        userId: userId,
        id: created.session.id,
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
      final session = await _store.finalizeLocal(
        userId: userId,
        id: created.session.id,
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
  }) async {
    _requireEnabled();
    final sessions = await _store.list(userId, limit: limit, deckId: deckId);
    final now = DateTime.now().toUtc();
    return Future.wait(
      sessions.map((session) => _expireIfNeeded(userId, session, now: now)),
    );
  }

  Future<InteractiveBattleSession> get(String userId, String id) async {
    _requireEnabled();
    final owned = await _owned(userId, id);
    final session = await _expireIfNeeded(userId, owned);
    if (session.status.isTerminal) return session;
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
      if (error.code == 'runtime_replay_identity_rejected') {
        return _replayContractRejected(userId, session);
      }
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
    if (reservation.alreadyAccepted ||
        reservation.duplicate && reservation.session.status.isTerminal) {
      return reservation.session;
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
      if (error.code == 'runtime_replay_identity_rejected') {
        return _replayContractRejected(userId, reservation.session);
      }
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
    if (reservation.alreadyAccepted || reservation.session.status.isTerminal) {
      return reservation.session;
    }
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
      if (error.code == 'runtime_replay_identity_rejected') {
        return _replayContractRejected(userId, reservation.session);
      }
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
      return _store.finalizeLocal(
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
      );
    }

    final effectiveAttemptId = attemptId ?? session.attemptId;
    if (effectiveAttemptId == null) {
      return _store.finalizeLocal(
        userId: userId,
        id: session.id,
        status: InteractiveBattleStatus.persistenceError,
        reason: 'interactive_attempt_missing_at_terminal',
        errorCode: 'interactive_battle_attempt_missing',
      );
    }
    try {
      final sourceReplay = snapshot.publicReplay;
      if (sourceReplay != null &&
          interactiveBattlePublicReplayContractValidationError(
                sourceReplay,
                expected: _configuration.identity,
                expectedRequestId: snapshot.requestId,
                expectedRequestHash: snapshot.requestHash,
              ) !=
              null) {
        throw const InteractiveBattlePersistenceException(
          'interactive_battle_public_replay_identity_rejected',
        );
      }
      if (snapshot.status.requiresPersistedReplay) {
        if (sourceReplay == null ||
            session.deckAId == null ||
            session.deckBId == null) {
          throw const InteractiveBattlePersistenceException(
            'interactive_battle_public_replay_missing',
          );
        }
      }
      final replay =
          sourceReplay == null
              ? null
              : <String, dynamic>{
                ...sourceReplay,
                'request_schema_version': interactiveBattleRequestSchema,
                'request_hash': snapshot.requestHash,
                'engine': 'xmage',
                'engine_contract': 'canonical_rules_execution',
                'engine_version': snapshot.engineVersion,
                'engine_commit': snapshot.engineCommit,
                'sidecar_build_identity': snapshot.engineBuild,
                'sidecar_process_id': snapshot.engineProcessId,
              };
      return _store.finalizeRuntimeSnapshot(
        userId: userId,
        id: session.id,
        snapshot: snapshot,
        actionId: actionId,
        replay: replay,
      );
    } on InteractiveBattlePersistenceException catch (error) {
      return _store.finalizeLocal(
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
    return _store.finalizeLocal(
      userId: userId,
      id: session.id,
      status: InteractiveBattleStatus.processLost,
      reason: 'interactive_runtime_process_lost',
      errorCode: 'interactive_battle_runtime_process_lost',
    );
  }

  Future<InteractiveBattleSession> _replayContractRejected(
    String userId,
    InteractiveBattleSession session,
  ) async {
    return _store.finalizeLocal(
      userId: userId,
      id: session.id,
      status: InteractiveBattleStatus.engineError,
      reason: 'interactive_runtime_replay_contract_rejected',
      errorCode: 'runtime_replay_identity_rejected',
    );
  }

  Future<InteractiveBattleSession> _expireIfNeeded(
    String userId,
    InteractiveBattleSession session, {
    DateTime? now,
  }) async {
    final observedAt = now ?? DateTime.now().toUtc();
    if (session.status.isTerminal || observedAt.isBefore(session.expiresAt)) {
      return session;
    }
    final runtimeId = session.runtimeSessionId;
    if (runtimeId != null) {
      try {
        final snapshot = await _runtime.concede(
          runtimeId,
          actionId: 'system-expire-${session.id}',
        );
        if (snapshot.status.isTerminal) {
          return _applySnapshot(
            userId: userId,
            session: session,
            snapshot: snapshot,
            attemptId: session.attemptId,
          );
        }
      } on InteractiveBattleRuntimeProcessMismatchException {
        return _processLost(userId, session);
      } on InteractiveBattleRuntimeException catch (error) {
        if (error.code == 'runtime_replay_identity_rejected') {
          return _replayContractRejected(userId, session);
        }
        if (!error.retryable && !error.processLost) rethrow;
      }
    }
    return _store.finalizeLocal(
      userId: userId,
      id: session.id,
      status: InteractiveBattleStatus.expired,
      reason: 'interactive_session_ttl_expired',
    );
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
  final failure = battleDeckAdmissionFailure(
    format: deck.format,
    validationState: deck.validationState,
    cards: deck.cards,
  );
  if (failure == null) return;
  final code = switch (failure) {
    BattleDeckAdmissionFailure.format =>
      'interactive_battle_deck_format_invalid',
    BattleDeckAdmissionFailure.validation =>
      'interactive_battle_deck_validation_required',
    _ => 'interactive_battle_deck_invalid',
  };
  final message = switch (failure) {
    BattleDeckAdmissionFailure.format =>
      '$field precisa usar o formato Commander.',
    BattleDeckAdmissionFailure.validation =>
      '$field precisa ser validado novamente antes do Battle.',
    BattleDeckAdmissionFailure.quantity =>
      '$field contém quantidade de carta inválida.',
    BattleDeckAdmissionFailure.size =>
      '$field precisa ter exatamente 100 cartas.',
    BattleDeckAdmissionFailure.commander =>
      '$field precisa ter exatamente um comandante.',
  };
  throw InteractiveBattleValidationException(code, message);
}
