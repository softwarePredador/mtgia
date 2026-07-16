import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('public web product contract source guards', () {
    test('cross-service app links use browser navigation', () {
      final ui = File('../web-public/src/components/ui.tsx').readAsStringSync();
      final shell =
          File(
            '../web-public/src/components/site-shell.tsx',
          ).readAsStringSync();
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();

      expect(ui, contains('function crossesIntoFlutterApp'));
      expect(ui, contains('<a href={href} className={className}>'));
      expect(shell, contains('<RouteLink'));
      expect(home, contains('<RouteLink'));
    });

    test('public host emits security headers without framework disclosure', () {
      final config = File('../web-public/next.config.ts').readAsStringSync();

      expect(config, contains('poweredByHeader: false'));
      expect(config, contains('X-Content-Type-Options'));
      expect(config, contains('X-Frame-Options'));
      expect(config, contains('Referrer-Policy'));
      expect(config, contains('Permissions-Policy'));
      expect(config, contains('Strict-Transport-Security'));
    });

    test('landing keeps first viewport assets lean and prioritized', () {
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();
      final layout =
          File('../web-public/src/app/layout.tsx').readAsStringSync();
      final styles =
          File('../web-public/src/app/globals.css').readAsStringSync();

      expect(home, contains('fetchPriority="high"'));
      expect(home, isNot(contains('loading="eager"')));
      expect(layout, contains('icons:'));
      expect(styles, contains('/fonts/Inter.woff2'));
      expect(styles, contains('/fonts/Fraunces.woff2'));
      expect(styles, isNot(contains('splash_art.png')));
      expect(
        File('../web-public/public/fonts/Inter.woff2').existsSync(),
        isTrue,
      );
      expect(
        File('../web-public/public/fonts/Fraunces.woff2').existsSync(),
        isTrue,
      );
      expect(
        File('../web-public/public/fonts/Inter.ttf').existsSync(),
        isFalse,
      );
      expect(
        File('../web-public/public/fonts/Fraunces.ttf').existsSync(),
        isFalse,
      );
    });

    test('landing leaves the next product section visible at first load', () {
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();

      expect(
        RegExp(r'min-h-\[calc\(100svh-11rem\)\]').allMatches(home),
        hasLength(2),
      );
      expect(home, isNot(contains('min-h-[calc(100svh-4rem)]')));
      expect(home, contains('id="produto" className="pb-20 pt-12 sm:py-20"'));
      expect(home, contains('grid-cols-3 gap-2'));
    });

    test('legacy Scryfall redirects bypass the Next image optimizer', () {
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();

      expect(home, contains('function bypassImageOptimizer'));
      expect(home, contains('function normalizeCardImageUrl'));
      expect(home, contains('hostname === "api.scryfall.com"'));
      expect(home, contains('url.searchParams.set("version", "normal")'));
      expect(
        RegExp(r'unoptimized=\{bypassImageOptimizer\(').allMatches(home),
        hasLength(2),
      );
      expect(
        RegExp(r'src=\{normalizeCardImageUrl\(').allMatches(home),
        hasLength(2),
      );
    });

    test('full and E2E gates execute the public web smoke', () {
      final qualityGate = File('../scripts/quality_gate.sh').readAsStringSync();
      final e2eSuite =
          File('../scripts/manaloom_e2e_suite.sh').readAsStringSync();

      expect(qualityGate, contains('run_public_web_full'));
      expect(qualityGate, contains('scripts/manaloom_public_web_smoke.sh'));
      expect(e2eSuite, contains('Public web product E2E'));
    });

    test('public deploy is pinned to master SHA and verifies production', () {
      final deploy =
          File('../scripts/manaloom_deploy_public_web.sh').readAsStringSync();

      expect(deploy, contains(r'git -C "$ROOT_DIR" fetch origin master'));
      expect(
        deploy,
        contains('HEAD local nao esta alinhado com origin/master'),
      );
      expect(deploy, contains(r'IMAGE="$IMAGE_REPO:$SHORT_SHA"'));
      expect(deploy, contains("docker service update"));
      expect(deploy, contains(r"--image '$IMAGE'"));
      expect(deploy, contains(r'running_image" == "$IMAGE"'));
      expect(deploy, contains('/legal/disclaimer /robots.txt /sitemap.xml'));
      expect(deploy, contains("'^x-powered-by:'"));
    });

    test('web smoke isolates build dependencies for concurrent gates', () {
      final smoke =
          File('../scripts/manaloom_public_web_smoke.sh').readAsStringSync();

      expect(smoke, contains('RUN_ID='));
      expect(smoke, contains('WORK_DIR='));
      expect(smoke, contains('shutil.copytree'));
      expect(smoke, contains('ignore_patterns("node_modules", ".next")'));
      expect(smoke, contains(r'cd "$WORK_DIR"'));
      expect(smoke, isNot(contains(r'cd "$WEB_DIR"')));
      expect(
        smoke,
        contains(r'exec env HOSTNAME=127.0.0.1 PORT="$PORT" node server.js'),
      );
      expect(smoke, contains(r'kill -TERM "$SERVER_PID"'));
      expect(smoke, contains(r'kill -KILL "$SERVER_PID"'));
      expect(smoke, contains('trap cleanup EXIT'));
    });
  });
}
