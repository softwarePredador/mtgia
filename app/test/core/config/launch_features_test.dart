import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/launch_features.dart';

void main() {
  test('scanner stays opt-in and disabled by default', () {
    expect(LaunchFeatures.scannerEnabled, isFalse);
  });

  test('Battle live spectator stays fail-closed by default', () {
    expect(LaunchFeatures.battleLiveSpectatorEnabled, isFalse);

    final source = File(
      'lib/core/config/launch_features.dart',
    ).readAsStringSync();
    expect(source, contains("'ENABLE_BATTLE_LIVE_SPECTATOR'"));
    expect(
      source,
      matches(
        RegExp(r'battleLiveSpectatorEnabled[\s\S]*?defaultValue:\s*false'),
      ),
    );
  });

  test('interactive Battle Coach stays fail-closed by default', () {
    expect(LaunchFeatures.interactiveBattleEnabled, isFalse);

    final features = File(
      'lib/core/config/launch_features.dart',
    ).readAsStringSync();
    expect(features, contains("'ENABLE_INTERACTIVE_BATTLE'"));
    expect(
      features,
      matches(RegExp(r'interactiveBattleEnabled[\s\S]*?defaultValue:\s*false')),
    );

    final routes = File('lib/main.dart').readAsStringSync();
    expect(
      routes,
      matches(
        RegExp(
          r"if \(LaunchFeatures\.interactiveBattleEnabled\)\s+GoRoute\(\s+path: 'battle-coach/:sessionId'",
          multiLine: true,
        ),
      ),
    );
    expect(
      routes,
      matches(
        RegExp(
          r"if \(LaunchFeatures\.interactiveBattleEnabled\)\s+GoRoute\(\s+path: 'battle-coach'",
          multiLine: true,
        ),
      ),
    );
  });

  test('disabled scanner route is absent and deep links recover to search', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      matches(
        RegExp(
          r"if \(LaunchFeatures\.scannerEnabled\)\s+GoRoute\(\s+path: 'scan'",
          multiLine: true,
        ),
      ),
    );
    expect(source, contains("uriPath.endsWith('/scan')"));
    expect(source, contains("RegExp(r'/scan\$')"));
    expect(source, contains("'/search'"));
  });

  test('signed Android beta fixes the scanner launch flag to false', () {
    final build = File(
      '../scripts/manaloom_build_android_release.sh',
    ).readAsStringSync();

    expect(build, contains('--dart-define="ENABLE_SCANNER_RELEASE=false"'));
    expect(build, contains('scanner_release_enabled: false'));
    expect(build, isNot(contains('ENABLE_SCANNER_RELEASE=true')));
    expect(build, isNot(contains('scanner_release_enabled: true')));
  });

  test('release build scripts pin interactive Battle off', () {
    for (final path in const [
      '../scripts/manaloom_build_android_release.sh',
      '../scripts/manaloom_deploy_flutter_web.sh',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('--dart-define="ENABLE_INTERACTIVE_BATTLE=false"'),
        reason: path,
      );
      expect(
        source,
        isNot(contains('ENABLE_INTERACTIVE_BATTLE=true')),
        reason: path,
      );
    }
  });
}
