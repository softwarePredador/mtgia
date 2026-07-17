import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.path;

  String source(String relativePath) =>
      File('$repoRoot/$relativePath').readAsStringSync();

  const liveEntrypoints = <String>[
    'scripts/manaloom_deploy_ops_image.sh',
    'scripts/manaloom_deploy_battle_sidecars.sh',
    'scripts/manaloom_mobile_authenticated_qa.sh',
    'scripts/manaloom_ai_paywall_e2e.sh',
    'scripts/manaloom_product_smoke.sh',
    'scripts/manaloom_ai_generation_benchmark.sh',
    'scripts/manaloom_commercial_quality_gate.sh',
  ];

  group('live operational boundary', () {
    for (final relativePath in liveEntrypoints) {
      test('$relativePath is approval-gated and anchored', () {
        final script = source(relativePath);
        final liveApproval = script.indexOf('require_live_mutation_approval');
        final postgresApproval = script.indexOf(
          'require_postgres_write_approval',
        );
        final envLoad = script.indexOf('load_manaloom_env_keys "\$ENV_FILE"');
        final sshInitialization = script.indexOf(
          'initialize_manaloom_secure_ssh "\$SSH_HOST"',
        );

        expect(liveApproval, greaterThanOrEqualTo(0));
        expect(postgresApproval, greaterThanOrEqualTo(0));
        expect(envLoad, greaterThan(liveApproval));
        expect(envLoad, greaterThan(postgresApproval));
        expect(sshInitialization, greaterThan(envLoad));
        expect(script, contains('manaloom_safe_env.sh'));
        expect(script, contains('manaloom_release_runtime_contract.sh'));
        expect(script, contains('MANALOOM_EXPECTED_SSH_TARGET'));
        expect(script, isNot(contains('StrictHostKeyChecking=accept-new')));
        expect(script, isNot(contains(r'. "$ENV_FILE"')));
        expect(script, isNot(contains('set -a')));
      });
    }

    test('deploy entrypoints prove removal of remote build directories', () {
      for (final relativePath in const [
        'scripts/manaloom_deploy_ops_image.sh',
        'scripts/manaloom_deploy_battle_sidecars.sh',
      ]) {
        final script = source(relativePath);
        expect(script, contains('cleanup_remote_build_dir'));
        expect(script, contains("test ! -e '\$remote_dir'"));
        expect(script, contains('REMOTE_CLEANUP_PROOF'));
        expect(script, contains('trap cleanup_on_exit EXIT'));
      }
    });

    test('deploy entrypoints block before environment or network access', () {
      for (final relativePath in const [
        'scripts/manaloom_deploy_ops_image.sh',
        'scripts/manaloom_deploy_battle_sidecars.sh',
      ]) {
        final result = Process.runSync(
          '/bin/bash',
          ['$repoRoot/$relativePath'],
          environment: const {
            'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
            'MANALOOM_CONFIRM_POSTGRES_WRITES': '',
            'MANALOOM_NEW_SERVER_ENV': '/definitely/not/read.env',
          },
          includeParentEnvironment: true,
        );
        expect(result.exitCode, 2);
        expect('${result.stderr}', contains('BLOCKED:'));
        expect('${result.stderr}', isNot(contains('arquivo de ambiente')));
        expect('${result.stderr}', isNot(contains('env file not found')));
      }
    });

    test('fixture entrypoints require exact user cleanup proof', () {
      for (final relativePath in const [
        'scripts/manaloom_mobile_authenticated_qa.sh',
        'scripts/manaloom_ai_paywall_e2e.sh',
        'scripts/manaloom_product_smoke.sh',
        'scripts/manaloom_ai_generation_benchmark.sh',
      ]) {
        final script = source(relativePath);
        expect(script, contains('deleted_users=1,remaining_users=0'));
        expect(script, contains('psql -qAt'));
        expect(script, contains('trap cleanup_on_exit EXIT'));
        expect(script, isNot(contains('>/dev/null 2>&1 || true')));
        final transaction = script.indexOf('BEGIN;');
        final deleteLogs = script.indexOf('DELETE FROM ai_logs', transaction);
        final deleteUser = script.indexOf('DELETE FROM users', deleteLogs);
        final postcheck = script.indexOf(
          'SELECT COUNT(*) FROM users',
          deleteUser,
        );
        final commit = script.indexOf('COMMIT;', postcheck);
        expect(transaction, greaterThanOrEqualTo(0));
        expect(deleteLogs, greaterThan(transaction));
        expect(deleteUser, greaterThan(deleteLogs));
        expect(postcheck, greaterThan(deleteUser));
        expect(commit, greaterThan(postcheck));
      }
    });

    test('EasyPanel TLS cannot be downgraded', () {
      final sidecars = source('scripts/manaloom_deploy_battle_sidecars.sh');
      final commercial = source('scripts/manaloom_commercial_quality_gate.sh');

      expect(sidecars, contains('TLS inseguro para EasyPanel e proibido'));
      expect(sidecars, contains("--proto '=https'"));
      expect(sidecars, isNot(contains('curl_args+=(-k)')));
      expect(commercial, contains('MANALOOM_ALLOW_DEGRADED_AI:-0'));
      expect(commercial, contains('product_smoke_cleanup_unproven'));
      expect(commercial, contains('ai_benchmark_cleanup_unproven'));
    });
  });

  test('Python live auditors pin TLS and SSH trust', () {
    for (final relativePath in const [
      'server/bin/audit_easypanel_runtime_alignment.py',
      'server/bin/audit_easypanel_cron_runtime.py',
    ]) {
      final auditor = source(relativePath);
      expect(auditor, contains('MANALOOM_EXPECTED_SSH_TARGET'));
      expect(auditor, contains('MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256'));
      expect(auditor, contains('MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256'));
      expect(auditor, contains('StrictHostKeyChecking=yes'));
      expect(auditor, contains('UserKnownHostsFile='));
      expect(auditor, isNot(contains('StrictHostKeyChecking=accept-new')));
      expect(auditor, isNot(contains('--insecure-health')));
      expect(auditor, isNot(contains('CERT_NONE')));
      expect(auditor, isNot(contains('_create_unverified_context')));
    }
  });
}
