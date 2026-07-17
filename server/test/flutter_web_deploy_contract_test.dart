import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Flutter web deploy keeps the authenticated app under /app', () {
    final dockerfile = File('../app/Dockerfile.web').readAsStringSync();
    final dockerignore = File('../app/.dockerignore').readAsStringSync();
    final nginx = File('../app/web/nginx.conf').readAsStringSync();
    final deploy =
        File('../scripts/manaloom_deploy_flutter_web.sh').readAsStringSync();

    expect(dockerfile, contains('COPY build/web /usr/share/nginx/html/app'));
    expect(dockerignore, startsWith('**\n'));
    expect(dockerignore, contains('!Dockerfile.web'));
    expect(dockerignore, contains('!web/nginx.conf'));
    expect(dockerignore, contains('!build/web/**'));
    expect(nginx, contains('location = /app'));
    expect(nginx, contains('try_files \$uri \$uri/ /app/index.html'));
    expect(nginx, contains('map \$uri \$manaloom_app_cache_control'));
    expect(nginx, contains('"/healthz" "no-cache, no-store, must-revalidate"'));
    expect(nginx, contains(r'"~*^/app/.*[.-][0-9a-f]{8,}'));
    expect(
      RegExp('add_header Cache-Control').allMatches(nginx),
      hasLength(1),
      reason: 'location-level add_header must not discard security headers',
    );
    expect(nginx, contains('add_header X-Content-Type-Options "nosniff"'));
    expect(nginx, contains('add_header X-Frame-Options "SAMEORIGIN"'));
    expect(nginx, contains('add_header Referrer-Policy'));
    expect(nginx, contains('add_header Permissions-Policy'));
    expect(nginx, contains('add_header Strict-Transport-Security'));
    expect(deploy, contains('--base-href /app/'));
    expect(
      deploy,
      contains('--no-web-resources-cdn'),
      reason:
          'Flutter runtime assets must remain same-origin so the production '
          'CSP cannot block CanvasKit during bootstrap',
    );
    expect(deploy, contains('MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app'));
    expect(deploy, contains('PathPrefix(\\`/app/\\`)'));
    expect(deploy, contains('worktree add --detach'));
    expect(deploy, contains('HEAD local nao esta alinhado com origin/master'));
    expect(
      deploy,
      contains(
        r'source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"',
      ),
    );
    expect(deploy, contains('resolve_manaloom_release_flutter'));
    expect(deploy, contains('pub get --enforce-lockfile'));
    expect(deploy, contains(r'"$MANALOOM_FLUTTER_BIN_RESOLVED" build'));
    expect(deploy, contains('--no-pub'));

    const approvalCall =
        'require_live_mutation_approval "ManaLoom Flutter Web deployment"';
    final buildOnlyBranch = deploy.indexOf(r'if [[ "$BUILD_ONLY" == "0" ]]');
    final approval = deploy.indexOf(approvalCall);
    final envLoad = deploy.indexOf(r'load_manaloom_env_keys "$ENV_FILE"');
    final firstRemoteUpload = deploy.indexOf('COPYFILE_DISABLE=1 tar');
    expect(
      deploy,
      contains(r'source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"'),
    );
    expect(deploy, contains('readonly LIVE_MUTATION_APPROVED=0'));
    expect(buildOnlyBranch, greaterThanOrEqualTo(0));
    expect(approval, greaterThan(buildOnlyBranch));
    expect(envLoad, greaterThan(approval));
    expect(
      deploy,
      contains(r'source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"'),
    );
    expect(deploy, isNot(contains(r'. "$ENV_FILE"')));
    expect(firstRemoteUpload, greaterThan(approval));
    expect(
      deploy,
      contains(
        r'if [[ "$LIVE_MUTATION_APPROVED" == "1" && -n "${REMOTE_DIR:-}" &&',
      ),
      reason: 'cleanup remoto nao pode executar antes da aprovacao live',
    );
    expect(
      deploy,
      contains(r'-n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}"'),
      reason: 'cleanup remoto exige sessao SSH com host key verificada',
    );
    expect(deploy, isNot(contains('StrictHostKeyChecking=accept-new')));

    final fixture = Directory.systemTemp.createTempSync('manaloom-web-env-');
    try {
      final envFile = File('${fixture.path}/server.env')..writeAsStringSync(
        'MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL\n',
      );
      final blocked = Process.runSync(
        '/bin/bash',
        [File('../scripts/manaloom_deploy_flutter_web.sh').absolute.path],
        environment: {
          'MANALOOM_NEW_SERVER_ENV': envFile.path,
          'MANALOOM_RELEASE_BUILD_ONLY': '0',
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
        },
      );
      expect(blocked.exitCode, 2);
      expect(
        blocked.stderr,
        contains('BLOCKED: ManaLoom Flutter Web deployment'),
      );
      expect(blocked.stderr, contains('only after approval was granted'));

      final buildOnly = Process.runSync(
        '/bin/bash',
        [File('../scripts/manaloom_deploy_flutter_web.sh').absolute.path],
        environment: {
          'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
          'MANALOOM_NEW_SERVER_ENV': envFile.path,
          'MANALOOM_RELEASE_BUILD_ONLY': '1',
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
          'MANALOOM_FLUTTER_BIN': '${fixture.path}/missing-flutter',
        },
      );
      expect(buildOnly.exitCode, 2);
      expect(buildOnly.stderr, isNot(contains('BLOCKED:')));
      expect(
        buildOnly.stderr,
        contains('ferramenta obrigatoria ausente: Flutter 3.44.6'),
      );
    } finally {
      fixture.deleteSync(recursive: true);
    }
  });
}
