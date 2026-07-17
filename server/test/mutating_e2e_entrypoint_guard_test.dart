import 'dart:io';

import 'package:test/test.dart';

import '../bin/run_three_commander_optimization_validation.dart'
    as three_commander_validation;

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

    test('resolution corpus gates every runner before mutation', () {
      final source = scriptSource('scripts/quality_gate_resolution_corpus.sh');
      final preflight = source.indexOf(
        'print_header "Preflight read-only do corpus"',
      );
      final liveApproval = source.indexOf(
        'require_live_mutation_approval "Commander resolution corpus PostgreSQL runner"',
      );
      final postgresApproval = source.indexOf(
        'require_postgres_write_approval "Commander resolution corpus PostgreSQL runner"',
      );
      final preflightRunner = source.indexOf(
        'with_new_server_pg.sh" --write-approved',
        postgresApproval,
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
      expect(liveApproval, greaterThan(preflight));
      expect(postgresApproval, greaterThan(liveApproval));
      expect(preflightRunner, greaterThan(postgresApproval));
      expect(identityPrecheck, greaterThan(preflightRunner));
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
      expect(source, contains('dart_frog build'));
      expect(source, contains('dart run build/bin/server.dart'));
      expect(source, contains('server_build.log'));
      expect(source, contains('InternetAddress.loopbackIPv4'));
      expect(source, contains(r'assert_listener_closed "$PORT"'));
      expect(source, contains('SERVER_LISTENER_PIDS='));
      expect(source, contains('capture_listener_pids'));
      expect(source, contains('collect_process_tree_pids'));
      expect(source, contains('kill -KILL'));
      expect(source, contains('"runtime_cleanup"'));
      expect(source, contains(r'assert_loopback_listener "$PORT"'));
      expect(source, isNot(contains('dart_frog dev')));
      expect(
        source,
        contains(r'MANALOOM_E2E_VALIDATION_RUN_TOKEN="$RUN_TOKEN"'),
      );
      expect(source, contains('VALIDATION_DEFER_CLEANUP_TO_HARNESS=1'));
      expect(source, contains('RATE_LIMIT_DISTRIBUTED=false'));
      expect(source, contains('MANALOOM_E2E_ISOLATED_RUNTIME=1'));
      expect(source, contains('e2e_isolated_runtime'));
      expect(source, contains('"telemetry_deleted": cleanup_ok == "1"'));
      expect(source, contains('manaloom_validation_user_ids'));
      expect(source, contains('manaloom_validation_deck_ids'));
      expect(source, contains("decisions_reasoning->>'validation_run_token'"));
      expect(source, contains('manaloom_validation_context'));
      expect(source, contains('SELECT run_started_at'));
      expect(source, contains(r'DO $telemetry_postcheck$'));
      expect(source, contains("'postcheck_passed', true"));
      expect(source, contains('RAISE EXCEPTION'));
      expect(source, contains('deck_learning_events'));
      expect(source, contains('ai_optimize_jobs'));
      expect(source, contains('commander_card_usage'));
      expect(source, contains('manaloom_validation_usage_adjustments'));
      expect(source, contains('UPDATE commander_card_usage'));
      expect(source, contains('DELETE FROM commander_card_usage'));
      expect(source, contains('ml_prompt_feedback_delta'));
      expect(source, contains('"learning_write_guard"'));

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
          contains('DELETE FROM ${table.toUpperCase()}'),
          reason: table,
        );
      }
    });

    test('Battle product E2E has an honest isolated mutating entrypoint', () async {
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
      final liveApproval = isolatedSource.indexOf(
        'require_live_mutation_approval "Battle product isolated mutating E2E"',
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
      expect(liveApproval, greaterThanOrEqualTo(0));
      expect(approval, greaterThan(liveApproval));
      expect(mutationArmed, greaterThan(approval));
      expect(
        isolatedSource,
        contains('with_new_server_pg.sh" --write-approved env'),
      );
      expect(runner, greaterThan(mutationArmed));
      expect(runnerStatus, greaterThan(runner));
      expect(listenerCheck, greaterThan(runnerStatus));
      expect(cleanup, greaterThan(listenerCheck));
      expect(audit, greaterThan(cleanup));
      expect(isolatedSource, contains('dart_frog build'));
      expect(isolatedSource, contains('dart run build/bin/server.dart'));
      expect(
        isolatedSource,
        contains('final address = InternetAddress.loopbackIPv4;'),
      );
      expect(isolatedSource, isNot(contains('dart_frog dev')));
      expect(isolatedSource, isNot(contains('--dart-vm-service-port')));
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
        ['$repoRoot/scripts/manaloom_battle_product_gate.sh', '--isolated-e2e'],
        environment: const {
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
          'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
        },
        includeParentEnvironment: true,
      );
      expect(blocked.exitCode, 2);
      expect('${blocked.stderr}', contains('BLOCKED:'));
    });

    test('E2E suite aggregates Battle isolated execution or a real skip', () {
      final source = scriptSource('scripts/manaloom_e2e_suite.sh');
      final runner = source.indexOf('run_battle_product_e2e()');
      final functionEnd = source.indexOf('\n}\n', runner);
      final battleFunction = source.substring(runner, functionEnd);
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
      expect(
        battleFunction,
        contains(r'${MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E:-0}'),
      );
      expect(battleFunction, isNot(contains('E2E_PROFILE')));
      expect(
        battleFunction,
        isNot(contains('MANALOOM_RUN_MUTATING_RESOLUTION_E2E')),
      );
    });

    test('E2E suite pins ramp, foundation and rules safety contracts', () {
      final source = scriptSource('scripts/manaloom_e2e_suite.sh');
      final runner = source.indexOf('run_ramp_and_data_foundation_contracts()');
      final functionEnd = source.indexOf('\n}\n', runner);
      final focusedFunction = source.substring(runner, functionEnd);

      expect(runner, greaterThanOrEqualTo(0));
      expect(
        source.indexOf('run_ramp_and_data_foundation_contracts\n', runner),
        greaterThan(functionEnd),
      );
      for (final contract in const [
        'test/ramp_family_classifier_test.dart',
        'test/optimization_ramp_profile_test.dart',
        'test/optimization_quality_gate_test.dart',
        'test/optimization_validator_test.dart',
        'test/ramp_floor_consumer_contract_test.dart',
        'test/functional_card_tags_test.dart',
        'test/optimize_filler_loader_support_test.dart',
        'test/optimize_functional_role_support_test.dart',
        'test/optimize_removal_candidate_support_test.dart',
        'test/optimize_swap_candidate_support_test.dart',
        'test/candidate_quality_data_foundation_preflight_test.dart',
        'test/candidate_quality_data_foundation_source_test.dart',
        'test/semantic_tag_query_contract_test.dart',
        'test/sync_rules_safety_test.dart',
        'test/magic_rules_source_test.dart',
        'test_scryfall_classifier_multi_tags.py',
      ]) {
        expect(focusedFunction, contains(contract), reason: contract);
      }
      expect(
        focusedFunction,
        contains('semantic_layer_v2_backfill*_test.dart'),
      );
      expect(focusedFunction, contains('RUN_INTEGRATION_TESTS=0'));
      expect(focusedFunction, isNot(contains('--apply')));
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

    test('three-commander runtime is dry-run by default', () {
      expect(
        three_commander_validation.ThreeCommanderRuntimeConfig.parse(
          const [],
        ).dryRun,
        isTrue,
      );
      expect(
        three_commander_validation.ThreeCommanderRuntimeConfig.parse(const [
          '--dry-run',
        ]).dryRun,
        isTrue,
      );
      expect(
        three_commander_validation.ThreeCommanderRuntimeConfig.parse(const [
          '--apply',
        ]).apply,
        isTrue,
      );
      expect(
        () => three_commander_validation.ThreeCommanderRuntimeConfig.parse(
          const ['--apply', '--dry-run'],
        ),
        throwsArgumentError,
      );
      expect(
        () => three_commander_validation.ThreeCommanderRuntimeConfig.parse(
          const ['--unknown'],
        ),
        throwsArgumentError,
      );
    });

    test('Dart deck runtime apply guards are before environment and I/O', () {
      final commanderSource = scriptSource(
        'server/bin/run_commander_only_optimization_validation.dart',
      );
      final commanderMain = commanderSource.substring(
        commanderSource.indexOf('Future<void> main(List<String> args)'),
      );
      final commanderGuard = commanderMain.indexOf(
        'if (config.apply && !_hasLiveMutationApproval())',
      );
      expect(commanderGuard, greaterThanOrEqualTo(0));
      for (final firstExternalOperation in const [
        'loadRuntimeEnvironment(',
        'Directory(artifactDirPath)',
        '_validateApiBaseUrl(apiBaseUrl)',
        'Database()',
      ]) {
        expect(
          commanderGuard,
          lessThan(commanderMain.indexOf(firstExternalOperation)),
          reason: firstExternalOperation,
        );
      }

      final threeSource = scriptSource(
        'server/bin/run_three_commander_optimization_validation.dart',
      );
      final threeMain = threeSource.substring(
        threeSource.indexOf('Future<void> main(List<String> args)'),
      );
      final threeGuard = threeMain.indexOf(
        'if (config.apply && !_hasLiveMutationApproval())',
      );
      expect(threeGuard, greaterThanOrEqualTo(0));
      for (final firstExternalOperation in const [
        'loadRuntimeEnvironment(',
        'Database()',
        '_ensureServerIsReachable(apiBaseUrl)',
        'Directory(_artifactDirPath)',
      ]) {
        expect(
          threeGuard,
          lessThan(threeMain.indexOf(firstExternalOperation)),
          reason: firstExternalOperation,
        );
      }
      final dryRunReturn = threeMain.indexOf('if (config.dryRun)');
      expect(dryRunReturn, greaterThan(threeMain.indexOf('Database()')));
      expect(
        dryRunReturn,
        lessThan(threeMain.indexOf('_ensureServerIsReachable(apiBaseUrl)')),
      );

      final wrapperSource = scriptSource(
        'server/bin/mana_loom_deck_runtime_e2e.dart',
      );
      final wrapperGuard = wrapperSource.indexOf('if (config.apply &&');
      final delegation = wrapperSource.indexOf(
        'commander_only_validation.main(args)',
      );
      expect(wrapperGuard, greaterThanOrEqualTo(0));
      expect(wrapperGuard, lessThan(delegation));

      for (final source in [commanderSource, threeSource, wrapperSource]) {
        expect(source, contains('MANALOOM_CONFIRM_LIVE_MUTATIONS'));
        expect(source, contains('I_HAVE_EXPLICIT_APPROVAL'));
      }
    });

    test(
      'Dart deck runtime apply entrypoints fail closed without approval',
      () async {
        for (final relativePath in const [
          'bin/run_commander_only_optimization_validation.dart',
          'bin/mana_loom_deck_runtime_e2e.dart',
          'bin/run_three_commander_optimization_validation.dart',
        ]) {
          final result = await Process.run(
            'dart',
            ['run', relativePath, '--apply'],
            workingDirectory: '$repoRoot/server',
            environment: const {'MANALOOM_CONFIRM_LIVE_MUTATIONS': ''},
            includeParentEnvironment: true,
          );

          expect(result.exitCode, 2, reason: relativePath);
          expect(
            '${result.stderr}',
            contains('BLOCKED:'),
            reason: relativePath,
          );
          expect(
            '${result.stdout}${result.stderr}',
            isNot(contains('Conectando ao banco')),
            reason: relativePath,
          );
        }
      },
    );
  });
}
