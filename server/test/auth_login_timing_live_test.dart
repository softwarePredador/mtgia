@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

/// Aceite da D-21 para o oráculo de enumeração do login (BT-AUTH-003):
/// em 50 tentativas de cada caso, a diferença entre as medianas do tempo de
/// resposta de "e-mail com conta + senha errada" e "e-mail sem conta" fica
/// abaixo de 20 ms, e as duas respostas são idênticas.
///
/// Roda contra uma API viva com cadastro ligado (harness isolado). Fora do
/// perfil determinístico: tempo de rede e de CPU dependem da máquina.
void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  test(
    'login não denuncia pelo tempo nem pelo corpo quais e-mails têm conta',
    () async {
      const rounds = 50;
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final email = 'timing_$suffix@example.invalid';
      final client = http.Client();
      addTearDown(client.close);

      Future<http.Response> post(String path, Map<String, dynamic> payload) =>
          client.post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

      final registration = await post('/auth/register', {
        'username': 'timing_$suffix',
        'email': email,
        'password': 'BetaQa!2026-Deck',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      });
      expect(registration.statusCode, 201, reason: registration.body);

      Future<(int, http.Response)> attempt(String target) async {
        final watch = Stopwatch()..start();
        final response = await post('/auth/login', {
          'email': target,
          'password': 'Senha!Errada-2026',
        });
        return (watch.elapsedMicroseconds, response);
      }

      final existing = <int>[];
      final missing = <int>[];
      for (var i = 0; i < rounds; i++) {
        final (existingMicros, existingResponse) = await attempt(email);
        final (missingMicros, missingResponse) = await attempt(
          'timing_missing_${suffix}_$i@example.invalid',
        );
        expect(existingResponse.statusCode, 401, reason: existingResponse.body);
        expect(missingResponse.statusCode, 401, reason: missingResponse.body);
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
