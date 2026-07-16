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
      final nginx = File('../app/release-host/nginx.conf').readAsStringSync();

      expect(build, contains('origin/master'));
      expect(build, contains('security find-generic-password'));
      expect(build, contains('apksigner'));
      expect(build, contains('jarsigner -verify'));
      expect(publish, contains('private_aab_backup'));
      expect(publish, contains('PUBLIC_HASH'));
      expect(publish, contains('REMOTE_AAB_HASH'));
      expect(publish, contains('chmod 644'));
      expect(patrol, contains(r'summary = re.search(r"Total:\s*(\d+)"'));
      expect(patrol, contains('actual != expected'));
      expect(patrol, contains('Patrol CLI confirmou {actual}/{expected}'));
      expect(nginx, contains('location /downloads/'));
      expect(nginx, contains('try_files \$uri =404'));
      expect(nginx, contains('map \$uri \$manaloom_release_cache_control'));
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
