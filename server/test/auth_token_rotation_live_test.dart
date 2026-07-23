@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  test(
    'session revocation rejects every old JWT and preserves cleanup access',
    () async {
      final client = http.Client();
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final email = 'token_rotation_$suffix@example.com';
      final username = 'token_rotation_$suffix';
      const password = 'TokenRotation!2026-Safe';
      var accountCreated = false;
      String? cleanupToken;

      addTearDown(() async {
        if (accountCreated && cleanupToken != null) {
          final cleanup = await client.delete(
            Uri.parse('$baseUrl/users/me'),
            headers: _headers(cleanupToken),
            body: jsonEncode({
              'confirmation': 'EXCLUIR MINHA CONTA',
              'password': password,
            }),
          );
          expect(cleanup.statusCode, 200, reason: cleanup.body);
        }
        client.close();
      });

      final registration = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'legal_accepted': true,
          'terms_version': currentTermsVersion,
          'privacy_version': currentPrivacyVersion,
        }),
      );
      expect(registration.statusCode, 201, reason: registration.body);
      accountCreated = true;
      final tokenA = _body(registration)['token'] as String;
      cleanupToken = tokenA;

      final login = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      expect(login.statusCode, 200, reason: login.body);
      final tokenB = _body(login)['token'] as String;
      cleanupToken = tokenB;

      expect(
        await client.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(tokenA),
        ),
        _hasStatus(200),
      );
      expect(
        await client.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(tokenB),
        ),
        _hasStatus(200),
      );

      final revoke = await client.post(
        Uri.parse('$baseUrl/auth/revoke-sessions'),
        headers: _headers(tokenB),
        body: jsonEncode({'current_password': password}),
      );
      expect(revoke.statusCode, 200, reason: revoke.body);
      final tokenC = _body(revoke)['token'] as String;
      cleanupToken = tokenC;

      expect(
        await client.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(tokenA),
        ),
        _hasStatus(401),
      );
      expect(
        await client.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(tokenB),
        ),
        _hasStatus(401),
      );
      expect(
        await client.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _headers(tokenC),
        ),
        _hasStatus(200),
      );

      final deletion = await client.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers(tokenC),
        body: jsonEncode({
          'confirmation': 'EXCLUIR MINHA CONTA',
          'password': password,
        }),
      );
      expect(deletion.statusCode, 200, reason: deletion.body);
      expect(_body(deletion)['account_deleted'], isTrue);
      accountCreated = false;
    },
    skip: skipIntegration,
  );
}

Map<String, String> _headers([String? token]) => {
  'Content-Type': 'application/json',
  'X-Request-Id': 'qa-token-rotation-${DateTime.now().microsecondsSinceEpoch}',
  if (token != null) 'Authorization': 'Bearer $token',
};

Map<String, dynamic> _body(http.Response response) =>
    jsonDecode(response.body) as Map<String, dynamic>;

Matcher _hasStatus(int expected) => isA<http.Response>().having(
  (response) => response.statusCode,
  'statusCode',
  expected,
);
