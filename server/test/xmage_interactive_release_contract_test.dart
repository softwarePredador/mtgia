import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.path;

  String source(String relativePath) =>
      File('$repoRoot/$relativePath').readAsStringSync();

  late String sidecars;
  late String backend;
  late String runtimeContract;
  late String localE2e;
  late String isolatedServerE2e;
  late String sidecarEntrypoint;

  setUpAll(() {
    sidecars = source('scripts/manaloom_deploy_battle_sidecars.sh');
    backend = source('scripts/manaloom_deploy_backend_image.sh');
    runtimeContract = source(
      'scripts/lib/manaloom_release_runtime_contract.sh',
    );
    localE2e = source('scripts/manaloom_play_vs_ai_e2e.sh');
    isolatedServerE2e = source(
      'scripts/manaloom_server_contract_e2e_isolated.sh',
    );
    sidecarEntrypoint = source('services/xmage-sidecar/entrypoint.sh');
  });

  group('dedicated XMage interactive release', () {
    test('is caller-opt-in and cannot be enabled by persistent dotenv', () {
      const capture =
          r'RELEASE_ENABLE_INTERACTIVE_BATTLE="${MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE:-0}"';
      for (final script in [sidecars, backend]) {
        final captureIndex = script.indexOf(capture);
        final approvalIndex = script.indexOf('require_live_mutation_approval');
        final envLoadIndex = script.indexOf(
          r'load_manaloom_env_keys "$ENV_FILE"',
        );
        expect(captureIndex, greaterThanOrEqualTo(0));
        expect(approvalIndex, greaterThan(captureIndex));
        expect(envLoadIndex, greaterThan(approvalIndex));

        final envLoadEnd = script.indexOf('\n\n', envLoadIndex);
        final allowlist = script.substring(envLoadIndex, envLoadEnd);
        expect(
          allowlist,
          isNot(contains('MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE')),
        );
        expect(
          allowlist,
          isNot(contains('MANALOOM_RELEASE_XMAGE_INTERACTIVE_MAX_ACTIVE')),
        );
      }
      expect(
        sidecars,
        contains('INTERACTIVE_BATTLE_ENABLED=false'),
        reason: 'sidecar preparation must not enable an older backend revision',
      );
      expect(sidecars, contains('"backend_interactive_enabled":false'));
    });

    test(
      'uses one immutable XMage digest in a private direct Swarm service',
      () {
        expect(
          runtimeContract,
          contains(
            'MANALOOM_PRODUCTION_XMAGE_INTERACTIVE_SERVICE='
            '"evolution_xmage-interactive"',
          ),
        );
        expect(
          runtimeContract,
          contains(
            'MANALOOM_PRODUCTION_XMAGE_INTERACTIVE_DNS="xmage-interactive"',
          ),
        );
        expect(
          sidecars,
          contains(
            r'deploy_xmage_interactive_digest "$XMAGE_IMAGE_DIGEST_REF"',
          ),
        );
        expect(sidecars, contains("--image '\$image_digest_ref'"));
        expect(sidecars, contains(r"'$image_digest_ref' >/dev/null"));
        expect(
          sidecars,
          contains(
            r'xmage_interactive_release_proof "$XMAGE_IMAGE_DIGEST_REF"',
          ),
        );
        expect(sidecars, contains('org.opencontainers.image.revision'));
        expect(sidecars, contains(r'"$image_revision" != "$sha"'));
        expect(
          sidecars,
          contains(
            "--network 'name=\$PROJECT_NETWORK,alias=\$XMAGE_INTERACTIVE_DNS'",
          ),
        );
        expect(sidecars, contains(r'"$topology" != "0|1|1|1|0"'));
        expect(sidecars, isNot(contains('--publish')));
        expect(sidecars, isNot(contains('traefik.http.routers')));
        expect(sidecars, contains(r"'/^traefik\\./{count++}"));
        expect(
          sidecars,
          contains(
            'XMage interativo deve permanecer direct Swarm '
            'sem source EasyPanel concorrente',
          ),
        );
      },
    );

    test('pins mode, identity and bounded capacity in health proof', () {
      for (final fragment in const [
        'XMAGE_RUNTIME_MODE=interactive',
        'XMAGE_INTERACTIVE_MAX_ACTIVE=\$INTERACTIVE_MAX_ACTIVE',
        '.schema_version == "external_battle_execution_v2"',
        '.engine_patch_commit == \$patch_commit',
        '"xmage-sidecar-v2@" + \$commit + "+patch." + \$patch_commit',
        '.runtime_mode == "interactive"',
        '.batch_simulation_available == false',
        '.interactive_battle.schema_version ==',
        '"interactive_battle_runtime_v1"',
        '.interactive_battle.maximum_active == \$maximum_active',
        '.interactive_battle.active <= \$maximum_active',
      ]) {
        expect(sidecars, contains(fragment), reason: fragment);
      }
      expect(
        sidecars,
        contains(
          r'INTERACTIVE_MAX_ACTIVE="${MANALOOM_RELEASE_XMAGE_INTERACTIVE_MAX_ACTIVE:-4}"',
        ),
      );
      expect(sidecars, contains(r'"$INTERACTIVE_MAX_ACTIVE" -gt 32'));
      expect(
        backend,
        contains(
          r'INTERACTIVE_PER_USER_ACTIVE_LIMIT="${MANALOOM_RELEASE_INTERACTIVE_PER_USER_ACTIVE_LIMIT:-1}"',
        ),
      );
      expect(
        backend,
        contains(
          r'"$INTERACTIVE_PER_USER_ACTIVE_LIMIT" -gt "$INTERACTIVE_MAX_ACTIVE"',
        ),
      );
    });

    test('requires the governed patch proof before building or deploying', () {
      expect(sidecars, contains('xmage_governed_patch_audit.py'));
      expect(sidecars, contains('--require-deployable'));
      expect(
        sidecars,
        contains(
          'docs/qa/evidence/'
          'LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch',
        ),
      );
      expect(sidecars, contains('XMAGE_EXPECTED_PATCH_COMMIT'));
      expect(backend, contains('XMAGE_EXPECTED_PATCH_COMMIT'));
    });

    test('rolls back updates and removes an uncommitted first install', () {
      expect(sidecars, contains('rollback_xmage_interactive()'));
      expect(
        sidecars,
        contains(r'if [[ "$XMAGE_INTERACTIVE_PREVIOUS_EXISTS" == "0" ]]'),
      );
      expect(
        sidecars,
        contains("docker service rm '\$XMAGE_INTERACTIVE_SERVICE'"),
      );
      expect(
        sidecars,
        contains(
          "docker service update --detach=true --rollback "
          "'\$XMAGE_INTERACTIVE_SERVICE'",
        ),
      );
      expect(sidecars, contains(r'"$XMAGE_INTERACTIVE_PREVIOUS_SPEC_IMAGE"'));
      expect(
        sidecars,
        contains(r'"$XMAGE_INTERACTIVE_PREVIOUS_ENGINE_COMMIT"'),
      );
      expect(
        sidecars,
        contains('rollback automatico XMage interativo comprovado'),
      );
      final rollback = sidecars.indexOf('rollback_xmage_interactive ||');
      final forgeRollback = sidecars.indexOf(
        r'if [[ "$FORGE_MUTATION_STARTED" == "1" ]]',
      );
      expect(rollback, greaterThanOrEqualTo(0));
      expect(forgeRollback, greaterThan(rollback));
    });
  });

  group('backend interactive release containment', () {
    test('binds all-OFF policy before mutation without runtime preflight', () {
      final preflight = backend.indexOf(
        r'require_xmage_interactive_release_contract "$sha"',
      );
      final capabilityPolicy = backend.indexOf(
        r'manaloom_load_release_capabilities_from_git "$ROOT_DIR" "$sha"',
      );
      final mutation = backend.indexOf('DEPLOY_MUTATION_STARTED=1');
      expect(preflight, -1);
      expect(capabilityPolicy, greaterThanOrEqualTo(0));
      expect(mutation, greaterThan(capabilityPolicy));
      expect(backend, contains('INTERACTIVE_BATTLE_ENABLED=false'));
      expect(backend, contains('BATTLE_LIVE_SPECTATOR_ENABLED=false'));
    });

    test('writes disabled config and requires disabled readiness', () {
      expect(
        backend,
        contains(
          "--env-add INTERACTIVE_BATTLE_ENABLED="
          "'\$INTERACTIVE_BATTLE_ENABLED'",
        ),
      );
      expect(
        backend,
        contains(
          "--env-add XMAGE_INTERACTIVE_SIDECAR_URL="
          "'\$XMAGE_INTERACTIVE_URL'",
        ),
      );
      expect(
        backend,
        contains(
          "--env-add XMAGE_EXPECTED_PATCH_COMMIT="
          "'\$XMAGE_EXPECTED_PATCH_COMMIT'",
        ),
      );
      expect(backend, contains('expected_interactive_contract='));
      expect(
        backend,
        contains(
          r'"$runtime_interactive_contract" != "$expected_interactive_contract"',
        ),
      );
      expect(
        backend,
        isNot(contains(r'if $interactive_enabled == "true" then')),
      );
      expect(
        backend,
        contains(
          'disabled_by_policy(.checks.interactive_battle; "battle_coach")',
        ),
      );
    });

    test('invalid opt-in fails before reading env or requesting approval', () {
      for (final relativePath in const [
        'scripts/manaloom_deploy_battle_sidecars.sh',
        'scripts/manaloom_deploy_backend_image.sh',
      ]) {
        final result = Process.runSync(
          '/bin/bash',
          ['$repoRoot/$relativePath'],
          environment: const {
            'MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE': 'yes',
            'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
            'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
            'MANALOOM_NEW_SERVER_ENV': '/definitely/not/read.env',
          },
          includeParentEnvironment: true,
        );
        expect(result.exitCode, 2, reason: relativePath);
        expect('${result.stderr}', contains('deve'), reason: relativePath);
        expect(
          '${result.stderr}',
          isNot(contains('env file')),
          reason: relativePath,
        );
        expect(
          '${result.stderr}',
          isNot(contains('arquivo de ambiente')),
          reason: relativePath,
        );
      }
    });
  });

  group('isolated Play vs AI E2E containment', () {
    test('requires approvals, Java 17 and exact governed pins', () {
      for (final fragment in const [
        'require_postgres_write_approval',
        'require_live_mutation_approval',
        '/usr/libexec/java_home -v 17',
        'java.specification.version',
        '^Java version: 17',
        '2c43ec8cdb5cd475d47e6b555a4077151f476a3b',
        '991948742f840cd88493a4ea8cb3f4ed192e4742',
        'xmage_governed_patch_audit.py',
        '--require-deployable',
      ]) {
        expect(localE2e, contains(fragment), reason: fragment);
      }
    });

    test('uses distinct loopback runtimes and explicit H2/JBoss binds', () {
      for (final fragment in const [
        'XMAGE_SIDECAR_HTTP_HOST=127.0.0.1',
        'XMAGE_SERVER_HOST=127.0.0.1',
        'XMAGE_RUNTIME_MODE=batch',
        'XMAGE_RUNTIME_MODE=interactive',
        'XMAGE_INTERACTIVE_MAX_ACTIVE=4',
        '-Dh2.bindAddress=127.0.0.1',
        'secondaryBindPort=',
        'assert_pid_loopback_listeners',
        'sidecar_process_id',
      ]) {
        expect(localE2e, contains(fragment), reason: fragment);
      }
      expect(sidecarEntrypoint, contains('-Dh2.bindAddress=127.0.0.1'));
      expect(sidecarEntrypoint, contains('secondaryBindPort='));
    });

    test('enables only the isolated minimum and runs the real test', () {
      for (final capability in const [
        'account_registration',
        'decks_private',
        'battle_batch',
        'battle_coach',
      ]) {
        expect(localE2e, contains('"$capability"'));
      }
      expect(localE2e, contains('test/play_vs_ai_real_xmage_e2e_test.dart'));
      expect(localE2e, contains('MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE'));
      expect(
        isolatedServerE2e,
        contains('final address = InternetAddress.loopbackIPv4;'),
      );
      expect(isolatedServerE2e, contains('cleanup.txt'));
    });

    test('publishes proof only after cleanup and denies release credit', () {
      final cleanup = localE2e.indexOf('cleanup_runtime');
      final pass = localE2e.indexOf('PASS: Play vs AI real XMage E2E');
      expect(cleanup, greaterThanOrEqualTo(0));
      expect(pass, greaterThan(cleanup));
      for (final fragment in const [
        'database_remaining=0',
        'api_listeners=0',
        'email_fixture_listeners=0',
        'strategy_superiority_proven: false',
        'release_ready: false',
        'latest.json',
      ]) {
        expect(localE2e, contains(fragment), reason: fragment);
      }
    });

    test('browser QA binds real Web evidence to the current UI digest', () {
      for (final fragment in const [
        'MANALOOM_PLAY_VS_AI_BROWSER_QA',
        'run_browser_qa',
        'scripts/manaloom_ui_source_digest.sh',
        'ui_runtime_evidence.dart',
        'validate-directory',
        'index-directory',
        'PASS_RUNTIME',
        'PASS_VISUAL_REVIEWED',
        'web_play_vs_ai_1440x900',
        'overall_ui_proof_claimed: false',
      ]) {
        expect(localE2e, contains(fragment), reason: fragment);
      }
      expect(
        localE2e,
        isNot(contains('visual_fixture_arcane_artificer.webp')),
        reason: 'real card names must not be paired with fictional art',
      );
      expect(
        localE2e,
        isNot(contains('MANALOOM_ALLOW_DEV_ORIGINS=true')),
        reason: 'the browser QA proxy is same-origin under /api',
      );
    });

    test('browser QA child exits normally and proves bounded cleanup', () {
      for (final fragment in const [
        'MANALOOM_BROWSER_QA_COMPLETION_FILE',
        'PASS: isolated browser QA fixture completed',
        'browser_completion=pass',
        'terminate_fixture_pid',
        'forced_kill_used=',
      ]) {
        expect(isolatedServerE2e, contains(fragment), reason: fragment);
      }
      expect(localE2e, contains('forced_kill_used=0'));
      expect(localE2e, contains('browser-server-contract-cleanup.txt'));
    });

    test('browser QA validates disposable rows without psql interpolation', () {
      expect(localE2e, contains("deck_a_id = '\$browser_human_deck_id'::uuid"));
      expect(localE2e, contains("session_id = '\$browser_session_id'::uuid"));
      expect(localE2e, isNot(contains(":'deck_a_id'")));
      expect(localE2e, isNot(contains(":'session_id'")));
    });
  });
}
