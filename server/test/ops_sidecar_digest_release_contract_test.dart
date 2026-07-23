import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.path;

  String script(String name) =>
      File('$repoRoot/scripts/$name').readAsStringSync();

  group('immutable ops image release', () {
    late String ops;

    setUpAll(() {
      ops = script('manaloom_deploy_ops_image.sh');
    });

    test('resolves and validates the registry RepoDigest before mutation', () {
      expect(ops, contains('.RepoDigests'));
      expect(ops, contains('readonly IMAGE_DIGEST_REF'));
      expect(ops, contains(r'! "$image_digest" =~ ^[0-9a-f]{64}$'));

      final digestLocked = ops.indexOf('readonly IMAGE_DIGEST_REF');
      final mutation = ops.indexOf('DEPLOY_MUTATION_STARTED=1', digestLocked);
      expect(digestLocked, greaterThanOrEqualTo(0));
      expect(mutation, greaterThan(digestLocked));
    });

    test('promotes only the immutable digest and proves spec and task', () {
      expect(ops, contains("--image '\$IMAGE_DIGEST_REF'"));
      expect(ops, isNot(contains("--image '\$IMAGE_REPO:\$short_sha'")));
      expect(ops, contains('spec_image='));
      expect(ops, contains('running_image='));
      expect(
        ops,
        contains(
          r'$IMAGE_DIGEST_REF|$IMAGE_DIGEST_REF|ok|native_reviewed_rules_execution|$sha',
        ),
      );
      expect(
        ops,
        isNot(contains('services.app.updateSourceImage')),
        reason: 'manaloom-ops is a direct Swarm service, not an EasyPanel app',
      );
    });

    test('captures a rollback-safe digest and verifies rollback health', () {
      expect(ops, contains('PREVIOUS_SPEC_IMAGE'));
      expect(ops, contains('baseline manaloom-ops nao e rollback-safe'));
      expect(ops, contains('rollback_ops_deploy'));
      expect(ops, contains("--image '\$PREVIOUS_SPEC_IMAGE'"));
      expect(ops, contains('previous_health_proof='));
      expect(ops, contains('baseline manaloom-ops sem health rollback-safe'));
      expect(ops, contains("d['status']=='ok'"));
      expect(
        ops,
        contains("d['engine_contract']=='native_reviewed_rules_execution'"),
      );
      expect(ops, contains('rollback manaloom-ops comprovado'));
    });
  });

  group('immutable battle sidecar releases', () {
    late String sidecars;

    setUpAll(() {
      sidecars = script('manaloom_deploy_battle_sidecars.sh');
    });

    test('requires existing services and immutable rollback baselines', () {
      expect(sidecars, contains('sidecar EasyPanel existente e obrigatorio'));
      expect(sidecars, isNot(contains('services.app.createService')));
      expect(sidecars, contains('validate_sidecar_baseline'));
      expect(sidecars, contains('XMAGE_PREVIOUS_SPEC_IMAGE'));
      expect(sidecars, contains('FORGE_PREVIOUS_SPEC_IMAGE'));
      expect(sidecars, contains('XMAGE_ROLLBACK_SOURCE_IMAGE'));
      expect(sidecars, contains('FORGE_ROLLBACK_SOURCE_IMAGE'));

      final baseline = sidecars.indexOf('XMAGE_PREVIOUS_RUNTIME_STATE=');
      final baselineHealth = sidecars.indexOf(
        'wait_for_sidecar_health',
        baseline,
      );
      final archive = sidecars.indexOf(r'git archive "$sha" --');
      expect(baseline, greaterThanOrEqualTo(0));
      expect(baselineHealth, greaterThan(baseline));
      expect(archive, greaterThan(baselineHealth));
    });

    test('tests and publishes the same immutable source snapshot', () {
      expect(sidecars, contains('manaloom_release_identity.sh'));
      expect(sidecars, contains('worktree add --detach'));
      expect(
        sidecars,
        contains(r'"$SOURCE_WORKTREE/scripts/manaloom_battle_product_gate.sh"'),
      );
      expect(sidecars, contains(r'git archive "$sha" --'));
      expect(sidecars, isNot(contains('git archive HEAD --')));
      expect(sidecars, contains(r'worktree remove --force "$SOURCE_WORKTREE"'));
      expect(sidecars, contains('readonly sha short_sha'));

      final snapshot = sidecars.indexOf('worktree add --detach');
      final gate = sidecars.indexOf(
        r'"$SOURCE_WORKTREE/scripts/manaloom_battle_product_gate.sh"',
      );
      final archive = sidecars.indexOf(r'git archive "$sha" --');
      expect(snapshot, greaterThanOrEqualTo(0));
      expect(gate, greaterThan(snapshot));
      expect(archive, greaterThan(gate));
    });

    test('resolves both RepoDigests before any release mutation', () {
      expect(sidecars, contains('.RepoDigests'));
      expect(
        sidecars,
        contains('readonly XMAGE_IMAGE_DIGEST_REF FORGE_IMAGE_DIGEST_REF'),
      );
      expect(sidecars, contains(r'! "$xmage_digest" =~ ^[0-9a-f]{64}$'));
      expect(sidecars, contains(r'! "$forge_digest" =~ ^[0-9a-f]{64}$'));

      final digestLocked = sidecars.indexOf(
        'readonly XMAGE_IMAGE_DIGEST_REF FORGE_IMAGE_DIGEST_REF',
      );
      final firstDeploy = sidecars.indexOf('deploy_sidecar_digest \\');
      expect(digestLocked, greaterThanOrEqualTo(0));
      expect(firstDeploy, greaterThan(digestLocked));
    });

    test('keeps EasyPanel origin, Swarm spec and task on one digest', () {
      expect(sidecars, contains('services.app.updateSourceImage'));
      expect(sidecars, contains("--image '\$image_digest_ref'"));
      expect(sidecars, contains('configured_image" != "\$image_digest_ref'));
      expect(sidecars, contains('proof_spec_image" != "\$image_digest_ref'));
      expect(sidecars, contains('proof_running_image" != "\$image_digest_ref'));
      expect(sidecars, contains('origem=spec=tarefa=digest'));
      expect(sidecars, isNot(contains(r'${spec_image%%@*}')));
      expect(sidecars, isNot(contains(r'${running_image%%@*}')));
      expect(sidecars, isNot(contains("--image '\$xmage_tag'")));
      expect(sidecars, isNot(contains("--image '\$forge_tag'")));
      expect(
        sidecars,
        contains(
          'curlimages/curl:8.10.1@sha256:'
          'd9b4541e214bcd85196d6e92e2753ac6d0ea699f0af5741f8c6cccbfcf00ef4b',
        ),
      );
      expect(
        sidecars,
        isNot(contains('entrypoint sh curlimages/curl:8.10.1 -c')),
      );
    });

    test('rollback restores both origins and runtime digests with health', () {
      expect(sidecars, contains('rollback_battle_sidecars'));
      expect(sidecars, contains('rollback_one_sidecar'));
      expect(sidecars, contains("--image '\$previous_digest_ref'"));
      expect(sidecars, contains('services.app.deployService'));
      expect(
        sidecars,
        contains('configured_image" == "\$rollback_source_image'),
      );
      expect(sidecars, contains('wait_for_sidecar_health'));
      expect(sidecars, contains('rollback \$service_name comprovado'));
      expect(sidecars, contains('DEPLOY_COMMITTED=1'));
    });
  });
}
