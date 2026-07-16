import 'package:manaloom_lints/src/avoid_manaloom_secret_literal.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidManaLoomSecretLiteral', () {
    test('only targets production Dart paths', () {
      expect(
        AvoidManaLoomSecretLiteral.isProductionPathForTest(
          '/repo/server/routes/ai/generate/index.dart',
        ),
        isTrue,
      );
      expect(
        AvoidManaLoomSecretLiteral.isProductionPathForTest(
          '/repo/tools/manaloom_lints/test/fixture.dart',
        ),
        isFalse,
      );
    });

    test('detects real-looking provider secrets and database DSNs', () {
      expect(
        AvoidManaLoomSecretLiteral.containsSecretForTest(
          'sk-proj-1234567890abcdef',
        ),
        isTrue,
      );
      expect(
        AvoidManaLoomSecretLiteral.containsSecretForTest(
          'dop_v1_64ca1e02efd700e1fb9cf96f87cb5761',
        ),
        isTrue,
      );
      expect(
        AvoidManaLoomSecretLiteral.containsSecretForTest(
          'postgres://user:pass@localhost:5432/manaloom',
        ),
        isTrue,
      );
    });

    test('allows environment variable names and sanitizer regex literals', () {
      expect(
        AvoidManaLoomSecretLiteral.containsSecretForTest('OPENAI_API_KEY'),
        isFalse,
      );
      expect(
        AvoidManaLoomSecretLiteral.containsSecretForTest(
          r'\bsk-[A-Za-z0-9_-]{10,}\b',
        ),
        isFalse,
      );
    });
  });
}
