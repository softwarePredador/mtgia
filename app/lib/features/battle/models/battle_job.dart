import 'dart:collection';

import 'battle_test_setup.dart';

const battleJobSchemaVersion = 'battle_job_v1';
const battleJobListSchemaVersion = 'battle_job_list_v1';
const externalBattleDeckHashSchemaVersion = 'external_battle_deck_hash_v1';
const externalBattleRequestSchemaVersion = 'external_battle_request_v2';

class BattleJobContractException implements Exception {
  const BattleJobContractException(this.code);

  final String code;

  @override
  String toString() => 'BattleJobContractException($code)';
}

enum BattleJobStatus {
  queued('queued', false, true),
  claimed('claimed', false, true),
  running('running', false, true),
  cancelPending('cancel_pending', false, false),
  completed('completed', true, false),
  censored('censored', true, false),
  timeout('timeout', true, false),
  coverageError('coverage_error', true, false),
  engineError('engine_error', true, false),
  cancelled('cancelled', true, false),
  persistenceError('persistence_error', true, false);

  const BattleJobStatus(this.wireValue, this.isTerminal, this.canCancel);

  final String wireValue;
  final bool isTerminal;
  final bool canCancel;

  static BattleJobStatus parse(Object? value) {
    if (value is! String) {
      throw const BattleJobContractException('invalid_status');
    }
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    throw const BattleJobContractException('invalid_status');
  }
}

enum BattleJobOutcome {
  completed('completed'),
  censored('censored'),
  timeout('timeout'),
  coverageError('coverage_error'),
  engineError('engine_error'),
  cancelled('cancelled'),
  persistenceError('persistence_error');

  const BattleJobOutcome(this.wireValue);

  final String wireValue;

  static BattleJobOutcome? fromStatus(BattleJobStatus status) =>
      switch (status) {
        BattleJobStatus.completed => BattleJobOutcome.completed,
        BattleJobStatus.censored => BattleJobOutcome.censored,
        BattleJobStatus.timeout => BattleJobOutcome.timeout,
        BattleJobStatus.coverageError => BattleJobOutcome.coverageError,
        BattleJobStatus.engineError => BattleJobOutcome.engineError,
        BattleJobStatus.cancelled => BattleJobOutcome.cancelled,
        BattleJobStatus.persistenceError => BattleJobOutcome.persistenceError,
        _ => null,
      };
}

enum BattleRequestedEngine {
  auto('auto'),
  xmage('xmage'),
  forge('forge'),
  native('native');

  const BattleRequestedEngine(this.wireValue);

  final String wireValue;

  static BattleRequestedEngine parse(Object? value) {
    if (value is! String) {
      throw const BattleJobContractException('invalid_requested_engine');
    }
    for (final engine in values) {
      if (engine.wireValue == value) return engine;
    }
    throw const BattleJobContractException('invalid_requested_engine');
  }
}

enum BattleExecutionEngine {
  xmage('xmage'),
  forge('forge'),
  nativeReviewed('manaloom_native_reviewed');

  const BattleExecutionEngine(this.wireValue);

  final String wireValue;

  static BattleExecutionEngine? parseOptional(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const BattleJobContractException('invalid_engine');
    }
    for (final engine in values) {
      if (engine.wireValue == value) return engine;
    }
    throw const BattleJobContractException('invalid_engine');
  }
}

class BattleJobProgress {
  const BattleJobProgress({
    required this.current,
    required this.total,
    required this.ratio,
  });

  final int current;
  final int total;
  final double ratio;

  factory BattleJobProgress.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _progressKeys, 'unknown_progress_field');
    final current = _requireInt(json['current'], 'invalid_progress');
    final total = _requireInt(json['total'], 'invalid_progress');
    final rawRatio = json['ratio'];
    if (rawRatio is! num) {
      throw const BattleJobContractException('invalid_progress');
    }
    final ratio = rawRatio.toDouble();
    if (current < 0 ||
        total < 1 ||
        current > total ||
        !ratio.isFinite ||
        ratio < 0 ||
        ratio > 1) {
      throw const BattleJobContractException('invalid_progress');
    }
    final expectedRatio = current / total;
    if ((ratio - expectedRatio).abs() > 0.000001) {
      throw const BattleJobContractException('progress_ratio_mismatch');
    }
    return BattleJobProgress(current: current, total: total, ratio: ratio);
  }
}

class BattleJobDeckHashes {
  const BattleJobDeckHashes({required this.deckA, required this.deckB});

  final String deckA;
  final String deckB;

  factory BattleJobDeckHashes.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _deckHashKeys, 'unknown_deck_hash_field');
    if (json['schema_version'] != externalBattleDeckHashSchemaVersion) {
      throw const BattleJobContractException('unsupported_deck_hash_schema');
    }
    if (json['algorithm'] != 'sha256') {
      throw const BattleJobContractException('unsupported_hash_algorithm');
    }
    return BattleJobDeckHashes(
      deckA: _requireSha256(json['deck_a'], 'invalid_deck_hash'),
      deckB: _requireSha256(json['deck_b'], 'invalid_deck_hash'),
    );
  }
}

class BattleJob {
  BattleJob._({
    required this.jobId,
    required this.idempotencyKey,
    required this.status,
    required this.stage,
    required this.progress,
    required this.deckAId,
    required this.deckBId,
    required this.deckHashes,
    required this.requestHash,
    required this.requestedEngine,
    required this.engine,
    required this.engineVersion,
    required this.engineCommit,
    required this.engineBuild,
    required this.engineProcessId,
    required this.engineProcessStartedAt,
    required this.timeoutMs,
    required this.attemptCount,
    required this.attemptId,
    required this.replayId,
    required this.terminalReason,
    required this.errorCode,
    required this.claimedAt,
    required this.startedAt,
    required this.cancelRequestedAt,
    required this.heartbeatAt,
    required this.leaseExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.finishedAt,
    required this.canCancel,
    required this.canResume,
    required this.pollUrl,
    required this.cancelUrl,
  });

  final String jobId;
  final String idempotencyKey;
  final BattleJobStatus status;
  final String stage;
  final BattleJobProgress progress;
  final String? deckAId;
  final String? deckBId;
  final BattleJobDeckHashes deckHashes;
  final String requestHash;
  final BattleRequestedEngine requestedEngine;
  final BattleExecutionEngine? engine;
  final String? engineVersion;
  final String? engineCommit;
  final String? engineBuild;
  final String? engineProcessId;
  final DateTime? engineProcessStartedAt;
  final int timeoutMs;
  final int attemptCount;
  final String? attemptId;
  final String? replayId;
  final String? terminalReason;
  final String? errorCode;
  final DateTime? claimedAt;
  final DateTime? startedAt;
  final DateTime? cancelRequestedAt;
  final DateTime? heartbeatAt;
  final DateTime? leaseExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;
  final bool canCancel;
  final bool canResume;
  final String pollUrl;
  final String cancelUrl;

  BattleJobOutcome? get outcome => BattleJobOutcome.fromStatus(status);
  bool get isTerminal => status.isTerminal;

  factory BattleJob.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _jobKeys, 'unknown_job_field');
    if (json['schema_version'] != battleJobSchemaVersion) {
      throw const BattleJobContractException('unsupported_schema_version');
    }
    final jobId = _requireIdentifier(json['job_id'], 'invalid_job_id');
    final idempotencyKey = _requireIdentifier(
      json['idempotency_key'],
      'invalid_idempotency_key',
    );
    final status = BattleJobStatus.parse(json['status']);
    final stage = _requireSafeCode(json['stage'], 'invalid_stage');
    if (!_battleJobStages.contains(stage)) {
      throw const BattleJobContractException('invalid_stage');
    }
    if (!_stagesForStatus(status).contains(stage)) {
      throw const BattleJobContractException('stage_status_mismatch');
    }
    final progress = BattleJobProgress.fromJson(
      _requireMap(json['progress'], 'invalid_progress'),
    );
    final deckAId = _optionalIdentifier(json['deck_a_id'], 'invalid_deck_id');
    final deckBId = _optionalIdentifier(json['deck_b_id'], 'invalid_deck_id');
    final deckHashes = BattleJobDeckHashes.fromJson(
      _requireMap(json['deck_hashes'], 'invalid_deck_hashes'),
    );
    if (json['request_schema_version'] != externalBattleRequestSchemaVersion) {
      throw const BattleJobContractException(
        'unsupported_request_schema_version',
      );
    }
    final requestHash = _requireSha256(
      json['request_hash'],
      'invalid_request_hash',
    );
    final requestedEngine = BattleRequestedEngine.parse(
      json['requested_engine'],
    );
    final engine = BattleExecutionEngine.parseOptional(json['engine']);
    final engineVersion = _optionalText(
      json['engine_version'],
      'invalid_engine_identity',
    );
    final engineCommit = _optionalText(
      json['engine_commit'],
      'invalid_engine_identity',
    );
    final engineBuild = _optionalText(
      json['engine_build'],
      'invalid_engine_identity',
    );
    final engineProcessId = _optionalIdentifier(
      json['engine_process_id'],
      'invalid_engine_process_id',
    );
    final engineProcessStartedAt = _optionalDateTime(
      json['engine_process_started_at'],
      'invalid_engine_process_started_at',
    );
    if (engine == null &&
        (engineVersion != null ||
            engineCommit != null ||
            engineBuild != null ||
            engineProcessId != null ||
            engineProcessStartedAt != null)) {
      throw const BattleJobContractException('engine_identity_without_engine');
    }

    final timeoutMs = _requireInt(json['timeout_ms'], 'invalid_timeout');
    if (timeoutMs < 1000 || timeoutMs > 40000) {
      throw const BattleJobContractException('invalid_timeout');
    }
    final attemptCount = _requireInt(
      json['attempt_count'],
      'invalid_attempt_count',
    );
    if (attemptCount < 0) {
      throw const BattleJobContractException('invalid_attempt_count');
    }
    final attemptId = _optionalIdentifier(
      json['attempt_id'],
      'invalid_attempt_id',
    );
    if (attemptCount == 0 && attemptId != null) {
      throw const BattleJobContractException('attempt_identity_mismatch');
    }
    final replayId = _optionalIdentifier(
      json['replay_id'],
      'invalid_replay_id',
    );
    final terminalReason = _optionalSafeCode(
      json['terminal_reason'],
      'invalid_terminal_reason',
    );
    final errorCode = _optionalSafeCode(
      json['error_code'],
      'invalid_error_code',
    );
    final claimedAt = _optionalDateTime(
      json['claimed_at'],
      'invalid_claimed_at',
    );
    final startedAt = _optionalDateTime(
      json['started_at'],
      'invalid_started_at',
    );
    final cancelRequestedAt = _optionalDateTime(
      json['cancel_requested_at'],
      'invalid_cancel_requested_at',
    );
    final heartbeatAt = _optionalDateTime(
      json['heartbeat_at'],
      'invalid_heartbeat_at',
    );
    final leaseExpiresAt = _optionalDateTime(
      json['lease_expires_at'],
      'invalid_lease_expires_at',
    );
    final createdAt = _requireDateTime(
      json['created_at'],
      'invalid_created_at',
    );
    final updatedAt = _requireDateTime(
      json['updated_at'],
      'invalid_updated_at',
    );
    final finishedAt = _optionalDateTime(
      json['finished_at'],
      'invalid_finished_at',
    );
    if (updatedAt.isBefore(createdAt) ||
        (finishedAt != null && finishedAt.isBefore(createdAt))) {
      throw const BattleJobContractException('invalid_job_timeline');
    }
    if (status.isTerminal != (finishedAt != null)) {
      throw const BattleJobContractException('terminal_timeline_mismatch');
    }
    if (status.isTerminal && leaseExpiresAt != null) {
      throw const BattleJobContractException('terminal_job_has_lease');
    }
    if (!status.isTerminal &&
        (replayId != null || terminalReason != null || errorCode != null)) {
      throw const BattleJobContractException('active_job_has_terminal_data');
    }
    if (status == BattleJobStatus.completed && replayId == null) {
      throw const BattleJobContractException('completed_job_missing_replay');
    }
    final canCancel = _requireBool(json['can_cancel'], 'invalid_can_cancel');
    if (canCancel != status.canCancel) {
      throw const BattleJobContractException('can_cancel_status_mismatch');
    }
    final canResume = _requireBool(json['can_resume'], 'invalid_can_resume');
    if (canResume == status.isTerminal) {
      throw const BattleJobContractException('can_resume_status_mismatch');
    }
    final expectedUrl = '/ai/battle/jobs/$jobId';
    final pollUrl = _requirePath(json['poll_url'], 'invalid_poll_url');
    final cancelUrl = _requirePath(json['cancel_url'], 'invalid_cancel_url');
    if (pollUrl != expectedUrl || cancelUrl != expectedUrl) {
      throw const BattleJobContractException('job_url_mismatch');
    }

    return BattleJob._(
      jobId: jobId,
      idempotencyKey: idempotencyKey,
      status: status,
      stage: stage,
      progress: progress,
      deckAId: deckAId,
      deckBId: deckBId,
      deckHashes: deckHashes,
      requestHash: requestHash,
      requestedEngine: requestedEngine,
      engine: engine,
      engineVersion: engineVersion,
      engineCommit: engineCommit,
      engineBuild: engineBuild,
      engineProcessId: engineProcessId,
      engineProcessStartedAt: engineProcessStartedAt,
      timeoutMs: timeoutMs,
      attemptCount: attemptCount,
      attemptId: attemptId,
      replayId: replayId,
      terminalReason: terminalReason,
      errorCode: errorCode,
      claimedAt: claimedAt,
      startedAt: startedAt,
      cancelRequestedAt: cancelRequestedAt,
      heartbeatAt: heartbeatAt,
      leaseExpiresAt: leaseExpiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      finishedAt: finishedAt,
      canCancel: canCancel,
      canResume: canResume,
      pollUrl: pollUrl,
      cancelUrl: cancelUrl,
    );
  }
}

class BattleJobCreation {
  const BattleJobCreation({required this.job, required this.created});

  final BattleJob job;
  final bool created;

  factory BattleJobCreation.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _creationKeys, 'unknown_creation_field');
    final created = _requireBool(json['created'], 'invalid_created_flag');
    return BattleJobCreation(
      job: BattleJob.fromJson(_requireMap(json['job'], 'invalid_job')),
      created: created,
    );
  }
}

class BattleJobCancellation {
  const BattleJobCancellation({required this.job, required this.accepted});

  final BattleJob job;
  final bool accepted;

  factory BattleJobCancellation.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _cancellationKeys, 'unknown_cancellation_field');
    return BattleJobCancellation(
      job: BattleJob.fromJson(_requireMap(json['job'], 'invalid_job')),
      accepted: _requireBool(json['accepted'], 'invalid_accepted_flag'),
    );
  }
}

class BattleJobList {
  BattleJobList._(List<BattleJob> jobs) : jobs = List.unmodifiable(jobs);

  final List<BattleJob> jobs;

  factory BattleJobList.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, _listKeys, 'unknown_job_list_field');
    if (json['schema_version'] != battleJobListSchemaVersion) {
      throw const BattleJobContractException('unsupported_list_schema_version');
    }
    final rawJobs = json['jobs'];
    if (rawJobs is! List || rawJobs.length > 100) {
      throw const BattleJobContractException('invalid_job_list');
    }
    final jobs = rawJobs
        .map(
          (job) =>
              BattleJob.fromJson(_requireMap(job, 'invalid_job_list_item')),
        )
        .toList(growable: false);
    final ids = jobs.map((job) => job.jobId).toSet();
    if (ids.length != jobs.length) {
      throw const BattleJobContractException('duplicate_job_id');
    }
    return BattleJobList._(jobs);
  }
}

class BattleJobCreateRequest {
  BattleJobCreateRequest({
    required String deckId,
    required this.setup,
    required String idempotencyKey,
    this.maxTurns = 30,
    this.timeoutMs = 40000,
    this.engine,
    this.seed,
  }) : deckId = _validateRequestIdentifier(deckId, 'invalid_deck_id'),
       idempotencyKey = _validateRequestIdentifier(
         idempotencyKey,
         'invalid_idempotency_key',
       ) {
    if (setup.opponentDeckId.trim().isEmpty ||
        !_identifierPattern.hasMatch(setup.opponentDeckId.trim())) {
      throw const BattleJobContractException('invalid_opponent_deck_id');
    }
    if (this.deckId == setup.opponentDeckId.trim()) {
      throw const BattleJobContractException('battle_job_same_deck');
    }
    if (setup.objective == BattleTestObjective.focusCards &&
        setup.focusCards.isEmpty) {
      throw const BattleJobContractException('focus_cards_required');
    }
    if (maxTurns < 1 || maxTurns > 100) {
      throw const BattleJobContractException('invalid_max_turns');
    }
    if (timeoutMs < 1000 || timeoutMs > 40000) {
      throw const BattleJobContractException('invalid_timeout');
    }
    if (seed != null && (seed! < 0 || seed! > 0x7fffffff)) {
      throw const BattleJobContractException('invalid_seed');
    }
  }

  final String deckId;
  final BattleTestSetup setup;
  final String idempotencyKey;
  final int maxTurns;
  final int timeoutMs;
  final BattleRequestedEngine? engine;
  final int? seed;

  Map<String, dynamic> toJson() => UnmodifiableMapView({
    'schema_version': battleJobSchemaVersion,
    'deck_id': deckId,
    ...setup.toRequestJson(),
    'max_turns': maxTurns,
    'timeout_ms': timeoutMs,
    if (engine != null) 'engine': engine!.wireValue,
    if (seed != null) 'seed': seed,
    'idempotency_key': idempotencyKey,
  });
}

String _validateRequestIdentifier(String value, String code) {
  final normalized = value.trim();
  if (!_identifierPattern.hasMatch(normalized)) {
    throw BattleJobContractException(code);
  }
  return normalized;
}

void _requireOnlyKeys(
  Map<String, dynamic> json,
  Set<String> allowed,
  String code,
) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw BattleJobContractException(code);
  }
}

Map<String, dynamic> _requireMap(Object? value, String code) {
  if (value is! Map) throw BattleJobContractException(code);
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _requireIdentifier(Object? value, String code) {
  if (value is! String || !_identifierPattern.hasMatch(value)) {
    throw BattleJobContractException(code);
  }
  return value;
}

String? _optionalIdentifier(Object? value, String code) {
  if (value == null) return null;
  return _requireIdentifier(value, code);
}

String _requireSafeCode(Object? value, String code) {
  if (value is! String || !_safeCodePattern.hasMatch(value)) {
    throw BattleJobContractException(code);
  }
  return value;
}

String? _optionalSafeCode(Object? value, String code) {
  if (value == null) return null;
  return _requireSafeCode(value, code);
}

String? _optionalText(Object? value, String code) {
  if (value == null) return null;
  if (value is! String || value.isEmpty || value.runes.length > 256) {
    throw BattleJobContractException(code);
  }
  return value;
}

String _requireSha256(Object? value, String code) {
  if (value is! String || !_sha256Pattern.hasMatch(value)) {
    throw BattleJobContractException(code);
  }
  return value;
}

String _requirePath(Object? value, String code) {
  if (value is! String ||
      value.length > 256 ||
      !value.startsWith('/') ||
      value.contains('?') ||
      value.contains('#')) {
    throw BattleJobContractException(code);
  }
  return value;
}

int _requireInt(Object? value, String code) {
  if (value is! int) throw BattleJobContractException(code);
  return value;
}

bool _requireBool(Object? value, String code) {
  if (value is! bool) throw BattleJobContractException(code);
  return value;
}

DateTime _requireDateTime(Object? value, String code) {
  if (value is! String) throw BattleJobContractException(code);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw BattleJobContractException(code);
  return parsed;
}

DateTime? _optionalDateTime(Object? value, String code) {
  if (value == null) return null;
  return _requireDateTime(value, code);
}

final _identifierPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');
final _safeCodePattern = RegExp(r'^[a-z0-9][a-z0-9_:-]{0,127}$');
final _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

const _progressKeys = <String>{'current', 'total', 'ratio'};
const _deckHashKeys = <String>{
  'schema_version',
  'algorithm',
  'deck_a',
  'deck_b',
};
const _creationKeys = <String>{'job', 'created'};
const _cancellationKeys = <String>{'job', 'accepted'};
const _listKeys = <String>{'schema_version', 'jobs'};
const _jobKeys = <String>{
  'schema_version',
  'job_id',
  'idempotency_key',
  'status',
  'stage',
  'progress',
  'deck_a_id',
  'deck_b_id',
  'deck_hashes',
  'request_schema_version',
  'request_hash',
  'requested_engine',
  'engine',
  'engine_version',
  'engine_commit',
  'engine_build',
  'engine_process_id',
  'engine_process_started_at',
  'timeout_ms',
  'attempt_count',
  'attempt_id',
  'replay_id',
  'terminal_reason',
  'error_code',
  'claimed_at',
  'started_at',
  'cancel_requested_at',
  'heartbeat_at',
  'lease_expires_at',
  'created_at',
  'updated_at',
  'finished_at',
  'can_cancel',
  'can_resume',
  'poll_url',
  'cancel_url',
};
const _battleJobStages = <String>{
  'queued',
  'claimed',
  'starting_engine',
  'running',
  'persisting_replay',
  'cancel_pending',
  'completed',
  'censored',
  'timeout',
  'coverage_error',
  'engine_error',
  'cancelled',
  'persistence_error',
};

Set<String> _stagesForStatus(BattleJobStatus status) => switch (status) {
  BattleJobStatus.queued => const {'queued'},
  BattleJobStatus.claimed => const {'claimed'},
  BattleJobStatus.running => const {
    'starting_engine',
    'running',
    'persisting_replay',
  },
  BattleJobStatus.cancelPending => const {'cancel_pending'},
  BattleJobStatus.completed => const {'completed'},
  BattleJobStatus.censored => const {'censored'},
  BattleJobStatus.timeout => const {'timeout'},
  BattleJobStatus.coverageError => const {'coverage_error'},
  BattleJobStatus.engineError => const {'engine_error'},
  BattleJobStatus.cancelled => const {'cancelled'},
  BattleJobStatus.persistenceError => const {'persistence_error'},
};
