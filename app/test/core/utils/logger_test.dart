import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/utils/logger.dart';

void main() {
  group('AppLogger', () {
    test('deve existir métodos estáticos', () {
      // Apenas verifica que os métodos existem e podem ser chamados
      // Em modo de teste (debug), eles vão printar
      expect(() => AppLogger.debug('test debug'), returnsNormally);
      expect(() => AppLogger.info('test info'), returnsNormally);
      expect(() => AppLogger.warning('test warning'), returnsNormally);
      expect(() => AppLogger.error('test error'), returnsNormally);
      expect(
        () => AppLogger.error('test error', Exception('test')),
        returnsNormally,
      );
    });

    test('redacts provider credentials and personal data', () {
      final sanitized = sanitizeAppLogMessage(
        'Authorization: Bearer secret-token '
        'OPENAI_API_KEY=sk-example-secret '
        'https://example.test?access_token=url-secret '
        'user@example.com',
      );

      expect(sanitized, isNot(contains('secret-token')));
      expect(sanitized, isNot(contains('sk-example-secret')));
      expect(sanitized, isNot(contains('url-secret')));
      expect(sanitized, isNot(contains('user@example.com')));
      expect(sanitized, contains('[REDACTED]'));
    });
  });
}
