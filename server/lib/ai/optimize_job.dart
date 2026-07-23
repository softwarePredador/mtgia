import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';

import '../e2e_validation_policy.dart';
import '../ai_job_lifecycle.dart';
import '../logger.dart';

/// Gerenciador de jobs assíncronos de otimização de deck.
///
/// Permite que o endpoint retorne 202 imediatamente enquanto o
/// processamento pesado (IA + múltiplos fallbacks) roda em background.
/// O cliente faz polling via GET /ai/optimize/jobs/:id.
///
/// PostgreSQL é a fonte de verdade; o mapa local é apenas um cache do processo.
/// Jobs expiram após 30 minutos.
class OptimizeJobStore {
  OptimizeJobStore._();

  static const _jobTtl = Duration(minutes: 30);
  static const _cleanupInterval = Duration(minutes: 5);
  static const executionTimeout = Duration(minutes: 6);
  static final Map<String, OptimizeJob> _memoryJobs = <String, OptimizeJob>{};
  static DateTime? _lastCleanupAt;

  @visibleForTesting
  static void reset() {
    _memoryJobs.clear();
    _lastCleanupAt = null;
  }

  /// Cria um novo job e retorna seu ID.
  static Future<String> create({
    required Pool pool,
    required String deckId,
    required String archetype,
    required String userId,
    String? requestKey,
    String? requestFingerprint,
  }) async {
    unawaited(
      _cleanupIfDue(pool).catchError(
        (Object error) =>
            Log.w('Optimize job cleanup failed type=${error.runtimeType}'),
      ),
    );
    final id = _generateId();
    final job = OptimizeJob(
      id: id,
      deckId: deckId,
      archetype: archetype,
      userId: userId,
    );
    await pool.execute(
      Sql.named('''
        INSERT INTO ai_optimize_jobs (
          id, deck_id, archetype, user_id, status, stage, stage_number,
          total_stages, result, error, quality_error,
          request_key, request_fingerprint, created_at, updated_at
        )
        VALUES (
          @id, CAST(@deck_id AS uuid), @archetype, CAST(@user_id AS uuid),
          @status, @stage, @stage_number, @total_stages,
          @result::jsonb, @error, @quality_error::jsonb,
          @request_key, @request_fingerprint, NOW(), NOW()
        )
      '''),
      parameters: {
        'id': job.id,
        'deck_id': job.deckId,
        'archetype': job.archetype,
        'user_id': job.userId,
        'status': job.status,
        'stage': job.stage,
        'stage_number': job.stageNumber,
        'total_stages': job.totalStages,
        'result': job.result == null ? null : jsonEncode(job.result),
        'error': job.error,
        'quality_error':
            job.qualityError == null ? null : jsonEncode(job.qualityError),
        'request_key': requestKey,
        'request_fingerprint': requestFingerprint,
      },
    );
    _memoryJobs[id] = job;
    return id;
  }

  static Future<AiJobCreation> createOrReuse({
    required Pool pool,
    required String deckId,
    required String archetype,
    required String userId,
    required String requestKey,
    required String requestFingerprint,
  }) async {
    unawaited(
      _cleanupIfDue(pool).catchError(
        (Object error) =>
            Log.w('Optimize job cleanup failed type=${error.runtimeType}'),
      ),
    );
    final id = _generateId();
    final inserted = await pool.execute(
      Sql.named('''
        INSERT INTO ai_optimize_jobs (
          id, deck_id, archetype, user_id, status, stage, stage_number,
          total_stages, request_key, request_fingerprint,
          created_at, updated_at
        )
        VALUES (
          @id, CAST(@deck_id AS uuid), @archetype, CAST(@user_id AS uuid),
          'pending', 'Iniciando...', 0, 6, @request_key,
          @request_fingerprint, NOW(), NOW()
        )
        ON CONFLICT (user_id, request_key)
          WHERE user_id IS NOT NULL AND request_key IS NOT NULL
        DO NOTHING
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'deck_id': deckId,
        'archetype': archetype,
        'user_id': userId,
        'request_key': requestKey,
        'request_fingerprint': requestFingerprint,
      },
    );
    if (inserted.isNotEmpty) {
      return AiJobCreation(jobId: id, requestKey: requestKey, isNew: true);
    }

    final existing = await pool.execute(
      Sql.named('''
        SELECT id, request_fingerprint
        FROM ai_optimize_jobs
        WHERE user_id = CAST(@user_id AS uuid)
          AND request_key = @request_key
        LIMIT 1
      '''),
      parameters: {'user_id': userId, 'request_key': requestKey},
    );
    if (existing.isEmpty) {
      throw StateError('Optimize idempotency conflict without persisted job.');
    }
    final row = existing.first.toColumnMap();
    if (row['request_fingerprint']?.toString() != requestFingerprint) {
      throw const AiJobIdempotencyConflict();
    }
    final existingId = row['id']!.toString();
    final persisted = await get(pool, existingId);
    if (persisted != null) _memoryJobs[existingId] = persisted;
    return AiJobCreation(
      jobId: existingId,
      requestKey: requestKey,
      isNew: false,
    );
  }

  /// Busca um job pelo ID.
  static Future<OptimizeJob?> get(Pool pool, String id) async {
    await _cleanupIfDue(pool);
    await pool.execute(
      Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = 'A otimização foi interrompida. Inicie uma nova tentativa.',
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
          AND updated_at <
            NOW() - (CAST(@timeout_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'id': id, 'timeout_seconds': executionTimeout.inSeconds},
    );
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id,
          deck_id::text AS deck_id,
          archetype,
          user_id::text AS user_id,
          status,
          stage,
          stage_number,
          total_stages,
          result,
          error,
          quality_error,
          request_key,
          request_fingerprint,
          cancelled_at,
          created_at,
          updated_at
        FROM ai_optimize_jobs
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    final persistedJob = OptimizeJob.fromRow(result.first.toColumnMap());
    _memoryJobs[id] = persistedJob;
    return persistedJob;
  }

  static Future<OptimizeJob?> latestForUser(
    Pool pool,
    String userId, {
    String? deckId,
    bool activeOnly = false,
  }) async {
    await _cleanupIfDue(pool);
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id, deck_id::text AS deck_id, archetype,
          user_id::text AS user_id, status, stage, stage_number,
          total_stages, result, error, quality_error,
          request_key, request_fingerprint, cancelled_at,
          created_at, updated_at
        FROM ai_optimize_jobs
        WHERE user_id = CAST(@user_id AS uuid)
          AND (
            CAST(@deck_id AS text) IS NULL
            OR deck_id = CAST(@deck_id AS uuid)
          )
          AND created_at >=
            NOW() - (CAST(@ttl_seconds AS int) * INTERVAL '1 second')
          AND (
            CAST(@active_only AS boolean) = FALSE
            OR status IN ('pending', 'processing')
          )
        ORDER BY updated_at DESC, created_at DESC
        LIMIT 1
      '''),
      parameters: {
        'user_id': userId,
        'deck_id': deckId,
        'ttl_seconds': _jobTtl.inSeconds,
        'active_only': activeOnly,
      },
    );
    if (result.isEmpty) return null;
    final job = OptimizeJob.fromRow(result.first.toColumnMap());
    _memoryJobs[job.id] = job;
    return job;
  }

  static Future<OptimizeJob?> cancel(
    Pool pool,
    String id, {
    required String userId,
  }) async {
    await pool.execute(
      Sql.named('''
        UPDATE ai_optimize_jobs
        SET status = 'cancelled',
            stage = 'Cancelado',
            error = NULL,
            quality_error = NULL,
            cancelled_at = NOW(),
            updated_at = NOW()
        WHERE id = @id
          AND user_id = CAST(@user_id AS uuid)
          AND status IN ('pending', 'processing')
      '''),
      parameters: {'id': id, 'user_id': userId},
    );
    final job = await get(pool, id);
    if (job == null || job.userId != userId) return null;
    _memoryJobs[id] = job;
    return job;
  }

  /// Atualiza o progresso de um job.
  static Future<bool> progress(
    Pool pool,
    String id, {
    required String stage,
    required int stageNumber,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'processing',
          stage = @stage,
          stage_number = @stage_number,
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
        RETURNING id
      '''),
      parameters: {'id': id, 'stage': stage, 'stage_number': stageNumber},
    );
    if (updated.isEmpty) return false;
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) {
      memoryJob
        ..status = 'processing'
        ..stage = stage
        ..stageNumber = stageNumber
        ..updatedAt = DateTime.now();
    }
    return true;
  }

  /// Marca o job como concluído com o resultado.
  static Future<bool> complete(
    Pool pool,
    String id, {
    required Map<String, dynamic> result,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'completed',
          stage = 'Concluído',
          result = @result::jsonb,
          error = NULL,
          quality_error = NULL,
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
        RETURNING id
      '''),
      parameters: {'id': id, 'result': jsonEncode(result)},
    );
    if (updated.isEmpty) return false;
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) {
      memoryJob
        ..status = 'completed'
        ..stage = 'Concluído'
        ..result = result
        ..error = null
        ..qualityError = null
        ..updatedAt = DateTime.now();
    }
    return true;
  }

  /// Marca o job como falho.
  static Future<bool> fail(
    Pool pool,
    String id, {
    required String error,
    Map<String, dynamic>? qualityError,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = @error,
          quality_error = @quality_error::jsonb,
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'error': error,
        'quality_error': qualityError == null ? null : jsonEncode(qualityError),
      },
    );
    if (updated.isEmpty) return false;
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) {
      memoryJob
        ..status = 'failed'
        ..stage = 'Erro'
        ..error = error
        ..qualityError = qualityError
        ..updatedAt = DateTime.now();
    }
    return true;
  }

  /// Remove jobs com mais de 30 minutos para não vazar memória.
  static Future<void> _cleanupIfDue(Pool pool) async {
    final now = DateTime.now();
    final last = _lastCleanupAt;
    if (last != null && now.difference(last) < _cleanupInterval) {
      return;
    }
    _lastCleanupAt = now;
    _memoryJobs.removeWhere(
      (_, job) => job.createdAt.isBefore(now.subtract(_jobTtl)),
    );
    if (shouldRunGlobalHousekeeping()) {
      await _cleanup(pool);
    }
  }

  static Future<void> _cleanup(Pool pool) async {
    await pool.execute(
      Sql.named('''
        DELETE FROM ai_optimize_jobs
        WHERE created_at < NOW() - (CAST(@ttl_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'ttl_seconds': _jobTtl.inSeconds},
    );
  }

  static String _generateId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// Representa um job de otimização em andamento.
class OptimizeJob {
  final String id;
  final String deckId;
  final String archetype;
  final String userId;

  String status; // pending, processing, completed, failed
  String stage;
  int stageNumber;
  final int totalStages;

  Map<String, dynamic>? result;
  String? error;
  Map<String, dynamic>? qualityError;
  String? requestKey;
  String? requestFingerprint;
  DateTime? cancelledAt;

  final DateTime createdAt;
  DateTime updatedAt;

  OptimizeJob({
    required this.id,
    required this.deckId,
    required this.archetype,
    required this.userId,
    this.status = 'pending',
    this.stage = 'Iniciando...',
    this.stageNumber = 0,
    this.totalStages = 6,
    this.result,
    this.error,
    this.qualityError,
    this.requestKey,
    this.requestFingerprint,
    this.cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory OptimizeJob.fromRow(Map<String, dynamic> row) {
    return OptimizeJob(
      id: row['id'] as String? ?? '',
      deckId: row['deck_id'] as String? ?? '',
      archetype: row['archetype'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      stage: row['stage'] as String? ?? 'Iniciando...',
      stageNumber: row['stage_number'] as int? ?? 0,
      totalStages: row['total_stages'] as int? ?? 6,
      result: _decodeJsonMap(row['result']),
      error: row['error'] as String?,
      qualityError: _decodeJsonMap(row['quality_error']),
      requestKey: row['request_key'] as String?,
      requestFingerprint: row['request_fingerprint'] as String?,
      cancelledAt: row['cancelled_at'] as DateTime?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'cancelled';

  Map<String, dynamic> toJson() => {
    'job_id': id,
    'deck_id': deckId,
    'archetype': archetype,
    'status': status,
    'stage': stage,
    'stage_number': stageNumber,
    'total_stages': totalStages,
    if (result != null) 'result': result,
    if (error != null) 'error': error,
    if (qualityError != null) 'quality_error': qualityError,
    if (requestKey != null) 'request_key': requestKey,
    if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
    'progress': {
      'current': stageNumber,
      'total': totalStages,
      'ratio': totalStages <= 0 ? 0 : stageNumber / totalStages,
    },
    'can_cancel': status == 'pending' || status == 'processing',
    'can_resume': !isTerminal,
    'poll_url': '/ai/optimize/jobs/$id',
    'cancel_url': '/ai/optimize/jobs/$id',
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

Map<String, dynamic>? _decodeJsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
  }
  return null;
}
