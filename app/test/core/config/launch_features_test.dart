import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/launch_features.dart';

void main() {
  test('scanner stays opt-in outside the signed Android release pipeline', () {
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
}
