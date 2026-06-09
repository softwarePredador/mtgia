import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';

import '../logger.dart';

/// Gerenciador de jobs assíncronos de otimização de deck.
///
/// Permite que o endpoint retorne 202 imediatamente enquanto o
/// processamento pesado (IA + múltiplos fallbacks) roda em background.
/// O cliente faz polling via GET /ai/optimize/jobs/:id.
///
/// Armazenamento in-memory (singleton). Jobs expiram após 30 minutos.
class OptimizeJobStore {
  OptimizeJobStore._();

  static const _jobTtl = Duration(minutes: 30);
  static const _cleanupInterval = Duration(minutes: 5);
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
  }) async {
    unawaited(
      _cleanupIfDue(pool).catchError(
        (Object error) => Log.w('Optimize job cleanup failed: $error'),
      ),
    );
    final id = _generateId();
    final job = OptimizeJob(
      id: id,
      deckId: deckId,
      archetype: archetype,
      userId: userId,
    );
    _memoryJobs[id] = job;
    unawaited(
      () async {
        try {
          await pool.execute(
            Sql.named('''
        INSERT INTO ai_optimize_jobs (
          id, deck_id, archetype, user_id, status, stage, stage_number,
          total_stages, result, error, quality_error, created_at, updated_at
        )
        VALUES (
          @id, CAST(@deck_id AS uuid), @archetype, CAST(@user_id AS uuid),
          @status, @stage, @stage_number, @total_stages,
          @result::jsonb, @error, @quality_error::jsonb, NOW(), NOW()
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
              'quality_error': job.qualityError == null
                  ? null
                  : jsonEncode(job.qualityError),
            },
          );
        } catch (error) {
          Log.w('Optimize job ${job.id} initial persistence failed: $error');
          // Memory-backed polling remains available for the current process.
        }
      }(),
    );
    return id;
  }

  /// Busca um job pelo ID.
  static Future<OptimizeJob?> get(Pool pool, String id) async {
    await _cleanupIfDue(pool);
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) return memoryJob;
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
          created_at,
          updated_at
        FROM ai_optimize_jobs
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return OptimizeJob.fromRow(result.first.toColumnMap());
  }

  /// Atualiza o progresso de um job.
  static Future<void> progress(
    Pool pool,
    String id, {
    required String stage,
    required int stageNumber,
  }) async {
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) {
      memoryJob
        ..status = 'processing'
        ..stage = stage
        ..stageNumber = stageNumber
        ..updatedAt = DateTime.now();
    }
    try {
      await pool.execute(
        Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'processing',
          stage = @stage,
          stage_number = @stage_number,
          updated_at = NOW()
        WHERE id = @id
      '''),
        parameters: {
          'id': id,
          'stage': stage,
          'stage_number': stageNumber,
        },
      );
    } catch (error) {
      Log.w('Optimize job $id progress persistence failed: $error');
      if (memoryJob == null) rethrow;
    }
  }

  /// Marca o job como concluído com o resultado.
  static Future<void> complete(
    Pool pool,
    String id, {
    required Map<String, dynamic> result,
  }) async {
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
    try {
      await pool.execute(
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
      '''),
        parameters: {
          'id': id,
          'result': jsonEncode(result),
        },
      );
    } catch (error) {
      Log.w('Optimize job $id completion persistence failed: $error');
      if (memoryJob == null) rethrow;
    }
  }

  /// Marca o job como falho.
  static Future<void> fail(
    Pool pool,
    String id, {
    required String error,
    Map<String, dynamic>? qualityError,
  }) async {
    final memoryJob = _memoryJobs[id];
    if (memoryJob != null) {
      memoryJob
        ..status = 'failed'
        ..stage = 'Erro'
        ..error = error
        ..qualityError = qualityError
        ..updatedAt = DateTime.now();
    }
    try {
      await pool.execute(
        Sql.named('''
        UPDATE ai_optimize_jobs
        SET
          status = 'failed',
          stage = 'Erro',
          error = @error,
          quality_error = @quality_error::jsonb,
          updated_at = NOW()
        WHERE id = @id
      '''),
        parameters: {
          'id': id,
          'error': error,
          'quality_error':
              qualityError == null ? null : jsonEncode(qualityError),
        },
      );
    } catch (error) {
      Log.w('Optimize job $id failure persistence failed: $error');
      if (memoryJob == null) rethrow;
    }
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
    await _cleanup(pool);
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
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
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  bool get isTerminal => status == 'completed' || status == 'failed';

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
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

Map<String, dynamic>? _decodeJsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
  }
  return null;
}
