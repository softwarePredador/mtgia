import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('root middleware does not print raw exceptions or stack traces', () {
    final source = File('routes/_middleware.dart').readAsStringSync();

    expect(source, isNot(contains("print('[ERROR] middleware: \$e')")));
    expect(source, isNot(contains("print('[ERROR] stack: \$st')")));
    expect(source, contains('type=\${e.runtimeType}'));
    expect(source, contains('captureObservedException('));
  });
}
