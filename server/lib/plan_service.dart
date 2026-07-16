import 'package:postgres/postgres.dart';

import 'ai_telemetry_contract.dart';

class UserPlanSnapshot {
  const UserPlanSnapshot({
    required this.planName,
    required this.status,
    required this.aiMonthlyLimit,
    required this.aiRequestsUsed,
    required this.aiRequestsRemaining,
    required this.estimatedCostUsd,
    required this.estimatedCostPricingVersion,
    required this.estimatedCostCoverageRatio,
    required this.usagePeriodStart,
    required this.usagePeriodEnd,
  });

  final String planName;
  final String status;
  final int aiMonthlyLimit;
  final int aiRequestsUsed;
  final int aiRequestsRemaining;
  final double estimatedCostUsd;
  final String estimatedCostPricingVersion;
  final double estimatedCostCoverageRatio;
  final DateTime usagePeriodStart;
  final DateTime usagePeriodEnd;

  Map<String, dynamic> toJson() => {
    'plan_name': planName,
    'status': status,
    'ai_monthly_limit': aiMonthlyLimit,
    'ai_requests_used': aiRequestsUsed,
    'ai_requests_remaining': aiRequestsRemaining,
    'estimated_cost_usd': estimatedCostUsd,
    'estimated_cost_pricing_version': estimatedCostPricingVersion,
    'estimated_cost_coverage_ratio': estimatedCostCoverageRatio,
    'usage_period_start': usagePeriodStart.toUtc().toIso8601String(),
    'usage_period_end': usagePeriodEnd.toUtc().toIso8601String(),
  };
}

class AiPlanReservationDecision {
  const AiPlanReservationDecision({required this.snapshot, this.reservationId});

  final UserPlanSnapshot snapshot;
  final String? reservationId;

  bool get isAllowed => reservationId != null;
}

class AiProviderUsageTotals {
  const AiProviderUsageTotals({
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
  });

  final String model;
  final int inputTokens;
  final int outputTokens;
}

class AiProviderCostEstimate {
  const AiProviderCostEstimate({
    required this.usd,
    required this.coverageRatio,
  });

  final double usd;
  final double coverageRatio;
}

class PlanService {
  const PlanService(this.pool);

  final Pool pool;

  static const _defaultFreeLimit = 120;
  static const _proLimit = 2500;
  static const _reservationTtl = Duration(minutes: 10);
  static const providerTelemetrySqlPredicate = aiProviderTelemetrySqlPredicate;
  static const estimatedCostPricingVersion = 'openai-2026-07-16';

  Future<void> ensureFreePlan(String userId) async {
    await _ensureFreePlan(pool, userId);
  }

  Future<void> _ensureFreePlan(Session session, String userId) async {
    await session.execute(
      Sql.named('''
        INSERT INTO user_plans (user_id, plan_name, status)
        VALUES (@userId, 'free', 'active')
        ON CONFLICT (user_id) DO NOTHING
      '''),
      parameters: {'userId': userId},
    );
  }

  Future<UserPlanSnapshot> activatePro(String userId) async {
    await pool.execute(
      Sql.named('''
        INSERT INTO user_plans (
          user_id,
          plan_name,
          status,
          started_at,
          renews_at,
          updated_at
        )
        VALUES (
          @userId,
          'pro',
          'active',
          NOW(),
          NOW() + INTERVAL '30 days',
          NOW()
        )
        ON CONFLICT (user_id) DO UPDATE SET
          plan_name = 'pro',
          status = 'active',
          renews_at = NOW() + INTERVAL '30 days',
          updated_at = NOW()
      '''),
      parameters: {'userId': userId},
    );
    return getSnapshot(userId);
  }

  Future<UserPlanSnapshot> getSnapshot(String userId) async {
    return pool.runTx((session) async {
      await _ensureFreePlan(session, userId);
      await _cleanupStaleReservations(session, userId);
      return _loadSnapshot(session, userId);
    });
  }

  Future<AiPlanReservationDecision> reserveAiAction(
    String userId, {
    required String actionEndpoint,
  }) {
    if (!actionEndpoint.startsWith('plan:')) {
      throw ArgumentError.value(
        actionEndpoint,
        'actionEndpoint',
        'must start with plan:',
      );
    }

    return pool.runTx((session) async {
      await _ensureFreePlan(session, userId);
      await session.execute(
        Sql.named('''
          SELECT pg_advisory_xact_lock(
            hashtext('manaloom_ai_plan'),
            hashtext(@userId)
          )
        '''),
        parameters: {'userId': userId},
      );
      await _cleanupStaleReservations(session, userId);

      final snapshot = await _loadSnapshot(session, userId);
      if (snapshot.status != 'active' || snapshot.aiRequestsRemaining <= 0) {
        return AiPlanReservationDecision(snapshot: snapshot);
      }

      final reservationEndpoint = actionEndpoint.replaceFirst(
        'plan:',
        'plan-reservation:',
      );
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO ai_logs (
            user_id,
            endpoint,
            model,
            latency_ms,
            success
          )
          VALUES (
            CAST(@userId AS uuid),
            @endpoint,
            'application_action',
            0,
            FALSE
          )
          RETURNING id::text AS id
        '''),
        parameters: {'userId': userId, 'endpoint': reservationEndpoint},
      );

      return AiPlanReservationDecision(
        snapshot: snapshot,
        reservationId: inserted.first.toColumnMap()['id'] as String,
      );
    });
  }

  Future<bool> finalizeAiActionReservation({
    required String userId,
    required String reservationId,
    required int latencyMs,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        UPDATE ai_logs
        SET
          endpoint = regexp_replace(
            endpoint,
            '^plan-reservation:',
            'plan:'
          ),
          latency_ms = @latencyMs,
          success = TRUE
        WHERE id = CAST(@reservationId AS uuid)
          AND user_id = CAST(@userId AS uuid)
          AND endpoint LIKE 'plan-reservation:%'
        RETURNING id
      '''),
      parameters: {
        'userId': userId,
        'reservationId': reservationId,
        'latencyMs': latencyMs,
      },
    );
    return result.isNotEmpty;
  }

  Future<bool> releaseAiActionReservation({
    required String userId,
    required String reservationId,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        DELETE FROM ai_logs
        WHERE id = CAST(@reservationId AS uuid)
          AND user_id = CAST(@userId AS uuid)
          AND endpoint LIKE 'plan-reservation:%'
        RETURNING id
      '''),
      parameters: {'userId': userId, 'reservationId': reservationId},
    );
    return result.isNotEmpty;
  }

  Future<void> _cleanupStaleReservations(Session session, String userId) async {
    await session.execute(
      Sql.named('''
        DELETE FROM ai_logs
        WHERE user_id = CAST(@userId AS uuid)
          AND endpoint LIKE 'plan-reservation:%'
          AND success = FALSE
          AND created_at <
            NOW() - (CAST(@ttlSeconds AS int) * INTERVAL '1 second')
      '''),
      parameters: {'userId': userId, 'ttlSeconds': _reservationTtl.inSeconds},
    );
  }

  Future<UserPlanSnapshot> _loadSnapshot(Session session, String userId) async {
    final planResult = await session.execute(
      Sql.named('''
        SELECT plan_name, status
        FROM user_plans
        WHERE user_id = @userId
        LIMIT 1
      '''),
      parameters: {'userId': userId},
    );

    final planName =
        planResult.isNotEmpty
            ? (planResult.first[0] as String? ?? 'free')
            : 'free';
    final status =
        planResult.isNotEmpty
            ? (planResult.first[1] as String? ?? 'active')
            : 'active';

    final aiMonthlyLimit = planName == 'pro' ? _proLimit : _defaultFreeLimit;

    final usageResult = await session.execute(
      Sql.named('''
        SELECT
          COUNT(*) FILTER (
            WHERE
              (endpoint LIKE 'plan:%' AND success = TRUE)
              OR (
                endpoint LIKE 'plan-reservation:%'
                AND success = FALSE
                AND created_at >=
                  NOW() - (CAST(@reservationTtlSeconds AS int) * INTERVAL '1 second')
              )
          )::int AS requests_used,
          date_trunc('month', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
            AS usage_period_start,
          (date_trunc('month', NOW() AT TIME ZONE 'UTC') + INTERVAL '1 month')
            AT TIME ZONE 'UTC' AS usage_period_end
        FROM ai_logs
        WHERE user_id = @userId
          AND created_at >=
            date_trunc('month', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
          AND created_at <
            (date_trunc('month', NOW() AT TIME ZONE 'UTC') + INTERVAL '1 month')
              AT TIME ZONE 'UTC'
      '''),
      parameters: {
        'userId': userId,
        'reservationTtlSeconds': _reservationTtl.inSeconds,
      },
    );

    final providerUsageResult = await session.execute(
      Sql.named('''
        SELECT
          model,
          COALESCE(SUM(COALESCE(input_tokens, 0)), 0)::bigint
            AS input_tokens,
          COALESCE(SUM(COALESCE(output_tokens, 0)), 0)::bigint
            AS output_tokens
        FROM ai_logs
        WHERE user_id = @userId
          AND $providerTelemetrySqlPredicate
          AND success = TRUE
          AND created_at >=
            date_trunc('month', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
          AND created_at <
            (date_trunc('month', NOW() AT TIME ZONE 'UTC') + INTERVAL '1 month')
              AT TIME ZONE 'UTC'
        GROUP BY model
      '''),
      parameters: {'userId': userId},
    );

    final requestsUsed =
        usageResult.isNotEmpty ? (usageResult.first[0] as int? ?? 0) : 0;
    final now = DateTime.now().toUtc();
    final fallbackPeriodStart = DateTime.utc(now.year, now.month);
    final fallbackPeriodEnd = DateTime.utc(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
    );
    final usagePeriodStart =
        usageResult.isNotEmpty
            ? usageResult.first[1] as DateTime? ?? fallbackPeriodStart
            : fallbackPeriodStart;
    final usagePeriodEnd =
        usageResult.isNotEmpty
            ? usageResult.first[2] as DateTime? ?? fallbackPeriodEnd
            : fallbackPeriodEnd;

    final remaining = (aiMonthlyLimit - requestsUsed).clamp(0, aiMonthlyLimit);

    final costEstimate = estimateAiProviderCost(
      providerUsageResult.map((row) {
        final values = row.toColumnMap();
        return AiProviderUsageTotals(
          model: values['model'] as String? ?? '',
          inputTokens: values['input_tokens'] as int? ?? 0,
          outputTokens: values['output_tokens'] as int? ?? 0,
        );
      }),
    );

    return UserPlanSnapshot(
      planName: planName,
      status: status,
      aiMonthlyLimit: aiMonthlyLimit,
      aiRequestsUsed: requestsUsed,
      aiRequestsRemaining: remaining,
      estimatedCostUsd: double.parse(costEstimate.usd.toStringAsFixed(4)),
      estimatedCostPricingVersion: estimatedCostPricingVersion,
      estimatedCostCoverageRatio: double.parse(
        costEstimate.coverageRatio.toStringAsFixed(4),
      ),
      usagePeriodStart: usagePeriodStart,
      usagePeriodEnd: usagePeriodEnd,
    );
  }
}

AiProviderCostEstimate estimateAiProviderCost(
  Iterable<AiProviderUsageTotals> usage,
) {
  var totalTokens = 0;
  var coveredTokens = 0;
  var estimatedUsd = 0.0;

  for (final item in usage) {
    final inputTokens = item.inputTokens < 0 ? 0 : item.inputTokens;
    final outputTokens = item.outputTokens < 0 ? 0 : item.outputTokens;
    final tokens = inputTokens + outputTokens;
    totalTokens += tokens;

    final pricing = _pricingForModel(item.model);
    if (pricing == null) continue;
    coveredTokens += tokens;
    estimatedUsd +=
        (inputTokens * pricing.$1 + outputTokens * pricing.$2) / 1000000.0;
  }

  return AiProviderCostEstimate(
    usd: estimatedUsd,
    coverageRatio: totalTokens == 0 ? 1 : coveredTokens / totalTokens,
  );
}

(double, double)? _pricingForModel(String model) {
  final normalized = model.trim().toLowerCase();
  if (normalized.startsWith('gpt-5.4-mini')) return (0.75, 4.50);
  if (normalized.startsWith('gpt-4o-mini')) return (0.15, 0.60);
  return null;
}
