import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'battle_replay_payload_sanitizer.dart';

const battleSimulationAttemptSchema = 'battle_simulation_attempt_v1';
const battleSimulationAttemptOutcomes = <String>{
  'completed',
  'censored',
  'timeout',
  'coverage_error',
  'engine_error',
  'cancelled',
  'persistence_error',
};

enum BattleSimulationAttemptOutcome {
  completed,
  censored,
  timeout,
  coverageError,
  engineError,
  cancelled,
  persistenceError,
}

extension BattleSimulationAttemptOutcomeValue
    on BattleSimulationAttemptOutcome {
  String get value => switch (this) {
    BattleSimulationAttemptOutcome.completed => 'completed',
    BattleSimulationAttemptOutcome.censored => 'censored',
    BattleSimulationAttemptOutcome.timeout => 'timeout',
    BattleSimulationAttemptOutcome.coverageError => 'coverage_error',
    BattleSimulationAttemptOutcome.engineError => 'engine_error',
    BattleSimulationAttemptOutcome.cancelled => 'cancelled',
    BattleSimulationAttemptOutcome.persistenceError => 'persistence_error',
  };
}

class BattleSimulationAttemptHandle {
  const BattleSimulationAttemptHandle({required this.id, required this.userId});

  final String id;
  final String userId;
}

class BattleSimulationAttemptStartResult {
  const BattleSimulationAttemptStartResult.started(this.handle)
    : errorCode = null;

  const BattleSimulationAttemptStartResult.failed(this.errorCode)
    : handle = null;

  final BattleSimulationAttemptHandle? handle;
  final String? errorCode;

  bool get isStarted => handle != null;
}

class BattleSimulationAttemptFinishResult {
  const BattleSimulationAttemptFinishResult.finished() : errorCode = null;

  const BattleSimulationAttemptFinishResult.failed(this.errorCode);

  final String? errorCode;

  bool get isFinished => errorCode == null;
}

class BattleSimulationAttemptService {
  const BattleSimulationAttemptService(this._pool);

  final Pool _pool;

  Future<BattleSimulationAttemptStartResult> start({
    required String userId,
    required String deckAId,
    String? deckBId,
    required String simulationType,
    String testObjective = 'general',
    required String requestId,
    required String deckAHash,
    String? deckBHash,
    required String deckHashSchema,
    required int timeoutMs,
    String requestSchemaVersion = battleSimulationAttemptSchema,
    String? jobRequestSchemaVersion,
    String? jobRequestHash,
    String? engine,
    Map<String, dynamic> provenance = const {},
  }) async {
    try {
      final sanitizedProvenance = sanitizeBattleReplayMetadata({
        'schema_version': battleSimulationAttemptSchema,
        ...provenance,
      });
      final result = await _pool.execute(
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
            CAST(@userId AS uuid),
            owner_deck.id,
            CAST(@deckBId AS uuid),
            @simulationType,
            @testObjective,
            @requestId,
            @requestSchemaVersion,
            @jobRequestSchemaVersion,
            @jobRequestHash,
            @deckHashSchema,
            @deckAHash,
            @deckBHash,
            @timeoutMs,
            @engine,
            @provenance::jsonb
          FROM decks owner_deck
          WHERE owner_deck.id = CAST(@deckAId AS uuid)
            AND owner_deck.user_id = CAST(@userId AS uuid)
            AND owner_deck.deleted_at IS NULL
            AND (
              CAST(@deckBId AS uuid) IS NULL
              OR EXISTS (
                SELECT 1
                FROM decks opponent_deck
                WHERE opponent_deck.id = CAST(@deckBId AS uuid)
                  AND opponent_deck.deleted_at IS NULL
                  AND (
                    opponent_deck.user_id = CAST(@userId AS uuid)
                    OR opponent_deck.is_public = TRUE
                  )
              )
            )
          RETURNING id::text
          '''),
        parameters: {
          'userId': userId,
          'deckAId': deckAId,
          'deckBId': deckBId,
          'simulationType': simulationType,
          'testObjective': testObjective,
          'requestId': requestId,
          'requestSchemaVersion': requestSchemaVersion,
          'jobRequestSchemaVersion': jobRequestSchemaVersion,
          'jobRequestHash': jobRequestHash,
          'deckHashSchema': deckHashSchema,
          'deckAHash': deckAHash,
          'deckBHash': deckBHash,
          'timeoutMs': timeoutMs,
          'engine': engine,
          'provenance': jsonEncode(sanitizedProvenance),
        },
      );
      final id = result.isEmpty ? null : result.first[0]?.toString().trim();
      if (id == null || id.isEmpty) {
        return const BattleSimulationAttemptStartResult.failed(
          'battle_attempt_owner_scope_failed',
        );
      }
      return BattleSimulationAttemptStartResult.started(
        BattleSimulationAttemptHandle(id: id, userId: userId),
      );
    } on BattleReplayPayloadException {
      return const BattleSimulationAttemptStartResult.failed(
        'battle_attempt_metadata_invalid',
      );
    } catch (_) {
      return const BattleSimulationAttemptStartResult.failed(
        'battle_attempt_persistence_failed',
      );
    }
  }

  Future<BattleSimulationAttemptFinishResult> finish({
    required BattleSimulationAttemptHandle attempt,
    required BattleSimulationAttemptOutcome outcome,
    String? replayId,
    String? reason,
    String? errorCode,
    String? engineRequestSchemaVersion,
    String? engineRequestHash,
    String? engineRequestCorrelationSource,
    Map<String, dynamic> result = const {},
    Map<String, dynamic> provenance = const {},
  }) async {
    try {
      final identity = battleSimulationIdentityFromResult(result);
      final sanitizedProvenance = sanitizeBattleReplayMetadata({
        ...provenance,
        if (result['status'] != null) 'engine_status': result['status'],
      });
      final update = await _pool.execute(
        Sql.named('''
          UPDATE battle_simulation_attempts
          SET outcome = @outcome,
              replay_id = CAST(@replayId AS uuid),
              outcome_reason = @reason,
              error_code = @errorCode,
              engine = COALESCE(@engine, engine),
              engine_version = COALESCE(@engineVersion, engine_version),
              engine_commit = COALESCE(@engineCommit, engine_commit),
              engine_build = COALESCE(@engineBuild, engine_build),
              engine_process_id = COALESCE(
                @engineProcessId,
                engine_process_id
              ),
              request_schema_version = COALESCE(
                @requestSchemaVersion,
                request_schema_version
              ),
              request_hash = COALESCE(@requestHash, request_hash),
              engine_request_correlation_source = COALESCE(
                @engineRequestCorrelationSource,
                engine_request_correlation_source
              ),
              events_truncated = @eventsTruncated,
              snapshots_truncated = @snapshotsTruncated,
              provenance = provenance || @provenance::jsonb,
              finished_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@attemptId AS uuid)
            AND user_id = CAST(@userId AS uuid)
            AND outcome IS NULL
          RETURNING id::text
          '''),
        parameters: {
          'attemptId': attempt.id,
          'userId': attempt.userId,
          'outcome': outcome.value,
          'replayId': replayId,
          'reason': sanitizeBattleReplayText(reason),
          'errorCode': sanitizeBattleReplayText(errorCode),
          ...identity,
          'requestSchemaVersion':
              engineRequestSchemaVersion ?? identity['requestSchemaVersion'],
          'requestHash': engineRequestHash ?? identity['requestHash'],
          'engineRequestCorrelationSource': engineRequestCorrelationSource,
          'provenance': jsonEncode(sanitizedProvenance),
        },
      );
      if (update.isEmpty) {
        return const BattleSimulationAttemptFinishResult.failed(
          'battle_attempt_not_open',
        );
      }
      return const BattleSimulationAttemptFinishResult.finished();
    } on BattleReplayPayloadException {
      return const BattleSimulationAttemptFinishResult.failed(
        'battle_attempt_metadata_invalid',
      );
    } catch (_) {
      return const BattleSimulationAttemptFinishResult.failed(
        'battle_attempt_persistence_failed',
      );
    }
  }
}

Map<String, dynamic> battleSimulationIdentityFromResult(
  Map<String, dynamic> result,
) {
  final metrics = _stringKeyedMap(result['metrics']);
  final processIdentity =
      result['sidecar_process_id'] ??
      result['engine_process_id'] ??
      result['process_id'];
  return {
    'engine': _nonEmpty(result['engine']),
    'engineVersion': _nonEmpty(result['engine_version']),
    'engineCommit': _nonEmpty(result['engine_commit']),
    'engineBuild':
        _nonEmpty(result['sidecar_build_identity']) ??
        _nonEmpty(result['engine_build']) ??
        _nonEmpty(result['build_id']),
    'engineProcessId': _nonEmpty(processIdentity),
    'requestSchemaVersion': _nonEmpty(result['request_schema_version']),
    'requestHash': _nonEmpty(result['request_hash']),
    'eventsTruncated':
        result['events_truncated'] == true ||
        metrics['events_truncated'] == true,
    'snapshotsTruncated':
        result['snapshots_truncated'] == true ||
        metrics['snapshots_truncated'] == true,
  };
}

Map<String, dynamic> _stringKeyedMap(Object? value) =>
    value is Map
        ? value.map((key, value) => MapEntry(key.toString(), value))
        : const {};

String? _nonEmpty(Object? value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
