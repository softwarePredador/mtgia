@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:server/legal_policy.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL.'
          : null;

  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  final userSuffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final testUser = {
    'email': 'ai_tel_$userSuffix@example.invalid',
    'password': 'BetaQa!2026-Deck',
    'username': 'ai_tel_$userSuffix',
  };
  String? authToken;

  Map<String, dynamic> decodeJson(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'value': decoded};
  }

  Future<String> getAuthToken() async {
    if (authToken != null) return authToken!;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...testUser,
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register test user: ${response.body}');
    }

    authToken = decodeJson(response)['token'] as String;
    return authToken!;
  }

  Future<void> deleteAccount() async {
    if (authToken == null) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'confirmation': 'EXCLUIR MINHA CONTA',
        'password': testUser['password'],
      }),
    );
    expect(response.statusCode, anyOf(200, 404), reason: response.body);
    authToken = null;
  }

  tearDownAll(deleteAccount);

  group('AI optimize telemetry contract | /ai/optimize/telemetry', () {
    test('returns 401 without token', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/optimize/telemetry'),
      );

      expect(response.statusCode, equals(401), reason: response.body);
      final body = decodeJson(response);
      expect(body['error'], isA<String>());
    }, skip: skipIntegration);

    test('returns persisted telemetry aggregate with auth', () async {
      final token = await getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/ai/optimize/telemetry?days=7'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(response.statusCode, equals(200), reason: response.body);

      final body = decodeJson(response);
      expect(
        body['status'],
        anyOf(equals('ok'), equals('not_initialized')),
        reason: response.body,
      );

      if (body['status'] == 'ok') {
        expect(body['window_days'], equals(7));
        expect(body['current_user_window'], isA<Map<String, dynamic>>());
        expect(body['current_user_by_day'], isA<List>());
        expect(body['scope'], isA<Map<String, dynamic>>());
      }
    }, skip: skipIntegration);

    test('returns 400 for invalid days', () async {
      final token = await getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/ai/optimize/telemetry?days=abc'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(response.statusCode, equals(400), reason: response.body);
      final body = decodeJson(response);
      expect(body['error'], isA<String>());
    }, skip: skipIntegration);

    test(
      'returns 403 for global scope without admin privileges',
      () async {
        final token = await getAuthToken();

        final response = await http.get(
          Uri.parse('$baseUrl/ai/optimize/telemetry?include_global=true'),
          headers: {'Authorization': 'Bearer $token'},
        );

        expect(response.statusCode, equals(403), reason: response.body);
        final body = decodeJson(response);
        expect(body['error'], isA<String>());
      },
      skip: skipIntegration,
    );
  });
}
