import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('migration 052 and fresh schema share the Battle attempt contract', () {
    final migration = File('bin/migrate.dart').readAsStringSync();
    final baseline = File('database_setup.sql').readAsStringSync();

    for (final source in [migration, baseline]) {
      expect(
        source,
        contains('CREATE TABLE IF NOT EXISTS battle_simulation_attempts'),
      );
      expect(source, contains('replay_id UUID UNIQUE'));
      expect(
        source,
        contains("test_objective TEXT NOT NULL DEFAULT 'general'"),
      );
      expect(source, contains('request_schema_version TEXT NOT NULL'));
      expect(source, contains('request_hash TEXT'));
      expect(source, contains('deck_a_hash TEXT'));
      expect(source, contains('deck_b_hash TEXT'));
      expect(source, contains('engine_process_id TEXT'));
      expect(source, contains('events_truncated BOOLEAN NOT NULL'));
      expect(source, contains('snapshots_truncated BOOLEAN NOT NULL'));
      expect(source, contains('chk_battle_attempt_test_objective'));
      for (final outcome in const [
        'completed',
        'censored',
        'timeout',
        'coverage_error',
        'engine_error',
        'cancelled',
        'persistence_error',
      ]) {
        expect(source, contains("'$outcome'"));
      }
    }

    expect(migration, contains("version: '052'"));
    expect(migration, contains("name: 'version_battle_simulation_attempts'"));
    expect(
      migration,
      isNot(contains('INSERT INTO battle_simulation_attempts')),
    );
    expect(migration, isNot(contains("'legacy_replay_backfill'")));
    expect(migration, contains('Historical replays stay readable'));
    expect(
      migration,
      contains('DROP TABLE IF EXISTS battle_simulation_attempts CASCADE'),
    );
  });

  test(
    'simulate route closes attempts without changing failure HTTP paths',
    () {
      final route = File('routes/ai/simulate/index.dart').readAsStringSync();
      final runtime =
          File('lib/battle/battle_execution_runtime.dart').readAsStringSync();

      expect(route, contains('BattleSimulationAttemptService(pool)'));
      expect(route, contains('BattleSimulationAttemptOutcome.censored'));
      expect(route, contains('BattleSimulationAttemptOutcome.engineError'));
      expect(
        route,
        contains('BattleSimulationAttemptOutcome.persistenceError'),
      );
      expect(route, contains('_finishFailedAttemptAndReturn'));
      expect(route, contains('BattleExecutionRuntime.fromEnvironment('));
      expect(route, contains('outcome: error.outcome'));
      expect(route, contains('_battleRuntimeFailure(error)'));
      expect(runtime, contains('BattleSimulationAttemptOutcome.timeout'));
      expect(runtime, contains('BattleSimulationAttemptOutcome.coverageError'));
      expect(runtime, contains('BattleSimulationAttemptOutcome.cancelled'));
      expect(runtime, contains('statusCode == HttpStatus.gatewayTimeout'));
    },
  );
}
