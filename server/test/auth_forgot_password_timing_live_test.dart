@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

/// Aceite da D-21 para a recuperação de senha (BT-AUTH-003): em 50
/// tentativas de cada caso, a diferença entre as medianas do tempo de
/// resposta de "e-mail com conta" e "e-mail sem conta" fica abaixo de 20 ms,
/// e as respostas são idênticas.
///
/// Mede o modo de produção: se a API devolve `test_reset_token` (modo de
/// teste, que cria o token dentro da requisição), o teste pula.
void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  test(
    'recuperação de senha não denuncia pelo tempo quais e-mails têm conta',
    () async {
      const rounds = 50;
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final email = 'forgot_timing_$suffix@example.invalid';
      final client = http.Client();
      addTearDown(client.close);

      Future<http.Response> post(String path, Map<String, dynamic> payload) =>
          client.post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

      final registration = await post('/auth/register', {
        'username': 'forgot_timing_$suffix',
        'email': email,
        'password': 'BetaQa!2026-Deck',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      });
      expect(registration.statusCode, 201, reason: registration.body);

      Future<(int, http.Response)> attempt(String target) async {
        final watch = Stopwatch()..start();
        final response = await post('/auth/forgot-password', {'email': target});
        return (watch.elapsedMicroseconds, response);
      }

      final (_, probe) = await attempt(email);
      if (probe.body.contains('test_reset_token')) {
        markTestSkipped(
          'A API está no modo de teste (test_reset_token); a medição exige '
          'o modo de produção.',
        );
        return;
      }

      final existing = <int>[];
      final missing = <int>[];
      for (var i = 0; i < rounds; i++) {
        final (existingMicros, existingResponse) = await attempt(email);
        final (missingMicros, missingResponse) = await attempt(
          'forgot_missing_${suffix}_$i@example.invalid',
        );
        expect(existingResponse.statusCode, 202, reason: existingResponse.body);
        expect(missingResponse.statusCode, 202, reason: missingResponse.body);
        expect(missingResponse.body, existingResponse.body);
        existing.add(existingMicros);
        missing.add(missingMicros);
      }

      final difference = (_median(existing) - _median(missing)).abs() / 1000;
      printOnFailure(
        'mediana com conta ${_median(existing) / 1000} ms, '
        'sem conta ${_median(missing) / 1000} ms',
      );
      expect(difference, lessThan(20));
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

int _median(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) ~/ 2;
}
