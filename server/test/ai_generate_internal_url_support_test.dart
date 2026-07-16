import 'package:test/test.dart';

import '../lib/ai_generate_internal_url_support.dart';

void main() {
  group('resolveAiGenerateInternalUrl', () {
    test('uses configured base URL when present', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {'host': 'example.test'},
        requestUri: Uri.parse('http://example.test/ai/generate'),
        configuredBaseUrl: 'https://internal.example.test/',
        fallbackPort: '8080',
      );

      expect(uri.toString(), 'https://internal.example.test/ai/generate');
    });

    test('ignores client-controlled host and proxy headers', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {
          'host': 'attacker.example',
          'x-forwarded-proto': 'https',
        },
        requestUri: Uri.parse('http://attacker.example/ai/generate'),
        fallbackPort: '8082',
      );

      expect(uri.toString(), 'http://127.0.0.1:8082/ai/generate');
    });

    test('resolves arbitrary AI route only on the local process', () {
      final uri = resolveInternalAiRouteUrl(
        headers: const {
          'host': 'attacker.example',
          'x-forwarded-proto': 'https',
        },
        requestUri: Uri.parse('http://attacker.example/ai/optimize'),
        routePath: '/ai/optimize',
        fallbackPort: '8082',
      );

      expect(uri.toString(), 'http://127.0.0.1:8082/ai/optimize');
    });

    test('does not reuse a direct development request host', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {'host': '127.0.0.1:9000'},
        requestUri: Uri.parse('http://127.0.0.1:9000/ai/generate'),
        fallbackPort: '8082',
      );

      expect(uri.toString(), 'http://127.0.0.1:8082/ai/generate');
    });

    test('falls back to localhost port when host header is unavailable', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {},
        requestUri: Uri(path: '/ai/generate'),
        fallbackPort: '8082',
      );

      expect(uri.toString(), 'http://127.0.0.1:8082/ai/generate');
    });

    test('invalid configured base falls back to loopback', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {'host': 'attacker.example'},
        requestUri: Uri.parse('https://attacker.example/ai/generate'),
        configuredBaseUrl: 'file:///tmp/exfiltrate',
        fallbackPort: '8082',
      );

      expect(uri.toString(), 'http://127.0.0.1:8082/ai/generate');
    });

    test('configured base rejects credentials, paths and query strings', () {
      for (final configuredBaseUrl in <String>[
        'https://user:secret@internal.example.test',
        'https://internal.example.test/proxy',
        'https://internal.example.test?redirect=attacker.example',
      ]) {
        final uri = resolveAiGenerateInternalUrl(
          headers: const {},
          requestUri: Uri(path: '/ai/generate'),
          configuredBaseUrl: configuredBaseUrl,
          fallbackPort: '8082',
        );
        expect(
          uri.toString(),
          'http://127.0.0.1:8082/ai/generate',
          reason: configuredBaseUrl,
        );
      }
    });

    test('invalid fallback port uses the bounded default', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {},
        requestUri: Uri(path: '/ai/generate'),
        fallbackPort: '70000',
      );

      expect(uri.toString(), 'http://127.0.0.1:8080/ai/generate');
    });
  });
}
