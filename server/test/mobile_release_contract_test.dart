import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'mobile release requires clean source, signing and checksum validation',
    () {
      final build =
          File(
            '../scripts/manaloom_build_android_release.sh',
          ).readAsStringSync();
      final publish =
          File(
            '../scripts/manaloom_publish_android_release.sh',
          ).readAsStringSync();
      final patrol =
          File('../scripts/manaloom_patrol_smoke.sh').readAsStringSync();
      final localCi =
          File('../scripts/manaloom_local_ci.sh').readAsStringSync();
      final verifier =
          File(
            '../scripts/manaloom_verify_android_release_artifacts.sh',
          ).readAsStringSync();
      final releaseManifest =
          File(
            '../app/android/app/src/release/AndroidManifest.xml',
          ).readAsStringSync();
      final nginx = File('../app/release-host/nginx.conf').readAsStringSync();

      expect(build, contains('origin/master'));
      expect(build, contains('security find-generic-password'));
      expect(build, contains('apksigner'));
      expect(build, contains('jarsigner -verify'));
      expect(
        build,
        contains(
          r'source "$ROOT_DIR/scripts/lib/manaloom_flutter_release_sdk.sh"',
        ),
      );
      expect(build, contains('resolve_manaloom_release_flutter'));
      expect(build, contains('pub get --enforce-lockfile'));
      expect(
        build,
        contains(r'"$MANALOOM_FLUTTER_BIN_RESOLVED" build appbundle'),
      );
      expect(build, contains('--no-pub'));
      expect(publish, contains('private_aab_backup'));
      expect(publish, contains('PUBLIC_HASH'));
      expect(publish, contains('REMOTE_AAB_HASH'));
      expect(publish, contains('chmod 644'));
      expect(
        publish,
        contains(r'source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"'),
      );
      expect(publish, contains('readonly LIVE_MUTATION_APPROVED=1'));
      const approvalCall =
          'require_live_mutation_approval "ManaLoom Android release publication"';
      final approval = publish.indexOf(approvalCall);
      final envLoad = publish.indexOf(r'load_manaloom_env_keys "$ENV_FILE"');
      final sshInitialization = publish.indexOf(
        r'initialize_manaloom_secure_ssh "$SSH_HOST"',
      );
      expect(approval, greaterThanOrEqualTo(0));
      expect(envLoad, greaterThan(approval));
      expect(
        publish,
        contains(r'source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"'),
      );
      expect(publish, isNot(contains(r'. "$ENV_FILE"')));
      expect(sshInitialization, greaterThan(approval));
      expect(publish, isNot(contains('StrictHostKeyChecking=accept-new')));
      expect(build, contains('--dart-define="RELEASE_STARTUP_PROOF=true"'));
      expect(build, contains('--dart-define="ENABLE_SCANNER_RELEASE=false"'));
      expect(build, contains('scanner_release_enabled: false'));
      expect(build, isNot(contains('ENABLE_SCANNER_RELEASE=true')));
      expect(build, isNot(contains('scanner_release_enabled: true')));
      expect(releaseManifest, contains('android.permission.CAMERA'));
      expect(releaseManifest, contains('tools:node="remove"'));
      expect(
        verifier,
        contains(
          'APK de beta nao pode declarar camera com Scanner DEFERRED_BY_SCOPE',
        ),
      );
      expect(verifier, isNot(contains('android.permission.CAMERA|\\')));
      expect(localCi, contains('manaloom_build_android_release.sh'));
      expect(localCi, contains('run_battle_gate'));
      expect(
        File('../.github/workflows/manaloom-guardrails.yml').existsSync(),
        isFalse,
      );
      expect(publish, contains('.sentry.scope == "exact_signed_apk"'));
      expect(
        publish,
        contains('.fcm.artifact_token_availability == "confirmed"'),
      );
      expect(
        publish,
        contains(r'if [[ "$LIVE_MUTATION_APPROVED" == "1" &&'),
        reason: 'cleanup remoto nao pode executar antes da aprovacao live',
      );
      expect(
        publish,
        contains(r'-n "${MANALOOM_SECURE_SSH_KNOWN_HOSTS:-}"'),
        reason: 'cleanup remoto exige sessao SSH com host key verificada',
      );

      final fixture = Directory.systemTemp.createTempSync(
        'manaloom-android-env-',
      );
      try {
        final envFile = File('${fixture.path}/server.env')..writeAsStringSync(
          'MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL\n',
        );
        final blocked = Process.runSync(
          '/bin/bash',
          [
            File(
              '../scripts/manaloom_publish_android_release.sh',
            ).absolute.path,
          ],
          environment: {
            'MANALOOM_NEW_SERVER_ENV': envFile.path,
            'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
          },
        );
        expect(blocked.exitCode, 2);
        expect(
          blocked.stderr,
          contains('BLOCKED: ManaLoom Android release publication'),
        );
        expect(blocked.stderr, contains('only after approval was granted'));
      } finally {
        fixture.deleteSync(recursive: true);
      }
      expect(patrol, contains(r'summary = re.search(r"Total:\s*(\d+)"'));
      expect(patrol, contains('actual != expected'));
      expect(patrol, contains('Patrol CLI confirmou {actual}/{expected}'));
      expect(nginx, contains('location /downloads/'));
      expect(nginx, contains('try_files \$uri =404'));
      expect(nginx, contains('map \$uri \$manaloom_release_cache_control'));
      expect(
        nginx,
        contains('"/healthz" "no-cache, no-store, must-revalidate"'),
      );
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
    },
  );
}
