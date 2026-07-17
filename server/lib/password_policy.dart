class PasswordPolicy {
  const PasswordPolicy._();

  static const minimumLength = 12;
  static const maximumLength = 256;

  static PasswordPolicyResult validate(
    String password, {
    String? username,
    String? email,
  }) {
    final length = password.runes.length;
    if (length < minimumLength) {
      return const PasswordPolicyResult.invalid(
        code: 'password_too_short',
        message: 'Senha deve ter no mínimo 12 caracteres.',
      );
    }
    if (length > maximumLength) {
      return const PasswordPolicyResult.invalid(
        code: 'password_too_long',
        message: 'Senha deve ter no máximo 256 caracteres.',
      );
    }
    if (password != password.trim()) {
      return const PasswordPolicyResult.invalid(
        code: 'weak_password',
        message: 'A senha não pode começar ou terminar com espaços.',
      );
    }

    final canonicalPassword = _canonicalize(password);
    final commonPattern = _isCommonPattern(canonicalPassword, password);
    final containsAccountIdentity = <String?>[username, email?.split('@').first]
        .map(_canonicalizeNullable)
        .whereType<String>()
        .any(
          (identity) =>
              identity.length >= 4 && canonicalPassword.contains(identity),
        );

    if (commonPattern || containsAccountIdentity) {
      return const PasswordPolicyResult.invalid(
        code: 'weak_password',
        message:
            'Escolha uma senha menos previsível, sem sequências ou dados da conta.',
      );
    }

    return const PasswordPolicyResult.valid();
  }

  static bool _isCommonPattern(String canonical, String original) {
    const exactCommonPasswords = <String>{
      '12345678',
      '123456789',
      '1234567890',
      'abcdefgh',
      'abc123456',
      'admin123',
      'iloveyou',
      'letmein',
      'magic123',
      'password',
      'password123',
      'qwerty',
      'qwerty123',
      'senha123',
      'welcome',
    };
    if (exactCommonPasswords.contains(canonical)) return true;

    final leetFolded = _foldLeet(canonical);
    const forbiddenWords = <String>['password', 'senha', 'qwerty', 'manaloom'];
    if (forbiddenWords.any(leetFolded.contains)) return true;

    const forbiddenSequences = <String>[
      '01234567',
      '12345678',
      '23456789',
      'abcdefgh',
      'qwerty',
      'asdfgh',
      'zxcvbn',
      'manaloom',
    ];
    if (forbiddenSequences.any(canonical.contains)) return true;

    if (original.runes.length >= 8 && original.runes.toSet().length <= 2) {
      return true;
    }
    return false;
  }

  static String _canonicalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('@', 'a')
        .replaceAll(r'$', 's')
        .replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static String _foldLeet(String value) {
    return value.replaceAllMapped(
      RegExp(r'[@\$013457]'),
      (match) =>
          const <String, String>{
            '@': 'a',
            r'$': 's',
            '0': 'o',
            '1': 'i',
            '3': 'e',
            '4': 'a',
            '5': 's',
            '7': 't',
          }[match.group(0)]!,
    );
  }

  static String? _canonicalizeNullable(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _canonicalize(value);
  }
}

class PasswordPolicyResult {
  const PasswordPolicyResult.valid()
    : isValid = true,
      code = null,
      message = null;

  const PasswordPolicyResult.invalid({
    required this.code,
    required this.message,
  }) : isValid = false;

  final bool isValid;
  final String? code;
  final String? message;
}
