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
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.Response> post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) => http.post(
    Uri.parse('$baseUrl$path'),
    headers: headers(token),
    body: jsonEncode(payload),
  );

  Map<String, dynamic> body(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<Map<String, dynamic>> register(String name) async {
    final response = await post('/auth/register', {
      'username': name,
      'email': '$name@example.invalid',
      'password': 'BetaQa!2026-Deck',
      'legal_accepted': true,
      'terms_version': currentTermsVersion,
      'privacy_version': currentPrivacyVersion,
    });
    expect(response.statusCode, 201, reason: response.body);
    return body(response);
  }

  Future<void> expire(String rawToken) async {
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
          UPDATE email_verification_tokens
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
    'UGC writes require verified email; tokens expire and are single-use',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final actor = await register('verified_actor_$suffix');
      final target = await register('verified_target_$suffix');
      expect(actor['verification_sent'], isTrue);
      expect(target['verification_sent'], isTrue);
      final actorToken = actor['token'] as String;
      final targetId = (target['user'] as Map<String, dynamic>)['id'] as String;

      final blocked = await post('/conversations', {
        'user_id': targetId,
      }, token: actorToken);
      expect(blocked.statusCode, 403, reason: blocked.body);
      expect(body(blocked)['error'], 'email_verification_required');

      final initialToken = actor['test_verification_token'] as String;
      await expire(initialToken);
      final expired = await post('/auth/verify-email', {'token': initialToken});
      expect(expired.statusCode, 400, reason: expired.body);

      final resend = await post(
        '/auth/resend-verification',
        const {},
        token: actorToken,
      );
      expect(resend.statusCode, 202, reason: resend.body);
      final usableToken = body(resend)['test_verification_token'] as String;
      final verified = await post('/auth/verify-email', {'token': usableToken});
      expect(verified.statusCode, 200, reason: verified.body);
      expect(body(verified)['email_verified'], isTrue);

      final reused = await post('/auth/verify-email', {'token': usableToken});
      expect(reused.statusCode, 400, reason: reused.body);
      final me = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers(actorToken),
      );
      expect(me.statusCode, 200, reason: me.body);
      expect((body(me)['user'] as Map)['email_verified'], isTrue);

      final conversation = await post('/conversations', {
        'user_id': targetId,
      }, token: actorToken);
      expect(conversation.statusCode, 200, reason: conversation.body);

      final alreadyVerified = await post(
        '/auth/resend-verification',
        const {},
        token: actorToken,
      );
      expect(alreadyVerified.statusCode, 200, reason: alreadyVerified.body);
      expect(body(alreadyVerified)['already_verified'], isTrue);
      expect(body(alreadyVerified), isNot(contains('test_verification_token')));
    },
    skip: skipIntegration,
  );
}
