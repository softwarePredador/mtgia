import 'dart:io';

import 'package:test/test.dart';

String script(String name) => File('../scripts/$name').readAsStringSync();

void main() {
  final deploys = <String, String>{
    'backend': script('manaloom_deploy_backend_image.sh'),
    'public-web': script('manaloom_deploy_public_web.sh'),
    'flutter-web': script('manaloom_deploy_flutter_web.sh'),
    'android': script('manaloom_publish_android_release.sh'),
  };

  test('every production service uses monitored automatic Swarm rollback', () {
    for (final entry in deploys.entries) {
      // O backend escolhe entre rollback e pause pela guarda da migration
      // (teste abaixo); os outros serviços não dependem do banco.
      expect(
        entry.value,
        contains(
          entry.key == 'backend'
              ? "--update-failure-action '\$SWARM_UPDATE_FAILURE_ACTION'"
              : '--update-failure-action rollback',
        ),
        reason: entry.key,
      );
      expect(entry.value, contains('--update-monitor 30s'), reason: entry.key);
      expect(
        entry.value,
        contains('--rollback-failure-action pause'),
        reason: entry.key,
      );
      expect(
        entry.value,
        contains('--rollback-monitor 30s'),
        reason: entry.key,
      );
      expect(entry.value, contains('rollback_paused'), reason: entry.key);
    }
  });

  test(
    'previous origin and immutable running image are captured pre-mutation',
    () {
      for (final entry in deploys.entries) {
        final source = entry.value;
        final sourceCapture = source.indexOf('PREVIOUS_SOURCE_IMAGE="\$(jq');
        final runtimeCapture = source.indexOf(
          entry.key == 'backend'
              ? 'previous_runtime_state="\$(ssh'
              : 'PREVIOUS_RUNTIME_STATE="\$(ssh',
        );
        final mutation = source.indexOf('DEPLOY_MUTATION_STARTED=1');

        expect(sourceCapture, greaterThanOrEqualTo(0), reason: entry.key);
        expect(runtimeCapture, greaterThan(sourceCapture), reason: entry.key);
        expect(mutation, greaterThan(runtimeCapture), reason: entry.key);
        expect(
          source,
          contains(r'! "$PREVIOUS_SPEC_IMAGE" =~ @sha256:[0-9a-f]{64}$'),
          reason: entry.key,
        );
        expect(
          source,
          contains(r'"$PREVIOUS_RUNNING_IMAGE" != "$PREVIOUS_SPEC_IMAGE"'),
          reason: entry.key,
        );
        expect(source, contains('DEPLOY_COMMITTED=1'), reason: entry.key);
      }
    },
  );

  test('rollback additions preserve caller approval and verified SSH', () {
    const approvals = {
      'backend': 'require_live_mutation_approval "deploy do backend ManaLoom"',
      'public-web':
          'require_live_mutation_approval "deploy do site publico ManaLoom"',
      'flutter-web':
          'require_live_mutation_approval "ManaLoom Flutter Web deployment"',
      'android':
          'require_live_mutation_approval "ManaLoom Android release publication"',
    };
    for (final entry in deploys.entries) {
      final source = entry.value;
      final approval = source.indexOf(approvals[entry.key]!);
      final envLoad = source.indexOf(r'load_manaloom_env_keys "$ENV_FILE"');
      expect(approval, greaterThanOrEqualTo(0), reason: entry.key);
      expect(envLoad, greaterThan(approval), reason: entry.key);
      expect(
        source,
        contains(r'initialize_manaloom_secure_ssh "$SSH_HOST"'),
        reason: entry.key,
      );
      expect(
        source,
        isNot(contains('StrictHostKeyChecking=accept-new')),
        reason: entry.key,
      );
    }
  });

  test(
    'Flutter Web restores source, digest and exact prior release health',
    () {
      final source = deploys['flutter-web']!;

      expect(source, contains('rollback_flutter_web()'));
      expect(source, contains(r'--arg image "$ROLLBACK_SOURCE_IMAGE"'));
      expect(source, contains(r'ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"'));
      expect(source, contains("--image '\$PREVIOUS_SPEC_IMAGE'"));
      expect(source, contains('flutter_web_release_marker()'));
      expect(source, contains('PREVIOUS_RELEASE_MARKER='));
      expect(source, contains(r'"$PUBLIC_BASE_URL/app/release.json"'));
      expect(
        source,
        contains(r'"$release_marker" == "$PREVIOUS_RELEASE_MARKER"'),
      );
      expect(source, contains('servico Flutter Web precisa existir'));
      expect(source, isNot(contains('services.app.createService')));
      expect(source, contains('rollback Flutter Web comprovado'));
    },
  );

  test('Android restores source, digest and exact prior public APK', () {
    final source = deploys['android']!;

    expect(source, contains('rollback_android_release_host()'));
    expect(source, contains(r'--arg image "$ROLLBACK_SOURCE_IMAGE"'));
    expect(source, contains(r'ROLLBACK_SOURCE_IMAGE="$PREVIOUS_SPEC_IMAGE"'));
    expect(source, contains("--image '\$PREVIOUS_SPEC_IMAGE'"));
    expect(source, contains('PREVIOUS_PUBLIC_APK_HASH='));
    expect(source, contains(r'"$public_hash" == "$PREVIOUS_PUBLIC_APK_HASH"'));
    expect(source, contains('release host precisa existir'));
    expect(source, isNot(contains('services.app.createService')));
    expect(source, contains('rollback Android comprovado'));
  });

  test('public web persists and proves the new EasyPanel digest', () {
    final source = deploys['public-web']!;
    final swarmConvergence = source.indexOf('servico publico nao convergiu');
    final sourceMutation = source.lastIndexOf('SOURCE_MUTATED=1');
    final configuredProof = source.indexOf(
      'web-public convergiu sem o digest exato na origem EasyPanel',
    );
    final smoke = source.indexOf(
      'manaloom_public_web_required_routes',
      configuredProof,
    );

    expect(swarmConvergence, greaterThanOrEqualTo(0));
    expect(sourceMutation, greaterThan(swarmConvergence));
    expect(configuredProof, greaterThan(sourceMutation));
    expect(smoke, greaterThan(configuredProof));
    expect(source, contains('rollback_public_web()'));
    expect(source, contains('services.app.updateSourceImage'));
    expect(source, contains(r'--arg image "$IMAGE_DIGEST_REF"'));
    expect(source, contains(r'--arg image "$ROLLBACK_SOURCE_IMAGE"'));
    expect(source, contains('rollback web-public comprovado'));
  });

  test(
    'backend only rolls back automatically to an image that accepts the '
    'migrated database (D-104, item 12)',
    () {
      final source = deploys['backend']!;
      final guard = source.indexOf('# >>> guarda do rollback automatico');
      final guardEnd = source.indexOf('# <<< guarda do rollback automatico');
      final capture = source.indexOf('previous_runtime_state="\$(ssh');
      final mutation = source.indexOf('\nDEPLOY_MUTATION_STARTED=1\n');
      final update = source.indexOf(
        "--update-failure-action '\$SWARM_UPDATE_FAILURE_ACTION'",
      );

      expect(
        source,
        contains(
          'source "\$ROOT_DIR/scripts/lib/manaloom_backend_rollback_guard.sh"',
        ),
      );
      expect(guard, greaterThan(capture));
      expect(guardEnd, greaterThan(guard));
      expect(mutation, greaterThan(guardEnd));
      expect(update, greaterThan(mutation));
      expect(source, isNot(contains('--update-failure-action rollback')));
      expect(source, contains('SWARM_UPDATE_FAILURE_ACTION="pause"'));
      final block = source.substring(guard, guardEnd);
      expect(block, contains("awk '/^GIT_SHA=/"));
      expect(
        block,
        contains(
          'manaloom_readiness_required_migration "\$ROOT_DIR" "\$PREVIOUS_GIT_SHA"',
        ),
      );
      expect(block, contains('with_new_server_pg.sh" --read-only'));
      expect(block, contains('MAX(version)'));
      expect(block, contains('manaloom_swarm_update_failure_action'));

      final rollback = source.indexOf('rollback_backend_deploy() {');
      final refusal = source.indexOf(
        'if [[ "\$BACKEND_ROLLBACK_POLICY" != "rollback" ]]; then',
        rollback,
      );
      final firstRemote = source.indexOf('trpc_post', rollback);
      expect(refusal, greaterThan(rollback));
      expect(refusal, lessThan(firstRemote));
      expect(
        source.substring(refusal, firstRemote),
        contains('manaloom_backend_restore_path'),
      );
    },
  );

  test('backend restores the prior full Swarm spec and readiness', () {
    final source = deploys['backend']!;

    expect(source, contains('rollback_backend_deploy()'));
    expect(source, contains('docker service update --detach=true --rollback'));
    expect(source, contains(r'--arg image "$ROLLBACK_SOURCE_IMAGE"'));
    expect(source, contains(r'"$API_BASE_URL/health/ready"'));
    expect(source, contains('rollback backend comprovado'));
  });
}
