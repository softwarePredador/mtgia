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

    test('honors forwarded https protocol behind reverse proxy', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {
          'host': 'evolution-cartinhas.8ktevp.easypanel.host',
          'x-forwarded-proto': 'https',
        },
        requestUri: Uri.parse(
          'http://evolution-cartinhas.8ktevp.easypanel.host/ai/generate',
        ),
      );

      expect(
        uri.toString(),
        'https://evolution-cartinhas.8ktevp.easypanel.host/ai/generate',
      );
    });

    test('keeps local http for direct development requests', () {
      final uri = resolveAiGenerateInternalUrl(
        headers: const {'host': '127.0.0.1:8082'},
        requestUri: Uri.parse('http://127.0.0.1:8082/ai/generate'),
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
  });
}
