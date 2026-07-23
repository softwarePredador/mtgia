import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/launch_features.dart';

void main() {
  test('scanner stays opt-in and disabled by default', () {
    expect(LaunchFeatures.scannerEnabled, isFalse);
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
}
