import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/health_readiness_support.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

void main() {
  test('migration 056 and fresh schema share the interactive contract', () {
    final migration = migrate.migrations.singleWhere(
      (candidate) => candidate.version == '056',
    );
    final baseline = File('database_setup.sql').readAsStringSync();

    expect(migration.name, 'create_interactive_battle_sessions');
    for (final source in [migration.up, baseline]) {
      for (final fragment in const [
        'CREATE TABLE IF NOT EXISTS interactive_battle_sessions',
        "schema_version TEXT NOT NULL DEFAULT 'interactive_battle_session_v1'",
        'request_hash TEXT NOT NULL',
        'request_payload JSONB NOT NULL',
        'engine_process_id TEXT',
        'runtime_session_id TEXT',
        'state_version BIGINT NOT NULL',
        'active_prompt JSONB',
        'private_state JSONB NOT NULL',
        'prompt_deadline_at TIMESTAMP WITH TIME ZONE',
        'attempt_id UUID UNIQUE',
        'replay_id UUID UNIQUE',
        'fk_interactive_battle_attempt_replay',
        'chk_interactive_battle_prompt',
        'chk_interactive_battle_lifecycle',
        'chk_interactive_battle_replay',
        'uq_interactive_battle_user_idempotency',
        'uq_interactive_battle_runtime_session',
        'idx_interactive_battle_user_active',
        'CREATE TABLE IF NOT EXISTS interactive_battle_records',
        "DEFAULT 'interactive_battle_record_v1'",
        'uq_interactive_battle_record_sequence',
        'uq_interactive_battle_record_idempotency',
        'manaloom_interactive_battle_record_append_only',
        'manaloom_interactive_battle_record_no_update',
      ]) {
        expect(source, contains(fragment), reason: fragment);
      }
      for (final status in const [
        'starting',
        'running',
        'waiting_for_action',
        'action_pending',
        'completed',
        'censored',
        'conceded',
        'expired',
        'timeout',
        'abandoned',
        'engine_error',
        'process_lost',
        'persistence_error',
      ]) {
        expect(source, contains("'$status'"), reason: status);
      }
    }

    expect(splitPostgresStatements(migration.up), isNotEmpty);
    expect(
      migrate.migrationRollbackPolicy('056'),
      migrate.MigrationRollbackPolicy.manualOnly,
    );
    expect(
      migration.down,
      contains('DROP TABLE IF EXISTS interactive_battle_records CASCADE'),
    );
    expect(
      migration.down,
      contains('DROP TABLE IF EXISTS interactive_battle_sessions CASCADE'),
    );
  });

  test('release and capability readiness require migration 056 shape', () {
    expect(
      requiredReleaseSchemaMigrations['056'],
      'create_interactive_battle_sessions',
    );
    expect(releaseSchemaReadinessSql, contains("= '057'"));
    expect(
      releaseSchemaReadinessSql,
      contains("to_regclass('public.interactive_battle_sessions')"),
    );
    expect(
      releaseSchemaReadinessSql,
      contains("to_regclass('public.interactive_battle_records')"),
    );
    expect(
      interactiveBattleSchemaReadinessSql,
      contains("name = 'create_interactive_battle_sessions'"),
    );
    expect(
      interactiveBattleSchemaReadinessSql,
      contains('manaloom_interactive_battle_record_no_update'),
    );
  });
}
