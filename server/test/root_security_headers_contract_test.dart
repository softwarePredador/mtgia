import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('root middleware applies defensive headers to every response path', () {
    final source = File('routes/_middleware.dart').readAsStringSync();

    expect(source, contains("'X-Content-Type-Options': 'nosniff'"));
    expect(source, contains("'X-Frame-Options': 'SAMEORIGIN'"));
    expect(source, contains("'Referrer-Policy': 'no-referrer'"));
    expect(source, contains("'Permissions-Policy':"));
    expect(source, contains("'Strict-Transport-Security':"));
    expect(source, contains('..._corsHeaders'));
  });
}
