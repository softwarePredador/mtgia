import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:server/battle/interactive_battle_service.dart';
import 'package:server/battle/interactive_battle_store.dart';
import 'package:test/test.dart';

void main() {
  test(
    'interactive hash excludes only root request_hash across Java and Dart',
    () {
      final payload = <String, dynamic>{
        'z': 1,
        'list': [3, 'x'],
        'a': <String, dynamic>{'b': true, 'a': null},
      };
      expect(
        canonicalBattlePayloadHash(payload),
        '4d1b4c9b71e840dd99f86933047dda7a'
        'b42d901b69698d7a3e5275a770412fef',
      );

      final nested = payload['a'] as Map<String, dynamic>;
      nested['request_hash'] = 'nested-one';
      final nestedOne = canonicalBattlePayloadHash(payload);
      nested['request_hash'] = 'nested-two';
      final nestedTwo = canonicalBattlePayloadHash(payload);
      expect(nestedTwo, isNot(nestedOne));

      final received = <String, dynamic>{
        ...payload,
        'request_hash': 'root-is-not-hash-material',
      }..remove('request_hash');
      expect(canonicalBattlePayloadHash(received), nestedTwo);
    },
  );

  test(
    'create atomically admits session and attempt before opening runtime',
    () async {
      final store = _Store();
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      final result = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-service-1',
        ),
      );

      expect(result.created, isTrue);
      expect(result.session.status, InteractiveBattleStatus.waitingForAction);
      expect(result.session.attemptId, _attemptId);
      expect(runtime.createdRequests, hasLength(1));
      expect(
        runtime.createdRequests.single['request_hash'],
        result.session.requestHash,
      );
      expect(
        runtime.createdRequests.single['expected_engine_patch_commit'],
        pinnedXmagePatchCommit,
      );
      expect(runtime.createdRequests.single['ai_profile'], 'computer_mad');
      expect(persistence.started, 1);
    },
  );

  test(
    'runtime hash divergence terminalizes fail closed and finishes attempt',
    () async {
      final store = _Store();
      final runtime = _Runtime(corruptRequestHash: true);
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      final result = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-service-corrupt',
        ),
      );

      expect(result.session.status, InteractiveBattleStatus.engineError);
      expect(
        result.session.errorCode,
        'interactive_battle_runtime_correlation_rejected',
      );
      expect(persistence.finishedStatuses, [
        InteractiveBattleStatus.engineError,
      ]);
    },
  );

  test(
    'admission failure leaves no session, attempt, or runtime side effect',
    () async {
      final store = _Store(failAdmission: true);
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      await expectLater(
        service.create(
          userId: _userId,
          input: const InteractiveBattleCreateInput(
            deckId: _deckAId,
            opponentDeckId: _deckBId,
            ttlSeconds: 600,
            promptTimeoutSeconds: 60,
            idempotencyKey: 'create-service-attach-failure',
          ),
        ),
        throwsA(
          isA<InteractiveBattlePersistenceException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_admission_failed',
          ),
        ),
      );

      expect(runtime.createdRequests, isEmpty);
      expect(store.current, isNull);
      expect(persistence.started, 0);
      expect(persistence.finishedStatuses, isEmpty);
    },
  );

  test(
    'retryable start resumes the same starting admission and request payload',
    () async {
      final store = _Store();
      final runtime = _Runtime(failFirstCreateTransiently: true);
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );
      const input = InteractiveBattleCreateInput(
        deckId: _deckAId,
        opponentDeckId: _deckBId,
        ttlSeconds: 600,
        promptTimeoutSeconds: 60,
        idempotencyKey: 'create-retryable-start',
      );

      await expectLater(
        service.create(userId: _userId, input: input),
        throwsA(
          isA<InteractiveBattleStartException>()
              .having(
                (error) => error.session.status,
                'session status',
                InteractiveBattleStatus.starting,
              )
              .having(
                (error) => error.code,
                'code',
                'runtime_transport_failed',
              ),
        ),
      );
      final admittedSessionId = store.current!.id;
      final admittedRequestId =
          runtime.createdRequests.single['request_id'] as String;

      final resumed = await service.create(userId: _userId, input: input);

      expect(resumed.created, isFalse);
      expect(resumed.session.id, admittedSessionId);
      expect(resumed.session.status, InteractiveBattleStatus.waitingForAction);
      expect(runtime.createAttempts, 2);
      expect(
        runtime.createdRequests.map((request) => request['request_id']).toSet(),
        {admittedRequestId},
      );
      expect(persistence.started, 1);
      expect(persistence.finishedStatuses, isEmpty);
    },
  );

  test(
    'retry resumes frozen admission before mutable decks are read again',
    () async {
      final store = _Store();
      final runtime = _Runtime(failFirstCreateTransiently: true);
      final deckStore = _MutableDeckStore();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: _Persistence(),
        deckStore: deckStore,
      );
      const input = InteractiveBattleCreateInput(
        deckId: _deckAId,
        opponentDeckId: _deckBId,
        ttlSeconds: 600,
        promptTimeoutSeconds: 60,
        idempotencyKey: 'create-frozen-retry',
      );

      await expectLater(
        service.create(userId: _userId, input: input),
        throwsA(isA<InteractiveBattleStartException>()),
      );
      expect(deckStore.loadCount, 2);
      deckStore.available = false;

      final resumed = await service.create(userId: _userId, input: input);

      expect(resumed.created, isFalse);
      expect(resumed.session.status, InteractiveBattleStatus.waitingForAction);
      expect(deckStore.loadCount, 2);
      expect(runtime.createdRequests, hasLength(2));
      expect(runtime.createdRequests.first, runtime.createdRequests.last);
    },
  );

  test('same key rejects different deck ids before reading decks', () async {
    final store = _Store();
    final runtime = _Runtime(failFirstCreateTransiently: true);
    final deckStore = _MutableDeckStore();
    final service = _service(
      store: store,
      runtime: runtime,
      persistence: _Persistence(),
      deckStore: deckStore,
    );
    const first = InteractiveBattleCreateInput(
      deckId: _deckAId,
      opponentDeckId: _deckBId,
      ttlSeconds: 600,
      promptTimeoutSeconds: 60,
      idempotencyKey: 'create-deck-id-conflict',
    );
    await expectLater(
      service.create(userId: _userId, input: first),
      throwsA(isA<InteractiveBattleStartException>()),
    );
    expect(deckStore.loadCount, 2);

    await expectLater(
      service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckCId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-deck-id-conflict',
        ),
      ),
      throwsA(isA<InteractiveBattleIdempotencyConflictException>()),
    );
    expect(deckStore.loadCount, 2);
  });

  test(
    'attempt finish failure cannot leave a terminal session or replay behind',
    () async {
      final store = _Store(failAttemptFinish: true);
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );
      final created = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-before-attempt-finish-failure',
        ),
      );

      await expectLater(
        service.concede(
          userId: _userId,
          id: created.session.id,
          idempotencyKey: 'concede-attempt-finish-failure',
        ),
        throwsA(
          isA<InteractiveBattlePersistenceException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_attempt_finish_failed',
          ),
        ),
      );

      expect(store.current!.status, InteractiveBattleStatus.actionPending);
      expect(store.current!.status.isTerminal, isFalse);
      expect(store.current!.replayId, isNull);
      expect(persistence.persistedReplays, isEmpty);
      expect(persistence.finishedStatuses, isEmpty);
    },
  );

  test('rejects an unvalidated deck before persistence or runtime', () async {
    final store = _Store();
    final runtime = _Runtime();
    final persistence = _Persistence();
    final service = _service(
      store: store,
      runtime: runtime,
      persistence: persistence,
      deckStore: _DeckStore(
        deckA: const BattleJobDeckSnapshot(
          id: _deckAId,
          name: 'Unvalidated',
          format: 'commander',
          validationState: 'unknown',
          validationReasons: ['validation_not_recorded'],
          cards: [
            {'name': 'Isamaru', 'quantity': 1, 'is_commander': true},
            {'name': 'Plains', 'quantity': 99, 'is_commander': false},
          ],
          hash: _deckAHash,
        ),
      ),
    );

    await expectLater(
      service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-unvalidated',
        ),
      ),
      throwsA(
        isA<InteractiveBattleValidationException>().having(
          (error) => error.code,
          'code',
          'interactive_battle_deck_validation_required',
        ),
      ),
    );
    expect(persistence.started, 0);
    expect(runtime.createdRequests, isEmpty);
  });

  test(
    'transient runtime read failure preserves the active durable session',
    () async {
      final store = _Store();
      final runtime = _Runtime(failReadsTransiently: true);
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );

      final created = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-before-transient-read',
        ),
      );

      await expectLater(
        service.get(_userId, created.session.id),
        throwsA(
          isA<InteractiveBattleRuntimeException>()
              .having((error) => error.code, 'code', 'runtime_transport_failed')
              .having((error) => error.processLost, 'processLost', isFalse),
        ),
      );

      expect(store.current?.status, InteractiveBattleStatus.waitingForAction);
      expect(persistence.finishedStatuses, isEmpty);
    },
  );

  test(
    'idempotent retries resend an action and concede after lost responses',
    () async {
      final store = _Store();
      final runtime = _Runtime(
        failFirstResponseTransiently: true,
        failFirstConcedeTransiently: true,
      );
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );
      final created = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-before-idempotent-retry',
        ),
      );
      final prompt = created.session.prompt!;
      final action = InteractiveBattleActionInput(
        stateVersion: prompt.stateVersion,
        promptId: prompt.id,
        responseKind: InteractiveBattleResponseKind.option,
        optionId: prompt.options.single.id,
        idempotencyKey: 'action-idempotent-retry-1',
      );

      await expectLater(
        service.respond(
          userId: _userId,
          id: created.session.id,
          action: action,
        ),
        throwsA(
          isA<InteractiveBattleRuntimeException>().having(
            (error) => error.code,
            'code',
            'runtime_transport_failed',
          ),
        ),
      );
      final retriedAction = await service.respond(
        userId: _userId,
        id: created.session.id,
        action: action,
      );
      expect(retriedAction.status.isTerminal, isFalse);
      expect(runtime.responseAttempts, 2);

      await expectLater(
        service.concede(
          userId: _userId,
          id: created.session.id,
          idempotencyKey: 'concede-idempotent-retry-1',
        ),
        throwsA(
          isA<InteractiveBattleRuntimeException>().having(
            (error) => error.code,
            'code',
            'runtime_transport_failed',
          ),
        ),
      );
      final conceded = await service.concede(
        userId: _userId,
        id: created.session.id,
        idempotencyKey: 'concede-idempotent-retry-1',
      );

      expect(runtime.concedeAttempts, 2);
      expect(conceded.status, InteractiveBattleStatus.conceded);
      expect(conceded.replayId, _replayId);
    },
  );

  test('expired prompt reservation never reaches the runtime', () async {
    final store = _Store(rejectActionsAfterPromptDeadline: true);
    final runtime = _Runtime();
    final service = _service(
      store: store,
      runtime: runtime,
      persistence: _Persistence(),
    );
    final created = await service.create(
      userId: _userId,
      input: const InteractiveBattleCreateInput(
        deckId: _deckAId,
        opponentDeckId: _deckBId,
        ttlSeconds: 600,
        promptTimeoutSeconds: 60,
        idempotencyKey: 'create-before-expired-prompt-action',
      ),
    );
    final prompt = created.session.prompt!;

    await expectLater(
      service.respond(
        userId: _userId,
        id: created.session.id,
        action: InteractiveBattleActionInput(
          stateVersion: prompt.stateVersion,
          promptId: prompt.id,
          responseKind: InteractiveBattleResponseKind.delegate,
          idempotencyKey: 'action-after-prompt-deadline',
        ),
      ),
      throwsA(isA<InteractiveBattleStaleActionException>()),
    );

    expect(runtime.responseAttempts, 0);
    expect(store.actionKeys, isEmpty);
  });

  test('concede persists and links the partial public replay', () async {
    final store = _Store();
    final runtime = _Runtime();
    final persistence = _Persistence();
    final service = _service(
      store: store,
      runtime: runtime,
      persistence: persistence,
    );

    final created = await service.create(
      userId: _userId,
      input: const InteractiveBattleCreateInput(
        deckId: _deckAId,
        opponentDeckId: _deckBId,
        ttlSeconds: 600,
        promptTimeoutSeconds: 60,
        idempotencyKey: 'create-before-concede',
      ),
    );
    final conceded = await service.concede(
      userId: _userId,
      id: created.session.id,
      idempotencyKey: 'concede-service-1',
    );

    expect(conceded.status, InteractiveBattleStatus.conceded);
    expect(conceded.replayId, _replayId);
    expect(persistence.persistedReplays, hasLength(1));
    expect(persistence.persistedReplays.single['status'], 'conceded');
    expect(
      persistence.persistedReplays.single['engine_contract'],
      'canonical_rules_execution',
    );
    expect(persistence.finishedStatuses, [InteractiveBattleStatus.conceded]);
    expect(persistence.finishedReplayIds, [_replayId]);
  });

  test(
    'expiry persists a terminal concede snapshot instead of discarding it',
    () async {
      final store = _Store();
      final runtime = _Runtime();
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: persistence,
      );
      final created = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-before-terminal-expiry',
        ),
      );
      store.current = _copy(
        created.session,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
      );

      final terminal = await service.get(_userId, created.session.id);

      expect(terminal.status, InteractiveBattleStatus.conceded);
      expect(terminal.replayId, _replayId);
      expect(runtime.concedeAttempts, 1);
      expect(persistence.persistedReplays, hasLength(1));
      expect(persistence.finishedStatuses, [InteractiveBattleStatus.conceded]);
    },
  );

  test('expiry keeps replay identity rejection fail closed', () async {
    final store = _Store();
    final runtime = _Runtime(
      replayFailureOperation: _ReplayFailureOperation.concede,
    );
    final persistence = _Persistence();
    final service = _service(
      store: store,
      runtime: runtime,
      persistence: persistence,
    );
    final created = await service.create(
      userId: _userId,
      input: const InteractiveBattleCreateInput(
        deckId: _deckAId,
        opponentDeckId: _deckBId,
        ttlSeconds: 600,
        promptTimeoutSeconds: 60,
        idempotencyKey: 'create-before-rejected-expiry',
      ),
    );
    store.current = _copy(
      created.session,
      expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
    );

    final rejected = await service.get(_userId, created.session.id);

    expect(rejected.status, InteractiveBattleStatus.engineError);
    expect(rejected.errorCode, 'runtime_replay_identity_rejected');
    expect(persistence.finishedStatuses, [InteractiveBattleStatus.engineError]);
    expect(persistence.persistedReplays, isEmpty);
  });

  test(
    'durably accepted action retry does not resend to the sidecar',
    () async {
      final store = _Store();
      final runtime = _Runtime();
      final service = _service(
        store: store,
        runtime: runtime,
        persistence: _Persistence(),
      );
      final created = await service.create(
        userId: _userId,
        input: const InteractiveBattleCreateInput(
          deckId: _deckAId,
          opponentDeckId: _deckBId,
          ttlSeconds: 600,
          promptTimeoutSeconds: 60,
          idempotencyKey: 'create-before-accepted-retry',
        ),
      );
      final prompt = created.session.prompt!;
      final action = InteractiveBattleActionInput(
        stateVersion: prompt.stateVersion,
        promptId: prompt.id,
        responseKind: InteractiveBattleResponseKind.option,
        optionId: prompt.options.single.id,
        idempotencyKey: 'durable-action-retry-1',
      );

      await service.respond(
        userId: _userId,
        id: created.session.id,
        action: action,
      );
      final retried = await service.respond(
        userId: _userId,
        id: created.session.id,
        action: action,
      );

      expect(retried.status, InteractiveBattleStatus.waitingForAction);
      expect(runtime.responseAttempts, 1);
    },
  );

  test(
    'concede rejects replay contract divergence before persistence',
    () async {
      for (final corruption in _ReplayCorruption.values) {
        final store = _Store();
        final runtime = _Runtime(replayCorruption: corruption);
        final persistence = _Persistence();
        final service = _service(
          store: store,
          runtime: runtime,
          persistence: persistence,
        );

        final created = await service.create(
          userId: _userId,
          input: InteractiveBattleCreateInput(
            deckId: _deckAId,
            opponentDeckId: _deckBId,
            ttlSeconds: 600,
            promptTimeoutSeconds: 60,
            idempotencyKey: 'create-corrupt-${corruption.name}',
          ),
        );
        final rejected = await service.concede(
          userId: _userId,
          id: created.session.id,
          idempotencyKey: 'concede-corrupt-${corruption.name}',
        );

        expect(
          rejected.status,
          InteractiveBattleStatus.persistenceError,
          reason: corruption.name,
        );
        expect(
          rejected.errorCode,
          'interactive_battle_public_replay_identity_rejected',
          reason: corruption.name,
        );
        expect(persistence.persistedReplays, isEmpty);
        expect(persistence.finishedStatuses, [
          InteractiveBattleStatus.persistenceError,
        ]);
        expect(persistence.finishedReplayIds, [null]);
      }
    },
  );

  test(
    'replay rejection closes get respond and concede without action pending',
    () async {
      for (final operation in _ReplayFailureOperation.values) {
        final store = _Store();
        final runtime = _Runtime(replayFailureOperation: operation);
        final persistence = _Persistence();
        final service = _service(
          store: store,
          runtime: runtime,
          persistence: persistence,
        );
        final created = await service.create(
          userId: _userId,
          input: InteractiveBattleCreateInput(
            deckId: _deckAId,
            opponentDeckId: _deckBId,
            ttlSeconds: 600,
            promptTimeoutSeconds: 60,
            idempotencyKey: 'create-replay-failure-${operation.name}',
          ),
        );

        late final InteractiveBattleSession rejected;
        switch (operation) {
          case _ReplayFailureOperation.read:
            rejected = await service.get(_userId, created.session.id);
          case _ReplayFailureOperation.respond:
            final prompt = created.session.prompt!;
            rejected = await service.respond(
              userId: _userId,
              id: created.session.id,
              action: InteractiveBattleActionInput(
                stateVersion: prompt.stateVersion,
                promptId: prompt.id,
                responseKind: InteractiveBattleResponseKind.delegate,
                idempotencyKey: 'respond-replay-failure',
              ),
            );
          case _ReplayFailureOperation.concede:
            rejected = await service.concede(
              userId: _userId,
              id: created.session.id,
              idempotencyKey: 'concede-replay-failure',
            );
        }

        expect(
          rejected.status,
          InteractiveBattleStatus.engineError,
          reason: operation.name,
        );
        expect(rejected.status, isNot(InteractiveBattleStatus.actionPending));
        expect(rejected.errorCode, 'runtime_replay_identity_rejected');
        expect(store.current?.status, InteractiveBattleStatus.engineError);
        if (operation != _ReplayFailureOperation.read) {
          expect(
            store.reservedStatuses,
            contains(InteractiveBattleStatus.actionPending),
          );
        }
        expect(persistence.finishedStatuses, [
          InteractiveBattleStatus.engineError,
        ]);
        expect(persistence.finishedErrorCodes, [
          'runtime_replay_identity_rejected',
        ]);
        expect(store.terminalizedIds, [created.session.id]);
      }
    },
  );

  test(
    'list terminalizes expired TTL rows without stale state and preserves owner scope',
    () async {
      final now = DateTime.now().toUtc();
      final expired = _session(
        id: '55555555-5555-4555-8555-555555555555',
        requestHash: 'c' * 64,
        status: InteractiveBattleStatus.waitingForAction,
        expiresAt: now.subtract(const Duration(minutes: 1)),
        attemptId: _attemptId,
      );
      final fresh = _session(
        id: '66666666-6666-4666-8666-666666666666',
        requestHash: 'd' * 64,
        status: InteractiveBattleStatus.waitingForAction,
        expiresAt: now.add(const Duration(minutes: 5)),
      );
      final completed = _session(
        id: '77777777-7777-4777-8777-777777777777',
        requestHash: 'e' * 64,
        status: InteractiveBattleStatus.completed,
        expiresAt: now.subtract(const Duration(minutes: 5)),
      );
      final foreignExpired = _session(
        id: '88888888-8888-4888-8888-888888888888',
        userId: _otherUserId,
        requestHash: 'f' * 64,
        status: InteractiveBattleStatus.waitingForAction,
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      final store = _Store(
        listedSessions: [expired, fresh, completed, foreignExpired],
      );
      final persistence = _Persistence();
      final service = _service(
        store: store,
        runtime: _Runtime(),
        persistence: persistence,
      );

      final sessions = await service.list(_userId);

      expect(sessions.map((session) => session.id), [
        expired.id,
        fresh.id,
        completed.id,
      ]);
      expect(sessions.first.status, InteractiveBattleStatus.expired);
      expect(sessions[1].status, InteractiveBattleStatus.waitingForAction);
      expect(sessions[2].status, InteractiveBattleStatus.completed);
      expect(
        sessions.any(
          (session) =>
              session.id == expired.id &&
              session.status == InteractiveBattleStatus.waitingForAction,
        ),
        isFalse,
      );
      expect(store.terminalizedIds, [expired.id]);
      expect(store.terminalizedIds, isNot(contains(foreignExpired.id)));
      expect(persistence.finishedStatuses, [InteractiveBattleStatus.expired]);
    },
  );
}

enum _ReplayCorruption { identity, correlation, learning }

enum _ReplayFailureOperation { read, respond, concede }

Map<String, dynamic> _interactiveLearningContract() => {
  'schema_version': 'external_battle_learning_v1',
  'named_draw_identity_available': false,
  'visible_stack_activity_available': true,
  'visible_battlefield_entries_available': true,
  'combat_activity_available': true,
  'ai_decision_rationale_available': false,
  'seed_semantics': 'request_correlation_only_server_rng_uncontrolled',
  'deterministic': false,
  'event_stream_completeness': 'best_effort_visible_state_lower_bound',
  'absence_proves_nonuse': false,
  'strategy_or_swap_proof': false,
};

InteractiveBattleService _service({
  required _Store store,
  required _Runtime runtime,
  required _Persistence persistence,
  BattleJobStoreApi? deckStore,
}) {
  store.persistence = persistence;
  return InteractiveBattleService(
    configuration: const InteractiveBattleConfiguration(
      enabled: true,
      baseUrl: 'http://interactive-xmage:8080',
      identity: ExternalBattleEngineIdentity(
        engine: 'xmage',
        version: pinnedXmageVersion,
        commit: pinnedXmageCommit,
        patchCommit: pinnedXmagePatchCommit,
        aiProfile: 'computer_mad',
        telemetryField: 'normalizer_version',
        telemetryVersion: 'xmage_replay_normalizer_v2',
        seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
        deterministic: false,
      ),
      maximumActivePerUser: 1,
      maximumActiveGlobal: 4,
    ),
    store: store,
    deckStore: deckStore ?? _DeckStore(),
    runtime: runtime,
  );
}

class _DeckStore implements BattleJobStoreApi {
  const _DeckStore({this.deckA = _deckA});

  final BattleJobDeckSnapshot deckA;

  @override
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async =>
      deckId == _deckAId
          ? deckA
          : deckId == _deckBId
          ? _deckB
          : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MutableDeckStore implements BattleJobStoreApi {
  bool available = true;
  int loadCount = 0;

  @override
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async {
    loadCount += 1;
    if (!available) return null;
    return switch (deckId) {
      _deckAId => _deckA,
      _deckBId => _deckB,
      _ => null,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runtime implements InteractiveBattleRuntime {
  _Runtime({
    this.corruptRequestHash = false,
    this.replayCorruption,
    this.replayFailureOperation,
    this.failReadsTransiently = false,
    this.failFirstCreateTransiently = false,
    this.failFirstResponseTransiently = false,
    this.failFirstConcedeTransiently = false,
  });

  final bool corruptRequestHash;
  final _ReplayCorruption? replayCorruption;
  final _ReplayFailureOperation? replayFailureOperation;
  final bool failReadsTransiently;
  final bool failFirstCreateTransiently;
  final bool failFirstResponseTransiently;
  final bool failFirstConcedeTransiently;
  final List<Map<String, dynamic>> createdRequests = [];
  int responseAttempts = 0;
  int concedeAttempts = 0;
  int createAttempts = 0;

  @override
  Future<InteractiveBattleRuntimeSnapshot> create(
    Map<String, dynamic> request,
  ) async {
    createAttempts += 1;
    createdRequests.add(Map<String, dynamic>.from(request));
    if (failFirstCreateTransiently && createAttempts == 1) {
      throw const InteractiveBattleRuntimeException(
        'runtime_transport_failed',
        retryable: true,
      );
    }
    return _snapshot(
      requestId: request['request_id'] as String,
      requestHash:
          corruptRequestHash ? 'f' * 64 : request['request_hash'] as String,
    );
  }

  @override
  Future<InteractiveBattleRuntimeSnapshot> concede(
    String runtimeSessionId, {
    required String actionId,
  }) async {
    concedeAttempts += 1;
    if (failFirstConcedeTransiently && concedeAttempts == 1) {
      throw const InteractiveBattleRuntimeException(
        'runtime_transport_failed',
        retryable: true,
      );
    }
    final request = createdRequests.single;
    if (replayFailureOperation == _ReplayFailureOperation.concede) {
      throw const InteractiveBattleRuntimeException(
        'runtime_replay_identity_rejected',
      );
    }
    final replay = <String, dynamic>{
      'status': 'conceded',
      'winner': null,
      'engine': 'xmage',
      'engine_version': pinnedXmageVersion,
      'engine_commit': pinnedXmageCommit,
      'engine_patch_commit': pinnedXmagePatchCommit,
      'ai_profile': 'computer_mad',
      'request_schema_version': interactiveBattleRequestSchema,
      'request_id': request['request_id'],
      'request_hash': request['request_hash'],
      'learning_contract': _interactiveLearningContract(),
      'events': <Map<String, dynamic>>[],
      'snapshots': <Map<String, dynamic>>[],
    };
    switch (replayCorruption) {
      case _ReplayCorruption.identity:
        replay['engine_patch_commit'] = 'f' * 40;
      case _ReplayCorruption.correlation:
        replay['request_hash'] = 'e' * 64;
      case _ReplayCorruption.learning:
        (replay['learning_contract'] as Map)['deterministic'] = true;
      case null:
        break;
    }
    return _snapshot(
      requestId: request['request_id'] as String,
      requestHash: request['request_hash'] as String,
      status: InteractiveBattleStatus.conceded,
      publicReplay: replay,
    );
  }

  @override
  Future<InteractiveBattleRuntimeSnapshot> respond(
    String runtimeSessionId,
    InteractiveBattleActionInput action,
  ) async {
    responseAttempts += 1;
    if (failFirstResponseTransiently && responseAttempts == 1) {
      throw const InteractiveBattleRuntimeException(
        'runtime_transport_failed',
        retryable: true,
      );
    }
    if (replayFailureOperation == _ReplayFailureOperation.respond) {
      throw const InteractiveBattleRuntimeException(
        'runtime_replay_identity_rejected',
      );
    }
    final request = createdRequests.single;
    return _snapshot(
      requestId: request['request_id'] as String,
      requestHash: request['request_hash'] as String,
    );
  }

  @override
  Future<InteractiveBattleRuntimeSnapshot> read(String runtimeSessionId) async {
    if (failReadsTransiently) {
      throw const InteractiveBattleRuntimeException(
        'runtime_transport_failed',
        retryable: true,
      );
    }
    if (replayFailureOperation == _ReplayFailureOperation.read) {
      throw const InteractiveBattleRuntimeException(
        'runtime_replay_identity_rejected',
      );
    }
    final request = createdRequests.single;
    return _snapshot(
      requestId: request['request_id'] as String,
      requestHash: request['request_hash'] as String,
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Persistence {
  int started = 0;
  final List<InteractiveBattleStatus> finishedStatuses = [];
  final List<String?> finishedReplayIds = [];
  final List<String?> finishedErrorCodes = [];
  final List<Map<String, dynamic>> persistedReplays = [];
}

class _Store implements InteractiveBattleStoreApi {
  _Store({
    this.failAdmission = false,
    this.failAttemptFinish = false,
    this.rejectActionsAfterPromptDeadline = false,
    List<InteractiveBattleSession> listedSessions = const [],
  }) : listedSessions = List<InteractiveBattleSession>.from(listedSessions);

  final bool failAdmission;
  final bool failAttemptFinish;
  final bool rejectActionsAfterPromptDeadline;
  final List<InteractiveBattleSession> listedSessions;
  _Persistence? persistence;
  InteractiveBattleSession? current;
  Map<String, dynamic>? admittedRequestPayload;
  String? admittedRequestFingerprint;
  String? admittedIdempotencyKey;
  final Set<String> actionKeys = <String>{};
  final Set<String> acceptedActionKeys = <String>{};
  final Set<String> concedeKeys = <String>{};
  final List<String> terminalizedIds = <String>[];
  final List<InteractiveBattleStatus> reservedStatuses = [];

  @override
  Future<InteractiveBattleSession?> get(String userId, String id) async {
    if (current?.id == id && current?.userId == userId) return current;
    for (final session in listedSessions) {
      if (session.id == id && session.userId == userId) return session;
    }
    return null;
  }

  @override
  Future<List<InteractiveBattleSession>> list(
    String userId, {
    int limit = 20,
    String? deckId,
  }) async => listedSessions
      .where(
        (session) =>
            session.userId == userId &&
            (deckId == null || session.deckAId == deckId),
      )
      .take(limit)
      .toList(growable: false);

  @override
  Future<InteractiveBattleCreateResult?> findCreate({
    required String userId,
    required String idempotencyKey,
    required String requestFingerprint,
  }) async {
    if (current == null || admittedIdempotencyKey != idempotencyKey) {
      return null;
    }
    if (admittedRequestFingerprint != requestFingerprint) {
      throw const InteractiveBattleIdempotencyConflictException();
    }
    return InteractiveBattleCreateResult(
      session: current!,
      created: false,
      requestPayload: admittedRequestPayload!,
    );
  }

  @override
  Future<InteractiveBattleCreateResult> create(
    InteractiveBattleCreateCommand command, {
    required int perUserActiveLimit,
    required int globalActiveLimit,
  }) async {
    if (current != null &&
        admittedRequestFingerprint == command.requestFingerprint) {
      return InteractiveBattleCreateResult(
        session: current!,
        created: false,
        requestPayload: admittedRequestPayload!,
      );
    }
    if (failAdmission) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_admission_failed',
      );
    }
    persistence?.started += 1;
    admittedRequestPayload = Map<String, dynamic>.from(command.requestPayload);
    admittedRequestFingerprint = command.requestFingerprint;
    admittedIdempotencyKey = command.idempotencyKey;
    current = _session(
      id: command.id,
      requestHash: command.requestHash,
      status: InteractiveBattleStatus.starting,
      attemptId: _attemptId,
    );
    return InteractiveBattleCreateResult(
      session: current!,
      created: true,
      requestPayload: admittedRequestPayload!,
    );
  }

  @override
  Future<InteractiveBattleSession> applyRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    String? actionId,
  }) async {
    if (actionId != null) acceptedActionKeys.add(actionId);
    current = _copy(
      current!,
      status: snapshot.status,
      stateVersion: snapshot.stateVersion,
      prompt: snapshot.prompt,
      privateState: snapshot.privateState,
      runtimeSessionId: snapshot.runtimeSessionId,
    );
    return current!;
  }

  @override
  Future<InteractiveBattleSession> finalizeRuntimeSnapshot({
    required String userId,
    required String id,
    required InteractiveBattleRuntimeSnapshot snapshot,
    required Map<String, dynamic>? replay,
    String? actionId,
  }) async {
    if (failAttemptFinish) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_attempt_finish_failed',
      );
    }
    final replayId = snapshot.status.requiresPersistedReplay ? _replayId : null;
    if (replay != null) {
      persistence?.persistedReplays.add(Map<String, dynamic>.from(replay));
    }
    if (actionId != null) acceptedActionKeys.add(actionId);
    persistence?.finishedStatuses.add(snapshot.status);
    persistence?.finishedReplayIds.add(replayId);
    persistence?.finishedErrorCodes.add(snapshot.errorCode);
    current = _copy(
      current!,
      status: snapshot.status,
      stateVersion: snapshot.stateVersion,
      prompt: snapshot.prompt,
      privateState: snapshot.privateState,
      runtimeSessionId: snapshot.runtimeSessionId,
      replayId: replayId,
      terminalReason: snapshot.terminalReason,
      errorCode: snapshot.errorCode,
    );
    return current!;
  }

  @override
  Future<InteractiveBattleConcedeReservation> reserveConcede({
    required String userId,
    required String id,
    required String idempotencyKey,
    required String requestFingerprint,
  }) async {
    final duplicate = !concedeKeys.add(idempotencyKey);
    if (!duplicate) {
      current = _copy(current!, status: InteractiveBattleStatus.actionPending);
      reservedStatuses.add(current!.status);
    }
    return InteractiveBattleConcedeReservation(
      session: current!,
      duplicate: duplicate,
      alreadyAccepted: acceptedActionKeys.contains(idempotencyKey),
    );
  }

  @override
  Future<InteractiveBattleActionReservation> reserveAction({
    required String userId,
    required String id,
    required InteractiveBattleActionInput action,
  }) async {
    if (rejectActionsAfterPromptDeadline) {
      throw const InteractiveBattleStaleActionException(
        'interactive_battle_action_stale',
      );
    }
    final duplicate = !actionKeys.add(action.idempotencyKey);
    if (!duplicate) {
      current = _copy(current!, status: InteractiveBattleStatus.actionPending);
      reservedStatuses.add(current!.status);
    }
    return InteractiveBattleActionReservation(
      session: current!,
      prompt: current!.prompt,
      duplicate: duplicate,
      alreadyAccepted: acceptedActionKeys.contains(action.idempotencyKey),
    );
  }

  @override
  Future<InteractiveBattleSession> finalizeLocal({
    required String userId,
    required String id,
    required InteractiveBattleStatus status,
    required String reason,
    String? errorCode,
  }) async {
    if (failAttemptFinish) {
      throw const InteractiveBattlePersistenceException(
        'interactive_battle_attempt_finish_failed',
      );
    }
    final source = await get(userId, id);
    if (source == null) throw const InteractiveBattleNotFoundException();
    if (source.status.isTerminal) return source;
    final updated = _copy(
      source,
      status: status,
      terminalReason: reason,
      errorCode: errorCode,
    );
    if (current?.id == id) current = updated;
    final listedIndex = listedSessions.indexWhere(
      (session) => session.id == id && session.userId == userId,
    );
    if (listedIndex >= 0) listedSessions[listedIndex] = updated;
    persistence?.finishedStatuses.add(status);
    persistence?.finishedReplayIds.add(null);
    persistence?.finishedErrorCodes.add(errorCode);
    terminalizedIds.add(id);
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InteractiveBattleSession _session({
  required String id,
  required String requestHash,
  required InteractiveBattleStatus status,
  String userId = _userId,
  DateTime? expiresAt,
  String? attemptId,
}) {
  final now = DateTime.now().toUtc();
  return InteractiveBattleSession(
    id: id,
    userId: userId,
    status: status,
    stateVersion: 0,
    deckAId: _deckAId,
    deckBId: _deckBId,
    deckAHash: _deckAHash,
    deckBHash: _deckBHash,
    requestHash: requestHash,
    ttlSeconds: 600,
    expiresAt: expiresAt ?? now.add(const Duration(minutes: 10)),
    lastActivityAt: now,
    createdAt: now,
    updatedAt: now,
    privateState: const {},
    attemptId: attemptId,
  );
}

InteractiveBattleSession _copy(
  InteractiveBattleSession source, {
  InteractiveBattleStatus? status,
  int? stateVersion,
  InteractiveBattlePrompt? prompt,
  Map<String, dynamic>? privateState,
  String? runtimeSessionId,
  String? attemptId,
  String? replayId,
  String? terminalReason,
  String? errorCode,
  DateTime? expiresAt,
}) => InteractiveBattleSession(
  id: source.id,
  userId: source.userId,
  status: status ?? source.status,
  stateVersion: stateVersion ?? source.stateVersion,
  deckAId: source.deckAId,
  deckBId: source.deckBId,
  deckAHash: source.deckAHash,
  deckBHash: source.deckBHash,
  requestHash: source.requestHash,
  ttlSeconds: source.ttlSeconds,
  expiresAt: expiresAt ?? source.expiresAt,
  lastActivityAt: source.lastActivityAt,
  createdAt: source.createdAt,
  updatedAt: source.updatedAt,
  privateState: privateState ?? source.privateState,
  prompt: prompt ?? source.prompt,
  engineVersion: source.engineVersion,
  engineCommit: source.engineCommit,
  engineBuild: source.engineBuild,
  engineProcessId: source.engineProcessId,
  engineProcessStartedAt: source.engineProcessStartedAt,
  runtimeSessionId: runtimeSessionId ?? source.runtimeSessionId,
  attemptId: attemptId ?? source.attemptId,
  replayId: replayId ?? source.replayId,
  terminalReason: terminalReason ?? source.terminalReason,
  errorCode: errorCode ?? source.errorCode,
  startedAt: source.startedAt,
  finishedAt: status?.isTerminal == true ? DateTime.now().toUtc() : null,
);

InteractiveBattleRuntimeSnapshot _snapshot({
  required String requestId,
  required String requestHash,
  InteractiveBattleStatus status = InteractiveBattleStatus.waitingForAction,
  Map<String, dynamic>? publicReplay,
}) => InteractiveBattleRuntimeSnapshot(
  runtimeSessionId: 'ibsrt_abcdefghijklmnop',
  requestId: requestId,
  requestHash: requestHash,
  status: status,
  stateVersion: 4,
  privateState: const {
    'schema_version': interactiveBattlePrivateStateSchema,
    'own_hand': [],
    'players': [],
  },
  prompt:
      status == InteractiveBattleStatus.waitingForAction
          ? InteractiveBattlePrompt(
            id: 'p_abcdefghijklmnop',
            stateVersion: 4,
            kind: 'mulligan',
            inputMode: 'options',
            title: 'Mulligan',
            message: 'Manter?',
            deadlineAt: DateTime.parse('2026-07-27T12:01:00Z'),
            options: const [
              InteractiveBattlePromptOption(
                id: 'o_abcdefghijklmnop',
                label: 'Manter',
                role: 'keep',
              ),
            ],
          )
          : null,
  engineVersion: pinnedXmageVersion,
  engineCommit: pinnedXmageCommit,
  engineBuild:
      'xmage-sidecar-v2@$pinnedXmageCommit+patch.$pinnedXmagePatchCommit',
  engineProcessId: 'process-1',
  engineProcessStartedAt: DateTime.parse('2026-07-27T11:59:00Z'),
  lastActivityAt: DateTime.parse('2026-07-27T12:00:01Z'),
  terminalReason: status.isTerminal ? 'user_conceded' : null,
  publicReplay: publicReplay,
);

const _deckA = BattleJobDeckSnapshot(
  id: _deckAId,
  name: 'Deck A',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [
    {'name': 'Isamaru', 'quantity': 1, 'is_commander': true},
    {'name': 'Plains', 'quantity': 99, 'is_commander': false},
  ],
  hash: _deckAHash,
);
const _deckB = BattleJobDeckSnapshot(
  id: _deckBId,
  name: 'Deck B',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [
    {'name': 'Krenko', 'quantity': 1, 'is_commander': true},
    {'name': 'Mountain', 'quantity': 99, 'is_commander': false},
  ],
  hash: _deckBHash,
);
const _userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _otherUserId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _deckAId = '11111111-1111-4111-8111-111111111111';
const _deckBId = '22222222-2222-4222-8222-222222222222';
const _deckCId = '33333333-3333-4333-8333-333333333333';
const _attemptId = '33333333-3333-4333-8333-333333333333';
const _replayId = '44444444-4444-4444-8444-444444444444';
const _deckAHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _deckBHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
