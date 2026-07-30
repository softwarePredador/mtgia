import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.path;

  String source(String relativePath) =>
      File('$repoRoot/$relativePath').readAsStringSync();

  late String sidecars;
  late String backend;
  late String runtimeContract;

  setUpAll(() {
    sidecars = source('scripts/manaloom_deploy_battle_sidecars.sh');
    backend = source('scripts/manaloom_deploy_backend_image.sh');
    runtimeContract = source(
      'scripts/lib/manaloom_release_runtime_contract.sh',
    );
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

  group('backend interactive release opt-in', () {
    test('preflights same-SHA private runtime before backend mutation', () {
      final preflight = backend.indexOf(
        r'require_xmage_interactive_release_contract "$sha"',
      );
      final firstBackendMutation = backend.indexOf(
        '# Bootstrap one server-side operations credential',
      );
      final mutation = backend.indexOf('DEPLOY_MUTATION_STARTED=1');
      expect(preflight, greaterThanOrEqualTo(0));
      expect(firstBackendMutation, greaterThan(preflight));
      expect(mutation, greaterThan(preflight));
      expect(
        backend,
        contains(
          r'! "$spec_image" =~ ^localhost:5000/manaloom/xmage-sidecar@sha256:[0-9a-f]{64}$',
        ),
      );
      expect(backend, contains(r'"$image_revision" != "$expected_sha"'));
      expect(backend, contains(r'"$ports" != "0"'));
      expect(backend, contains(r'"$network_count" != "1"'));
      expect(backend, contains(r'"$alias_attached" != "1"'));
      expect(backend, contains(r'"$traefik_labels" != "0"'));
    });

    test('writes exact config and requires ready only when explicitly on', () {
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
      expect(backend, contains(r'if $interactive_enabled == "true" then'));
      expect(
        backend,
        contains('.checks.interactive_battle.runtime_isolation =='),
      );
      expect(backend, contains('.checks.interactive_battle.maximum_active =='));
      expect(
        backend,
        contains('.checks.interactive_battle.status == "disabled" and'),
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
        expect(
          '${result.stderr}',
          contains(
            'MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE deve ser 0 ou 1',
          ),
          reason: relativePath,
        );
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
}
