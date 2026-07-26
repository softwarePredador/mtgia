import 'package:postgres/postgres.dart';

import '../ai/battle_learning_evidence_support.dart';
import '../ai/battle_replay_event_support.dart';
import 'battle_execution_runtime.dart';
import 'battle_job_contract.dart';
import 'battle_job_runner.dart';
import 'battle_request_correlation.dart';
import 'battle_simulation_attempt_service.dart';
import 'battle_simulation_persistence_service.dart';

typedef BattleExecutionRuntimeFactory =
    BattleExecutionRuntime Function(String requestedEngine);

class PersistentBattleJobExecutor implements BattleJobExecutor {
  PersistentBattleJobExecutor(
    Pool pool, {
    required Map<String, String> environment,
    BattleExecutionRuntimeFactory? runtimeFactory,
  }) : _attempts = BattleSimulationAttemptService(pool),
       _replays = BattleSimulationPersistenceService(pool),
       _runtimeFactory =
           runtimeFactory ??
           ((requestedEngine) => BattleExecutionRuntime.fromEnvironment(
             environment,
             requestedEngine: requestedEngine,
           ));

  final BattleSimulationAttemptService _attempts;
  final BattleSimulationPersistenceService _replays;
  final BattleExecutionRuntimeFactory _runtimeFactory;

  @override
  Future<BattleJobExecutionResult> execute(
    BattleJob job,
    BattleJobExecutionControl control,
  ) async {
    final deckAId = job.deckAId;
    final deckBId = job.deckBId;
    if (deckAId == null || deckBId == null) {
      throw BattleJobExecutionException(
        status: BattleJobStatus.persistenceError,
        code: 'battle_job_deck_reference_missing',
        reason: 'deck_deleted_after_job_creation',
      );
    }
    if (job.requestSchemaVersion != battleJobRequestSchema ||
        canonicalBattleJobRequestHash(job.requestPayload) != job.requestHash) {
      throw BattleJobExecutionException(
        status: BattleJobStatus.engineError,
        code: 'battle_job_request_hash_invalid',
        reason: 'frozen_job_request_failed_hash_validation',
      );
    }

    final requestId = job.requestPayload['request_id']?.toString() ?? '';
    final testObjective =
        job.requestPayload['test_objective']?.toString() ?? 'general';
    final attemptStart = await _attempts.start(
      userId: job.userId,
      deckAId: deckAId,
      deckBId: deckBId,
      simulationType: 'battle',
      testObjective: testObjective,
      requestId: requestId,
      deckAHash: job.deckAHash,
      deckBHash: job.deckBHash,
      deckHashSchema: job.deckHashSchema,
      timeoutMs: job.timeoutMs,
      requestSchemaVersion: battleJobRequestSchema,
      jobRequestSchemaVersion: battleJobRequestSchema,
      jobRequestHash: job.requestHash,
      engine: job.requestedEngine,
      provenance: {
        'job_id': job.id,
        'job_request_schema_version': battleJobRequestSchema,
        'job_request_hash': job.requestHash,
        'attempt_count': job.attemptCount,
      },
    );
    if (!attemptStart.isStarted) {
      throw BattleJobExecutionException(
        status: BattleJobStatus.persistenceError,
        code: attemptStart.errorCode ?? 'battle_attempt_persistence_failed',
        reason: 'battle_attempt_start_failed',
      );
    }
    final attempt = attemptStart.handle!;

    BattleExecutionRuntimeResult runtimeResult;
    try {
      await control.progress(stage: 'starting_engine', current: 5, total: 100);
      runtimeResult = await _runtimeFactory(job.requestedEngine).execute(
        request: job.requestPayload,
        requestedEngine: job.requestedEngine,
        jobRequestSchemaVersion: battleJobRequestSchema,
        jobRequestHash: job.requestHash,
        checkpoint:
            (stage, current, total) =>
                control.progress(stage: stage, current: current, total: total),
        cancellationRequested: control.cancellationRequested,
      );
    } on BattleExecutionRuntimeFailure catch (error) {
      final correlation =
          error.correlation ??
          _failureCorrelation(
            error.dispatchTrace,
            jobRequestSchemaVersion: battleJobRequestSchema,
            jobRequestHash: job.requestHash,
          );
      final finish = await _attempts.finish(
        attempt: attempt,
        outcome: error.outcome,
        reason: error.reason,
        errorCode: error.code,
        engineRequestSchemaVersion: correlation?.engineRequestSchemaVersion,
        engineRequestHash: correlation?.engineRequestHash,
        engineRequestCorrelationSource: correlation?.correlationSource,
        result: error.partialResult,
        provenance: {
          'job_id': job.id,
          'dispatch_trace': error.dispatchTrace
              .map((record) => record.toJson())
              .toList(growable: false),
          'fallback_reason': error.fallbackReason,
          if (error.engineSelectionReason != null)
            'engine_selection_reason': error.engineSelectionReason,
        },
      );
      if (!finish.isFinished) {
        throw BattleJobExecutionException(
          status: BattleJobStatus.persistenceError,
          code: finish.errorCode ?? 'battle_attempt_persistence_failed',
          reason: 'battle_attempt_failure_finish_failed',
          attemptId: attempt.id,
        );
      }
      final identity = battleSimulationIdentityFromResult(error.partialResult);
      throw BattleJobExecutionException(
        status: _jobStatus(error.outcome),
        code: error.code,
        reason: error.reason,
        engine:
            _nonEmpty(identity['engine']) ?? _normalizedEngine(error.engine),
        engineVersion: _nonEmpty(identity['engineVersion']),
        engineCommit: _nonEmpty(identity['engineCommit']),
        engineBuild: _nonEmpty(identity['engineBuild']),
        engineProcessId: _nonEmpty(identity['engineProcessId']),
        engineProcessStartedAt: _engineProcessStartedAt(error.partialResult),
        attemptId: attempt.id,
        engineRequestSchemaVersion: correlation?.engineRequestSchemaVersion,
        engineRequestHash: correlation?.engineRequestHash,
        engineRequestCorrelationSource: correlation?.correlationSource,
      );
    } catch (error) {
      await _attempts.finish(
        attempt: attempt,
        outcome: BattleSimulationAttemptOutcome.engineError,
        reason: 'battle_job_runtime_failed',
        errorCode: 'battle_job_runtime_failed',
        provenance: {
          'job_id': job.id,
          'error_type': error.runtimeType.toString(),
        },
      );
      throw BattleJobExecutionException(
        status: BattleJobStatus.engineError,
        code: 'battle_job_runtime_failed',
        reason: 'battle_job_runtime_failed_without_operational_fallback',
        attemptId: attempt.id,
      );
    }

    if (await control.cancellationRequested()) {
      await _attempts.finish(
        attempt: attempt,
        outcome: BattleSimulationAttemptOutcome.cancelled,
        reason: 'cancelled_before_replay_persistence',
        errorCode: 'battle_job_cancelled',
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
        result: runtimeResult.result,
        provenance: {'job_id': job.id},
      );
      final identity = battleSimulationIdentityFromResult(runtimeResult.result);
      throw BattleJobExecutionException(
        status: BattleJobStatus.cancelled,
        code: 'battle_job_cancelled',
        reason: 'cancelled_before_replay_persistence',
        engine: _nonEmpty(identity['engine']),
        engineVersion: _nonEmpty(identity['engineVersion']),
        engineCommit: _nonEmpty(identity['engineCommit']),
        engineBuild: _nonEmpty(identity['engineBuild']),
        engineProcessId: _nonEmpty(identity['engineProcessId']),
        engineProcessStartedAt: _engineProcessStartedAt(runtimeResult.result),
        attemptId: attempt.id,
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
      );
    }

    var result = normalizeBattleReplayResultEvents(
      result: runtimeResult.result,
      deckAId: deckAId,
      deckAName: _deckName(job.requestPayload, 'deck_a', deckAId),
      deckBId: deckBId,
      deckBName: _deckName(job.requestPayload, 'deck_b', deckBId),
    );
    result['test_objective'] = testObjective;
    final focusCards = _stringList(job.requestPayload['focus_cards']);
    final sameLane = job.requestPayload['same_lane'] == true;
    final naturalSample = _isNaturalBattleResult(job.requestPayload, result);
    final deckAEvidence = buildBattleLearningEvidence(
      result,
      subjectDeckKey: 'deck_a',
      focusCards: focusCards,
      sameLane: sameLane,
      naturalSample: naturalSample,
    );
    final deckBEvidence = buildBattleLearningEvidence(
      result,
      subjectDeckKey: 'deck_b',
      sameLane: sameLane,
      naturalSample: naturalSample,
    );
    result['battle_learning_evidence'] = deckAEvidence;
    result['battle_learning_evidence_by_subject'] = {
      'deck_a': deckAEvidence,
      'deck_b': deckBEvidence,
    };

    await control.progress(stage: 'persisting_replay', current: 90, total: 100);
    final persistence = await _replays.save(
      deckAId: deckAId,
      deckBId: deckBId,
      type: 'battle',
      result: result,
    );
    if (!persistence.isSaved) {
      await _attempts.finish(
        attempt: attempt,
        outcome: BattleSimulationAttemptOutcome.persistenceError,
        reason: 'replay_persistence_failed',
        errorCode: persistence.errorCode,
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
        result: result,
        provenance: {'job_id': job.id},
      );
      final identity = battleSimulationIdentityFromResult(result);
      throw BattleJobExecutionException(
        status: BattleJobStatus.persistenceError,
        code: persistence.errorCode ?? 'simulation_persistence_failed',
        reason: 'replay_persistence_failed',
        engine: _nonEmpty(identity['engine']),
        engineVersion: _nonEmpty(identity['engineVersion']),
        engineCommit: _nonEmpty(identity['engineCommit']),
        engineBuild: _nonEmpty(identity['engineBuild']),
        engineProcessId: _nonEmpty(identity['engineProcessId']),
        engineProcessStartedAt: _engineProcessStartedAt(result),
        attemptId: attempt.id,
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
      );
    }

    final outcome =
        result['status'] == 'censored'
            ? BattleSimulationAttemptOutcome.censored
            : BattleSimulationAttemptOutcome.completed;
    final finish = await _attempts.finish(
      attempt: attempt,
      outcome: outcome,
      replayId: persistence.replayId,
      reason:
          outcome == BattleSimulationAttemptOutcome.censored
              ? 'engine_max_turns_censored'
              : 'engine_completed',
      engineRequestSchemaVersion:
          runtimeResult.correlation.engineRequestSchemaVersion,
      engineRequestHash: runtimeResult.correlation.engineRequestHash,
      engineRequestCorrelationSource:
          runtimeResult.correlation.correlationSource,
      result: result,
      provenance: {'job_id': job.id, 'job_request_hash': job.requestHash},
    );
    if (!finish.isFinished) {
      throw BattleJobExecutionException(
        status: BattleJobStatus.persistenceError,
        code: finish.errorCode ?? 'battle_attempt_persistence_failed',
        reason: 'battle_attempt_completion_finish_failed',
        attemptId: attempt.id,
        replayId: persistence.replayId,
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
      );
    }

    final identity = battleSimulationIdentityFromResult(result);
    return BattleJobExecutionResult(
      status:
          outcome == BattleSimulationAttemptOutcome.censored
              ? BattleJobStatus.censored
              : BattleJobStatus.completed,
      requestHash: job.requestHash,
      deckAHash: job.deckAHash,
      deckBHash: job.deckBHash,
      engine: _nonEmpty(identity['engine']),
      engineVersion: _nonEmpty(identity['engineVersion']),
      engineCommit: _nonEmpty(identity['engineCommit']),
      engineBuild: _nonEmpty(identity['engineBuild']),
      engineProcessId: _nonEmpty(identity['engineProcessId']),
      engineProcessStartedAt: _engineProcessStartedAt(result),
      attemptId: attempt.id,
      replayId: persistence.replayId,
      terminalReason:
          outcome == BattleSimulationAttemptOutcome.censored
              ? 'engine_max_turns_censored'
              : 'engine_completed',
      engineRequestSchemaVersion:
          runtimeResult.correlation.engineRequestSchemaVersion,
      engineRequestHash: runtimeResult.correlation.engineRequestHash,
      engineRequestCorrelationSource:
          runtimeResult.correlation.correlationSource,
    );
  }
}

BattleJobStatus _jobStatus(
  BattleSimulationAttemptOutcome outcome,
) => switch (outcome) {
  BattleSimulationAttemptOutcome.completed => BattleJobStatus.completed,
  BattleSimulationAttemptOutcome.censored => BattleJobStatus.censored,
  BattleSimulationAttemptOutcome.timeout => BattleJobStatus.timeout,
  BattleSimulationAttemptOutcome.coverageError => BattleJobStatus.coverageError,
  BattleSimulationAttemptOutcome.engineError => BattleJobStatus.engineError,
  BattleSimulationAttemptOutcome.cancelled => BattleJobStatus.cancelled,
  BattleSimulationAttemptOutcome.persistenceError =>
    BattleJobStatus.persistenceError,
};

String _normalizedEngine(String value) =>
    value == 'native' ? 'manaloom_native_reviewed' : value;

String _deckName(Map<String, dynamic> request, String key, String fallback) {
  final deck = request[key];
  return deck is Map
      ? deck['name']?.toString().trim().isNotEmpty == true
          ? deck['name'].toString()
          : fallback
      : fallback;
}

List<String> _stringList(Object? value) =>
    value is List
        ? value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const [];

bool _isNaturalBattleResult(
  Map<String, dynamic> request,
  Map<String, dynamic> result,
) {
  if (request['natural_sample'] == false) return false;
  final forcedMode =
      result['forced_access_mode']?.toString().trim().toLowerCase();
  return forcedMode == null || forcedMode.isEmpty || forcedMode == 'none';
}

String? _nonEmpty(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

DateTime? _engineProcessStartedAt(Map<String, dynamic> result) {
  for (final key in const [
    'sidecar_started_at',
    'engine_process_started_at',
    'process_started_at',
  ]) {
    final parsed = DateTime.tryParse(result[key]?.toString() ?? '');
    if (parsed != null) return parsed.toUtc();
  }
  return null;
}

BattleRequestCorrelation? _failureCorrelation(
  List<BattleEngineDispatchRecord> trace, {
  required String jobRequestSchemaVersion,
  required String jobRequestHash,
}) {
  if (trace.isEmpty) return null;
  final terminalDispatch = trace.last;
  return BattleRequestCorrelation(
    jobRequestSchemaVersion: jobRequestSchemaVersion,
    jobRequestHash: jobRequestHash,
    engineRequestSchemaVersion: terminalDispatch.requestSchemaVersion,
    engineRequestHash: terminalDispatch.requestHash,
    correlationSource: terminalDispatch.correlationSource,
    dispatchTrace: List.unmodifiable(trace),
  );
}
