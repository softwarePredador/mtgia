import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/commercial_metrics_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/operational_alerts.dart';
import '../../../lib/request_metrics_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  try {
    final pool = context.read<Pool>();
    final requestMetrics = RequestMetricsService.instance.snapshot();
    final commercialMetrics = CommercialMetricsService(pool);

    final aiCost = await _loadAiCostProxy(pool);
    final aiOptimize = await _loadAiOptimizeOverview(pool);
    final aiJobs = await _loadAiJobOverview(pool);
    final aiHistory = await commercialMetrics.aiPerformanceHistory(
      days: 30,
      bucket: 'day',
    );
    final commercial = await commercialMetrics.snapshot(days: 30);
    final operationalAlerts = evaluateOperationalAlerts(
      requestMetrics: requestMetrics,
      aiJobs: aiJobs,
      aiCost: aiCost,
    );

    return Response.json(
      statusCode: HttpStatus.ok,
      body: {
        'status': 'ok',
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'dashboard': {
          'requests': requestMetrics,
          'ai_cost_proxy': aiCost,
          'ai_optimize': aiOptimize,
          'ai_jobs': aiJobs,
          'operational_alerts': operationalAlerts,
          'ai_history': aiHistory,
          'commercial': commercial,
        },
      },
    );
  } catch (e) {
    return internalServerError(
      'Failed to load operational dashboard',
      details: e,
    );
  }
}

Future<Map<String, dynamic>> _loadAiJobOverview(Pool pool) async {
  final hasGenerateJobs = await _tableExists(pool, 'ai_generate_jobs');
  final hasOptimizeJobs = await _tableExists(pool, 'ai_optimize_jobs');
  if (!hasGenerateJobs || !hasOptimizeJobs) {
    return {
      'status': 'not_initialized',
      'active_total': 0,
      'generate_active': 0,
      'optimize_active': 0,
    };
  }

  final result = await pool.execute('''
    WITH jobs AS (
      SELECT 'generate'::text AS kind, status, created_at, updated_at
      FROM ai_generate_jobs
      UNION ALL
      SELECT 'optimize'::text AS kind, status, created_at, updated_at
      FROM ai_optimize_jobs
    )
    SELECT
      COUNT(*) FILTER (
        WHERE status IN ('pending', 'processing')
      )::int AS active_total,
      COUNT(*) FILTER (
        WHERE kind = 'generate' AND status IN ('pending', 'processing')
      )::int AS generate_active,
      COUNT(*) FILTER (
        WHERE kind = 'optimize' AND status IN ('pending', 'processing')
      )::int AS optimize_active,
      COUNT(*) FILTER (
        WHERE status = 'completed'
          AND updated_at >= NOW() - INTERVAL '24 hours'
      )::int AS completed_24h,
      COUNT(*) FILTER (
        WHERE status = 'failed'
          AND updated_at >= NOW() - INTERVAL '24 hours'
      )::int AS failed_24h,
      COALESCE(
        EXTRACT(EPOCH FROM (
          NOW() - MIN(created_at) FILTER (
            WHERE status IN ('pending', 'processing')
          )
        ))::int,
        0
      ) AS oldest_active_seconds
    FROM jobs
  ''');
  final row = result.first.toColumnMap();
  return {
    'status': 'ok',
    'active_total': row['active_total'] ?? 0,
    'generate_active': row['generate_active'] ?? 0,
    'optimize_active': row['optimize_active'] ?? 0,
    'completed_24h': row['completed_24h'] ?? 0,
    'failed_24h': row['failed_24h'] ?? 0,
    'oldest_active_seconds': row['oldest_active_seconds'] ?? 0,
  };
}

Future<Map<String, dynamic>> _loadAiCostProxy(Pool pool) async {
  final hasTable = await _tableExists(pool, 'ai_logs');
  if (!hasTable) {
    return {
      'status': 'not_initialized',
      'table': 'ai_logs',
      'window_hours': 24,
      'input_tokens': 0,
      'output_tokens': 0,
      'total_calls': 0,
      'errors': 0,
    };
  }

  final result = await pool.execute(
    Sql.named('''
      SELECT
        COALESCE(SUM(input_tokens),0)::int AS input_tokens,
        COALESCE(SUM(output_tokens),0)::int AS output_tokens,
        COUNT(*)::int AS total_calls,
        SUM(CASE WHEN success THEN 0 ELSE 1 END)::int AS errors
      FROM ai_logs
      WHERE created_at >= NOW() - INTERVAL '24 hours'
        AND ${CommercialMetricsService.providerTelemetrySqlPredicate}
  '''),
  );

  final row = result.first.toColumnMap();

  return {
    'status': 'ok',
    'window_hours': 24,
    'input_tokens': row['input_tokens'] ?? 0,
    'output_tokens': row['output_tokens'] ?? 0,
    'total_calls': row['total_calls'] ?? 0,
    'errors': row['errors'] ?? 0,
  };
}

Future<Map<String, dynamic>> _loadAiOptimizeOverview(Pool pool) async {
  final hasTable = await _tableExists(pool, 'ai_optimize_fallback_telemetry');
  if (!hasTable) {
    return {
      'status': 'not_initialized',
      'table': 'ai_optimize_fallback_telemetry',
      'window_hours': 24,
      'request_count': 0,
      'triggered_count': 0,
      'applied_count': 0,
      'trigger_rate': 0.0,
      'apply_rate': 0.0,
    };
  }

  final result = await pool.execute(
    Sql.named('''
      SELECT
        COUNT(*)::int AS request_count,
        SUM(CASE WHEN triggered THEN 1 ELSE 0 END)::int AS triggered_count,
        SUM(CASE WHEN applied THEN 1 ELSE 0 END)::int AS applied_count
      FROM ai_optimize_fallback_telemetry
      WHERE created_at >= NOW() - INTERVAL '24 hours'
  '''),
  );

  final row = result.first.toColumnMap();
  final requestCount = (row['request_count'] as int?) ?? 0;
  final triggeredCount = (row['triggered_count'] as int?) ?? 0;
  final appliedCount = (row['applied_count'] as int?) ?? 0;

  return {
    'status': 'ok',
    'window_hours': 24,
    'request_count': requestCount,
    'triggered_count': triggeredCount,
    'applied_count': appliedCount,
    'trigger_rate': requestCount > 0 ? triggeredCount / requestCount : 0.0,
    'apply_rate': triggeredCount > 0 ? appliedCount / triggeredCount : 0.0,
  };
}

Future<bool> _tableExists(Pool pool, String table) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT COUNT(*)::int AS c
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = @table
    '''),
    parameters: {'table': table},
  );

  if (result.isEmpty) return false;
  return ((result.first.toColumnMap()['c'] as int?) ?? 0) > 0;
}
