import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/auth/password_policy.dart';

void main() {
  test('registration policy accepts a strong passphrase', () {
    expect(
      validateRegistrationPassword(
        'Tigre lunar coleciona vinte cartas!',
        username: 'planeswalker',
        email: 'jogador@example.com',
      ),
      isNull,
    );
  });

  test(
    'registration policy mirrors server length and common-pattern errors',
    () {
      expect(
        validateRegistrationPassword('Ab3!short'),
        'Senha deve ter no mínimo 12 caracteres.',
      );
      expect(
        validateRegistrationPassword(r'P@ssw0rd!2026'),
        'Escolha uma senha menos previsível, sem sequências ou dados da conta.',
      );
      expect(
        validateRegistrationPassword('xx12345678yy'),
        'Escolha uma senha menos previsível, sem sequências ou dados da conta.',
      );
      expect(
        validateRegistrationPassword('😀😀😀😀😀😀😀😀😀😀😀😀'),
        'Escolha uma senha menos previsível, sem sequências ou dados da conta.',
      );
    },
  );

  test('registration policy rejects account identity and boundary spaces', () {
    expect(
      validateRegistrationPassword(
        'DeckMaster!2026-safe',
        username: 'deckmaster',
      ),
      'Escolha uma senha menos previsível, sem sequências ou dados da conta.',
    );
    expect(
      validateRegistrationPassword(' Strong passphrase 2026!'),
      'A senha não pode começar ou terminar com espaços.',
    );
  });
}
