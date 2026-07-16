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
      final nginx = File('../app/release-host/nginx.conf').readAsStringSync();

      expect(build, contains('origin/master'));
      expect(build, contains('security find-generic-password'));
      expect(build, contains('apksigner'));
      expect(build, contains('jarsigner -verify'));
      expect(publish, contains('private_aab_backup'));
      expect(publish, contains('PUBLIC_HASH'));
      expect(publish, contains('REMOTE_AAB_HASH'));
      expect(publish, contains('chmod 644'));
      expect(nginx, contains('location /downloads/'));
      expect(nginx, contains('try_files \$uri =404'));
    },
  );
}
