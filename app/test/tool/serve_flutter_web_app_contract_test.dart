import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local web helper permits HTTP only for an explicit loopback fixture',
    () {
      final source = File('tool/serve_flutter_web_app.py').readAsStringSync();

      expect(source, contains('--allow-loopback-http-api'));
      expect(source, contains('Access-Control-Allow-Origin'));
      expect(source, contains('Cross-Origin-Resource-Policy'));
      expect(
        source,
        contains(
          'parsed_upstream.hostname in {"127.0.0.1", "::1", "localhost"}',
        ),
      );
      expect(source, contains('is_explicit_loopback_http'));
      expect(source, contains('is_https_origin or is_explicit_loopback_http'));
      expect(source, contains('explicitly allowed loopback HTTP fixture'));
      expect(source, contains('--api-connect-address'));
      expect(source, contains('--api-connect-port'));
      expect(source, contains('connect_ip.is_loopback'));
      expect(source, contains('server_hostname=server_hostname'));
      expect(source, contains('forwarded_headers["Host"] = parsed_target.netloc'));
      expect(
        source,
        contains('--api-connect-address requires an HTTPS --api-upstream'),
      );
      expect(
        source,
        isNot(contains('ssl._create_unverified_context')),
        reason: 'HTTPS QA must never disable certificate verification.',
      );
    },
  );
}
