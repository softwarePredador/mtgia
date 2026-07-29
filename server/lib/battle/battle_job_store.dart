import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';

import '../ai/battle_engine_config.dart';
import '../deck_validation_state_support.dart';
import 'battle_job_contract.dart';
import 'battle_request_correlation.dart';

const battleJobDefaultPerUserQuota = 3;
const battleJobDefaultGlobalQuota = 24;
const battleJobDefaultLease = Duration(seconds: 30);

const battleJobSelectColumns = '''
  id::text AS id,
  user_id::text AS user_id,
  status,
  stage,
  progress_current,
  progress_total,
  deck_a_id::text AS deck_a_id,
  deck_b_id::text AS deck_b_id,
  deck_hash_schema,
  deck_a_hash,
  deck_b_hash,
  request_schema_version,
  request_hash,
  request_payload,
  requested_engine,
  engine_lane,
  engine,
  engine_version,
  engine_commit,
  engine_build,
  engine_process_id,
  engine_process_started_at,
  engine_request_schema_version,
  engine_request_hash,
  engine_request_correlation_source,
  timeout_ms,
  attempt_count,
  attempt_id::text AS attempt_id,
  replay_id::text AS replay_id,
  idempotency_key,
  request_fingerprint,
  terminal_reason,
  error_code,
  claimed_at,
  started_at,
  cancel_requested_at,
  heartbeat_at,
  lease_expires_at,
  finished_at,
  created_at,
  updated_at
''';

const battleJobClaimSql = '''
  SELECT $battleJobSelectColumns
  FROM battle_jobs candidate
  WHERE candidate.status = 'queued'
    AND candidate.attempt_count < 100
    AND NOT EXISTS (
      SELECT 1
      FROM battle_jobs active
      WHERE (
          active.engine_lane = candidate.engine_lane
          OR active.engine_lane = 'auto'
          OR candidate.engine_lane = 'auto'
        )
        AND active.status IN ('claimed', 'running', 'cancel_pending')
    )
  ORDER BY candidate.created_at ASC, candidate.id ASC
  FOR UPDATE OF candidate SKIP LOCKED
  LIMIT 1
''';

const battleJobRecoverClaimedLeasesSql = '''
  UPDATE battle_jobs
  SET status = 'queued',
      stage = 'queued',
      lease_owner = NULL,
      lease_token = NULL,
      lease_expires_at = NULL,
      heartbeat_at = NULL,
      claimed_at = NULL,
      updated_at = CURRENT_TIMESTAMP
  WHERE status = 'claimed'
    AND lease_expires_at <= CURRENT_TIMESTAMP
    AND attempt_count < 100
''';

const battleJobFailExhaustedClaimedLeasesSql = '''
  UPDATE battle_jobs
  SET status = 'engine_error',
      stage = 'engine_error',
      terminal_reason = 'worker_claim_retry_exhausted',
      error_code = 'battle_job_claim_retry_exhausted',
      finished_at = CURRENT_TIMESTAMP,
      lease_owner = NULL,
      lease_token = NULL,
      lease_expires_at = NULL,
      updated_at = CURRENT_TIMESTAMP
  WHERE status = 'claimed'
    AND lease_expires_at <= CURRENT_TIMESTAMP
    AND attempt_count >= 100
''';

const battleJobFailExpiredRunningLeasesSql = '''
  UPDATE battle_jobs
  SET status = 'engine_error',
      stage = 'engine_error',
      terminal_reason = CASE
        WHEN status = 'cancel_pending'
        THEN 'cancel_unconfirmed_after_worker_lease_expired'
        ELSE 'worker_lease_expired_after_engine_start'
      END,
      error_code = 'battle_job_running_lease_expired',
      finished_at = CURRENT_TIMESTAMP,
      lease_owner = NULL,
      lease_token = NULL,
      lease_expires_at = NULL,
      updated_at = CURRENT_TIMESTAMP
  WHERE status IN ('running', 'cancel_pending')
    AND lease_expires_at <= CURRENT_TIMESTAMP
''';

class BattleJobQuotaPolicy {
  const BattleJobQuotaPolicy({
    this.perUserActiveLimit = battleJobDefaultPerUserQuota,
    this.globalActiveLimit = battleJobDefaultGlobalQuota,
  }) : assert(perUserActiveLimit > 0),
       assert(globalActiveLimit > 0),
       assert(perUserActiveLimit <= globalActiveLimit);

  final int perUserActiveLimit;
  final int globalActiveLimit;

  factory BattleJobQuotaPolicy.fromEnvironment(
    Map<String, String> environment,
  ) {
    int bounded(String key, int fallback, int maximum) {
      final parsed = int.tryParse(environment[key]?.trim() ?? '');
      if (parsed == null || parsed < 1 || parsed > maximum) return fallback;
      return parsed;
    }

    final perUserActiveLimit = bounded(
      'BATTLE_JOB_PER_USER_ACTIVE_LIMIT',
      battleJobDefaultPerUserQuota,
      100,
    );
    final configuredGlobalLimit = bounded(
      'BATTLE_JOB_GLOBAL_ACTIVE_LIMIT',
      battleJobDefaultGlobalQuota,
      1000,
    );
    return BattleJobQuotaPolicy(
      perUserActiveLimit: perUserActiveLimit,
      globalActiveLimit:
          configuredGlobalLimit < perUserActiveLimit
              ? perUserActiveLimit
              : configuredGlobalLimit,
    );
  }
}

class BattleJobListFilter {
  const BattleJobListFilter({this.limit = 50, this.status, this.deckId});

  final int limit;
  final BattleJobStatus? status;
  final String? deckId;
}

class BattleJobClaim {
  const BattleJobClaim({
    required this.job,
    required this.workerId,
    required this.leaseToken,
  });

  final BattleJob job;
  final String workerId;
  final String leaseToken;
}

class BattleJobHeartbeat {
  const BattleJobHeartbeat({
    required this.active,
    required this.cancelRequested,
    this.status,
  });

  final bool active;
  final bool cancelRequested;
  final BattleJobStatus? status;
}

class BattleJobTerminalUpdate {
  const BattleJobTerminalUpdate({
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

abstract interface class BattleJobStoreApi {
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  });

  Future<BattleJobCreateResult> create(
    BattleJobCreateCommand command, {
    required BattleJobQuotaPolicy quota,
  });

  Future<List<BattleJob>> list(
    String userId, {
    BattleJobListFilter filter = const BattleJobListFilter(),
  });

  Future<BattleJob?> get(String userId, String id);

  Future<BattleJobCancelResult?> cancel(String userId, String id);
}

abstract interface class BattleJobWorkerStore {
  Future<BattleJobClaim?> claimNext({
    required String workerId,
    Duration leaseDuration = battleJobDefaultLease,
  });

  Future<bool> markRunning(
    BattleJobClaim claim, {
    String stage = 'starting_engine',
  });

  Future<BattleJobHeartbeat> heartbeat(
    BattleJobClaim claim, {
    Duration leaseDuration = battleJobDefaultLease,
    String? stage,
    int? progressCurrent,
    int? progressTotal,
  });

  Future<bool> transitionTerminal(
    BattleJobClaim claim,
    BattleJobTerminalUpdate update,
  );

  Future<bool> markPersistenceError(
    BattleJobClaim claim, {
    required String errorCode,
    String? engine,
    String? engineProcessId,
    DateTime? engineProcessStartedAt,
  });
}

class BattleJobStore implements BattleJobStoreApi, BattleJobWorkerStore {
  const BattleJobStore(this._pool);

  final Pool _pool;

  @override
  Future<BattleJobDeckSnapshot?> loadDeckSnapshot({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          deck.id::text AS deck_id,
          deck.name AS deck_name,
          deck.format AS deck_format,
          deck.validation_state,
          deck.validation_reasons,
          card.name,
          card.set_code,
          card.collector_number,
          deck_card.quantity::int,
          deck_card.is_commander
        FROM decks deck
        JOIN deck_cards deck_card ON deck_card.deck_id = deck.id
        JOIN cards card ON card.id = deck_card.card_id
        WHERE deck.id = CAST(@deck_id AS uuid)
          AND deck.deleted_at IS NULL
          AND (
            deck.user_id = CAST(@user_id AS uuid)
            OR (CAST(@allow_public AS boolean) AND deck.is_public = TRUE)
          )
        ORDER BY
          deck_card.is_commander DESC,
          LOWER(card.name) ASC,
          COALESCE(card.oracle_id::text, '') ASC,
          COALESCE(card.scryfall_id::text, '') ASC,
          card.id::text ASC
      '''),
      parameters: {
        'deck_id': deckId,
        'user_id': userId,
        'allow_public': allowPublic,
      },
    );
    if (result.isEmpty) return null;
    final first = result.first.toColumnMap();
    final cards = result
        .map((row) {
          final value = row.toColumnMap();
          return <String, dynamic>{
            'name': value['name']?.toString() ?? '',
            'set_code': value['set_code']?.toString(),
            'collector_number': value['collector_number']?.toString(),
            'quantity': _int(value['quantity']),
            'is_commander': value['is_commander'] == true,
          };
        })
        .toList(growable: false);
    final payload = <String, dynamic>{
      'id': first['deck_id']?.toString() ?? deckId,
      'name': first['deck_name']?.toString() ?? deckId,
      'cards': cards,
    };
    return BattleJobDeckSnapshot(
      id: payload['id']! as String,
      name: payload['name']! as String,
      format: first['deck_format']?.toString().trim().toLowerCase() ?? '',
      validationState: normalizeDeckValidationState(first['validation_state']),
      validationReasons: normalizeDeckValidationReasons(
        first['validation_reasons'],
      ),
      cards: cards,
      hash: canonicalExternalBattleDeckHash(payload),
    );
  }

  @override
  Future<BattleJobCreateResult> create(
    BattleJobCreateCommand command, {
    required BattleJobQuotaPolicy quota,
  }) {
    return _pool.runTx((transaction) async {
      await transaction.execute(
        "SELECT pg_advisory_xact_lock(hashtext('manaloom:battle_jobs:create:v1'))",
      );

      final existing = await transaction.execute(
        Sql.named('''
          SELECT $battleJobSelectColumns
          FROM battle_jobs
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
        final job = BattleJob.fromRow(existing.first.toColumnMap());
        if (job.requestFingerprint != command.requestFingerprint) {
          throw const BattleJobIdempotencyConflictException();
        }
        return BattleJobCreateResult(job: job, created: false);
      }

      final counts = await transaction.execute(
        Sql.named('''
          SELECT
            COUNT(*) FILTER (
              WHERE user_id = CAST(@user_id AS uuid)
            )::int AS user_active,
            COUNT(*)::int AS global_active
          FROM battle_jobs
          WHERE status IN (
            'queued',
            'claimed',
            'running',
            'cancel_pending'
          )
        '''),
        parameters: {'user_id': command.userId},
      );
      final countRow = counts.first.toColumnMap();
      final userActive = _int(countRow['user_active']);
      final globalActive = _int(countRow['global_active']);
      if (userActive >= quota.perUserActiveLimit) {
        throw BattleJobQuotaExceededException(
          scope: 'user',
          limit: quota.perUserActiveLimit,
        );
      }
      if (globalActive >= quota.globalActiveLimit) {
        throw BattleJobQuotaExceededException(
          scope: 'global',
          limit: quota.globalActiveLimit,
        );
      }

      final inserted = await transaction.execute(
        Sql.named('''
          INSERT INTO battle_jobs (
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
            requested_engine,
            engine_lane,
            status,
            stage,
            timeout_ms,
            idempotency_key,
            request_fingerprint,
            quota_user_limit,
            quota_global_limit
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
            @requested_engine,
            @engine_lane,
            'queued',
            'queued',
            @timeout_ms,
            @idempotency_key,
            @request_fingerprint,
            @quota_user_limit,
            @quota_global_limit
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
          RETURNING $battleJobSelectColumns
        '''),
        parameters: {
          'id': command.id,
          'user_id': command.userId,
          'deck_a_id': command.deckA.id,
          'deck_b_id': command.deckB.id,
          'deck_hash_schema': externalBattleDeckHashSchema,
          'deck_a_hash': command.deckA.hash,
          'deck_b_hash': command.deckB.hash,
          'request_schema_version': battleJobRequestSchema,
          'request_hash': command.requestHash,
          'request_payload': jsonEncode(command.requestPayload),
          'requested_engine': command.requestedEngine,
          'engine_lane': command.engineLane,
          'timeout_ms': command.timeoutMs,
          'idempotency_key': command.idempotencyKey,
          'request_fingerprint': command.requestFingerprint,
          'quota_user_limit': quota.perUserActiveLimit,
          'quota_global_limit': quota.globalActiveLimit,
        },
      );
      if (inserted.isEmpty) {
        throw const BattleJobNotFoundException();
      }
      return BattleJobCreateResult(
        job: BattleJob.fromRow(inserted.first.toColumnMap()),
        created: true,
      );
    });
  }

  @override
  Future<List<BattleJob>> list(
    String userId, {
    BattleJobListFilter filter = const BattleJobListFilter(),
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT $battleJobSelectColumns
        FROM battle_jobs
        WHERE user_id = CAST(@user_id AS uuid)
          AND (
            CAST(@status AS text) IS NULL
            OR status = CAST(@status AS text)
          )
          AND (
            CAST(@deck_id AS text) IS NULL
            OR deck_a_id = CAST(@deck_id AS uuid)
            OR deck_b_id = CAST(@deck_id AS uuid)
          )
        ORDER BY created_at DESC, id DESC
        LIMIT @limit
      '''),
      parameters: {
        'user_id': userId,
        'status': filter.status?.value,
        'deck_id': filter.deckId,
        'limit': filter.limit.clamp(1, 100),
      },
    );
    return result
        .map((row) => BattleJob.fromRow(row.toColumnMap()))
        .toList(growable: false);
  }

  @override
  Future<BattleJob?> get(String userId, String id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT $battleJobSelectColumns
        FROM battle_jobs
        WHERE id = CAST(@id AS uuid)
          AND user_id = CAST(@user_id AS uuid)
        LIMIT 1
      '''),
      parameters: {'id': id, 'user_id': userId},
    );
    if (result.isEmpty) return null;
    return BattleJob.fromRow(result.first.toColumnMap());
  }

  @override
  Future<BattleJobCancelResult?> cancel(String userId, String id) {
    return _pool.runTx((transaction) async {
      final selected = await transaction.execute(
        Sql.named('''
          SELECT $battleJobSelectColumns
          FROM battle_jobs
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
          LIMIT 1
          FOR UPDATE
        '''),
        parameters: {'id': id, 'user_id': userId},
      );
      if (selected.isEmpty) return null;
      final current = BattleJob.fromRow(selected.first.toColumnMap());
      if (current.status.isTerminal) {
        throw BattleJobNotCancellableException(current);
      }
      if (current.status == BattleJobStatus.cancelPending) {
        return BattleJobCancelResult(job: current, accepted: true);
      }

      final queued = current.status == BattleJobStatus.queued;
      final updated = await transaction.execute(
        Sql.named('''
          UPDATE battle_jobs
          SET status = CASE
                WHEN status = 'queued' THEN 'cancelled'
                ELSE 'cancel_pending'
              END,
              stage = CASE
                WHEN status = 'queued' THEN 'cancelled'
                ELSE 'cancel_pending'
              END,
              cancel_requested_at = CURRENT_TIMESTAMP,
              finished_at = CASE
                WHEN status = 'queued' THEN CURRENT_TIMESTAMP
                ELSE NULL
              END,
              terminal_reason = CASE
                WHEN status = 'queued' THEN 'cancelled_before_claim'
                ELSE terminal_reason
              END,
              lease_owner = CASE
                WHEN status = 'queued' THEN NULL
                ELSE lease_owner
              END,
              lease_token = CASE
                WHEN status = 'queued' THEN NULL
                ELSE lease_token
              END,
              lease_expires_at = CASE
                WHEN status = 'queued' THEN NULL
                ELSE lease_expires_at
              END,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
            AND status IN ('queued', 'claimed', 'running')
          RETURNING $battleJobSelectColumns
        '''),
        parameters: {'id': id, 'user_id': userId},
      );
      if (updated.isEmpty) {
        throw const BattleJobPersistenceException(
          'battle_job_cancel_race',
          'Battle job changed while cancellation was requested.',
        );
      }
      return BattleJobCancelResult(
        job: BattleJob.fromRow(updated.first.toColumnMap()),
        accepted: !queued || current.status == BattleJobStatus.queued,
      );
    });
  }

  @override
  Future<BattleJobClaim?> claimNext({
    required String workerId,
    Duration leaseDuration = battleJobDefaultLease,
  }) {
    if (workerId.trim().isEmpty || workerId.length > 128) {
      throw ArgumentError.value(
        workerId,
        'workerId',
        'Must contain 1-128 chars.',
      );
    }
    if (leaseDuration <= Duration.zero) {
      throw ArgumentError.value(
        leaseDuration,
        'leaseDuration',
        'Must be positive.',
      );
    }

    return _pool.runTx((transaction) async {
      // PostgreSQL row skipping alone permits two concurrent transactions to
      // claim different queued rows for the same lane before either commits.
      // This short transaction lock serializes admission; active rows remain
      // the durable per-lane reservation after the transaction commits.
      await transaction.execute(
        "SELECT pg_advisory_xact_lock(hashtext('manaloom:battle_jobs:claim:v1'))",
      );
      await transaction.execute(battleJobFailExhaustedClaimedLeasesSql);
      await transaction.execute(battleJobRecoverClaimedLeasesSql);
      await transaction.execute(battleJobFailExpiredRunningLeasesSql);
      final selected = await transaction.execute(battleJobClaimSql);
      if (selected.isEmpty) return null;

      final job = BattleJob.fromRow(selected.first.toColumnMap());
      final leaseToken = generateBattleJobUuid();
      final claimed = await transaction.execute(
        Sql.named('''
          UPDATE battle_jobs
          SET status = 'claimed',
              stage = 'claimed',
              lease_owner = @worker_id,
              lease_token = CAST(@lease_token AS uuid),
              lease_expires_at = CURRENT_TIMESTAMP
                + (CAST(@lease_milliseconds AS bigint) * INTERVAL '1 millisecond'),
              heartbeat_at = CURRENT_TIMESTAMP,
              claimed_at = CURRENT_TIMESTAMP,
              attempt_count = attempt_count + 1,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
            AND status = 'queued'
          RETURNING $battleJobSelectColumns
        '''),
        parameters: {
          'id': job.id,
          'worker_id': workerId,
          'lease_token': leaseToken,
          'lease_milliseconds': leaseDuration.inMilliseconds,
        },
      );
      if (claimed.isEmpty) return null;
      return BattleJobClaim(
        job: BattleJob.fromRow(claimed.first.toColumnMap()),
        workerId: workerId,
        leaseToken: leaseToken,
      );
    });
  }

  @override
  Future<bool> markRunning(
    BattleJobClaim claim, {
    String stage = 'starting_engine',
  }) async {
    final updated = await _pool.execute(
      Sql.named('''
        UPDATE battle_jobs
        SET status = 'running',
            stage = @stage,
            started_at = COALESCE(started_at, CURRENT_TIMESTAMP),
            heartbeat_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = CAST(@id AS uuid)
          AND lease_owner = @worker_id
          AND lease_token = CAST(@lease_token AS uuid)
          AND status = 'claimed'
        RETURNING id
      '''),
      parameters: {
        'id': claim.job.id,
        'worker_id': claim.workerId,
        'lease_token': claim.leaseToken,
        'stage': stage,
      },
    );
    return updated.isNotEmpty;
  }

  @override
  Future<BattleJobHeartbeat> heartbeat(
    BattleJobClaim claim, {
    Duration leaseDuration = battleJobDefaultLease,
    String? stage,
    int? progressCurrent,
    int? progressTotal,
  }) async {
    if (leaseDuration <= Duration.zero) {
      throw ArgumentError.value(
        leaseDuration,
        'leaseDuration',
        'Must be positive.',
      );
    }
    final updated = await _pool.execute(
      Sql.named('''
        UPDATE battle_jobs
        SET stage = COALESCE(@stage, stage),
            progress_total = GREATEST(
              progress_total,
              COALESCE(@progress_total, progress_total)
            ),
            progress_current = LEAST(
              GREATEST(
                progress_current,
                COALESCE(@progress_current, progress_current)
              ),
              GREATEST(
                progress_total,
                COALESCE(@progress_total, progress_total)
              )
            ),
            heartbeat_at = CURRENT_TIMESTAMP,
            lease_expires_at = CURRENT_TIMESTAMP
              + (CAST(@lease_milliseconds AS bigint) * INTERVAL '1 millisecond'),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = CAST(@id AS uuid)
          AND lease_owner = @worker_id
          AND lease_token = CAST(@lease_token AS uuid)
          AND status IN ('claimed', 'running', 'cancel_pending')
        RETURNING status
      '''),
      parameters: {
        'id': claim.job.id,
        'worker_id': claim.workerId,
        'lease_token': claim.leaseToken,
        'stage': stage,
        'progress_current': progressCurrent,
        'progress_total': progressTotal,
        'lease_milliseconds': leaseDuration.inMilliseconds,
      },
    );
    if (updated.isEmpty) {
      return const BattleJobHeartbeat(active: false, cancelRequested: false);
    }
    final status = parseBattleJobStatus(updated.first[0]);
    return BattleJobHeartbeat(
      active: true,
      cancelRequested: status == BattleJobStatus.cancelPending,
      status: status,
    );
  }

  @override
  Future<bool> transitionTerminal(
    BattleJobClaim claim,
    BattleJobTerminalUpdate update,
  ) async {
    if (!update.status.isTerminal) {
      throw ArgumentError.value(
        update.status,
        'update.status',
        'Must be terminal.',
      );
    }
    if ((update.status == BattleJobStatus.completed ||
            update.status == BattleJobStatus.censored) &&
        (update.attemptId == null ||
            update.replayId == null ||
            update.engine == null ||
            update.engineProcessId == null ||
            update.engineProcessId!.trim().isEmpty ||
            update.engineRequestSchemaVersion == null ||
            update.engineRequestSchemaVersion!.trim().isEmpty ||
            update.engineRequestHash == null ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(update.engineRequestHash!) ||
            update.engineRequestCorrelationSource == null ||
            update.engineRequestCorrelationSource!.trim().isEmpty)) {
      throw const BattleJobPersistenceException(
        'battle_job_completed_without_replay',
        'A completed or censored Battle job requires replay, engine process, and request correlation.',
      );
    }

    final result = await _pool.execute(
      Sql.named('''
        UPDATE battle_jobs job
        SET status = @status,
            stage = @status,
            progress_current = CASE
              WHEN @status IN ('completed', 'censored')
              THEN progress_total
              ELSE progress_current
            END,
            engine = COALESCE(@engine, engine),
            engine_version = COALESCE(@engine_version, engine_version),
            engine_commit = COALESCE(@engine_commit, engine_commit),
            engine_build = COALESCE(@engine_build, engine_build),
            engine_process_id = COALESCE(
              @engine_process_id,
              engine_process_id
            ),
            engine_process_started_at = COALESCE(
              CAST(@engine_process_started_at AS timestamptz),
              engine_process_started_at
            ),
            engine_request_schema_version = COALESCE(
              @engine_request_schema_version,
              engine_request_schema_version
            ),
            engine_request_hash = COALESCE(
              @engine_request_hash,
              engine_request_hash
            ),
            engine_request_correlation_source = COALESCE(
              @engine_request_correlation_source,
              engine_request_correlation_source
            ),
            attempt_id = CAST(@attempt_id AS uuid),
            replay_id = CAST(@replay_id AS uuid),
            terminal_reason = @terminal_reason,
            error_code = @error_code,
            finished_at = CURRENT_TIMESTAMP,
            lease_owner = NULL,
            lease_token = NULL,
            lease_expires_at = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE job.id = CAST(@id AS uuid)
          AND job.lease_owner = @worker_id
          AND job.lease_token = CAST(@lease_token AS uuid)
          AND job.status IN ('claimed', 'running', 'cancel_pending')
          AND job.request_hash = @request_hash
          AND job.deck_a_hash = @deck_a_hash
          AND job.deck_b_hash = @deck_b_hash
          AND (
            CAST(@attempt_id AS text) IS NULL
            OR EXISTS (
              SELECT 1
              FROM battle_simulation_attempts attempt
              WHERE attempt.id = CAST(@attempt_id AS uuid)
                AND attempt.user_id = job.user_id
                AND attempt.deck_a_id = job.deck_a_id
                AND attempt.deck_b_id = job.deck_b_id
                AND attempt.deck_hash_schema = job.deck_hash_schema
                AND attempt.deck_a_hash = job.deck_a_hash
                AND attempt.deck_b_hash = job.deck_b_hash
                AND attempt.job_request_schema_version =
                  job.request_schema_version
                AND attempt.job_request_hash = job.request_hash
                AND (
                  CAST(@engine_request_hash AS text) IS NULL
                  OR (
                    attempt.request_schema_version =
                      @engine_request_schema_version
                    AND attempt.request_hash = @engine_request_hash
                    AND attempt.engine_request_correlation_source =
                      @engine_request_correlation_source
                  )
                )
                AND (
                  CAST(@replay_id AS text) IS NULL
                  OR (
                    attempt.replay_id = CAST(@replay_id AS uuid)
                    AND EXISTS (
                      SELECT 1
                      FROM battle_simulations replay
                      WHERE replay.id = CAST(@replay_id AS uuid)
                        AND replay.deck_a_id = job.deck_a_id
                        AND replay.deck_b_id = job.deck_b_id
                        AND replay.simulation_type = 'battle'
                    )
                  )
                )
            )
          )
        RETURNING job.id
      '''),
      parameters: {
        'id': claim.job.id,
        'worker_id': claim.workerId,
        'lease_token': claim.leaseToken,
        'status': update.status.value,
        'request_hash': update.requestHash,
        'deck_a_hash': update.deckAHash,
        'deck_b_hash': update.deckBHash,
        'engine': update.engine,
        'engine_version': update.engineVersion,
        'engine_commit': update.engineCommit,
        'engine_build': update.engineBuild,
        'engine_process_id': update.engineProcessId,
        'engine_process_started_at':
            update.engineProcessStartedAt?.toUtc().toIso8601String(),
        'engine_request_schema_version': update.engineRequestSchemaVersion,
        'engine_request_hash': update.engineRequestHash,
        'engine_request_correlation_source':
            update.engineRequestCorrelationSource,
        'attempt_id': update.attemptId,
        'replay_id': update.replayId,
        'terminal_reason': update.terminalReason,
        'error_code': update.errorCode,
      },
    );
    return result.isNotEmpty;
  }

  @override
  Future<bool> markPersistenceError(
    BattleJobClaim claim, {
    required String errorCode,
    String? engine,
    String? engineProcessId,
    DateTime? engineProcessStartedAt,
  }) {
    return transitionTerminal(
      claim,
      BattleJobTerminalUpdate(
        status: BattleJobStatus.persistenceError,
        requestHash: claim.job.requestHash,
        deckAHash: claim.job.deckAHash,
        deckBHash: claim.job.deckBHash,
        engine: engine,
        engineProcessId: engineProcessId,
        engineProcessStartedAt: engineProcessStartedAt,
        terminalReason: 'terminal_transition_persistence_failed',
        errorCode: errorCode,
      ),
    );
  }
}

String battleJobEngineLane(String requestedEngine) => requestedEngine;

String generateBattleJobUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String part(int start, int end) =>
      bytes
          .sublist(start, end)
          .map((value) => value.toRadixString(16).padLeft(2, '0'))
          .join();
  return '${part(0, 4)}-${part(4, 6)}-${part(6, 8)}-'
      '${part(8, 10)}-${part(10, 16)}';
}

int _int(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
