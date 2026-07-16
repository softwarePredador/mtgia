import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.path;

  String scriptSource(String relativePath) =>
      File('$repoRoot/$relativePath').readAsStringSync();

  group('mutating E2E entrypoint guards', () {
    const directlyPostgresBackedScripts = <String>[
      'scripts/manaloom_product_smoke.sh',
      'scripts/manaloom_ai_paywall_e2e.sh',
      'scripts/manaloom_ai_generation_benchmark.sh',
      'scripts/manaloom_commercial_quality_gate.sh',
      'scripts/manaloom_mobile_authenticated_qa.sh',
      'scripts/quality_gate_carro_chefe.sh',
    ];

    for (final relativePath in directlyPostgresBackedScripts) {
      test('$relativePath blocks before tools or network', () async {
        final source = scriptSource(relativePath);
        final sourceGuard = source.indexOf('manaloom_mutation_guard.sh');
        final liveGuard = source.indexOf('require_live_mutation_approval');
        final postgresGuard = source.indexOf('require_postgres_write_approval');
        final firstToolOrNetwork = [
          source.indexOf('require_tool '),
          source.indexOf('curl '),
          source.indexOf('ssh '),
          source.indexOf('flutter '),
        ].where((index) => index >= 0).reduce((a, b) => a < b ? a : b);

        expect(sourceGuard, greaterThanOrEqualTo(0));
        expect(liveGuard, greaterThan(sourceGuard));
        expect(postgresGuard, greaterThan(sourceGuard));
        expect(liveGuard, lessThan(firstToolOrNetwork));
        expect(postgresGuard, lessThan(firstToolOrNetwork));

        final result = await Process.run(
          'bash',
          ['$repoRoot/$relativePath'],
          environment: const {
            'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
            'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
          },
          includeParentEnvironment: true,
        );
        expect(result.exitCode, 2);
        expect('${result.stderr}', contains('BLOCKED:'));
      });
    }

    test(
      'E2E orchestrator emits JSON and distinguishes partial or blocked',
      () {
        final source = scriptSource('scripts/manaloom_e2e_suite.sh');

        expect(source, contains('SUMMARY_JSON_FILE='));
        expect(source, contains('record_step "SKIP"'));
        expect(source, contains('record_step "BLOCKED"'));
        expect(source, contains('FINAL_STATUS="PARTIAL"'));
        expect(source, contains('FINAL_STATUS="BLOCKED"'));
        expect(source, contains('"steps": steps'));
      },
    );

    test('resolution corpus arms mutation only after preflight and approval', () {
      final source = scriptSource('scripts/quality_gate_resolution_corpus.sh');
      final preflight = source.indexOf(
        'print_header "Preflight read-only do corpus"',
      );
      final approval = source.indexOf(
        'require_postgres_write_approval "Commander resolution corpus mutating E2E"',
      );
      final identityPrecheck = source.indexOf('IDENTITY_BEFORE=');
      final serverStart = source.indexOf(r'SERVER_PID="$!"');
      final mutationArmed = source.indexOf('MUTATION_ARMED=1');
      final runner = source.indexOf(
        'dart run bin/run_three_commander_resolution_validation.dart',
        mutationArmed,
      );
      final runnerStatus = source.indexOf(r'RUNNER_STATUS="$?"', runner);
      final serverStop = source.indexOf('stop_local_server', runnerStatus);
      final listenerCheck = source.indexOf(
        r'if ! assert_listener_closed "$PORT"',
        serverStop,
      );
      final cleanup = source.indexOf(
        'if ! cleanup_validation_identity',
        listenerCheck,
      );
      final audit = source.indexOf('write_mutation_audit \\', runnerStatus);
      final listenerFailure = source.indexOf(
        r'if [[ "$LISTENER_CLOSE_OK" -ne 1',
        audit,
      );

      expect(preflight, greaterThanOrEqualTo(0));
      expect(approval, greaterThan(preflight));
      expect(identityPrecheck, greaterThan(approval));
      expect(serverStart, greaterThan(identityPrecheck));
      expect(mutationArmed, greaterThan(serverStart));
      expect(runner, greaterThan(mutationArmed));
      expect(runnerStatus, greaterThan(runner));
      expect(serverStop, greaterThan(runnerStatus));
      expect(listenerCheck, greaterThan(serverStop));
      expect(cleanup, greaterThan(listenerCheck));
      expect(audit, greaterThan(cleanup));
      expect(listenerFailure, greaterThan(audit));
      expect(source, contains('trap cleanup EXIT INT TERM'));
      expect(source, contains('DELETE FROM users'));
      expect(source, contains('LOWER(username) = LOWER'));
      expect(source, contains('"measurement_scope"'));
      expect(source, contains('"limitation"'));
      expect(source, contains('dart_frog dev'));
      expect(source, contains('script -q /dev/null dart_frog dev'));
      expect(source, contains(r'assert_listener_closed "$PORT"'));
      expect(source, contains('SERVER_LISTENER_PIDS='));
      expect(source, contains('capture_listener_pids'));
      expect(source, contains('collect_process_tree_pids'));
      expect(source, contains('kill -KILL'));
      expect(source, contains('"runtime_cleanup"'));
      expect(source, contains('--hostname 127.0.0.1'));
      expect(source, isNot(contains('dart run build/bin/server.dart')));

      for (final table in const [
        'ai_optimize_cache',
        'ai_optimize_fallback_telemetry',
        'ml_prompt_feedback',
        'optimization_analysis_logs',
        'ai_logs',
        'rate_limit_events',
      ]) {
        expect(
          source.toUpperCase(),
          isNot(contains('DELETE FROM ${table.toUpperCase()}')),
          reason: table,
        );
      }
    });

    test(
      'Battle product E2E has an honest isolated mutating entrypoint',
      () async {
        final source = scriptSource('scripts/manaloom_battle_product_gate.sh');
        final exactCleanup = source.substring(
          source.indexOf('cleanup_battle_identity()'),
          source.indexOf('cleanup_on_exit()'),
        );
        final staticStart = source.indexOf('run_static_gate()');
        final isolatedStart = source.indexOf('run_isolated_e2e()');
        final staticSource = source.substring(staticStart, isolatedStart);
        final isolatedSource = source.substring(isolatedStart);
        final approval = isolatedSource.indexOf(
          'require_postgres_write_approval "Battle product isolated mutating E2E"',
        );
        final mutationArmed = isolatedSource.indexOf('MUTATION_ARMED=1');
        final runner = isolatedSource.indexOf(
          'dart test --reporter compact -j 1 test/battle_product_e2e_test.dart',
        );
        final runnerStatus = isolatedSource.indexOf(
          r'runner_status="${PIPESTATUS[0]}"',
          runner,
        );
        final listenerCheck = isolatedSource.indexOf(
          'if ! assert_listener_closed',
          runnerStatus,
        );
        final cleanup = isolatedSource.indexOf(
          r'deleted="$(cleanup_battle_identity',
          runnerStatus,
        );
        final audit = isolatedSource.indexOf('write_mutation_audit', cleanup);

        expect(staticStart, greaterThanOrEqualTo(0));
        expect(isolatedStart, greaterThan(staticStart));
        expect(
          staticSource,
          isNot(contains('test/battle_product_e2e_test.dart')),
        );
        expect(approval, greaterThanOrEqualTo(0));
        expect(mutationArmed, greaterThan(approval));
        expect(runner, greaterThan(mutationArmed));
        expect(runnerStatus, greaterThan(runner));
        expect(listenerCheck, greaterThan(runnerStatus));
        expect(cleanup, greaterThan(listenerCheck));
        expect(audit, greaterThan(cleanup));
        expect(isolatedSource, contains('--hostname 127.0.0.1'));
        expect(isolatedSource, contains('script -q /dev/null dart_frog dev'));
        expect(isolatedSource, contains('assert_loopback_listener'));
        expect(isolatedSource, contains('assert_listener_closed'));
        expect(isolatedSource, contains('API_LISTENER_PIDS='));
        expect(isolatedSource, contains('NATIVE_LISTENER_PIDS='));
        expect(source, contains('collect_process_tree_pids'));
        expect(source, contains('kill -KILL'));
        expect(source, contains('"runtime_cleanup"'));
        expect(isolatedSource, contains('BATTLE_E2E_RUN_TOKEN'));
        expect(isolatedSource, contains('BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS'));
        expect(source, contains('mutation_audit.json'));
        expect(source, contains('"telemetry_deleted": False'));
        expect(source, contains('DELETE FROM battle_simulations'));
        expect(source, contains('DELETE FROM users'));
        expect(source, contains('identity_collision_count()'));
        expect(
          exactCleanup,
          contains("AND LOWER(username) = LOWER(:'validation_username')"),
        );
        expect(
          exactCleanup,
          isNot(contains("OR LOWER(username) = LOWER(:'validation_username')")),
        );

        for (final table in const [
          'ai_optimize_cache',
          'ai_optimize_fallback_telemetry',
          'ml_prompt_feedback',
          'optimization_analysis_logs',
          'ai_logs',
          'rate_limit_events',
        ]) {
          expect(
            source.toUpperCase(),
            isNot(contains('DELETE FROM ${table.toUpperCase()}')),
            reason: table,
          );
        }

        final blocked = await Process.run(
          'bash',
          [
            '$repoRoot/scripts/manaloom_battle_product_gate.sh',
            '--isolated-e2e',
          ],
          environment: const {'MANALOOM_CONFIRM_POSTGRES_WRITES': ''},
          includeParentEnvironment: true,
        );
        expect(blocked.exitCode, 2);
        expect('${blocked.stderr}', contains('BLOCKED:'));
      },
    );

    test('E2E suite aggregates Battle isolated execution or a real skip', () {
      final source = scriptSource('scripts/manaloom_e2e_suite.sh');
      final runner = source.indexOf('run_battle_product_e2e()');
      final invocation = source.indexOf(
        'manaloom_battle_product_gate.sh\\" --isolated-e2e',
        runner,
      );
      final skip = source.indexOf('skip_step', invocation);
      final skipLabel = source.indexOf(
        '"Battle product isolated mutating E2E"',
        skip,
      );

      expect(runner, greaterThanOrEqualTo(0));
      expect(invocation, greaterThan(runner));
      expect(skip, greaterThan(invocation));
      expect(skipLabel, greaterThan(skip));
      expect(source, contains('MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E'));
      expect(source, contains('record_step "SKIP"'));
    });

    test('deterministic full gates cannot auto-enable live tests', () {
      final shellSource = scriptSource('scripts/quality_gate.sh');
      final powershellSource = scriptSource('scripts/quality_gate.ps1');

      expect(shellSource, isNot(contains('_is_backend_api_ready')));
      expect(shellSource, isNot(contains('RUN_INTEGRATION_TESTS=1')));
      expect(shellSource, contains('RUN_INTEGRATION_TESTS=0 JWT_SECRET='));
      expect(powershellSource, isNot(contains('Test-BackendApiReady')));
      expect(powershellSource, contains(r'$env:RUN_INTEGRATION_TESTS = "0"'));
      expect(powershellSource, contains('dart test -P all-local'));
    });

    test(
      'migration status is SELECT-only and apply approval is pre-connect',
      () {
        final source = scriptSource('server/bin/migrate.dart');
        final mainSource = source.substring(source.indexOf('void main('));
        final approval = mainSource.indexOf('hasMigrationWriteApproval(');
        final connection = mainSource.indexOf('Connection.open(');
        final statusBranch = mainSource.indexOf('if (showStatus)');
        final controlTableDdl = mainSource.indexOf(
          'CREATE TABLE IF NOT EXISTS schema_migrations',
        );

        expect(approval, greaterThanOrEqualTo(0));
        expect(approval, lessThan(connection));
        expect(statusBranch, greaterThan(connection));
        expect(statusBranch, lessThan(controlTableDdl));
        expect(
          mainSource.substring(statusBranch, controlTableDdl),
          allOf(
            contains('SELECT version FROM schema_migrations'),
            contains("error.code != '42P01'"),
            isNot(contains('CREATE TABLE')),
          ),
        );
      },
    );

    test('every master optimizer apply-pg branch requires approval', () {
      for (final relativePath in const [
        'server/bin/master_optimizer_preflight.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_preflight_cron.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_slot_scan_cron.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_auto_cycle_cron.sh',
      ]) {
        final source = scriptSource(relativePath);
        final applyFlag = source.indexOf('MANALOOM_BATTLE_RULES_APPLY_PG');
        final approval = source.indexOf(
          'require_postgres_write_approval',
          applyFlag,
        );
        final secretEnvironmentLoad = source.indexOf(r'. "$SECRET_ENV"');
        final applyArgument = source.indexOf('--apply-pg', applyFlag);

        expect(source, contains('manaloom_mutation_guard.sh'));
        expect(source, contains('BATTLE_RULES_APPLY_PG_REQUESTED='));
        expect(applyFlag, greaterThanOrEqualTo(0));
        expect(approval, greaterThan(applyFlag));
        expect(secretEnvironmentLoad, greaterThan(approval));
        expect(approval, lessThan(applyArgument));
      }
    });

    test('master optimizer apply-pg flags block before loading secrets', () async {
      for (final relativePath in const [
        'server/bin/master_optimizer_preflight.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_preflight_cron.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_slot_scan_cron.sh',
        'docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_auto_cycle_cron.sh',
      ]) {
        final result = await Process.run(
          'bash',
          ['$repoRoot/$relativePath'],
          environment: {
            'MANALOOM_REPO': repoRoot,
            'MANALOOM_BATTLE_RULES_APPLY_PG': '1',
            'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
          },
          includeParentEnvironment: true,
        );

        expect(result.exitCode, 2, reason: relativePath);
        expect('${result.stderr}', contains('BLOCKED:'), reason: relativePath);
      }
    });

    test('retained legacy Python live suites keep their explicit guard', () {
      for (final relativePath in const [
        'server/test/e2e_general_tests.py',
        'server/test/e2e_ml_tests.py',
        'server/test/e2e_trade_tests.py',
      ]) {
        final source = scriptSource(relativePath);
        expect(source, contains('require_legacy_live_e2e_approval'));
        expect(
          source.lastIndexOf('require_legacy_live_e2e_approval('),
          lessThan(
            source.lastIndexOf('TestRunner(') >= 0
                ? source.lastIndexOf('TestRunner(')
                : source.lastIndexOf('MLTestSuite('),
          ),
        );
      }
    });
  });
}
