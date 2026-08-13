import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('public web product contract source guards', () {
    test('public access stays fail-closed without cross-app links', () {
      final ui = File('../web-public/src/components/ui.tsx').readAsStringSync();
      final shell =
          File(
            '../web-public/src/components/site-shell.tsx',
          ).readAsStringSync();
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();
      final pricing =
          File('../web-public/src/app/pricing/page.tsx').readAsStringSync();
      final report =
          File(
            '../web-public/src/app/reports/[id]/page.tsx',
          ).readAsStringSync();
      final routes = File('../web-public/src/lib/routes.ts').readAsStringSync();
      final publicSource = Directory('../web-public/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.ts') || file.path.endsWith('.tsx'),
          )
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(ui, contains('export function AccessPending'));
      expect(ui, contains('role="status"'));
      expect(ui, contains('Acesso ainda não liberado'));
      for (final surface in [shell, home, pricing, report]) {
        expect(surface, contains('<AccessPending'));
      }
      expect(publicSource, isNot(contains('crossesIntoFlutterApp')));
      expect(publicSource, isNot(matches(RegExp(r'routes\.app\b'))));
      expect(
        publicSource,
        isNot(
          matches(
            RegExp(
              r'''href\s*=\s*(?:["'`]\/app(?:[\/?#"'`]|\s)|\{\s*["'`]\/app(?:[\/?#"'`]|\s))''',
              caseSensitive: false,
            ),
          ),
        ),
      );
      expect(routes, isNot(contains('app:')));
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
      expect(home, isNot(contains('loadPublicSiteFeed')));
    });

    test('landing and pricing expose one free Beta without paid claims', () {
      final home = File('../web-public/src/app/page.tsx').readAsStringSync();
      final pricing =
          File('../web-public/src/app/pricing/page.tsx').readAsStringSync();
      final productData =
          File('../web-public/src/lib/product-data.ts').readAsStringSync();
      final offerSource = '$home\n$pricing\n$productData';

      expect(productData, contains('id: "free-beta"'));
      expect(productData, contains('name: "Beta gratuita"'));
      expect(offerSource.toLowerCase(), contains('beta'));
      expect(
        RegExp(
          r'gratuit|gr[aá]tis',
          caseSensitive: false,
        ).hasMatch(offerSource),
        isTrue,
      );
      expect(
        RegExp(r'sem cobran[cç]a', caseSensitive: false).hasMatch(offerSource),
        isTrue,
      );
      for (final retiredClaim in [
        RegExp(r'(^|[^a-z0-9_])pro([^a-z0-9_]|$)', caseSensitive: false),
        RegExp(r'checkout', caseSensitive: false),
        RegExp(r'(^|[^a-z0-9_])trades?([^a-z0-9_]|$)', caseSensitive: false),
        RegExp(r'marketplace', caseSensitive: false),
        RegExp(r'upgrade', caseSensitive: false),
        RegExp(r'R\$\s*\d', caseSensitive: false),
      ]) {
        expect(
          retiredClaim.hasMatch(offerSource),
          isFalse,
          reason:
              'free Beta copy must not advertise retired paid/social claims',
        );
      }
    });

    test('public route and data boundary is report-only', () {
      final routes = File('../web-public/src/lib/routes.ts').readAsStringSync();
      final publicServer =
          File('../web-public/src/lib/public-server.ts').readAsStringSync();
      final reportPage =
          File(
            '../web-public/src/app/reports/[id]/page.tsx',
          ).readAsStringSync();

      expect(routes, contains('report:'));
      expect(routes, isNot(contains('marketplace:')));
      expect(routes, isNot(contains('appUpgrade:')));
      expect(routes, isNot(contains('deck:')));
      expect(routes, isNot(contains('player:')));
      expect(publicServer, contains('loadPublicReport'));
      expect(RegExp(r'\bfetch\s*\(').allMatches(publicServer), hasLength(1));
      expect(publicServer, contains(r'`/reports/${encodeURIComponent(id)}`'));
      expect(publicServer, isNot(contains('/community/')));
      expect(publicServer, isNot(contains('loadPublicSiteFeed')));
      expect(publicServer, isNot(contains('loadMarketplaceFeed')));
      expect(publicServer, isNot(contains('loadPublicDeckDetail')));
      expect(publicServer, isNot(contains('loadPublicUserProfile')));
      expect(reportPage, contains('loadPublicReport'));
      expect(reportPage, contains('notFound()'));

      for (final retiredPage in [
        '../web-public/src/app/marketplace/page.tsx',
        '../web-public/src/app/decks/[id]/page.tsx',
        '../web-public/src/app/players/[id]/page.tsx',
      ]) {
        expect(File(retiredPage).existsSync(), isFalse, reason: retiredPage);
      }

      final package = File('../web-public/package.json').readAsStringSync();
      expect(package, contains('"test:contract"'));
      expect(
        File('../web-public/tests/free-beta-offer-contract.mjs').existsSync(),
        isTrue,
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

    test('public runtime exposes an uncached container health probe', () {
      final dockerfile = File('../web-public/Dockerfile').readAsStringSync();
      final health =
          File('../web-public/src/app/healthz/route.ts').readAsStringSync();

      expect(dockerfile, contains('/healthz'));
      expect(health, contains('new Response("ok\\n"'));
      expect(health, contains('no-cache, no-store, must-revalidate'));
    });

    test('public deploy is pinned to master SHA and verifies production', () {
      final deploy =
          File('../scripts/manaloom_deploy_public_web.sh').readAsStringSync();

      expect(
        deploy,
        contains(r'"$ROOT_DIR/scripts/manaloom_release_identity.sh"'),
      );
      expect(deploy, contains(r'MANALOOM_RELEASE_SOURCE_SHA='));
      expect(deploy, contains(r'IMAGE="$IMAGE_REPO:$SHORT_SHA"'));
      expect(deploy, contains("docker service update"));
      expect(deploy, contains(r"--image '$IMAGE_DIGEST_REF'"));
      expect(deploy, contains(r'running_image" == "$IMAGE_DIGEST_REF"'));
      expect(deploy, contains(r'"image_digest_ref":"%s"'));
      expect(deploy, isNot(contains('StrictHostKeyChecking=accept-new')));
      expect(deploy, contains('manaloom_public_web_required_routes'));
      expect(deploy, contains('manaloom_public_web_removed_routes'));
      expect(deploy, contains('manaloom_public_web_assert_removed_response'));
      expect(deploy, contains('manaloom_public_web_assert_free_beta_files'));
      expect(deploy, contains('manaloom_public_web_assert_sitemap_file'));
      expect(deploy, contains('MANALOOM_PUBLIC_WEB_REPORT_FIXTURE_ID'));
      expect(deploy, contains('MISSING_REPORT_STATUS'));
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
      expect(smoke, contains('npm run lint'));
      expect(smoke, contains('NEXT_PUBLIC_MANALOOM_API_BASE_URL='));
      expect(smoke, contains('npm audit --omit=dev --audit-level=moderate'));
      expect(smoke, contains('manaloom_public_web_required_routes'));
      expect(smoke, contains('manaloom_public_web_removed_routes'));
      expect(smoke, contains('manaloom_public_web_assert_removed_response'));
      expect(smoke, contains('manaloom_public_web_assert_free_beta_files'));
      expect(smoke, contains('manaloom_public_web_assert_sitemap_file'));
      expect(smoke, contains('Public Web Smoke Report'));
      expect(smoke, contains('MISSING_REPORT_STATUS'));
      expect(smoke, contains("grep -Fq 'BrewTact'"));
      expect(smoke, contains("grep -Fq 'ManaLoom'"));
      expect(smoke, contains('Legacy public brand is still visible'));
      expect(smoke, contains(r'exec env HOSTNAME=127.0.0.1 PORT="$PORT" \'));
      expect(smoke, contains(r'stop_process "$SERVER_PID"'));
      expect(smoke, contains(r'stop_process "$FIXTURE_API_PID"'));
      expect(smoke, contains(r'kill -TERM "$pid"'));
      expect(smoke, contains(r'kill -KILL "$pid"'));
      expect(smoke, contains('trap cleanup EXIT'));
    });
  });
}
