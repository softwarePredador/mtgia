import 'package:server/password_policy.dart';
import 'package:test/test.dart';

void main() {
  group('registration password policy', () {
    test('accepts a long passphrase without composition requirements', () {
      final result = PasswordPolicy.validate(
        'Tigre lunar coleciona vinte cartas!',
        username: 'planeswalker',
        email: 'jogador@example.com',
      );

      expect(result.isValid, isTrue);
    });

    test('requires at least twelve characters', () {
      final result = PasswordPolicy.validate('Ab3!short');

      expect(result.isValid, isFalse);
      expect(result.code, 'password_too_short');
      expect(result.message, 'Senha deve ter no mínimo 12 caracteres.');
    });

    test('rejects common, sequential, repeated and leetspeak patterns', () {
      for (final password in const [
        'password123456',
        'xx12345678yy',
        'aaaaaaaaaaaa',
        '😀😀😀😀😀😀😀😀😀😀😀😀',
        r'P@ssw0rd!2026',
        'ManaLoomBeta2026!',
      ]) {
        final result = PasswordPolicy.validate(password);
        expect(
          result.code,
          'weak_password',
          reason: 'expected predictable password to be rejected',
        );
      }
    });

    test('rejects username and email local-part inside the password', () {
      expect(
        PasswordPolicy.validate(
          'DeckMaster!2026-safe',
          username: 'deckmaster',
        ).code,
        'weak_password',
      );
      expect(
        PasswordPolicy.validate(
          'Rafa!2026-super-long',
          email: 'rafa@example.com',
        ).code,
        'weak_password',
      );
    });

    test('rejects leading or trailing spaces but allows internal spaces', () {
      expect(
        PasswordPolicy.validate(' Strong passphrase 2026!').code,
        'weak_password',
      );
      expect(
        PasswordPolicy.validate('Strong passphrase 2026!').isValid,
        isTrue,
      );
    });

    test('caps registration input without changing long-password hashing', () {
      final result = PasswordPolicy.validate('x' * 257);

      expect(result.code, 'password_too_long');
    });
  });
}
