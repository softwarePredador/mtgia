import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('backend deploy validates auth runtime without printing JWT_SECRET', () {
    final deploy =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();
    final preflight =
        File('bin/auth_runtime_preflight.dart').readAsStringSync();
    final mainSource = File('main.dart').readAsStringSync();
    final releaseContract =
        File(
          '../scripts/lib/manaloom_release_runtime_contract.sh',
        ).readAsStringSync();

    expect(deploy, contains('auth_runtime_preflight.dart'));
    expect(deploy, contains('MANALOOM_TRUSTED_PROXY_HOPS'));
    expect(deploy, contains('MANALOOM_TRUSTED_PROXY_PEERS'));
    expect(deploy, contains('--env-add MANALOOM_TRUSTED_PROXY_HOPS='));
    expect(deploy, contains('--env-add MANALOOM_TRUSTED_PROXY_PEERS='));
    expect(deploy, contains('require_trusted_proxy_topology'));
    expect(deploy, contains('easypanel-traefik'));
    expect(deploy, contains('JWT_SECRET nao foi fornecido'));
    expect(deploy, contains('--env-add SENTRY_DSN='));
    expect(deploy, contains('--env-add SENTRY_ENVIRONMENT=production'));
    expect(deploy, contains('MANALOOM_PRODUCTION_SENTRY_DSN_SHA256'));
    expect(deploy, contains('jwt_secret_configured'));
    expect(deploy, contains('MANALOOM_JWT_SECRET_KEYCHAIN_SERVICE'));
    expect(deploy, contains('MANALOOM_JWT_SECRET_KEYCHAIN_ACCOUNT'));
    expect(deploy, contains('read_manaloom_keychain_secret'));
    expect(deploy, isNot(contains('echo \"\$JWT_SECRET\"')));
    expect(preflight, contains('jwt_secret=validated'));
    expect(preflight, isNot(contains("Platform.environment['JWT_SECRET']")));
    expect(
      releaseContract,
      contains('MANALOOM_PRODUCTION_TRAEFIK_LOGICAL_IP="10.11.0.202"'),
    );
    expect(
      releaseContract,
      contains('MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4="10.11.0.4"'),
    );
    expect(
      releaseContract,
      contains(
        'MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS=' +
            '"\${MANALOOM_PRODUCTION_PROXY_TRANSPORT_PEER_IPV4}/32"',
      ),
    );
    expect(deploy, contains('lb-easypanel'));
    expect(
      deploy,
      isNot(
        contains(
          'expected_proxy_ip=' +
              '"\${MANALOOM_PRODUCTION_TRUSTED_PROXY_PEERS%/32}"',
        ),
      ),
    );
    expect(
      releaseContract,
      contains(
        'MANALOOM_PRODUCTION_SENTRY_DSN_SHA256=' +
            '"2e1cc23c01e5b7d989edc2f1d046c3e7de34a3fa57e995c0f2e6252902153e49"',
      ),
    );
    expect(mainSource, contains('validateAuthRuntimeEnvironment'));
  });
}
