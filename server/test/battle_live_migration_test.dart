import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/health_readiness_support.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

void main() {
  test('migration 055 and fresh schema share the durable Live contract', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '055',
    );
    final baseline = File('database_setup.sql').readAsStringSync();

    expect(migration.name, 'create_battle_job_live_records');
    for (final source in [migration.up, baseline]) {
      for (final fragment in const [
        'CREATE TABLE IF NOT EXISTS battle_job_live_records',
        "schema_version TEXT NOT NULL DEFAULT 'battle_live_record_v1'",
        'job_id UUID NOT NULL',
        'REFERENCES battle_jobs(id) ON DELETE CASCADE',
        'sequence BIGINT NOT NULL',
        'record_id TEXT NOT NULL',
        'payload JSONB NOT NULL',
        'content_truncated BOOLEAN NOT NULL',
        'fingerprint TEXT NOT NULL',
        'source_kind TEXT NOT NULL',
        'public_visible BOOLEAN NOT NULL',
        'source_process_id TEXT',
        'source_sequence BIGINT',
        'source_record_id TEXT',
        'source_truncated BOOLEAN NOT NULL',
        'chk_battle_live_record_source',
        'uq_battle_live_record_job_sequence',
        'uq_battle_live_record_job_fingerprint',
        'idx_battle_live_record_job_public_sequence',
        'idx_battle_live_record_checkpoint',
        'idx_battle_live_record_source_identity',
      ]) {
        expect(source, contains(fragment), reason: fragment);
      }
      for (final sourceKind in const [
        'xmage_live',
        'xmage_checkpoint',
        'terminal_replay',
      ]) {
        expect(source, contains("'$sourceKind'"), reason: sourceKind);
      }
    }

    expect(splitPostgresStatements(migration.up), isNotEmpty);
    expect(
      migrate.migrationRollbackPolicy('055'),
      migrate.MigrationRollbackPolicy.manualOnly,
    );
    expect(
      migration.down,
      contains('DROP TABLE IF EXISTS battle_job_live_records CASCADE'),
    );
  });

  test('release and capability readiness require migration 055 shape', () {
    expect(
      requiredReleaseSchemaMigrations['055'],
      'create_battle_job_live_records',
    );
    expect(releaseSchemaReadinessSql, contains("'055'"));
    expect(releaseSchemaReadinessSql, contains("= '055'"));
    expect(
      releaseSchemaReadinessSql,
      contains("to_regclass('public.battle_job_live_records')"),
    );
    expect(
      battleLiveSchemaReadinessSql,
      contains("name = 'create_battle_job_live_records'"),
    );
    expect(
      battleLiveSchemaReadinessSql,
      contains('chk_battle_live_record_source'),
    );
  });
}
