@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  Map<String, String> headers([String? token]) => {
    'Content-Type': 'application/json',
    'X-Request-Id': 'account-security-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> body(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<http.Response> post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) => http.post(
    Uri.parse('$baseUrl$path'),
    headers: headers(token),
    body: jsonEncode(payload),
  );

  Future<http.Response> me(String token) =>
      http.get(Uri.parse('$baseUrl/auth/me'), headers: headers(token));

  Future<void> expireResetToken(String rawToken) async {
    final pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    try {
      await pool.execute(
        Sql.named('''
          UPDATE password_reset_tokens
          SET expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
          WHERE token_hash = @tokenHash
        '''),
        parameters: {
          'tokenHash': sha256.convert(utf8.encode(rawToken)).toString(),
        },
      );
    } finally {
      await pool.close();
    }
  }

  test(
    'reset, change and revoke are atomic, single-use and invalidate old JWTs',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final email = 'security_$suffix@example.invalid';
      final username = 'security_$suffix';
      const originalPassword = 'BetaQa!2026-Deck';
      const resetPassword = 'Reset!2026-Deck-Safe';
      const changedPassword = 'Changed!2026-Deck-Safe';

      final registration = await post('/auth/register', {
        'username': username,
        'email': email,
        'password': originalPassword,
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      });
      expect(registration.statusCode, 201, reason: registration.body);
      final tokenA = body(registration)['token'] as String;

      final secondLogin = await post('/auth/login', {
        'email': email,
        'password': originalPassword,
      });
      expect(secondLogin.statusCode, 200, reason: secondLogin.body);
      final tokenB = body(secondLogin)['token'] as String;

      final unknownForgot = await post('/auth/forgot-password', {
        'email': 'missing_$suffix@example.invalid',
      });
      final forgot = await post('/auth/forgot-password', {'email': email});
      expect(unknownForgot.statusCode, 202, reason: unknownForgot.body);
      expect(forgot.statusCode, 202, reason: forgot.body);
      expect(body(unknownForgot)['message'], body(forgot)['message']);
      final firstResetToken = body(forgot)['test_reset_token'] as String;

      final weakReset = await post('/auth/reset-password', {
        'token': firstResetToken,
        'new_password': 'weak',
      });
      expect(weakReset.statusCode, 400, reason: weakReset.body);
      expect(await me(tokenA), hasStatus(200));

      final expiredForgot = await post('/auth/forgot-password', {
        'email': email,
      });
      final expiredToken = body(expiredForgot)['test_reset_token'] as String;
      await expireResetToken(expiredToken);
      final expiredReset = await post('/auth/reset-password', {
        'token': expiredToken,
        'new_password': resetPassword,
      });
      expect(expiredReset.statusCode, 400, reason: expiredReset.body);
      expect(body(expiredReset)['error'], 'reset_token_invalid');

      final usableForgot = await post('/auth/forgot-password', {
        'email': email,
      });
      final usableToken = body(usableForgot)['test_reset_token'] as String;
      final reset = await post('/auth/reset-password', {
        'token': usableToken,
        'new_password': resetPassword,
      });
      expect(reset.statusCode, 200, reason: reset.body);
      final reusedReset = await post('/auth/reset-password', {
        'token': usableToken,
        'new_password': changedPassword,
      });
      expect(reusedReset.statusCode, 400, reason: reusedReset.body);
      expect(body(reusedReset)['error'], 'reset_token_invalid');
      expect(await me(tokenA), hasStatus(401));
      expect(await me(tokenB), hasStatus(401));
      expect(
        await post('/auth/login', {
          'email': email,
          'password': originalPassword,
        }),
        hasStatus(401),
      );

      final loginAfterReset = await post('/auth/login', {
        'email': email,
        'password': resetPassword,
      });
      expect(loginAfterReset.statusCode, 200, reason: loginAfterReset.body);
      final tokenC = body(loginAfterReset)['token'] as String;

      final wrongChange = await post('/auth/change-password', {
        'current_password': 'Wrong!2026-Password',
        'new_password': changedPassword,
      }, token: tokenC);
      expect(wrongChange.statusCode, 400, reason: wrongChange.body);
      expect(await me(tokenC), hasStatus(200));

      final change = await post('/auth/change-password', {
        'current_password': resetPassword,
        'new_password': changedPassword,
      }, token: tokenC);
      expect(change.statusCode, 200, reason: change.body);
      final tokenD = body(change)['token'] as String;
      expect(await me(tokenC), hasStatus(401));
      expect(await me(tokenD), hasStatus(200));

      final wrongRevoke = await post('/auth/revoke-sessions', {
        'current_password': 'Wrong!2026-Password',
      }, token: tokenD);
      expect(wrongRevoke.statusCode, 400, reason: wrongRevoke.body);
      expect(await me(tokenD), hasStatus(200));

      final revoke = await post('/auth/revoke-sessions', {
        'current_password': changedPassword,
      }, token: tokenD);
      expect(revoke.statusCode, 200, reason: revoke.body);
      expect(body(revoke)['sessions_revoked'], isTrue);
      final tokenE = body(revoke)['token'] as String;
      expect(await me(tokenD), hasStatus(401));
      expect(await me(tokenE), hasStatus(200));
    },
    skip: skipIntegration,
  );
}

Matcher hasStatus(int status) => isA<http.Response>().having(
  (response) => response.statusCode,
  'statusCode',
  status,
);
