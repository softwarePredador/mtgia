import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';

import 'e2e_validation_policy.dart';

class AiGenerateJobStore {
  AiGenerateJobStore._();

  static const _jobTtl = Duration(minutes: 30);
  static const _cleanupInterval = Duration(minutes: 5);
  static const _executionTimeout = Duration(minutes: 4);
  static DateTime? _lastCleanupAt;
  static Future<String> create({
    required Pool pool,
    required String cacheKey,
    required String format,
    required String userId,
  }) async {
    final id = _generateId();
    await pool.execute(
      Sql.named('''
        INSERT INTO ai_generate_jobs (
          id, user_id, cache_key, format, status, stage, stage_number,
          total_stages, created_at, updated_at
        )
        VALUES (
          @id, CAST(@user_id AS uuid), @cache_key, @format, @status, @stage,
          @stage_number, @total_stages, NOW(), NOW()
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
      },
    );
    return id;
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
          AND updated_at <
            NOW() - (CAST(@timeout_seconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'id': id, 'timeout_seconds': _executionTimeout.inSeconds},
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

  static Future<void> progress(
    Pool pool,
    String id, {
    required String stage,
    required int stageNumber,
  }) async {
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'processing',
          stage = @stage,
          stage_number = @stage_number,
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'stage': stage, 'stage_number': stageNumber},
    );
  }

  static Future<void> complete(
    Pool pool,
    String id, {
    required int statusCode,
    required Map<String, dynamic> result,
  }) async {
    await pool.execute(
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
      '''),
      parameters: {
        'id': id,
        'result_status_code': statusCode,
        'result': jsonEncode(result),
      },
    );
  }

  static Future<void> fail(
    Pool pool,
    String id, {
    required String error,
  }) async {
    await pool.execute(
      Sql.named('''
        UPDATE ai_generate_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = @error,
          updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': id, 'error': error},
    );
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
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

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
