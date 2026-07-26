import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

void main() {
  test('migration 054 and fresh schema share the Battle job contract', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '054',
    );
    final baseline = File('database_setup.sql').readAsStringSync();

    expect(migration.name, 'create_battle_jobs');
    for (final source in [migration.up, baseline]) {
      expect(source, contains('CREATE TABLE IF NOT EXISTS battle_jobs'));
      for (final status in const [
        'queued',
        'claimed',
        'running',
        'cancel_pending',
        'completed',
        'censored',
        'timeout',
        'coverage_error',
        'engine_error',
        'cancelled',
        'persistence_error',
      ]) {
        expect(source, contains("'$status'"), reason: status);
      }
      for (final contract in const [
        'schema_version TEXT NOT NULL',
        'request_hash TEXT NOT NULL',
        'engine_request_hash TEXT',
        'engine_request_correlation_source TEXT',
        'request_payload JSONB NOT NULL',
        'deck_a_hash TEXT NOT NULL',
        'deck_b_hash TEXT NOT NULL',
        'engine_process_id TEXT',
        'lease_token UUID',
        'lease_expires_at TIMESTAMP WITH TIME ZONE',
        'heartbeat_at TIMESTAMP WITH TIME ZONE',
        'attempt_id UUID UNIQUE',
        'replay_id UUID UNIQUE',
        'idempotency_key TEXT NOT NULL',
        'request_fingerprint TEXT NOT NULL',
        'quota_user_limit INTEGER NOT NULL',
        'quota_global_limit INTEGER NOT NULL',
        'fk_battle_job_attempt_replay',
        'chk_battle_job_lease',
        'chk_battle_job_completed_replay',
        'chk_battle_job_engine_request',
        'uq_battle_jobs_user_idempotency',
        'idx_battle_jobs_user_active',
        'idx_battle_jobs_claim',
        'idx_battle_jobs_lease',
      ]) {
        expect(source, contains(contract), reason: contract);
      }
    }

    expect(
      migrate.migrationRollbackPolicy('054'),
      migrate.MigrationRollbackPolicy.manualOnly,
    );
    expect(
      migration.down,
      contains('DROP TABLE IF EXISTS battle_jobs CASCADE'),
    );
    expect(splitPostgresStatements(migration.up), isNotEmpty);
  });

  test('completed jobs require replay, process identity, and engine hash', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '054',
    );

    expect(
      migration.up,
      allOf(
        contains("status NOT IN ('completed', 'censored')"),
        contains('attempt_id IS NOT NULL'),
        contains('replay_id IS NOT NULL'),
        contains('engine_process_id IS NOT NULL'),
        contains('engine_request_hash IS NOT NULL'),
      ),
    );
    expect(migration.up, contains('FOREIGN KEY (attempt_id, replay_id)'));
    expect(
      migration.up,
      contains('REFERENCES battle_simulation_attempts (id, replay_id)'),
    );
  });

  test('migration 054 links job hash to attempt and engine request hashes', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '054',
    );

    expect(migration.up, contains('job_request_schema_version TEXT'));
    expect(migration.up, contains('job_request_hash TEXT'));
    expect(migration.up, contains('engine_request_correlation_source TEXT'));
    expect(migration.up, contains('idx_battle_attempt_job_request_hash'));
    expect(migration.up, contains("'battle_job_request_v1'"));
    expect(migration.up, contains("'server_dispatch_recorded'"));
    expect(migration.up, contains("'sidecar_echo_validated'"));
  });
}
