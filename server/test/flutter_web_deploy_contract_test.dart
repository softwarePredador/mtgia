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
    expect(nginx, contains('map \$uri \$manaloom_app_cache_control'));
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
    expect(deploy, contains('MANALOOM_FLUTTER_WEB_SERVICE:-manaloom-app'));
    expect(deploy, contains('PathPrefix(\\`/app/\\`)'));
    expect(deploy, contains('worktree add --detach'));
    expect(deploy, contains('HEAD local nao esta alinhado com origin/master'));
  });
}
