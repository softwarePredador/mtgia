import 'package:postgres/postgres.dart';

Future<void> recordOptimizeFallbackTelemetry({
  required Pool pool,
  required String? userId,
  required String? deckId,
  required String mode,
  required bool recognizedFormat,
  required bool triggered,
  required bool applied,
  required bool noCandidate,
  required bool noReplacement,
  required int candidateCount,
  required int replacementCount,
  required int pairCount,
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO ai_optimize_fallback_telemetry (
        user_id,
        deck_id,
        mode,
        recognized_format,
        triggered,
        applied,
        no_candidate,
        no_replacement,
        candidate_count,
        replacement_count,
        pair_count
      ) VALUES (
        CAST(@user_id AS uuid),
        CAST(@deck_id AS uuid),
        @mode,
        @recognized_format,
        @triggered,
        @applied,
        @no_candidate,
        @no_replacement,
        @candidate_count,
        @replacement_count,
        @pair_count
      )
    '''),
    parameters: {
      'user_id': userId,
      'deck_id': deckId,
      'mode': mode,
      'recognized_format': recognizedFormat,
      'triggered': triggered,
      'applied': applied,
      'no_candidate': noCandidate,
      'no_replacement': noReplacement,
      'candidate_count': candidateCount,
      'replacement_count': replacementCount,
      'pair_count': pairCount,
    },
  );
}

Future<Map<String, dynamic>> loadPersistedEmptyFallbackAggregate(
  Pool pool,
) async {
  final result = await pool.execute('''
    SELECT
      COUNT(*)::int AS total_requests,
      SUM(CASE WHEN triggered THEN 1 ELSE 0 END)::int AS triggered_count,
      SUM(CASE WHEN applied THEN 1 ELSE 0 END)::int AS applied_count,
      SUM(CASE WHEN no_candidate THEN 1 ELSE 0 END)::int AS no_candidate_count,
      SUM(CASE WHEN no_replacement THEN 1 ELSE 0 END)::int AS no_replacement_count,
      COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '24 hours')::int AS total_requests_24h,
      SUM(CASE WHEN triggered AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS triggered_count_24h,
      SUM(CASE WHEN applied AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS applied_count_24h,
      SUM(CASE WHEN no_candidate AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS no_candidate_count_24h,
      SUM(CASE WHEN no_replacement AND created_at >= NOW() - INTERVAL '24 hours' THEN 1 ELSE 0 END)::int AS no_replacement_count_24h
    FROM ai_optimize_fallback_telemetry
  ''');

  if (result.isEmpty) return emptyOptimizeFallbackAggregate();
  return buildOptimizeFallbackAggregateFromRow(result.first.toColumnMap());
}

Map<String, dynamic> emptyOptimizeFallbackAggregate() {
  return {
    'all_time': {
      'request_count': 0,
      'triggered_count': 0,
      'applied_count': 0,
      'no_candidate_count': 0,
      'no_replacement_count': 0,
      'trigger_rate': 0.0,
      'apply_rate': 0.0,
    },
    'last_24h': {
      'request_count': 0,
      'triggered_count': 0,
      'applied_count': 0,
      'no_candidate_count': 0,
      'no_replacement_count': 0,
      'trigger_rate': 0.0,
      'apply_rate': 0.0,
    },
  };
}

Map<String, dynamic> buildOptimizeFallbackAggregateFromRow(
  Map<String, dynamic> row,
) {
  final allRequests = _toInt(row['total_requests']);
  final allTriggered = _toInt(row['triggered_count']);
  final allApplied = _toInt(row['applied_count']);
  final allNoCandidate = _toInt(row['no_candidate_count']);
  final allNoReplacement = _toInt(row['no_replacement_count']);

  final requests24h = _toInt(row['total_requests_24h']);
  final triggered24h = _toInt(row['triggered_count_24h']);
  final applied24h = _toInt(row['applied_count_24h']);
  final noCandidate24h = _toInt(row['no_candidate_count_24h']);
  final noReplacement24h = _toInt(row['no_replacement_count_24h']);

  return {
    'all_time': {
      'request_count': allRequests,
      'triggered_count': allTriggered,
      'applied_count': allApplied,
      'no_candidate_count': allNoCandidate,
      'no_replacement_count': allNoReplacement,
      'trigger_rate': allRequests > 0 ? allTriggered / allRequests : 0.0,
      'apply_rate': allTriggered > 0 ? allApplied / allTriggered : 0.0,
    },
    'last_24h': {
      'request_count': requests24h,
      'triggered_count': triggered24h,
      'applied_count': applied24h,
      'no_candidate_count': noCandidate24h,
      'no_replacement_count': noReplacement24h,
      'trigger_rate': requests24h > 0 ? triggered24h / requests24h : 0.0,
      'apply_rate': triggered24h > 0 ? applied24h / triggered24h : 0.0,
    },
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
