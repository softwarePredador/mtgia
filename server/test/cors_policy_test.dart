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
  });
}
