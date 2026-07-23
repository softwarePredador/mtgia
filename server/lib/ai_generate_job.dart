import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';

import 'e2e_validation_policy.dart';
import 'ai_job_lifecycle.dart';

class AiGenerateJobStore {
  AiGenerateJobStore._();

  static const _jobTtl = Duration(minutes: 30);
  static const _cleanupInterval = Duration(minutes: 5);
  static const executionTimeout = Duration(minutes: 3);
  static DateTime? _lastCleanupAt;

  static Future<String> create({
    required Pool pool,
    required String cacheKey,
    required String format,
    required String userId,
    String? requestKey,
    String? requestFingerprint,
  }) async {
    final id = _generateId();
    await pool.execute(
      Sql.named('''
        INSERT INTO ai_generate_jobs (
          id, user_id, cache_key, format, status, stage, stage_number,
          total_stages, request_key, request_fingerprint,
          created_at, updated_at
        )
        VALUES (
          @id, CAST(@user_id AS uuid), @cache_key, @format, @status, @stage,
          @stage_number, @total_stages, @request_key, @request_fingerprint,
          NOW(), NOW()
        )
      '''),
      parameters: {
        'id': id,
        'user_id': userId,
        'cache_key': cacheKey,
        'format': format,
        'status': 'pending',
        'stage': 'Iniciando...',
        'stage_number': 0,
        'total_stages': 4,
        'request_key': requestKey,
        'request_fingerprint': requestFingerprint ?? cacheKey,
      },
    );
    return id;
  }

  static Future<AiJobCreation> createOrReuse({
    required Pool pool,
    required String cacheKey,
    required String format,
    required String userId,
    required String requestKey,
    required String requestFingerprint,
  }) async {
    final id = _generateId();
    final inserted = await pool.execute(
      Sql.named('''
        INSERT INTO ai_generate_jobs (
          id, user_id, cache_key, format, status, stage, stage_number,
          total_stages, request_key, request_fingerprint,
          created_at, updated_at
        )
        VALUES (
          @id, CAST(@user_id AS uuid), @cache_key, @format, 'pending',
          'Iniciando...', 0, 4, @request_key, @request_fingerprint,
          NOW(), NOW()
        )
        ON CONFLICT (user_id, request_key)
          WHERE user_id IS NOT NULL AND request_key IS NOT NULL
        DO NOTHING
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'user_id': userId,
        'cache_key': cacheKey,
        'format': format,
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
        FROM ai_generate_jobs
        WHERE user_id = CAST(@user_id AS uuid)
          AND request_key = @request_key
        LIMIT 1
      '''),
      parameters: {'user_id': userId, 'request_key': requestKey},
    );
    if (existing.isEmpty) {
      throw StateError('Generate idempotency conflict without persisted job.');
    }
    final row = existing.first.toColumnMap();
    if (row['request_fingerprint']?.toString() != requestFingerprint) {
      throw const AiJobIdempotencyConflict();
    }
    return AiJobCreation(
      jobId: row['id']!.toString(),
      requestKey: requestKey,
      isNew: false,
    );
  }

  static Future<AiGenerateJob?> get(Pool pool, String id) async {
    await _cleanupIfDue(pool);
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = 'A geração foi interrompida. Inicie uma nova tentativa.',
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
          AND created_at <
            NOW() - (CAST(@timeout_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'id': id, 'timeout_seconds': executionTimeout.inSeconds},
    );
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id,
          user_id::text AS user_id,
          cache_key,
          format,
          status,
          stage,
          stage_number,
          total_stages,
          result_status_code,
          result,
          error,
          request_key,
          request_fingerprint,
          cancelled_at,
          created_at,
          updated_at
        FROM ai_generate_jobs
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return AiGenerateJob.fromRow(result.first.toColumnMap());
  }

  static Future<AiGenerateJob?> latestForUser(
    Pool pool,
    String userId, {
    bool activeOnly = false,
  }) async {
    await _cleanupIfDue(pool);
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = 'A geração excedeu o tempo limite total. Inicie uma nova tentativa.',
          updated_at = NOW()
        WHERE user_id = CAST(@user_id AS uuid)
          AND status IN ('pending', 'processing')
          AND created_at <
            NOW() - (CAST(@timeout_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {
        'user_id': userId,
        'timeout_seconds': executionTimeout.inSeconds,
      },
    );
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id, user_id::text AS user_id, cache_key, format, status, stage,
          stage_number, total_stages, result_status_code, result, error,
          request_key, request_fingerprint, cancelled_at,
          created_at, updated_at
        FROM ai_generate_jobs
        WHERE user_id = CAST(@user_id AS uuid)
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
        'ttl_seconds': _jobTtl.inSeconds,
        'active_only': activeOnly,
      },
    );
    if (result.isEmpty) return null;
    return AiGenerateJob.fromRow(result.first.toColumnMap());
  }

  static Future<bool> isActive(Pool pool, String id) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT 1
        FROM ai_generate_jobs
        WHERE id = @id
          AND status IN ('pending', 'processing')
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  static Future<AiGenerateJob?> cancel(
    Pool pool,
    String id, {
    required String userId,
  }) async {
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET status = 'cancelled',
            stage = 'Cancelado',
            error = NULL,
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
    return job;
  }

  static Future<bool> progress(
    Pool pool,
    String id, {
    required String stage,
    required int stageNumber,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
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
    return updated.isNotEmpty;
  }

  static Future<bool> heartbeat(Pool pool, String id) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
          AND created_at >=
            NOW() - (CAST(@timeout_seconds AS int) * INTERVAL '1 second')
        RETURNING id
      '''),
      parameters: {'id': id, 'timeout_seconds': executionTimeout.inSeconds},
    );
    return updated.isNotEmpty;
  }

  static Future<bool> complete(
    Pool pool,
    String id, {
    required int statusCode,
    required Map<String, dynamic> result,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'completed',
          stage = 'Concluido',
          stage_number = total_stages,
          result_status_code = @result_status_code,
          result = @result::jsonb,
          error = NULL,
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
        RETURNING id
      '''),
      parameters: {
        'id': id,
        'result_status_code': statusCode,
        'result': jsonEncode(result),
      },
    );
    return updated.isNotEmpty;
  }

  static Future<bool> fail(
    Pool pool,
    String id, {
    required String error,
  }) async {
    final updated = await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = @error,
          updated_at = NOW()
        WHERE id = @id
          AND status IN ('pending', 'processing')
        RETURNING id
      '''),
      parameters: {'id': id, 'error': error},
    );
    return updated.isNotEmpty;
  }

  static Future<void> _cleanup(Pool pool) async {
    await pool.execute(
      Sql.named('''
        DELETE FROM ai_generate_jobs
        WHERE created_at < NOW() - (CAST(@ttl_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'ttl_seconds': _jobTtl.inSeconds},
    );
  }

  static Future<void> _cleanupIfDue(Pool pool) async {
    if (!shouldRunGlobalHousekeeping()) return;

    final now = DateTime.now();
    final last = _lastCleanupAt;
    if (last != null && now.difference(last) < _cleanupInterval) return;
    _lastCleanupAt = now;
    await _cleanup(pool);
  }

  static String _generateId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

class AiGenerateJob {
  AiGenerateJob({
    required this.id,
    required this.userId,
    required this.cacheKey,
    required this.format,
    this.status = 'pending',
    this.stage = 'Iniciando...',
    this.stageNumber = 0,
    this.totalStages = 4,
    this.resultStatusCode,
    this.result,
    this.error,
    this.requestKey,
    this.requestFingerprint,
    this.cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String cacheKey;
  final String format;
  final String status;
  final String stage;
  final int stageNumber;
  final int totalStages;
  final int? resultStatusCode;
  final Map<String, dynamic>? result;
  final String? error;
  final String? requestKey;
  final String? requestFingerprint;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AiGenerateJob.fromRow(Map<String, dynamic> row) {
    return AiGenerateJob(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      cacheKey: row['cache_key'] as String? ?? '',
      format: row['format'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      stage: row['stage'] as String? ?? 'Iniciando...',
      stageNumber: row['stage_number'] as int? ?? 0,
      totalStages: row['total_stages'] as int? ?? 4,
      resultStatusCode: row['result_status_code'] as int?,
      result: _decodeJsonMap(row['result']),
      error: row['error'] as String?,
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
    'status': status,
    'stage': stage,
    'stage_number': stageNumber,
    'total_stages': totalStages,
    'format': format,
    'cache_key': cacheKey,
    if (resultStatusCode != null) 'result_status_code': resultStatusCode,
    if (result != null) 'result': result,
    if (error != null) 'error': error,
    if (requestKey != null) 'request_key': requestKey,
    if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
    'progress': {
      'current': stageNumber,
      'total': totalStages,
      'ratio': totalStages <= 0 ? 0 : stageNumber / totalStages,
    },
    'can_cancel': status == 'pending' || status == 'processing',
    'can_resume': !isTerminal,
    'poll_url': '/ai/generate/jobs/$id',
    'cancel_url': '/ai/generate/jobs/$id',
    'job_timeout_ms': AiGenerateJobStore.executionTimeout.inMilliseconds,
    'heartbeat_at': updatedAt.toIso8601String(),
    'deadline_at':
        createdAt.add(AiGenerateJobStore.executionTimeout).toIso8601String(),
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
