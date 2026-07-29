import 'dart:convert';

const battleJobSchemaVersion = 'battle_job_v1';
const battleJobListSchemaVersion = 'battle_job_list_v1';
const battleJobMaximumBodyBytes = 64 * 1024;
const battleJobMaximumFocusCards = 3;
const battleJobMinimumTimeoutMs = 1000;
const battleJobMaximumTimeoutMs = 40000;
const battleJobMaximumTurns = 100;

final RegExp battleJobUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
  r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final RegExp battleJobIdempotencyKeyPattern = RegExp(
  r'^[A-Za-z0-9._:-]{1,128}$',
);

enum BattleJobStatus {
  queued,
  claimed,
  running,
  cancelPending,
  completed,
  censored,
  timeout,
  coverageError,
  engineError,
  cancelled,
  persistenceError,
}

extension BattleJobStatusValue on BattleJobStatus {
  String get value => switch (this) {
    BattleJobStatus.queued => 'queued',
    BattleJobStatus.claimed => 'claimed',
    BattleJobStatus.running => 'running',
    BattleJobStatus.cancelPending => 'cancel_pending',
    BattleJobStatus.completed => 'completed',
    BattleJobStatus.censored => 'censored',
    BattleJobStatus.timeout => 'timeout',
    BattleJobStatus.coverageError => 'coverage_error',
    BattleJobStatus.engineError => 'engine_error',
    BattleJobStatus.cancelled => 'cancelled',
    BattleJobStatus.persistenceError => 'persistence_error',
  };

  bool get isTerminal => switch (this) {
    BattleJobStatus.completed ||
    BattleJobStatus.censored ||
    BattleJobStatus.timeout ||
    BattleJobStatus.coverageError ||
    BattleJobStatus.engineError ||
    BattleJobStatus.cancelled ||
    BattleJobStatus.persistenceError => true,
    _ => false,
  };

  bool get canCancel => switch (this) {
    BattleJobStatus.queued ||
    BattleJobStatus.claimed ||
    BattleJobStatus.running => true,
    _ => false,
  };
}

BattleJobStatus parseBattleJobStatus(Object? raw) {
  final value = raw?.toString().trim();
  return BattleJobStatus.values.firstWhere(
    (status) => status.value == value,
    orElse:
        () =>
            throw BattleJobPersistenceException(
              'battle_job_status_unknown',
              'Persisted Battle job status is not supported.',
            ),
  );
}

const battleJobRequestedEngines = <String>{'auto', 'xmage', 'forge', 'native'};

const battleJobObjectives = <String>{
  'general',
  'commander',
  'mana_curve',
  'interaction',
  'combo',
  'focus_cards',
};

const battleJobForceFocusModes = <String>{
  'none',
  'opening_hand',
  'library_top',
};

const battleJobStages = <String>{
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

class BattleJobValidationException implements Exception {
  const BattleJobValidationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class BattleJobNotFoundException implements Exception {
  const BattleJobNotFoundException();
}

class BattleJobIdempotencyConflictException implements Exception {
  const BattleJobIdempotencyConflictException();
}

class BattleJobNotCancellableException implements Exception {
  const BattleJobNotCancellableException(this.job);

  final BattleJob job;
}

class BattleJobQuotaExceededException implements Exception {
  const BattleJobQuotaExceededException({
    required this.scope,
    required this.limit,
    this.retryAfterSeconds = 15,
  });

  final String scope;
  final int limit;
  final int retryAfterSeconds;
}

class BattleJobPersistenceException implements Exception {
  const BattleJobPersistenceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class BattleJobCreateInput {
  const BattleJobCreateInput({
    required this.deckId,
    required this.opponentDeckId,
    required this.requestedEngine,
    required this.timeoutMs,
    required this.maxTurns,
    required this.testObjective,
    required this.focusCards,
    required this.forceFocusAccessMode,
    required this.sameLane,
    required this.naturalSample,
    required this.idempotencyKey,
    this.seed,
  });

  final String deckId;
  final String opponentDeckId;
  final String requestedEngine;
  final int timeoutMs;
  final int maxTurns;
  final String testObjective;
  final List<String> focusCards;
  final String forceFocusAccessMode;
  final bool sameLane;
  final bool naturalSample;
  final String? idempotencyKey;
  final int? seed;

  static BattleJobCreateInput parse(
    Map<String, dynamic> body, {
    String? headerIdempotencyKey,
  }) {
    const allowedKeys = <String>{
      'schema_version',
      'deck_id',
      'opponent_deck_id',
      'engine',
      'timeout_ms',
      'max_turns',
      'seed',
      'test_objective',
      'focus_cards',
      'force_focus_access_mode',
      'same_lane',
      'natural_sample',
      'idempotency_key',
      'request_key',
      'type',
    };
    final unknownKeys = body.keys.where((key) => !allowedKeys.contains(key));
    if (unknownKeys.isNotEmpty) {
      throw const BattleJobValidationException(
        'battle_job_unknown_field',
        'The Battle job request contains an unsupported field.',
      );
    }

    final schemaVersion = _optionalString(
      body['schema_version'],
      key: 'schema_version',
      maxLength: 64,
    );
    if (schemaVersion != null && schemaVersion != battleJobSchemaVersion) {
      throw const BattleJobValidationException(
        'battle_job_schema_unsupported',
        'schema_version must be battle_job_v1.',
      );
    }
    final type = _optionalString(body['type'], key: 'type', maxLength: 16);
    if (type != null && type.toLowerCase() != 'battle') {
      throw const BattleJobValidationException(
        'battle_job_type_unsupported',
        'Battle jobs accept only type=battle.',
      );
    }

    final deckId = _requiredUuid(body['deck_id'], key: 'deck_id');
    final opponentDeckId = _requiredUuid(
      body['opponent_deck_id'],
      key: 'opponent_deck_id',
    );
    if (deckId == opponentDeckId) {
      throw const BattleJobValidationException(
        'battle_job_same_deck',
        'deck_id and opponent_deck_id must be different.',
      );
    }

    final requestedEngine =
        (_optionalString(body['engine'], key: 'engine', maxLength: 16) ??
                'auto')
            .toLowerCase();
    if (!battleJobRequestedEngines.contains(requestedEngine)) {
      throw const BattleJobValidationException(
        'battle_job_engine_invalid',
        'engine must be a supported execution mode.',
      );
    }

    final timeoutMs = _boundedInteger(
      body['timeout_ms'],
      key: 'timeout_ms',
      defaultValue: battleJobMaximumTimeoutMs,
      minimum: battleJobMinimumTimeoutMs,
      maximum: battleJobMaximumTimeoutMs,
    );
    final maxTurns = _boundedInteger(
      body['max_turns'],
      key: 'max_turns',
      defaultValue: 30,
      minimum: 1,
      maximum: battleJobMaximumTurns,
    );
    final seed = _optionalInteger(
      body['seed'],
      key: 'seed',
      minimum: 0,
      maximum: 2147483647,
    );
    final testObjective =
        (_optionalString(
              body['test_objective'],
              key: 'test_objective',
              maxLength: 32,
            ) ??
            'general');
    if (!battleJobObjectives.contains(testObjective)) {
      throw const BattleJobValidationException(
        'battle_job_objective_invalid',
        'test_objective is not supported.',
      );
    }

    final focusCards = _focusCards(body['focus_cards']);
    if (testObjective == 'focus_cards' && focusCards.isEmpty) {
      throw const BattleJobValidationException(
        'battle_job_focus_cards_required',
        'focus_cards is required for the focus_cards objective.',
      );
    }
    final forceFocusAccessMode =
        (_optionalString(
              body['force_focus_access_mode'],
              key: 'force_focus_access_mode',
              maxLength: 32,
            ) ??
            'none');
    if (!battleJobForceFocusModes.contains(forceFocusAccessMode)) {
      throw const BattleJobValidationException(
        'battle_job_focus_mode_invalid',
        'force_focus_access_mode is not supported.',
      );
    }
    if (requestedEngine != 'native' && forceFocusAccessMode != 'none') {
      throw const BattleJobValidationException(
        'external_battle_control_unsupported',
        'Forced focus access is available only for the reviewed simulation mode.',
      );
    }

    final headerKey = _normalizeIdempotencyKey(headerIdempotencyKey);
    final bodyKey = _normalizeIdempotencyKey(body['idempotency_key']);
    final legacyBodyKey = _normalizeIdempotencyKey(body['request_key']);
    final keys = <String>{
      if (headerKey != null) headerKey,
      if (bodyKey != null) bodyKey,
      if (legacyBodyKey != null) legacyBodyKey,
    };
    if (keys.length > 1) {
      throw const BattleJobValidationException(
        'battle_job_idempotency_mismatch',
        'Idempotency keys supplied in the request do not match.',
      );
    }

    return BattleJobCreateInput(
      deckId: deckId,
      opponentDeckId: opponentDeckId,
      requestedEngine: requestedEngine,
      timeoutMs: timeoutMs,
      maxTurns: maxTurns,
      seed: seed,
      testObjective: testObjective,
      focusCards: List.unmodifiable(focusCards),
      forceFocusAccessMode: forceFocusAccessMode,
      sameLane: _boolean(body['same_lane'], key: 'same_lane', fallback: false),
      naturalSample: _boolean(
        body['natural_sample'],
        key: 'natural_sample',
        fallback: true,
      ),
      idempotencyKey: keys.firstOrNull,
    );
  }
}

class BattleJobDeckSnapshot {
  const BattleJobDeckSnapshot({
    required this.id,
    required this.name,
    required this.format,
    required this.validationState,
    required this.validationReasons,
    required this.cards,
    required this.hash,
  });

  final String id;
  final String name;
  final String format;
  final String validationState;
  final List<String> validationReasons;
  final List<Map<String, dynamic>> cards;
  final String hash;

  Map<String, dynamic> get payload => {'id': id, 'name': name, 'cards': cards};
}

class BattleJobCreateCommand {
  const BattleJobCreateCommand({
    required this.id,
    required this.userId,
    required this.deckA,
    required this.deckB,
    required this.idempotencyKey,
    required this.requestFingerprint,
    required this.requestHash,
    required this.requestPayload,
    required this.requestedEngine,
    required this.engineLane,
    required this.timeoutMs,
  });

  final String id;
  final String userId;
  final BattleJobDeckSnapshot deckA;
  final BattleJobDeckSnapshot deckB;
  final String idempotencyKey;
  final String requestFingerprint;
  final String requestHash;
  final Map<String, dynamic> requestPayload;
  final String requestedEngine;
  final String engineLane;
  final int timeoutMs;
}

class BattleJobCreateResult {
  const BattleJobCreateResult({required this.job, required this.created});

  final BattleJob job;
  final bool created;
}

class BattleJobCancelResult {
  const BattleJobCancelResult({required this.job, required this.accepted});

  final BattleJob job;
  final bool accepted;
}

class BattleJob {
  const BattleJob({
    required this.id,
    required this.userId,
    required this.status,
    required this.stage,
    required this.progressCurrent,
    required this.progressTotal,
    required this.deckAId,
    required this.deckBId,
    required this.deckHashSchema,
    required this.deckAHash,
    required this.deckBHash,
    required this.requestSchemaVersion,
    required this.requestHash,
    required this.requestPayload,
    required this.requestedEngine,
    required this.engineLane,
    required this.timeoutMs,
    required this.attemptCount,
    required this.idempotencyKey,
    required this.requestFingerprint,
    required this.createdAt,
    required this.updatedAt,
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
    this.claimedAt,
    this.startedAt,
    this.cancelRequestedAt,
    this.heartbeatAt,
    this.leaseExpiresAt,
    this.finishedAt,
  });

  final String id;
  final String userId;
  final BattleJobStatus status;
  final String stage;
  final int progressCurrent;
  final int progressTotal;
  final String? deckAId;
  final String? deckBId;
  final String deckHashSchema;
  final String deckAHash;
  final String deckBHash;
  final String requestSchemaVersion;
  final String requestHash;
  final Map<String, dynamic> requestPayload;
  final String requestedEngine;
  final String engineLane;
  final String? engine;
  final String? engineVersion;
  final String? engineCommit;
  final String? engineBuild;
  final String? engineProcessId;
  final DateTime? engineProcessStartedAt;
  final String? engineRequestSchemaVersion;
  final String? engineRequestHash;
  final String? engineRequestCorrelationSource;
  final int timeoutMs;
  final int attemptCount;
  final String? attemptId;
  final String? replayId;
  final String idempotencyKey;
  final String requestFingerprint;
  final String? terminalReason;
  final String? errorCode;
  final DateTime? claimedAt;
  final DateTime? startedAt;
  final DateTime? cancelRequestedAt;
  final DateTime? heartbeatAt;
  final DateTime? leaseExpiresAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => status.isTerminal;

  Map<String, dynamic> toJson() => {
    'schema_version': battleJobSchemaVersion,
    'job_id': id,
    'status': status.value,
    'stage': stage,
    'progress': {
      'current': progressCurrent,
      'total': progressTotal,
      'ratio':
          progressTotal <= 0
              ? 0.0
              : (progressCurrent / progressTotal).clamp(0.0, 1.0),
    },
    if (deckAId != null) 'deck_a_id': deckAId,
    if (deckBId != null) 'deck_b_id': deckBId,
    'deck_hashes': {
      'schema_version': deckHashSchema,
      'algorithm': 'sha256',
      'deck_a': deckAHash,
      'deck_b': deckBHash,
    },
    'request_schema_version': requestSchemaVersion,
    'request_hash': requestHash,
    'requested_engine': requestedEngine,
    if (engine != null) 'engine': engine,
    if (engineVersion != null) 'engine_version': engineVersion,
    if (engineCommit != null) 'engine_commit': engineCommit,
    if (engineBuild != null) 'engine_build': engineBuild,
    if (engineProcessId != null) 'engine_process_id': engineProcessId,
    if (engineProcessStartedAt != null)
      'engine_process_started_at':
          engineProcessStartedAt!.toUtc().toIso8601String(),
    if (engineRequestHash != null)
      'request_correlation': {
        'schema_version': 'battle_request_correlation_v1',
        'job_request_schema_version': requestSchemaVersion,
        'job_request_hash': requestHash,
        if (engineRequestSchemaVersion != null)
          'engine_request_schema_version': engineRequestSchemaVersion,
        'engine_request_hash': engineRequestHash,
        if (engineRequestCorrelationSource != null)
          'correlation_source': engineRequestCorrelationSource,
      },
    'timeout_ms': timeoutMs,
    'attempt_count': attemptCount,
    if (attemptId != null) 'attempt_id': attemptId,
    if (replayId != null) 'replay_id': replayId,
    'idempotency_key': idempotencyKey,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    if (errorCode != null) 'error_code': errorCode,
    if (claimedAt != null) 'claimed_at': claimedAt!.toUtc().toIso8601String(),
    if (startedAt != null) 'started_at': startedAt!.toUtc().toIso8601String(),
    if (cancelRequestedAt != null)
      'cancel_requested_at': cancelRequestedAt!.toUtc().toIso8601String(),
    if (heartbeatAt != null)
      'heartbeat_at': heartbeatAt!.toUtc().toIso8601String(),
    if (leaseExpiresAt != null && !status.isTerminal)
      'lease_expires_at': leaseExpiresAt!.toUtc().toIso8601String(),
    if (finishedAt != null)
      'finished_at': finishedAt!.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'can_cancel': status.canCancel,
    'can_resume': !status.isTerminal,
    'poll_url': '/ai/battle/jobs/$id',
    'cancel_url': '/ai/battle/jobs/$id',
  };

  factory BattleJob.fromRow(Map<String, dynamic> row) {
    return BattleJob(
      id: _rowString(row, 'id'),
      userId: _rowString(row, 'user_id'),
      status: parseBattleJobStatus(row['status']),
      stage: _rowString(row, 'stage', fallback: 'queued'),
      progressCurrent: _rowInt(row, 'progress_current'),
      progressTotal: _rowInt(row, 'progress_total', fallback: 100),
      deckAId: _nullableRowString(row, 'deck_a_id'),
      deckBId: _nullableRowString(row, 'deck_b_id'),
      deckHashSchema: _rowString(row, 'deck_hash_schema'),
      deckAHash: _rowString(row, 'deck_a_hash'),
      deckBHash: _rowString(row, 'deck_b_hash'),
      requestSchemaVersion: _rowString(row, 'request_schema_version'),
      requestHash: _rowString(row, 'request_hash'),
      requestPayload: decodeBattleJobJsonMap(row['request_payload']),
      requestedEngine: _rowString(row, 'requested_engine'),
      engineLane: _rowString(row, 'engine_lane'),
      engine: _nullableRowString(row, 'engine'),
      engineVersion: _nullableRowString(row, 'engine_version'),
      engineCommit: _nullableRowString(row, 'engine_commit'),
      engineBuild: _nullableRowString(row, 'engine_build'),
      engineProcessId: _nullableRowString(row, 'engine_process_id'),
      engineProcessStartedAt: _rowDateTime(row, 'engine_process_started_at'),
      engineRequestSchemaVersion: _nullableRowString(
        row,
        'engine_request_schema_version',
      ),
      engineRequestHash: _nullableRowString(row, 'engine_request_hash'),
      engineRequestCorrelationSource: _nullableRowString(
        row,
        'engine_request_correlation_source',
      ),
      timeoutMs: _rowInt(row, 'timeout_ms'),
      attemptCount: _rowInt(row, 'attempt_count'),
      attemptId: _nullableRowString(row, 'attempt_id'),
      replayId: _nullableRowString(row, 'replay_id'),
      idempotencyKey: _rowString(row, 'idempotency_key'),
      requestFingerprint: _rowString(row, 'request_fingerprint'),
      terminalReason: _nullableRowString(row, 'terminal_reason'),
      errorCode: _nullableRowString(row, 'error_code'),
      claimedAt: _rowDateTime(row, 'claimed_at'),
      startedAt: _rowDateTime(row, 'started_at'),
      cancelRequestedAt: _rowDateTime(row, 'cancel_requested_at'),
      heartbeatAt: _rowDateTime(row, 'heartbeat_at'),
      leaseExpiresAt: _rowDateTime(row, 'lease_expires_at'),
      finishedAt: _rowDateTime(row, 'finished_at'),
      createdAt:
          _rowDateTime(row, 'created_at') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          _rowDateTime(row, 'updated_at') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

Map<String, dynamic> decodeBattleJobJsonMap(Object? raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  }
  return const {};
}

String _requiredUuid(Object? raw, {required String key}) {
  final value = _optionalString(raw, key: key, maxLength: 64);
  if (value == null || !battleJobUuidPattern.hasMatch(value)) {
    throw BattleJobValidationException(
      'battle_job_${key}_invalid',
      '$key must be a valid UUID.',
    );
  }
  return value.toLowerCase();
}

String? _optionalString(
  Object? raw, {
  required String key,
  required int maxLength,
}) {
  if (raw == null) return null;
  if (raw is! String) {
    throw BattleJobValidationException(
      'battle_job_${key}_invalid',
      '$key must be a string.',
    );
  }
  final value = raw.trim();
  if (value.isEmpty || value.length > maxLength) {
    throw BattleJobValidationException(
      'battle_job_${key}_invalid',
      '$key has an invalid length.',
    );
  }
  return value;
}

int _boundedInteger(
  Object? raw, {
  required String key,
  required int defaultValue,
  required int minimum,
  required int maximum,
}) {
  if (raw == null) return defaultValue;
  if (raw is! int || raw < minimum || raw > maximum) {
    throw BattleJobValidationException(
      'battle_job_${key}_invalid',
      '$key must be between $minimum and $maximum.',
    );
  }
  return raw;
}

int? _optionalInteger(
  Object? raw, {
  required String key,
  required int minimum,
  required int maximum,
}) {
  if (raw == null) return null;
  return _boundedInteger(
    raw,
    key: key,
    defaultValue: minimum,
    minimum: minimum,
    maximum: maximum,
  );
}

bool _boolean(Object? raw, {required String key, required bool fallback}) {
  if (raw == null) return fallback;
  if (raw is! bool) {
    throw BattleJobValidationException(
      'battle_job_${key}_invalid',
      '$key must be a boolean.',
    );
  }
  return raw;
}

List<String> _focusCards(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List || raw.length > battleJobMaximumFocusCards) {
    throw const BattleJobValidationException(
      'battle_job_focus_cards_invalid',
      'focus_cards must contain at most three card names.',
    );
  }
  final result = <String>[];
  final seen = <String>{};
  for (final item in raw) {
    if (item is! String) {
      throw const BattleJobValidationException(
        'battle_job_focus_cards_invalid',
        'focus_cards must contain only strings.',
      );
    }
    final value = item.trim();
    if (value.isEmpty || value.length > 300) {
      throw const BattleJobValidationException(
        'battle_job_focus_cards_invalid',
        'focus_cards contains an invalid card name.',
      );
    }
    if (seen.add(value.toLowerCase())) result.add(value);
  }
  return result;
}

String? _normalizeIdempotencyKey(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const BattleJobValidationException(
      'battle_job_idempotency_key_invalid',
      'idempotency_key must be a string.',
    );
  }
  final value = raw.trim();
  if (!battleJobIdempotencyKeyPattern.hasMatch(value)) {
    throw const BattleJobValidationException(
      'battle_job_idempotency_key_invalid',
      'idempotency_key must contain 1-128 safe characters.',
    );
  }
  return value;
}

String _rowString(
  Map<String, dynamic> row,
  String key, {
  String fallback = '',
}) {
  final value = row[key]?.toString().trim();
  return value == null || value.isEmpty ? fallback : value;
}

String? _nullableRowString(Map<String, dynamic> row, String key) {
  final value = row[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _rowInt(Map<String, dynamic> row, String key, {int fallback = 0}) {
  final value = row[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _rowDateTime(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
