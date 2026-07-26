import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_runner.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:test/test.dart';

void main() {
  test(
    'idle queue cannot report a completed job without an executor',
    () async {
      final store = _FakeWorkerStore(claim: null);
      final executor = _FakeExecutor((job, control) {
        throw StateError('executor must not be called');
      });

      final result = await _runner(store, executor).runNext();

      expect(result.state, BattleJobRunState.idle);
      expect(executor.calls, 0);
      expect(store.terminalUpdates, isEmpty);
    },
  );

  test('valid completion preserves replay and real process identity', () async {
    final store = _FakeWorkerStore(claim: _claim());
    final executor = _FakeExecutor(
      (job, control) async => _result(
        job,
        status: BattleJobStatus.completed,
        engine: 'manaloom_native_reviewed',
        engineProcessId: 'native-worker:321',
        attemptId: '55555555-5555-4555-8555-555555555555',
        replayId: '66666666-6666-4666-8666-666666666666',
      ),
    );

    final result = await _runner(store, executor).runNext();

    expect(result.state, BattleJobRunState.terminal);
    expect(result.status, BattleJobStatus.completed);
    expect(executor.calls, 1);
    final terminal = store.terminalUpdates.single;
    expect(terminal.status, BattleJobStatus.completed);
    expect(terminal.engine, 'manaloom_native_reviewed');
    expect(terminal.engineProcessId, 'native-worker:321');
    expect(terminal.attemptId, isNotNull);
    expect(terminal.replayId, isNotNull);
  });

  test(
    'fake completed or censored result without replay/process is rejected',
    () async {
      for (final claimedSuccess in const [
        BattleJobStatus.completed,
        BattleJobStatus.censored,
      ]) {
        final store = _FakeWorkerStore(claim: _claim());
        final executor = _FakeExecutor(
          (job, control) async => _result(
            job,
            status: claimedSuccess,
            engine: 'manaloom_native_reviewed',
          ),
        );

        final result = await _runner(store, executor).runNext();

        expect(result.status, BattleJobStatus.engineError);
        expect(
          store.terminalUpdates.single.status,
          BattleJobStatus.engineError,
        );
        expect(
          store.terminalUpdates.single.errorCode,
          'battle_job_executor_result_invalid',
        );
      }
    },
  );

  test(
    'typed engine failure is not retried and keeps process identity',
    () async {
      final store = _FakeWorkerStore(claim: _claim());
      final executor = _FakeExecutor((job, control) async {
        throw BattleJobExecutionException(
          status: BattleJobStatus.engineError,
          code: 'native_process_exit_9',
          reason: 'engine process exited',
          engine: 'manaloom_native_reviewed',
          engineProcessId: 'native-worker:999',
          engineProcessStartedAt: DateTime.utc(2026, 7, 26, 12),
        );
      });

      final result = await _runner(store, executor).runNext();

      expect(result.status, BattleJobStatus.engineError);
      expect(executor.calls, 1);
      final terminal = store.terminalUpdates.single;
      expect(terminal.errorCode, 'native_process_exit_9');
      expect(terminal.engineProcessId, 'native-worker:999');
    },
  );

  test('lost fencing token rejects a stale terminal result', () async {
    final store = _FakeWorkerStore(claim: _claim(), transitionResult: false);
    final executor = _FakeExecutor(
      (job, control) async => _result(
        job,
        status: BattleJobStatus.completed,
        engine: 'manaloom_native_reviewed',
        engineProcessId: 'native-worker:654',
        attemptId: '55555555-5555-4555-8555-555555555555',
        replayId: '66666666-6666-4666-8666-666666666666',
      ),
    );

    final result = await _runner(store, executor).runNext();

    expect(result.state, BattleJobRunState.leaseLost);
    expect(result.status, isNull);
  });

  test('cancel_pending before engine start closes without execution', () async {
    final store = _FakeWorkerStore(
      claim: _claim(),
      markRunningResult: false,
      heartbeats: const [
        BattleJobHeartbeat(
          active: true,
          cancelRequested: true,
          status: BattleJobStatus.cancelPending,
        ),
      ],
    );
    final executor = _FakeExecutor((job, control) {
      throw StateError('cancelled claim must not execute');
    });

    final result = await _runner(store, executor).runNext();

    expect(result.status, BattleJobStatus.cancelled);
    expect(executor.calls, 0);
    expect(store.terminalUpdates.single.status, BattleJobStatus.cancelled);
  });

  test('executor observes cancel_pending and records cancelled', () async {
    final store = _FakeWorkerStore(
      claim: _claim(),
      heartbeats: const [
        BattleJobHeartbeat(
          active: true,
          cancelRequested: true,
          status: BattleJobStatus.cancelPending,
        ),
        BattleJobHeartbeat(
          active: true,
          cancelRequested: true,
          status: BattleJobStatus.cancelPending,
        ),
      ],
    );
    final executor = _FakeExecutor((job, control) async {
      expect(await control.cancellationRequested(), isTrue);
      return _result(
        job,
        status: BattleJobStatus.cancelled,
        engine: 'manaloom_native_reviewed',
        engineProcessId: 'native-worker:cancelled',
      );
    });

    final result = await _runner(store, executor).runNext();

    expect(result.status, BattleJobStatus.cancelled);
    expect(store.terminalUpdates.single.status, BattleJobStatus.cancelled);
  });

  test(
    'terminal write failure is made explicit as persistence_error',
    () async {
      final store = _FakeWorkerStore(
        claim: _claim(),
        transitionError: StateError('injected terminal write failure'),
        persistenceResult: true,
      );
      final executor = _FakeExecutor(
        (job, control) async => _result(
          job,
          status: BattleJobStatus.engineError,
          engine: 'manaloom_native_reviewed',
          engineProcessId: 'native-worker:persist',
        ),
      );

      final result = await _runner(store, executor).runNext();

      expect(result.state, BattleJobRunState.terminal);
      expect(result.status, BattleJobStatus.persistenceError);
      expect(store.persistenceCalls, 1);
    },
  );
}

BattleJobRunner _runner(
  BattleJobWorkerStore store,
  BattleJobExecutor executor,
) {
  return BattleJobRunner(
    store: store,
    executor: executor,
    workerId: 'test-worker',
    leaseDuration: const Duration(hours: 1),
    heartbeatInterval: const Duration(minutes: 30),
  );
}

class _FakeExecutor implements BattleJobExecutor {
  _FakeExecutor(this.callback);

  final Future<BattleJobExecutionResult> Function(
    BattleJob,
    BattleJobExecutionControl,
  )
  callback;
  int calls = 0;

  @override
  Future<BattleJobExecutionResult> execute(
    BattleJob job,
    BattleJobExecutionControl control,
  ) {
    calls++;
    return callback(job, control);
  }
}

class _FakeWorkerStore implements BattleJobWorkerStore {
  _FakeWorkerStore({
    required this.claim,
    this.markRunningResult = true,
    this.transitionResult = true,
    this.transitionError,
    this.persistenceResult = false,
    List<BattleJobHeartbeat> heartbeats = const [],
  }) : heartbeats = List.of(heartbeats);

  final BattleJobClaim? claim;
  final bool markRunningResult;
  final bool transitionResult;
  final Object? transitionError;
  final bool persistenceResult;
  final List<BattleJobHeartbeat> heartbeats;
  final List<BattleJobTerminalUpdate> terminalUpdates = [];
  int persistenceCalls = 0;

  @override
  Future<BattleJobClaim?> claimNext({
    required String workerId,
    Duration leaseDuration = battleJobDefaultLease,
  }) async => claim;

  @override
  Future<BattleJobHeartbeat> heartbeat(
    BattleJobClaim claim, {
    Duration leaseDuration = battleJobDefaultLease,
    String? stage,
    int? progressCurrent,
    int? progressTotal,
  }) async {
    if (heartbeats.isNotEmpty) return heartbeats.removeAt(0);
    return const BattleJobHeartbeat(
      active: true,
      cancelRequested: false,
      status: BattleJobStatus.running,
    );
  }

  @override
  Future<bool> markRunning(
    BattleJobClaim claim, {
    String stage = 'starting_engine',
  }) async => markRunningResult;

  @override
  Future<bool> markPersistenceError(
    BattleJobClaim claim, {
    required String errorCode,
    String? engine,
    String? engineProcessId,
    DateTime? engineProcessStartedAt,
  }) async {
    persistenceCalls++;
    return persistenceResult;
  }

  @override
  Future<bool> transitionTerminal(
    BattleJobClaim claim,
    BattleJobTerminalUpdate update,
  ) async {
    terminalUpdates.add(update);
    if (transitionError case final error?) throw error;
    return transitionResult;
  }
}

BattleJobClaim _claim() => BattleJobClaim(
  job: _job(),
  workerId: 'test-worker',
  leaseToken: '77777777-7777-4777-8777-777777777777',
);

BattleJob _job() {
  final now = DateTime.utc(2026, 7, 26, 12);
  return BattleJob(
    id: '33333333-3333-4333-8333-333333333333',
    userId: '44444444-4444-4444-8444-444444444444',
    status: BattleJobStatus.claimed,
    stage: 'claimed',
    progressCurrent: 0,
    progressTotal: 100,
    deckAId: '11111111-1111-4111-8111-111111111111',
    deckBId: '22222222-2222-4222-8222-222222222222',
    deckHashSchema: 'external_battle_deck_hash_v1',
    deckAHash: 'a' * 64,
    deckBHash: 'b' * 64,
    requestSchemaVersion: battleJobRequestSchema,
    requestHash: 'c' * 64,
    requestPayload: const {'request': 'frozen'},
    requestedEngine: 'native',
    engineLane: 'native',
    timeoutMs: 12000,
    attemptCount: 1,
    idempotencyKey: 'runner-test',
    requestFingerprint: 'd' * 64,
    createdAt: now,
    updatedAt: now,
  );
}

BattleJobExecutionResult _result(
  BattleJob job, {
  required BattleJobStatus status,
  String? engine,
  String? engineProcessId,
  String? attemptId,
  String? replayId,
}) {
  return BattleJobExecutionResult(
    status: status,
    requestHash: job.requestHash,
    deckAHash: job.deckAHash,
    deckBHash: job.deckBHash,
    engine: engine,
    engineProcessId: engineProcessId,
    attemptId: attemptId,
    replayId: replayId,
    engineRequestSchemaVersion:
        attemptId != null && replayId != null
            ? nativeBattleDispatchSchema
            : null,
    engineRequestHash: attemptId != null && replayId != null ? 'e' * 64 : null,
    engineRequestCorrelationSource:
        attemptId != null && replayId != null
            ? serverDispatchRecordedCorrelation
            : null,
  );
}
