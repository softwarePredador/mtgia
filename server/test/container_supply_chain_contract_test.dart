import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('runtime container bases and locked Dart Frog build are immutable', () {
    final backend = File('Dockerfile').readAsStringSync();
    final web = File('../app/Dockerfile.web').readAsStringSync();
    final publicWeb = File('../web-public/Dockerfile').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockfile = File('pubspec.lock').readAsStringSync();

    expect(
      backend,
      startsWith(
        'FROM dart:3.12.2@sha256:'
        '13140e26d84f4fda57cea31942222112aeb2eec10e5e6874c1c0f70beed189ab AS build\n',
      ),
    );
    expect(backend, contains('RUN mkdir -p /out'));
    expect(backend, contains('dart run dart_frog_cli:dart_frog build'));
    expect(backend, contains('dart compile exe build/bin/server.dart'));
    expect(backend, contains('AS runtime'));
    expect(backend, contains('USER 10001:10001'));
    expect(backend, contains('HEALTHCHECK --interval=30s'));
    expect(backend, contains('/health/live'));
    expect(backend, isNot(contains('COPY server/ .\n\nENV PORT')));
    expect(backend, isNot(contains('dart pub global activate')));
    expect(pubspec, contains('  dart_frog_cli: 1.2.14\n'));
    expect(
      lockfile,
      contains('''  dart_frog_cli:
    dependency: "direct dev"'''),
    );
    expect(
      RegExp(
        r'dart_frog_cli:[\s\S]*?source: hosted\s+version: "1\.2\.14"',
      ).hasMatch(lockfile),
      isTrue,
    );
    expect(backend, isNot(contains('FROM dart:stable')));
    expect(
      web,
      startsWith(
        'FROM nginx:1.30.3-alpine@sha256:'
        '0d3b80406a13a767339fbe2f41406d6c7da727ab89cf8fae399e81f780f814d1\n',
      ),
    );
    expect(publicWeb, contains('COPY --chown=node:node --from=builder'));
    expect(publicWeb, contains('\nUSER node\n'));
    expect(publicWeb, contains('HEALTHCHECK --interval=30s'));
    expect(publicWeb, contains('/healthz'));
  });

  test('backend deploy converges only on its final remote RepoDigest', () {
    final deploy =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();
    final shaPush = deploy.indexOf("docker push '\$IMAGE_REPO:\$short_sha'");
    final latestPush = deploy.indexOf(
      "docker push '\$IMAGE_REPO:latest'",
      shaPush,
    );
    final repoDigest = deploy.indexOf(
      "docker image inspect '\$IMAGE_REPO:\$short_sha'",
      latestPush,
    );
    final serviceUpdate = deploy.indexOf(
      'docker service update \\',
      repoDigest,
    );
    final easyPanelUpdate = deploy.indexOf(
      'services.app.updateSourceImage',
      serviceUpdate,
    );

    expect(shaPush, greaterThanOrEqualTo(0));
    expect(latestPush, greaterThan(shaPush));
    expect(repoDigest, greaterThan(latestPush));
    expect(serviceUpdate, greaterThan(repoDigest));
    expect(easyPanelUpdate, greaterThan(serviceUpdate));
    expect(deploy, contains("--image '\$image_digest_ref'"));
    expect(deploy, contains('--arg image "\$image_digest_ref"'));
    expect(deploy, contains('"\$runtime_spec_image" != "\$image_digest_ref"'));
    expect(
      deploy,
      contains('"\$runtime_running_image" != "\$image_digest_ref"'),
    );
    expect(deploy, contains('"\$configured_image" != "\$image_digest_ref"'));
    expect(deploy, contains('image_digest_ref: \$image_digest_ref'));
    expect(deploy, isNot(contains(r'spec_image="${spec_image%%@*}"')));
    expect(deploy, isNot(contains(r'running_image="${running_image%%@*}"')));
  });

  test(
    'Flutter Web deploy preserves one digest across EasyPanel and Swarm',
    () {
      final deploy =
          File('../scripts/manaloom_deploy_flutter_web.sh').readAsStringSync();
      final shaPush = deploy.indexOf("docker push '\$IMAGE'");
      final latestPush = deploy.indexOf(
        "docker push '\$IMAGE_REPO:latest'",
        shaPush,
      );
      final repoDigest = deploy.indexOf(
        "docker image inspect '\$IMAGE'",
        latestPush,
      );
      final easyPanelUpdate = deploy.indexOf(
        'services.app.updateSourceImage',
        repoDigest,
      );
      final runtimeProof = deploy.indexOf(
        '1/1|\$IMAGE_DIGEST_REF|\$IMAGE_DIGEST_REF',
        easyPanelUpdate,
      );

      expect(shaPush, greaterThanOrEqualTo(0));
      expect(latestPush, greaterThan(shaPush));
      expect(repoDigest, greaterThan(latestPush));
      expect(easyPanelUpdate, greaterThan(repoDigest));
      expect(runtimeProof, greaterThan(easyPanelUpdate));
      expect(deploy, contains('--arg image "\$IMAGE_DIGEST_REF"'));
      expect(deploy, contains('"\$CONFIGURED_IMAGE" != "\$IMAGE_DIGEST_REF"'));
      expect(deploy, contains('image_digest_ref: \$image_digest_ref'));
      expect(deploy, isNot(contains(r'${image%%@*}')));
    },
  );
}
