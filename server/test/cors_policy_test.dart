import 'package:server/cors_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CorsPolicy', () {
    test('production accepts only exact configured origins', () {
      final policy = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'production',
        'MANALOOM_ALLOWED_ORIGINS':
            'https://app.manaloom.example,https://admin.manaloom.example,'
            'http://insecure.manaloom.example,http://localhost:3000',
        'MANALOOM_ALLOW_DEV_ORIGINS': 'true',
      });

      expect(
        policy.isAllowed(null),
        isTrue,
        reason: 'native clients omit Origin',
      );
      expect(policy.isAllowed('https://app.manaloom.example'), isTrue);
      expect(policy.isAllowed('https://app.manaloom.example/'), isTrue);
      expect(policy.isAllowed('https://evil.example'), isFalse);
      expect(policy.isAllowed('http://localhost:3000'), isFalse);
      expect(policy.isAllowed('http://insecure.manaloom.example'), isFalse);
      expect(policy.isAllowed('null'), isFalse);
    });

    test('development loopback requires explicit opt-in', () {
      final blocked = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'development',
      });
      final allowed = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'development',
        'MANALOOM_ALLOW_DEV_ORIGINS': 'true',
      });

      expect(blocked.isAllowed('http://localhost:5173'), isFalse);
      expect(allowed.isAllowed('http://localhost:5173'), isTrue);
      expect(allowed.isAllowed('http://127.0.0.1:8080'), isTrue);
      expect(allowed.isAllowed('http://192.168.0.10:8080'), isFalse);
    });

    test('preflight rejects unknown methods and headers', () {
      final policy = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'production',
        'MANALOOM_ALLOWED_ORIGINS': 'https://app.manaloom.example',
      });

      expect(
        policy.isValidPreflight(
          requestedMethod: 'POST',
          requestedHeaders: 'Content-Type, Authorization, X-Request-Id',
        ),
        isTrue,
      );
      expect(
        policy.isValidPreflight(
          requestedMethod: 'TRACE',
          requestedHeaders: 'Content-Type',
        ),
        isFalse,
      );
      expect(
        policy.isValidPreflight(
          requestedMethod: 'GET',
          requestedHeaders: 'X-Unsafe-Header',
        ),
        isFalse,
      );
    });

    test('a deck write from the web app passes the preflight with If-Match '
        'and Idempotency-Key (DCK-P0-01)', () {
      final policy = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'production',
        'MANALOOM_ALLOWED_ORIGINS': 'https://app.manaloom.example',
      });

      // O que o Chrome manda no preflight da escrita do app: minúsculas, em
      // ordem, sem espaço.
      const deckWrite =
          'authorization,content-type,idempotency-key,if-match,x-request-id';
      for (final method in const ['POST', 'PUT', 'PATCH', 'DELETE']) {
        expect(
          policy.isValidPreflight(
            requestedMethod: method,
            requestedHeaders: deckWrite,
          ),
          isTrue,
          reason: method,
        );
      }
      for (final header in const ['If-Match', 'Idempotency-Key']) {
        expect(
          policy.isValidPreflight(
            requestedMethod: 'PATCH',
            requestedHeaders: header,
          ),
          isTrue,
          reason: header,
        );
      }
      expect(
        policy.isValidPreflight(
          requestedMethod: 'PATCH',
          requestedHeaders: '$deckWrite,x-unlisted-header',
        ),
        isFalse,
        reason: 'one unlisted header refuses the whole preflight',
      );
    });

    test('the response headers come from the same lists as the preflight', () {
      final policy = CorsPolicy.fromEnvironment({
        'ENVIRONMENT': 'production',
        'MANALOOM_ALLOWED_ORIGINS': 'https://app.manaloom.example',
      });
      Set<String> listed(String name) =>
          CorsPolicy.responseHeaders[name]!
              .split(',')
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toSet();

      final allowHeaders = listed('Access-Control-Allow-Headers');
      expect(allowHeaders, CorsPolicy.allowedHeaders);
      expect(allowHeaders, containsAll(['if-match', 'idempotency-key']));
      expect(
        policy.isValidPreflight(
          requestedMethod: 'POST',
          requestedHeaders:
              CorsPolicy.responseHeaders['Access-Control-Allow-Headers'],
        ),
        isTrue,
        reason: 'every header the response announces passes the preflight',
      );

      final allowMethods = listed('Access-Control-Allow-Methods');
      expect(
        allowMethods,
        CorsPolicy.allowedMethods.map((m) => m.toLowerCase()).toSet(),
      );

      // O app lê a revisão do deck e o request id da resposta.
      expect(
        listed('Access-Control-Expose-Headers'),
        containsAll(['etag', 'x-request-id']),
      );
    });
  });
}
