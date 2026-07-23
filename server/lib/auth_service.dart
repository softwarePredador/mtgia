import 'dart:convert';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';
import 'auth_runtime_policy.dart';
import 'database.dart';
import 'legal_policy.dart';
import 'password_policy.dart';
import 'runtime_environment.dart';

/// Serviço centralizado de autenticação
///
/// Responsabilidades:
/// - Hash e verificação de senhas com bcrypt
/// - Geração e validação de JWT tokens
/// - Operações de autenticação no banco de dados
class AuthService {
  static const String _bcryptSha256Prefix = 'bcrypt_sha256\$';
  static AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  late final String _jwtSecret;

  AuthService._internal({String? jwtSecret}) {
    if (jwtSecret != null) {
      _jwtSecret = jwtSecret;
      return;
    }
    final env = loadRuntimeEnvironment();
    final secret = env['JWT_SECRET'];

    final production =
        (env['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
        'production';
    JwtSecretPolicy.validate(secret, production: production);

    _jwtSecret = secret!;
  }

  @visibleForTesting
  static void resetForTesting({String jwtSecret = 'hermes-local-test-secret'}) {
    _instance = AuthService._internal(jwtSecret: jwtSecret);
  }

  /// Duração de validade do token (24 horas)
  final Duration _tokenDuration = const Duration(hours: 24);

  /// Cria um hash seguro da senha usando bcrypt
  ///
  /// Bcrypt é um algoritmo de hashing adaptativo que inclui:
  /// - Salt automático (proteção contra rainbow tables)
  /// - Custo computacional configurável (resistência a força bruta)
  String hashPassword(String password) {
    final normalizedPassword = _normalizePasswordForStorage(password);
    final hash = BCrypt.hashpw(normalizedPassword.value, BCrypt.gensalt());
    return normalizedPassword.preHashed ? '$_bcryptSha256Prefix$hash' : hash;
  }

  /// Verifica se a senha fornecida corresponde ao hash armazenado
  bool verifyPassword(String password, String hashedPassword) {
    try {
      if (hashedPassword.startsWith(_bcryptSha256Prefix)) {
        final strippedHash = hashedPassword.substring(
          _bcryptSha256Prefix.length,
        );
        final normalizedPassword = _preparePassword(password);
        return BCrypt.checkpw(normalizedPassword, strippedHash);
      }
      return BCrypt.checkpw(password, hashedPassword);
    } on ArgumentError catch (e) {
      throw Exception('Invalid password hash format: $e');
    }
  }

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  /// Gera um JWT token contendo o ID e username do usuário
  ///
  /// Estrutura do payload:
  /// - userId: UUID do usuário
  /// - username: Nome de usuário
  /// - iat: Timestamp de emissão
  /// - exp: Timestamp de expiração
  String generateToken(String userId, String username, {int authVersion = 0}) {
    final jwt = JWT({
      'userId': userId,
      'username': username,
      'authVersion': authVersion,
      'iat': DateTime.now().millisecondsSinceEpoch,
    });

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: _tokenDuration);
  }

  /// Valida e decodifica um JWT token
  ///
  /// Retorna o payload se válido, null se inválido/expirado
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;

      // Normaliza iat para milissegundos (testes/clients usam ms).
      final iat = payload['iat'];
      if (iat is int && iat < 1000000000000) {
        payload['iat'] = iat * 1000;
      }

      return payload;
    } catch (e) {
      // Token inválido, expirado ou malformado
      return null;
    }
  }

  /// Registra um novo usuário no banco de dados
  ///
  /// Validações:
  /// - Username único
  /// - Email único
  /// - Senha com hash bcrypt
  ///
  /// Retorna: Map com 'userId', 'username', 'email' e 'token'
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    LegalAcceptance? legalAcceptance,
  }) async {
    final db = Database();
    final conn = db.connection;

    final normalizedUsername = normalizeUsername(username);
    final normalizedEmail = normalizeEmail(email);
    final passwordValidation = PasswordPolicy.validate(
      password,
      username: normalizedUsername,
      email: normalizedEmail,
    );
    if (!passwordValidation.isValid) {
      throw Exception(passwordValidation.message);
    }

    final hashedPassword = hashPassword(password);
    final emailVerificationToken = _newOpaqueToken();
    final emailVerificationExpiresAt = DateTime.now().toUtc().add(
      const Duration(hours: 24),
    );
    final account = await conn.runTx((session) async {
      final usernameCheck = await session.execute(
        Sql.named(
          'SELECT id FROM users WHERE LOWER(username) = @username '
          'AND deleted_at IS NULL',
        ),
        parameters: {'username': normalizedUsername},
      );
      if (usernameCheck.isNotEmpty) {
        throw Exception('Username já está em uso');
      }

      final emailCheck = await session.execute(
        Sql.named(
          'SELECT id FROM users WHERE LOWER(email) = @email '
          'AND deleted_at IS NULL',
        ),
        parameters: {'email': normalizedEmail},
      );
      if (emailCheck.isNotEmpty) {
        throw Exception('Email já está em uso');
      }

      final result = await session.execute(
        Sql.named('''
          INSERT INTO users (
            username, email, password_hash,
            terms_version, terms_accepted_at,
            privacy_version, privacy_accepted_at
          )
          VALUES (
            @username, @email, @passwordHash,
            CAST(@termsVersion AS text),
            CASE WHEN CAST(@termsVersion AS text) IS NULL
              THEN NULL ELSE CURRENT_TIMESTAMP END,
            CAST(@privacyVersion AS text),
            CASE WHEN CAST(@privacyVersion AS text) IS NULL
              THEN NULL ELSE CURRENT_TIMESTAMP END
          )
          RETURNING id, username, email
        '''),
        parameters: {
          'username': normalizedUsername,
          'email': normalizedEmail,
          'passwordHash': hashedPassword,
          'termsVersion': legalAcceptance?.termsVersion,
          'privacyVersion': legalAcceptance?.privacyVersion,
        },
      );
      final row = result.first;
      final userId = row[0] as String;
      await session.execute(
        Sql.named('''
          INSERT INTO user_plans (user_id, plan_name, status)
          VALUES (CAST(@userId AS uuid), 'free', 'active')
          ON CONFLICT (user_id) DO NOTHING
        '''),
        parameters: {'userId': userId},
      );
      await session.execute(
        Sql.named('''
          INSERT INTO email_verification_tokens (
            user_id, token_hash, expires_at
          ) VALUES (
            CAST(@userId AS uuid), @tokenHash, @expiresAt
          )
        '''),
        parameters: {
          'userId': userId,
          'tokenHash': _hashOpaqueToken(emailVerificationToken),
          'expiresAt': emailVerificationExpiresAt,
        },
      );
      return (
        userId: userId,
        username: row[1] as String,
        email: row[2] as String,
      );
    });

    // Gerar token
    final token = generateToken(account.userId, account.username);

    return {
      'userId': account.userId,
      'username': account.username,
      'email': account.email,
      'token': token,
      'emailVerified': false,
      'emailVerificationToken': emailVerificationToken,
      'emailVerificationExpiresAt': emailVerificationExpiresAt,
    };
  }

  /// Autentica um usuário com email e senha
  ///
  /// Validações:
  /// - Email existe no banco
  /// - Senha corresponde ao hash armazenado
  ///
  /// Retorna: Map com 'userId', 'username', 'email' e 'token'
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final db = Database();
    final conn = db.connection;

    final normalizedEmail = normalizeEmail(email);

    // Buscar usuário por email
    final result = await conn.execute(
      Sql.named('''
        SELECT id, username, email, password_hash, auth_version,
               email_verified_at
        FROM users
        WHERE (email = @email OR LOWER(email) = @email)
          AND deleted_at IS NULL
        ORDER BY CASE WHEN email = @email THEN 0 ELSE 1 END
        LIMIT 1
      '''),
      parameters: {'email': normalizedEmail},
    );

    if (result.isEmpty) {
      throw Exception('Credenciais inválidas');
    }

    final row = result.first;
    final userId = row[0] as String;
    final username = row[1] as String;
    final userEmail = row[2] as String;
    final passwordHash = row[3] as String;
    final authVersion = _readInteger(row[4]);

    // Verificar senha
    if (!verifyPassword(password, passwordHash)) {
      throw Exception('Credenciais inválidas');
    }

    // Gerar token
    final token = generateToken(userId, username, authVersion: authVersion);

    return {
      'userId': userId,
      'username': username,
      'email': userEmail,
      'token': token,
      'emailVerified': row[5] != null,
    };
  }

  /// Busca informações do usuário a partir do token JWT
  ///
  /// Útil para endpoints que precisam identificar o usuário autenticado
  Future<Map<String, dynamic>?> getUserFromToken(String token) async {
    final payload = verifyToken(token);
    if (payload == null) return null;

    final rawUserId = payload['userId'];
    if (rawUserId is! String || rawUserId.trim().isEmpty) return null;
    final userId = rawUserId.trim();

    final db = Database();
    final conn = db.connection;

    final result = await conn.execute(
      Sql.named(
        'SELECT id, username, email, display_name, avatar_url, auth_version, '
        'email_verified_at '
        'FROM users '
        'WHERE id = @userId AND deleted_at IS NULL',
      ),
      parameters: {'userId': userId},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final tokenAuthVersion = _readInteger(payload['authVersion']);
    final currentAuthVersion = _readInteger(row[5]);
    if (tokenAuthVersion != currentAuthVersion) return null;
    return {
      'id': row[0] as String,
      'username': row[1] as String,
      'email': row[2] as String,
      'display_name': row[3] as String?,
      'avatar_url': row[4] as String?,
      'email_verified': row[6] != null,
    };
  }

  Future<EmailVerificationRequest?> createEmailVerificationRequest({
    required String userId,
    Duration validFor = const Duration(hours: 24),
  }) async {
    final token = _newOpaqueToken();
    final expiresAt = DateTime.now().toUtc().add(validFor);
    final conn = Database().connection;
    return conn.runTx((session) async {
      final users = await session.execute(
        Sql.named('''
          SELECT email, email_verified_at
          FROM users
          WHERE id = CAST(@userId AS uuid) AND deleted_at IS NULL
          FOR UPDATE
        '''),
        parameters: {'userId': userId},
      );
      if (users.isEmpty || users.first[1] != null) return null;
      await session.execute(
        Sql.named('''
          UPDATE email_verification_tokens
          SET consumed_at = CURRENT_TIMESTAMP
          WHERE user_id = CAST(@userId AS uuid) AND consumed_at IS NULL
        '''),
        parameters: {'userId': userId},
      );
      await session.execute(
        Sql.named('''
          INSERT INTO email_verification_tokens (
            user_id, token_hash, expires_at
          ) VALUES (
            CAST(@userId AS uuid), @tokenHash, @expiresAt
          )
        '''),
        parameters: {
          'userId': userId,
          'tokenHash': _hashOpaqueToken(token),
          'expiresAt': expiresAt,
        },
      );
      return EmailVerificationRequest(
        email: users.first[0] as String,
        token: token,
        expiresAt: expiresAt,
      );
    });
  }

  Future<void> verifyEmail(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty || normalizedToken.length > 512) {
      throw const AccountSecurityException(
        'email_verification_token_invalid',
        'Link de verificação inválido ou expirado.',
      );
    }
    final conn = Database().connection;
    await conn.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          SELECT t.user_id, t.expires_at, t.consumed_at
          FROM email_verification_tokens t
          JOIN users u ON u.id = t.user_id
          WHERE t.token_hash = @tokenHash AND u.deleted_at IS NULL
          FOR UPDATE OF t, u
        '''),
        parameters: {'tokenHash': _hashOpaqueToken(normalizedToken)},
      );
      if (rows.isEmpty ||
          rows.first[2] != null ||
          !(rows.first[1] as DateTime).isAfter(DateTime.now().toUtc())) {
        throw const AccountSecurityException(
          'email_verification_token_invalid',
          'Link de verificação inválido ou expirado.',
        );
      }
      final userId = rows.first[0] as String;
      await session.execute(
        Sql.named('''
          UPDATE users
          SET email_verified_at = COALESCE(
                email_verified_at, CURRENT_TIMESTAMP
              ),
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@userId AS uuid)
        '''),
        parameters: {'userId': userId},
      );
      await session.execute(
        Sql.named('''
          UPDATE email_verification_tokens
          SET consumed_at = CURRENT_TIMESTAMP
          WHERE user_id = CAST(@userId AS uuid) AND consumed_at IS NULL
        '''),
        parameters: {'userId': userId},
      );
    });
  }

  /// Creates a single-use reset credential. Only its SHA-256 digest is stored.
  /// A null result deliberately means either "unknown" or "inactive" account;
  /// routes must keep the public response identical to prevent enumeration.
  Future<PasswordResetRequest?> createPasswordResetRequest({
    required String email,
    Duration validFor = const Duration(minutes: 20),
  }) async {
    final normalizedEmail = normalizeEmail(email);
    final rawToken = _newOpaqueToken();
    final tokenHash = _hashOpaqueToken(rawToken);
    final conn = Database().connection;
    final users = await conn.execute(
      Sql.named('''
        SELECT id, email
        FROM users
        WHERE LOWER(email) = @email AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'email': normalizedEmail},
    );
    if (users.isEmpty) return null;

    final userId = users.first[0] as String;
    final deliveryEmail = users.first[1] as String;
    final expiresAt = DateTime.now().toUtc().add(validFor);
    await conn.runTx((session) async {
      await session.execute(
        Sql.named('''
          UPDATE password_reset_tokens
          SET consumed_at = CURRENT_TIMESTAMP
          WHERE user_id = CAST(@userId AS uuid) AND consumed_at IS NULL
        '''),
        parameters: {'userId': userId},
      );
      await session.execute(
        Sql.named('''
          INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
          VALUES (CAST(@userId AS uuid), @tokenHash, @expiresAt)
        '''),
        parameters: {
          'userId': userId,
          'tokenHash': tokenHash,
          'expiresAt': expiresAt,
        },
      );
    });
    return PasswordResetRequest(
      email: deliveryEmail,
      token: rawToken,
      expiresAt: expiresAt,
    );
  }

  /// Consumes a reset credential atomically and invalidates every older JWT.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty || normalizedToken.length > 512) {
      throw const AccountSecurityException(
        'reset_token_invalid',
        'Link de recuperação inválido ou expirado.',
      );
    }
    final tokenHash = _hashOpaqueToken(normalizedToken);
    final conn = Database().connection;
    await conn.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          SELECT t.user_id, t.expires_at, t.consumed_at,
                 u.username, u.email, u.password_hash
          FROM password_reset_tokens t
          JOIN users u ON u.id = t.user_id
          WHERE t.token_hash = @tokenHash AND u.deleted_at IS NULL
          FOR UPDATE OF t, u
        '''),
        parameters: {'tokenHash': tokenHash},
      );
      if (rows.isEmpty) {
        throw const AccountSecurityException(
          'reset_token_invalid',
          'Link de recuperação inválido ou expirado.',
        );
      }
      final row = rows.first;
      final expiresAt = row[1] as DateTime;
      final consumedAt = row[2] as DateTime?;
      if (consumedAt != null || !expiresAt.isAfter(DateTime.now().toUtc())) {
        throw const AccountSecurityException(
          'reset_token_invalid',
          'Link de recuperação inválido ou expirado.',
        );
      }
      final username = row[3] as String;
      final email = row[4] as String;
      final currentHash = row[5] as String;
      _validateReplacementPassword(
        newPassword,
        username: username,
        email: email,
        currentHash: currentHash,
      );

      await session.execute(
        Sql.named('''
          UPDATE users
          SET password_hash = @passwordHash,
              password_changed_at = CURRENT_TIMESTAMP,
              auth_version = auth_version + 1,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@userId AS uuid)
        '''),
        parameters: {
          'userId': row[0] as String,
          'passwordHash': hashPassword(newPassword),
        },
      );
      await session.execute(
        Sql.named('''
          UPDATE password_reset_tokens
          SET consumed_at = CURRENT_TIMESTAMP
          WHERE user_id = CAST(@userId AS uuid) AND consumed_at IS NULL
        '''),
        parameters: {'userId': row[0] as String},
      );
    });
  }

  /// Changes the password and returns a replacement token for this client.
  /// Every token issued before the transaction becomes invalid immediately.
  Future<AccountSecurityResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _rotateAuthenticationVersion(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Revokes every existing session and returns one fresh token for the caller.
  Future<AccountSecurityResult> revokeSessions({
    required String userId,
    required String currentPassword,
  }) {
    return _rotateAuthenticationVersion(
      userId: userId,
      currentPassword: currentPassword,
    );
  }

  Future<AccountSecurityResult> _rotateAuthenticationVersion({
    required String userId,
    required String currentPassword,
    String? newPassword,
  }) async {
    final conn = Database().connection;
    return conn.runTx((session) async {
      final rows = await session.execute(
        Sql.named('''
          SELECT username, email, password_hash, auth_version
          FROM users
          WHERE id = CAST(@userId AS uuid) AND deleted_at IS NULL
          FOR UPDATE
        '''),
        parameters: {'userId': userId},
      );
      if (rows.isEmpty ||
          !verifyPassword(currentPassword, rows.first[2] as String)) {
        throw const AccountSecurityException(
          'current_password_invalid',
          'Senha atual incorreta.',
        );
      }
      final row = rows.first;
      final username = row[0] as String;
      final email = row[1] as String;
      if (newPassword != null) {
        _validateReplacementPassword(
          newPassword,
          username: username,
          email: email,
          currentHash: row[2] as String,
        );
      }
      final nextVersion = _readInteger(row[3]) + 1;
      await session.execute(
        Sql.named('''
          UPDATE users
          SET auth_version = @authVersion,
              password_hash = COALESCE(@passwordHash, password_hash),
              password_changed_at = CASE
                WHEN @passwordHash IS NULL THEN password_changed_at
                ELSE CURRENT_TIMESTAMP
              END,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@userId AS uuid)
        '''),
        parameters: {
          'userId': userId,
          'authVersion': nextVersion,
          'passwordHash':
              newPassword == null ? null : hashPassword(newPassword),
        },
      );
      if (newPassword != null) {
        await session.execute(
          Sql.named('''
            UPDATE password_reset_tokens
            SET consumed_at = CURRENT_TIMESTAMP
            WHERE user_id = CAST(@userId AS uuid) AND consumed_at IS NULL
          '''),
          parameters: {'userId': userId},
        );
      }
      return AccountSecurityResult(
        token: generateToken(userId, username, authVersion: nextVersion),
        userId: userId,
        username: username,
        email: email,
      );
    });
  }

  void _validateReplacementPassword(
    String password, {
    required String username,
    required String email,
    required String currentHash,
  }) {
    final validation = PasswordPolicy.validate(
      password,
      username: username,
      email: email,
    );
    if (!validation.isValid) {
      throw AccountSecurityException(
        validation.code ?? 'password_policy_failed',
        validation.message ?? 'A nova senha não atende aos requisitos.',
      );
    }
    if (verifyPassword(password, currentHash)) {
      throw const AccountSecurityException(
        'password_unchanged',
        'A nova senha deve ser diferente da senha atual.',
      );
    }
  }

  String _newOpaqueToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _hashOpaqueToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  int _readInteger(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String text => int.tryParse(text) ?? 0,
    _ => 0,
  };

  _PasswordPreparation _normalizePasswordForStorage(String password) {
    final normalized = _preparePassword(password);
    return _PasswordPreparation(
      value: normalized,
      preHashed: normalized != password,
    );
  }

  String _preparePassword(String password) {
    final passwordBytes = utf8.encode(password);
    if (passwordBytes.length <= 72) {
      return password;
    }
    return sha256.convert(passwordBytes).toString();
  }
}

class _PasswordPreparation {
  const _PasswordPreparation({required this.value, required this.preHashed});

  final String value;
  final bool preHashed;
}

class PasswordResetRequest {
  const PasswordResetRequest({
    required this.email,
    required this.token,
    required this.expiresAt,
  });

  final String email;
  final String token;
  final DateTime expiresAt;
}

class EmailVerificationRequest {
  const EmailVerificationRequest({
    required this.email,
    required this.token,
    required this.expiresAt,
  });

  final String email;
  final String token;
  final DateTime expiresAt;
}

class AccountSecurityResult {
  const AccountSecurityResult({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
  });

  final String token;
  final String userId;
  final String username;
  final String email;

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': {'id': userId, 'username': username, 'email': email},
  };
}

class AccountSecurityException implements Exception {
  const AccountSecurityException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
