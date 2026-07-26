import 'dart:io';

import 'package:server/battle/battle_job_store.dart';
import 'package:test/test.dart';

void main() {
  test('claim uses skip-locked fencing and serializes each engine lane', () {
    expect(battleJobClaimSql, contains('FOR UPDATE OF candidate SKIP LOCKED'));
    expect(battleJobClaimSql, contains("candidate.status = 'queued'"));
    expect(
      battleJobClaimSql,
      contains('active.engine_lane = candidate.engine_lane'),
    );
    expect(battleJobClaimSql, contains("active.engine_lane = 'auto'"));
    expect(battleJobClaimSql, contains("candidate.engine_lane = 'auto'"));
    expect(battleJobClaimSql, contains('candidate.attempt_count < 100'));
    expect(
      battleJobClaimSql,
      contains("active.status IN ('claimed', 'running', 'cancel_pending')"),
    );
  });

  test('lease recovery never repeats a job after engine start', () {
    expect(battleJobRecoverClaimedLeasesSql, contains("status = 'claimed'"));
    expect(battleJobRecoverClaimedLeasesSql, contains("SET status = 'queued'"));
    expect(
      battleJobRecoverClaimedLeasesSql,
      isNot(contains("status IN ('running', 'cancel_pending')")),
    );

    expect(
      battleJobFailExpiredRunningLeasesSql,
      contains("status IN ('running', 'cancel_pending')"),
    );
    expect(
      battleJobFailExpiredRunningLeasesSql,
      contains("SET status = 'engine_error'"),
    );
    expect(
      battleJobFailExpiredRunningLeasesSql,
      contains('worker_lease_expired_after_engine_start'),
    );
    expect(
      battleJobFailExpiredRunningLeasesSql,
      isNot(contains("SET status = 'queued'")),
    );
  });

  test('quota policy is bounded and never violates user <= global', () {
    final defaults = BattleJobQuotaPolicy.fromEnvironment(const {});
    expect(defaults.perUserActiveLimit, battleJobDefaultPerUserQuota);
    expect(defaults.globalActiveLimit, battleJobDefaultGlobalQuota);

    final normalized = BattleJobQuotaPolicy.fromEnvironment(const {
      'BATTLE_JOB_PER_USER_ACTIVE_LIMIT': '10',
      'BATTLE_JOB_GLOBAL_ACTIVE_LIMIT': '2',
    });
    expect(normalized.perUserActiveLimit, 10);
    expect(normalized.globalActiveLimit, 10);
  });

  test(
    'store source keeps idempotency, quotas, owner scope, and fencing atomic',
    () {
      final source =
          File('lib/battle/battle_job_store.dart').readAsStringSync();

      expect(source, contains('pg_advisory_xact_lock'));
      expect(source, contains('user_active'));
      expect(source, contains('global_active'));
      expect(source, contains('BattleJobQuotaExceededException'));
      expect(source, contains('request_fingerprint'));
      expect(source, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(source, contains('AND job.lease_owner = @worker_id'));
      expect(
        source,
        contains('AND job.lease_token = CAST(@lease_token AS uuid)'),
      );
      expect(source, contains('AND job.request_hash = @request_hash'));
      expect(source, contains('attempt.user_id = job.user_id'));
      expect(source, contains('attempt.job_request_hash = job.request_hash'));
      expect(source, contains('deck_a.deleted_at IS NULL'));
      expect(source, contains('deck_b.deleted_at IS NULL'));
    },
  );

  test('engine lanes are deterministic and closed', () {
    expect(battleJobEngineLane('auto'), 'auto');
    expect(battleJobEngineLane('xmage'), 'xmage');
    expect(battleJobEngineLane('forge'), 'forge');
    expect(battleJobEngineLane('native'), 'native');
  });
}
