import 'package:postgres/postgres.dart';

import 'ai_telemetry_contract.dart';
import 'analytics/activation_kpi.dart';
import 'plan_service.dart';

class CommercialMetricsService {
  const CommercialMetricsService(this.pool);

  final Pool pool;

  static const providerTelemetrySqlPredicate = aiProviderTelemetrySqlPredicate;

  static bool isProviderTelemetryEndpoint(String endpoint) =>
      isAiProviderTelemetryEndpoint(endpoint);

  static bool isPlanActionTelemetryEndpoint(String endpoint) =>
      isAiPlanActionTelemetryEndpoint(endpoint);

  Future<Map<String, dynamic>> snapshot({int days = 30}) async {
    final safeDays = normalizeWindowDays(days);
    final hasAiLogs = await _tableExists('ai_logs');
    final hasUserPlans = await _tableExists('user_plans');
    final hasReports = await _tableExists('shared_deck_reports');
    final hasPostGame = await _tableExists('post_game_notes');

    final activation = await activationKpi(days: safeDays);
    final guardrails = await activationGuardrails(days: safeDays);
    final ai = hasAiLogs ? await _aiPerformance(safeDays) : _missing('ai_logs');
    final plans = hasUserPlans ? await _planMix() : _missing('user_plans');
    final reports =
        hasReports
            ? await _sharedReports(safeDays)
            : _missing('shared_deck_reports');
    final retention =
        hasPostGame ? await _retention(safeDays) : _missing('post_game_notes');

    return {
      'status': 'ok',
      'window_days': safeDays,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'activation': activation,
      'guardrails': guardrails,
      'ai_performance': ai,
      'ai_performance_history':
          hasAiLogs
              ? await aiPerformanceHistory(days: safeDays, bucket: 'day')
              : _missing('ai_logs'),
      'ai_action_usage':
          hasAiLogs ? await _aiActionUsage(safeDays) : _missing('ai_logs'),
      'plan_mix': plans,
      'shareable_reports': reports,
      'retention': retention,
    };
  }

  static int normalizeWindowDays(int days) => days.clamp(1, 90);

  static String normalizeHistoryBucket(String? bucket) {
    final normalized = bucket?.trim().toLowerCase();
    return normalized == 'hour' ? 'hour' : 'day';
  }

  static int normalizeHistoryWindowDays(int days, {String bucket = 'day'}) {
    final normalizedBucket = normalizeHistoryBucket(bucket);
    final maxDays = normalizedBucket == 'hour' ? 7 : 90;
    return days.clamp(1, maxDays);
  }

  Future<Map<String, dynamic>> aiPerformanceHistory({
    int days = 30,
    String bucket = 'day',
  }) async {
    final normalizedBucket = normalizeHistoryBucket(bucket);
    final safeDays = normalizeHistoryWindowDays(days, bucket: normalizedBucket);
    final hasAiLogs = await _tableExists('ai_logs');
    if (!hasAiLogs) return _missing('ai_logs');

    final result = await pool.execute(
      Sql.named('''
        SELECT
          date_trunc('$normalizedBucket', created_at) AS period_start,
          CASE
            WHEN endpoint LIKE 'provider:%' THEN endpoint
            ELSE 'provider:' || endpoint
          END AS endpoint,
          COUNT(*)::int AS request_count,
          SUM(CASE WHEN success THEN 0 ELSE 1 END)::int AS error_count,
          ROUND(AVG(latency_ms))::int AS avg_latency_ms,
          COALESCE(
            percentile_disc(0.95) WITHIN GROUP (ORDER BY latency_ms),
            0
          )::int AS p95_latency_ms,
          COALESCE(SUM(COALESCE(input_tokens, 0)), 0)::int AS input_tokens,
          COALESCE(SUM(COALESCE(output_tokens, 0)), 0)::int AS output_tokens
        FROM ai_logs
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
          AND $providerTelemetrySqlPredicate
        GROUP BY
          period_start,
          CASE
            WHEN endpoint LIKE 'provider:%' THEN endpoint
            ELSE 'provider:' || endpoint
          END
        ORDER BY period_start ASC, endpoint ASC
      '''),
      parameters: {'days': safeDays},
    );

    final periodsByStart = <String, Map<String, dynamic>>{};
    var totalRequests = 0;
    var totalErrors = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;

    for (final row in result) {
      final periodStart = _dateIso(row[0]);
      final endpoint = row[1]?.toString() ?? 'unknown';
      final requestCount = (row[2] as int?) ?? 0;
      final errorCount = (row[3] as int?) ?? 0;
      final inputTokens = (row[6] as int?) ?? 0;
      final outputTokens = (row[7] as int?) ?? 0;

      totalRequests += requestCount;
      totalErrors += errorCount;
      totalInputTokens += inputTokens;
      totalOutputTokens += outputTokens;

      final period = periodsByStart.putIfAbsent(
        periodStart,
        () => {
          'period_start': periodStart,
          'request_count': 0,
          'error_count': 0,
          'total_tokens': 0,
          'endpoints': <Map<String, dynamic>>[],
        },
      );
      period['request_count'] = (period['request_count'] as int) + requestCount;
      period['error_count'] = (period['error_count'] as int) + errorCount;
      period['total_tokens'] =
          (period['total_tokens'] as int) + inputTokens + outputTokens;
      (period['endpoints'] as List<Map<String, dynamic>>).add({
        'endpoint': endpoint,
        'request_count': requestCount,
        'error_count': errorCount,
        'error_rate': requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
        'avg_latency_ms': (row[4] as int?) ?? 0,
        'p95_latency_ms': (row[5] as int?) ?? 0,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
      });
    }

    final periods =
        periodsByStart.values.map((period) {
          final requestCount = period['request_count'] as int;
          final errorCount = period['error_count'] as int;
          return {
            ...period,
            'error_rate':
                requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
          };
        }).toList();

    return {
      'status': 'ok',
      'bucket': normalizedBucket,
      'window_days': safeDays,
      'period_count': periods.length,
      'totals': {
        'request_count': totalRequests,
        'error_count': totalErrors,
        'error_rate':
            totalRequests > 0 ? _ratio(totalErrors, totalRequests) : 0.0,
        'input_tokens': totalInputTokens,
        'output_tokens': totalOutputTokens,
        'total_tokens': totalInputTokens + totalOutputTokens,
      },
      'periods': periods,
    };
  }

  Map<String, dynamic> _missing(String table) => {
    'status': 'not_initialized',
    'table': table,
  };

  /// BT-KPI-001 (D-47): coortes por semana de cadastro, ativação em 24 h,
  /// volta na segunda semana, loops de valor e funil, sempre em usuários
  /// distintos (`lib/analytics/activation_kpi.dart`).
  Future<Map<String, dynamic>> activationKpi({int days = 30}) async {
    final safeDays = normalizeWindowDays(days);
    if (!await _tableExists('users') || !await _tableExists('decks')) {
      return _missing('users');
    }
    final existing = <String>{
      for (final table in activationKpiOptionalTables())
        if (await _tableExists(table)) table,
    };

    final cohortRows = await pool.execute(
      Sql.named(activationKpiCohortSql(existing)),
      parameters: {'days': safeDays},
    );
    final funnelUsers = <String, Map<String, int>>{};
    if (existing.contains('activation_funnel_events')) {
      final funnelRows = await pool.execute(
        Sql.named(activationKpiFunnelSql()),
        parameters: {'days': safeDays},
      );
      for (final row in funnelRows) {
        final columns = row.toColumnMap();
        funnelUsers.putIfAbsent(
              columns['cohort_week'] as String,
              () => <String, int>{},
            )[columns['event_name'] as String] =
            columns['users'] as int;
      }
    }

    final totals = <String, int>{};
    final totalFunnel = <String, int>{};
    final cohorts = <Map<String, Object?>>[];
    for (final row in cohortRows) {
      final columns = row.toColumnMap();
      final week = columns['cohort_week'] as String;
      final counts = <String, int>{
        for (final counter in activationKpiCohortCounters)
          counter: columns[counter] as int,
      };
      counts.forEach(
        (counter, value) => totals[counter] = (totals[counter] ?? 0) + value,
      );
      final weekFunnel = funnelUsers[week] ?? const <String, int>{};
      weekFunnel.forEach(
        (event, users) =>
            totalFunnel[event] = (totalFunnel[event] ?? 0) + users,
      );
      cohorts.add(
        activationKpiCohortJson(
          cohortWeek: week,
          counts: counts,
          funnelUsers: weekFunnel,
        ),
      );
    }

    return {
      'status': 'ok',
      'window_days': safeDays,
      'definition': activationKpiDefinition(existing),
      'totals': activationKpiCohortJson(
        cohortWeek: null,
        counts: totals,
        funnelUsers: totalFunnel,
      ),
      'cohorts': cohorts,
    };
  }

  /// BT-KPI-001 (D-47): guardrails de custo de IA e de taxa de erro na
  /// janela, com os limites versionados em `lib/analytics/activation_kpi.dart`.
  Future<Map<String, dynamic>> activationGuardrails({int days = 30}) async {
    final safeDays = normalizeWindowDays(days);
    final items = <Map<String, Object?>>[];

    if (await _tableExists('ai_logs')) {
      final errors =
          (await pool.execute(
            Sql.named(activationKpiAiErrorSql),
            parameters: {'days': safeDays},
          )).first.toColumnMap();
      final calls = errors['calls'] as int;
      final failedCalls = errors['errors'] as int;
      items.add(
        evaluateActivationKpiGuardrail(
          id: 'ai_provider_error_rate',
          observed: activationKpiRate(failedCalls, calls),
          sample: calls,
          minimumSample: activationKpiErrorRateMinimumSample,
          warningAt: activationKpiErrorRateWarning,
          criticalAt: activationKpiErrorRateCritical,
          extra: {'errors': failedCalls},
        ),
      );

      final actions =
          (await pool.execute(
            Sql.named(activationKpiAiActionsSql),
            parameters: {'days': safeDays},
          )).first.toColumnMap();
      final aiUsers = actions['users'] as int;
      final completedActions = actions['actions'] as int;
      items.add(
        evaluateActivationKpiGuardrail(
          id: 'ai_actions_per_ai_user_30d',
          observed: activationKpiAiActionsPer30Days(
            actions: completedActions,
            users: aiUsers,
            windowDays: safeDays,
          ),
          sample: aiUsers,
          minimumSample: 1,
          warningAt: activationKpiAiActionsWarningAt(),
          criticalAt: activationKpiAiActionsCriticalAt(),
          extra: {
            'actions': completedActions,
            'monthly_cap': PlanService.freeBetaAiMonthlyOperationalLimit,
          },
        ),
      );
    }

    if (await _tableExists('ai_generate_requests')) {
      final generate =
          (await pool.execute(
            Sql.named(activationKpiGenerateFailureSql),
            parameters: {'days': safeDays},
          )).first.toColumnMap();
      final finished = generate['finished'] as int;
      final failed = generate['failed'] as int;
      items.add(
        evaluateActivationKpiGuardrail(
          id: 'generate_failure_rate',
          observed: activationKpiRate(failed, finished),
          sample: finished,
          minimumSample: activationKpiErrorRateMinimumSample,
          warningAt: activationKpiErrorRateWarning,
          criticalAt: activationKpiErrorRateCritical,
          extra: {'failed': failed},
        ),
      );
    }

    return {
      'status': activationKpiGuardrailsStatus(items),
      'version': activationKpiGuardrailsVersion,
      'window_days': safeDays,
      'items': items,
    };
  }

  Future<Map<String, dynamic>> _aiPerformance(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          CASE
            WHEN endpoint LIKE 'provider:%' THEN endpoint
            ELSE 'provider:' || endpoint
          END AS endpoint,
          COUNT(*)::int AS request_count,
          SUM(CASE WHEN success THEN 0 ELSE 1 END)::int AS error_count,
          ROUND(AVG(latency_ms))::int AS avg_latency_ms,
          COALESCE(
            percentile_disc(0.95) WITHIN GROUP (ORDER BY latency_ms),
            0
          )::int AS p95_latency_ms,
          COALESCE(SUM(COALESCE(input_tokens, 0)), 0)::int AS input_tokens,
          COALESCE(SUM(COALESCE(output_tokens, 0)), 0)::int AS output_tokens
        FROM ai_logs
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
          AND $providerTelemetrySqlPredicate
        GROUP BY
          CASE
            WHEN endpoint LIKE 'provider:%' THEN endpoint
            ELSE 'provider:' || endpoint
          END
        ORDER BY request_count DESC, endpoint ASC
      '''),
      parameters: {'days': days},
    );

    var totalRequests = 0;
    var totalErrors = 0;
    var totalTokens = 0;
    final endpoints = <Map<String, dynamic>>[];

    for (final row in result) {
      final requestCount = (row[1] as int?) ?? 0;
      final errorCount = (row[2] as int?) ?? 0;
      final inputTokens = (row[5] as int?) ?? 0;
      final outputTokens = (row[6] as int?) ?? 0;
      totalRequests += requestCount;
      totalErrors += errorCount;
      totalTokens += inputTokens + outputTokens;
      endpoints.add({
        'endpoint': row[0],
        'request_count': requestCount,
        'error_count': errorCount,
        'error_rate': requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
        'avg_latency_ms': (row[3] as int?) ?? 0,
        'p95_latency_ms': (row[4] as int?) ?? 0,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
      });
    }

    return {
      'status': 'ok',
      'request_count': totalRequests,
      'error_count': totalErrors,
      'error_rate':
          totalRequests > 0 ? _ratio(totalErrors, totalRequests) : 0.0,
      'total_tokens': totalTokens,
      'endpoints': endpoints,
    };
  }

  Future<Map<String, dynamic>> _aiActionUsage(int days) async {
    final completedResult = await pool.execute(
      Sql.named('''
        SELECT
          SUBSTRING(endpoint FROM 6) AS action,
          COUNT(*)::int AS completed_count
        FROM ai_logs
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
          AND endpoint LIKE 'plan:%'
          AND success = TRUE
        GROUP BY action
        ORDER BY completed_count DESC, action ASC
      '''),
      parameters: {'days': days},
    );
    final reservationResult = await pool.execute(
      Sql.named('''
      SELECT COUNT(*)::int
      FROM ai_logs
      WHERE endpoint LIKE 'plan-reservation:%'
        AND success = FALSE
        AND created_at >= NOW() - INTERVAL '10 minutes'
    '''),
    );

    var completedActionCount = 0;
    final actions = <Map<String, dynamic>>[];
    for (final row in completedResult) {
      final count = (row[1] as int?) ?? 0;
      completedActionCount += count;
      actions.add({'action': row[0]?.toString() ?? 'unknown', 'count': count});
    }

    return {
      'status': 'ok',
      'window_days': days,
      'completed_action_count': completedActionCount,
      'active_reservation_count':
          reservationResult.isEmpty
              ? 0
              : ((reservationResult.first[0] as int?) ?? 0),
      'actions': actions,
    };
  }

  Future<Map<String, dynamic>> _planMix() async {
    final result = await pool.execute(
      Sql.named('''
      SELECT plan_name, status, COUNT(*)::int AS total
      FROM user_plans
      GROUP BY plan_name, status
      ORDER BY plan_name ASC, status ASC
    '''),
    );

    final rows = <Map<String, dynamic>>[];
    var total = 0;
    for (final row in result) {
      final count = (row[2] as int?) ?? 0;
      total += count;
      rows.add({'plan_name': row[0], 'status': row[1], 'count': count});
    }

    return {'status': 'ok', 'total_users_with_plan': total, 'plans': rows};
  }

  Future<Map<String, dynamic>> _sharedReports(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE is_public)::int AS public_total
        FROM shared_deck_reports
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
      '''),
      parameters: {'days': days},
    );

    final row = result.first;
    return {
      'status': 'ok',
      'created_count': (row[0] as int?) ?? 0,
      'public_count': (row[1] as int?) ?? 0,
    };
  }

  Future<Map<String, dynamic>> _retention(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          COUNT(*)::int AS note_count,
          COUNT(DISTINCT user_id)::int AS active_users,
          COUNT(DISTINCT deck_id)::int AS active_decks
        FROM post_game_notes
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
      '''),
      parameters: {'days': days},
    );

    final row = result.first;
    return {
      'status': 'ok',
      'post_game_note_count': (row[0] as int?) ?? 0,
      'active_users': (row[1] as int?) ?? 0,
      'active_decks': (row[2] as int?) ?? 0,
    };
  }

  Future<bool> _tableExists(String table) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = @table
      '''),
      parameters: {'table': table},
    );
    return result.isNotEmpty && (((result.first[0] as int?) ?? 0) > 0);
  }
}

String _dateIso(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.tryParse(
        value?.toString() ?? '',
      )?.toUtc().toIso8601String() ??
      value.toString();
}

double _ratio(int numerator, int denominator) =>
    double.parse((numerator / denominator).toStringAsFixed(4));
