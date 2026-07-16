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

    test('full and E2E gates execute the public web smoke', () {
      final qualityGate = File('../scripts/quality_gate.sh').readAsStringSync();
      final e2eSuite =
          File('../scripts/manaloom_e2e_suite.sh').readAsStringSync();

      expect(qualityGate, contains('run_public_web_full'));
      expect(qualityGate, contains('scripts/manaloom_public_web_smoke.sh'));
      expect(e2eSuite, contains('Public web product E2E'));
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
    });
  });
}
