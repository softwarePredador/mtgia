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

  test('production entrypoint suppresses framework disclosure', () {
    final source = File('main.dart').readAsStringSync();

    expect(source, contains('Future<HttpServer> run('));
    expect(source, contains('poweredByHeader: null'));
  });
}
