import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  final repositoryRoot = Directory.current.parent;
  final patchFile = File(
    '${repositoryRoot.path}/docs/qa/evidence/'
    'LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch',
  );
  final verifierFile = File(
    '${repositoryRoot.path}/services/xmage-sidecar/bin/'
    'verify_lorehold_candidate_patch.sh',
  );
  final evidenceFile = File(
    '${repositoryRoot.path}/docs/qa/evidence/'
    'BATTLE_CARD_COVERAGE_CLOSURE_2026-07-29.json',
  );

  test('Lorehold patch is complete, pinned and excludes unrelated cards', () {
    const expectedPin = '2c43ec8cdb5cd475d47e6b555a4077151f476a3b';
    const expectedPatchSha =
        '24f6e88e082a222b60e2fb890898e43d3c7ef971ee6e38550aa476f371733642';

    expect(
      File(
        '${repositoryRoot.path}/services/xmage-sidecar/XMAGE_COMMIT',
      ).readAsStringSync().trim(),
      expectedPin,
    );
    expect(
      sha256.convert(patchFile.readAsBytesSync()).toString(),
      expectedPatchSha,
    );

    final patch = patchFile.readAsStringSync();
    for (final requiredFragment in const [
      'LoreholdTheHistorian.java',
      'MiracleGrantedAbility.java',
      'MiracleGrantedWatcher.java',
      'testLoreholdGrantsMiracleOnlyToInstantAndSorceryCards',
      'testLoreholdDoesNotGrantMiracleToCreatureCards',
      'testLoreholdMayDiscardAndDrawOnOpponentsUpkeep',
      'MatchOptionsRuntimeBoundaryTest.java',
      'gameOptions.stopOnTurn = match.getOptions().getStopOnTurn()',
    ]) {
      expect(patch, contains(requiredFragment));
    }
    expect(patch, isNot(contains('MoleculeMan')));
    expect(patch, isNot(contains('Aminatou')));
    expect(patch, isNot(contains('XMAGE_COMMIT')));
  });

  test('verification script rebuilds from the official pin with Java 17', () {
    final verifier = verifierFile.readAsStringSync();

    expect(verifier, contains('https://github.com/magefree/mage.git'));
    expect(verifier, contains('git -C "\$WORK_DIR/xmage" apply --check'));
    expect(verifier, contains('-Dtest=MiracleTest'));
    expect(verifier, contains('requires Java 17'));
    expect(verifier, contains('LOREHOLD_CANONICAL_PIN_CHANGED=false'));
    expect(verifier, contains('LOREHOLD_POSTGRES_MUTATIONS=0'));
  });

  test('coverage evidence labels the old runtime SHA as non-fetchable', () {
    final evidence =
        jsonDecode(evidenceFile.readAsStringSync()) as Map<String, dynamic>;
    final engineIdentity = evidence['engine_identity'] as Map<String, dynamic>;
    final candidatePatch = evidence['candidate_patch'] as Map<String, dynamic>;

    expect(
      engineIdentity['historical_local_runtime_commit'],
      '3ac810da650a51c33142175d6191693c3a077131',
    );
    expect(
      engineIdentity['historical_local_runtime_commit_fetchable'],
      isFalse,
    );
    expect(
      engineIdentity['historical_local_runtime_commit_deployable'],
      isFalse,
    );
    expect(
      candidatePatch['base_commit'],
      '2c43ec8cdb5cd475d47e6b555a4077151f476a3b',
    );
    expect(
      candidatePatch['sha256'],
      'ef492f2d3993a2918ceb88db715373be4ae1bcead74dfbb01c161eaaee6b1812',
    );
    expect(candidatePatch['focused_tests'], 6);
    expect(candidatePatch['focused_test_failures'], 0);
    expect(candidatePatch['canonical_pin_changed'], isFalse);
  });
}
