import 'dart:async';

import 'battle_job_contract.dart';
import 'battle_job_store.dart';

class BattleJobExecutionResult {
  const BattleJobExecutionResult({
    required this.status,
    required this.requestHash,
    required this.deckAHash,
    required this.deckBHash,
    this.engine,
    this.engineVersion,
    this.engineCommit,
    this.engineBuild,
    this.engineProcessId,
    this.engineProcessStartedAt,
    this.engineRequestSchemaVersion,
    this.engineRequestHash,
    this.engineRequestCorrelationSource,
    this.attemptId,
    this.replayId,
    this.terminalReason,
    this.errorCode,
  });

  final BattleJobStatus status;
  final String requestHash;
  final String deckAHash;
  final String deckBHash;
  final String? engine;
  final String? engineVersion;
  final String? engineCommit;
  final String? engineBuild;
  final String? engineProcessId;
  final DateTime? engineProcessStartedAt;
  final String? engineRequestSchemaVersion;
  final String? engineRequestHash;
  final String? engineRequestCorrelationSource;
  final String? attemptId;
  final String? replayId;
  final String? terminalReason;
  final String? errorCode;
}

class BattleJobExecutionException implements Exception {
  const BattleJobExecutionException({
    required this.status,
    required this.code,
    required this.reason,
    this.engine,
    this.engineVersion,
    this.engineCommit,
    this.engineBuild,
    this.engineProcessId,
    this.engineProcessStartedAt,
    this.engineRequestSchemaVersion,
    this.engineRequestHash,
    this.engineRequestCorrelationSource,
    this.attemptId,
    this.replayId,
  });

  final BattleJobStatus status;
  final String code;
  final String reason;
  final String? engine;
  final String? engineVersion;
  final String? engineCommit;
  final String? engineBuild;
  final String? engineProcessId;
  final DateTime? engineProcessStartedAt;
  final String? engineRequestSchemaVersion;
  final String? engineRequestHash;
  final String? engineRequestCorrelationSource;
  final String? attemptId;
  final String? replayId;
}

class BattleJobLeaseLostException implements Exception {
  const BattleJobLeaseLostException();
}

abstract interface class BattleJobExecutor {
  Future<BattleJobExecutionResult> execute(
    BattleJob job,
    BattleJobExecutionControl control,
  );
}

class BattleJobExecutionControl {
  BattleJobExecutionControl({
    required Future<BattleJobHeartbeat> Function({
      String? stage,
      int? progressCurrent,
      int? progressTotal,
    })
    pulse,
  }) : _pulse = pulse;

  final Future<BattleJobHeartbeat> Function({
    String? stage,
    int? progressCurrent,
    int? progressTotal,
  })
  _pulse;

  bool _cancelRequested = false;
  bool _leaseLost = false;

  bool get cancellationWasRequested => _cancelRequested;
  bool get leaseWasLost => _leaseLost;

  Future<void> progress({
    required String stage,
    required int current,
    required int total,
  }) async {
    if (!battleJobStages.contains(stage) ||
        current < 0 ||
        total < 1 ||
        current > total) {
      throw ArgumentError('Invalid battle_job_v1 progress update.');
    }
    final heartbeat = await _pulse(
      stage: stage,
      progressCurrent: current,
      progressTotal: total,
    );
    _observe(heartbeat);
    if (_leaseLost) throw const BattleJobLeaseLostException();
  }

  Future<bool> cancellationRequested() async {
    final heartbeat = await _pulse();
    _observe(heartbeat);
    if (_leaseLost) throw const BattleJobLeaseLostException();
    return _cancelRequested;
  }

  void observe(BattleJobHeartbeat heartbeat) => _observe(heartbeat);

  void _observe(BattleJobHeartbeat heartbeat) {
    if (!heartbeat.active) _leaseLost = true;
    if (heartbeat.cancelRequested) _cancelRequested = true;
  }
}

enum BattleJobRunState { idle, terminal, leaseLost, persistenceUnrecorded }

class BattleJobRunResult {
  const BattleJobRunResult({required this.state, this.jobId, this.status});

  const BattleJobRunResult.idle()
    : state = BattleJobRunState.idle,
      jobId = null,
      status = null;

  final BattleJobRunState state;
  final String? jobId;
  final BattleJobStatus? status;
}

class BattleJobRunner {
  const BattleJobRunner({
    required BattleJobWorkerStore store,
    required BattleJobExecutor executor,
    required String workerId,
    this.leaseDuration = battleJobDefaultLease,
    this.heartbeatInterval = const Duration(seconds: 10),
  }) : _store = store,
       _executor = executor,
       _workerId = workerId;

  final BattleJobWorkerStore _store;
  final BattleJobExecutor _executor;
  final String _workerId;
  final Duration leaseDuration;
  final Duration heartbeatInterval;

  Future<BattleJobRunResult> runNext() async {
    if (heartbeatInterval <= Duration.zero ||
        heartbeatInterval >= leaseDuration) {
      throw ArgumentError.value(
        heartbeatInterval,
        'heartbeatInterval',
        'Must be positive and shorter than the lease.',
      );
    }

    final claim = await _store.claimNext(
      workerId: _workerId,
      leaseDuration: leaseDuration,
    );
    if (claim == null) return const BattleJobRunResult.idle();

    final started = await _store.markRunning(claim);
    if (!started) {
      final heartbeat = await _store.heartbeat(
        claim,
        leaseDuration: leaseDuration,
      );
      if (heartbeat.active && heartbeat.cancelRequested) {
        final recorded = await _store.transitionTerminal(
          claim,
          _terminalFromClaim(
            claim,
            status: BattleJobStatus.cancelled,
            terminalReason: 'cancelled_before_engine_start',
          ),
        );
        return BattleJobRunResult(
          state:
              recorded
                  ? BattleJobRunState.terminal
                  : BattleJobRunState.leaseLost,
          jobId: claim.job.id,
          status: recorded ? BattleJobStatus.cancelled : null,
        );
      }
      return BattleJobRunResult(
        state: BattleJobRunState.leaseLost,
        jobId: claim.job.id,
      );
    }

    late final BattleJobExecutionControl control;
    var heartbeatInFlight = false;
    Future<BattleJobHeartbeat> pulse({
      String? stage,
      int? progressCurrent,
      int? progressTotal,
    }) async {
      final heartbeat = await _store.heartbeat(
        claim,
        leaseDuration: leaseDuration,
        stage: stage,
        progressCurrent: progressCurrent,
        progressTotal: progressTotal,
      );
      return heartbeat;
    }

    control = BattleJobExecutionControl(pulse: pulse);
    final timer = Timer.periodic(heartbeatInterval, (_) {
      if (heartbeatInFlight || control.leaseWasLost) return;
      heartbeatInFlight = true;
      unawaited(
        pulse()
            .then(control.observe)
            .catchError((Object _) {
              control.observe(
                const BattleJobHeartbeat(active: false, cancelRequested: false),
              );
            })
            .whenComplete(() {
              heartbeatInFlight = false;
            }),
      );
    });

    BattleJobExecutionResult executionResult;
    try {
      executionResult = await _executor.execute(claim.job, control);
    } on BattleJobLeaseLostException {
      return BattleJobRunResult(
        state: BattleJobRunState.leaseLost,
        jobId: claim.job.id,
      );
    } on BattleJobExecutionException catch (error) {
      executionResult = BattleJobExecutionResult(
        status:
            _allowedFailureStatus(error.status)
                ? error.status
                : BattleJobStatus.engineError,
        requestHash: claim.job.requestHash,
        deckAHash: claim.job.deckAHash,
        deckBHash: claim.job.deckBHash,
        engine: error.engine,
        engineVersion: error.engineVersion,
        engineCommit: error.engineCommit,
        engineBuild: error.engineBuild,
        engineProcessId: error.engineProcessId,
        engineProcessStartedAt: error.engineProcessStartedAt,
        engineRequestSchemaVersion: error.engineRequestSchemaVersion,
        engineRequestHash: error.engineRequestHash,
        engineRequestCorrelationSource: error.engineRequestCorrelationSource,
        attemptId: error.attemptId,
        replayId: error.replayId,
        terminalReason: error.reason,
        errorCode: error.code,
      );
    } catch (_) {
      executionResult = BattleJobExecutionResult(
        status: BattleJobStatus.engineError,
        requestHash: claim.job.requestHash,
        deckAHash: claim.job.deckAHash,
        deckBHash: claim.job.deckBHash,
        terminalReason: 'executor_failed_without_fallback',
        errorCode: 'battle_job_executor_failed',
      );
    } finally {
      timer.cancel();
    }

    if (control.leaseWasLost) {
      return BattleJobRunResult(
        state: BattleJobRunState.leaseLost,
        jobId: claim.job.id,
      );
    }

    executionResult = _validatedResult(claim.job, executionResult);
    final finalHeartbeat = await pulse(stage: 'persisting_replay');
    control.observe(finalHeartbeat);
    if (control.leaseWasLost) {
      return BattleJobRunResult(
        state: BattleJobRunState.leaseLost,
        jobId: claim.job.id,
      );
    }

    final terminalUpdate = BattleJobTerminalUpdate(
      status: executionResult.status,
      requestHash: executionResult.requestHash,
      deckAHash: executionResult.deckAHash,
      deckBHash: executionResult.deckBHash,
      engine: executionResult.engine,
      engineVersion: executionResult.engineVersion,
      engineCommit: executionResult.engineCommit,
      engineBuild: executionResult.engineBuild,
      engineProcessId: executionResult.engineProcessId,
      engineProcessStartedAt: executionResult.engineProcessStartedAt,
      engineRequestSchemaVersion: executionResult.engineRequestSchemaVersion,
      engineRequestHash: executionResult.engineRequestHash,
      engineRequestCorrelationSource:
          executionResult.engineRequestCorrelationSource,
      attemptId: executionResult.attemptId,
      replayId: executionResult.replayId,
      terminalReason: executionResult.terminalReason,
      errorCode: executionResult.errorCode,
    );

    try {
      final recorded = await _store.transitionTerminal(claim, terminalUpdate);
      return BattleJobRunResult(
        state:
            recorded ? BattleJobRunState.terminal : BattleJobRunState.leaseLost,
        jobId: claim.job.id,
        status: recorded ? executionResult.status : null,
      );
    } catch (_) {
      try {
        final recorded = await _store.markPersistenceError(
          claim,
          errorCode: 'battle_job_terminal_persistence_failed',
          engine: executionResult.engine,
          engineProcessId: executionResult.engineProcessId,
          engineProcessStartedAt: executionResult.engineProcessStartedAt,
        );
        return BattleJobRunResult(
          state:
              recorded
                  ? BattleJobRunState.terminal
                  : BattleJobRunState.persistenceUnrecorded,
          jobId: claim.job.id,
          status: recorded ? BattleJobStatus.persistenceError : null,
        );
      } catch (_) {
        return BattleJobRunResult(
          state: BattleJobRunState.persistenceUnrecorded,
          jobId: claim.job.id,
        );
      }
    }
  }
}

BattleJobExecutionResult _validatedResult(
  BattleJob job,
  BattleJobExecutionResult result,
) {
  if (!result.status.isTerminal ||
      result.requestHash != job.requestHash ||
      result.deckAHash != job.deckAHash ||
      result.deckBHash != job.deckBHash ||
      !_engineMatchesRequest(job.requestedEngine, result.engine) ||
      ((result.status == BattleJobStatus.completed ||
              result.status == BattleJobStatus.censored) &&
          (result.attemptId == null ||
              result.replayId == null ||
              result.engine == null ||
              result.engineRequestSchemaVersion == null ||
              result.engineRequestSchemaVersion!.trim().isEmpty ||
              result.engineRequestHash == null ||
              !RegExp(r'^[0-9a-f]{64}$').hasMatch(result.engineRequestHash!) ||
              result.engineRequestCorrelationSource == null ||
              result.engineRequestCorrelationSource!.trim().isEmpty ||
              result.engineProcessId == null ||
              result.engineProcessId!.trim().isEmpty))) {
    return BattleJobExecutionResult(
      status: BattleJobStatus.engineError,
      requestHash: job.requestHash,
      deckAHash: job.deckAHash,
      deckBHash: job.deckBHash,
      engine: result.engine,
      engineVersion: result.engineVersion,
      engineCommit: result.engineCommit,
      engineBuild: result.engineBuild,
      engineProcessId: result.engineProcessId,
      engineProcessStartedAt: result.engineProcessStartedAt,
      engineRequestSchemaVersion: result.engineRequestSchemaVersion,
      engineRequestHash: result.engineRequestHash,
      engineRequestCorrelationSource: result.engineRequestCorrelationSource,
      attemptId: result.attemptId,
      terminalReason: 'executor_result_contract_rejected',
      errorCode: 'battle_job_executor_result_invalid',
    );
  }
  return result;
}

bool _engineMatchesRequest(String requested, String? actual) {
  if (actual == null || actual.trim().isEmpty) return requested == 'auto';
  final normalized = actual.trim().toLowerCase();
  return switch (requested) {
    'auto' =>
      normalized == 'xmage' ||
          normalized == 'forge' ||
          normalized == 'native' ||
          normalized == 'manaloom_native_reviewed',
    'xmage' => normalized == 'xmage',
    'forge' => normalized == 'forge',
    'native' =>
      normalized == 'native' || normalized == 'manaloom_native_reviewed',
    _ => false,
  };
}

bool _allowedFailureStatus(BattleJobStatus status) =>
    status == BattleJobStatus.censored ||
    status == BattleJobStatus.timeout ||
    status == BattleJobStatus.coverageError ||
    status == BattleJobStatus.engineError ||
    status == BattleJobStatus.cancelled ||
    status == BattleJobStatus.persistenceError;

BattleJobTerminalUpdate _terminalFromClaim(
  BattleJobClaim claim, {
  required BattleJobStatus status,
  required String terminalReason,
}) {
  return BattleJobTerminalUpdate(
    status: status,
    requestHash: claim.job.requestHash,
    deckAHash: claim.job.deckAHash,
    deckBHash: claim.job.deckBHash,
    terminalReason: terminalReason,
  );
}
