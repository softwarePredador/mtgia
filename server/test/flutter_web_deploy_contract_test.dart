import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Flutter web deploy keeps the authenticated app under /app', () {
    final dockerfile = File('../app/Dockerfile.web').readAsStringSync();
    final nginx = File('../app/web/nginx.conf').readAsStringSync();
    final deploy =
        File('../scripts/manaloom_deploy_flutter_web.sh').readAsStringSync();

    expect(dockerfile, contains('COPY build/web /usr/share/nginx/html/app'));
    expect(nginx, contains('location = /app'));
    expect(nginx, contains('try_files \$uri \$uri/ /app/index.html'));
    expect(deploy, contains('--base-href /app/'));
    expect(deploy, contains('MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app'));
    expect(deploy, contains('PathPrefix(\\`/app/\\`)'));
    expect(deploy, contains('worktree add --detach'));
    expect(deploy, contains('HEAD local nao esta alinhado com origin/master'));
  });
}
