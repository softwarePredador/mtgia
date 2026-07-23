@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovação explícita.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;

  Map<String, dynamic> decode(http.Response response) =>
      (jsonDecode(response.body) as Map).cast<String, dynamic>();

  Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  test(
    'production AI provider outage fails closed without mock success',
    () async {
      expect(
        Platform.environment['OPENAI_PROFILE'],
        'prod',
        reason:
            'the failure-injection server and test process must share the '
            'fail-closed AI profile',
      );
      String? cleanupToken;
      addTearDown(() async {
        if (cleanupToken == null) return;
        final deletion = await http.delete(
          Uri.parse('$baseUrl/users/me'),
          headers: headers(cleanupToken),
          body: jsonEncode({
            'confirmation': 'EXCLUIR MINHA CONTA',
            'password': 'BetaQa!2026-Provider',
          }),
        );
        expect(deletion.statusCode, 200, reason: deletion.body);
      });

      final registerResponse = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 's8-04-provider-$suffix@example.com',
          'password': 'BetaQa!2026-Provider',
          'username': 's8_04_provider_$suffix',
          'legal_accepted': true,
          'terms_version': currentTermsVersion,
          'privacy_version': currentPrivacyVersion,
        }),
      );
      expect(
        registerResponse.statusCode,
        anyOf(200, 201),
        reason: registerResponse.body,
      );
      final token = decode(registerResponse)['token'] as String;
      cleanupToken = token;
      final authHeaders = headers(token);
      final errorRequestId = 'mob-s8-05-provider-$suffix';

      final syncGenerate = await http.post(
        Uri.parse('$baseUrl/ai/generate'),
        headers: {...authHeaders, 'x-request-id': errorRequestId},
        body: jsonEncode({
          'prompt': 'Mono white artifacts',
          'format': 'commander',
        }),
      );
      expect(syncGenerate.statusCode, 503, reason: syncGenerate.body);
      expect(syncGenerate.headers['x-request-id'], errorRequestId);
      final syncBody = decode(syncGenerate);
      expect(syncBody['error'], 'AI provider is not configured');
      expect(syncBody['generated_deck'], isNull);
      expect(syncBody['is_mock'], isNot(true));

      final requestKey = 'generate:provider-outage-$suffix';
      final asyncPayload = {
        'prompt': 'Mono white artifacts',
        'format': 'commander',
        'async': true,
        'request_key': requestKey,
      };
      final asyncGenerate = await http.post(
        Uri.parse('$baseUrl/ai/generate'),
        headers: authHeaders,
        body: jsonEncode(asyncPayload),
      );
      expect(asyncGenerate.statusCode, 202, reason: asyncGenerate.body);
      final accepted = decode(asyncGenerate);
      final jobId = accepted['job_id'] as String;

      final idempotentRetry = await http.post(
        Uri.parse('$baseUrl/ai/generate'),
        headers: authHeaders,
        body: jsonEncode(asyncPayload),
      );
      expect(idempotentRetry.statusCode, 202, reason: idempotentRetry.body);
      final retried = decode(idempotentRetry);
      expect(retried['job_id'], jobId);
      expect(
        (retried['idempotency'] as Map<String, dynamic>)['reused'],
        isTrue,
      );

      Map<String, dynamic>? terminal;
      for (var attempt = 0; attempt < 50; attempt += 1) {
        final poll = await http.get(
          Uri.parse('$baseUrl/ai/generate/jobs/$jobId'),
          headers: authHeaders,
        );
        expect(poll.statusCode, 200, reason: poll.body);
        final body = decode(poll);
        if (body['status'] == 'failed' ||
            body['status'] == 'completed' ||
            body['status'] == 'cancelled') {
          terminal = body;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(terminal, isNotNull);
      expect(terminal!['status'], 'failed');
      expect(terminal['result'], isNull);
      expect(terminal['is_mock'], isNot(true));
      expect(terminal['heartbeat_at'], isNotNull);
      expect(terminal['deadline_at'], isNotNull);

      final optimize = await http.post(
        Uri.parse('$baseUrl/ai/optimize'),
        headers: authHeaders,
        body: jsonEncode({
          'deck_id': '00000000-0000-4000-8000-000000000099',
          'archetype': 'control',
          'intensity': 'focused',
          'request_key': 'optimize:provider-outage-$suffix',
        }),
      );
      expect(optimize.statusCode, 503, reason: optimize.body);
      final optimizeBody = decode(optimize);
      expect(optimizeBody['outcome_code'], 'provider_unavailable');
      expect(optimizeBody['can_apply'], isFalse);
      expect(optimizeBody['learning_eligible'], isFalse);
      expect(optimizeBody['is_mock'], isNot(true));
      expect(optimizeBody['removals'], isNull);
      expect(optimizeBody['additions'], isNull);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
