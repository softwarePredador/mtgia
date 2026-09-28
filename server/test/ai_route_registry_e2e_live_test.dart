@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// BT-AI-029 e D-31 de ponta a ponta, por HTTP contra a API local com as
/// capabilities `account_registration`, `decks_private`,
/// `ai_analyze_optimize_advisory` e `legacy_ai_routes` ligadas no manifesto
/// isolado. Mesmo com a capability legada ligada, as quatro rotas removidas
/// respondem 404; as rotas que ficaram seguem respondendo.
///
/// Requer `RUN_AI_ROUTE_REGISTRY_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled =
      Platform.environment['RUN_AI_ROUTE_REGISTRY_E2E_TESTS'] == '1';
  final skipReason = enabled ? null : 'Requer API local e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late String token;
  late String deckId;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, String> headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    final sent = <String, String>{};
    final issuer = BetaInviteIssuer(
      pool,
      deliver: ({
        required String email,
        required String code,
        required DateTime expiresAt,
      }) async {
        sent[email] = code;
        return true;
      },
    );
    final email = '${unique('registry')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-registry',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('registry'),
        'email': email,
        'password': 'Convite!Beta-2026',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
        'invite_code': sent[email],
      }),
    );
    expect(created.statusCode, 201, reason: created.body);
    token = json(created)['token'] as String;

    final deck = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: headers(),
      body: jsonEncode({'name': unique('deck'), 'format': 'commander'}),
    );
    expect(deck.statusCode, anyOf(200, 201), reason: deck.body);
    deckId = ((json(deck)['deck'] ?? json(deck)) as Map)['id'] as String;
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  test('as quatro rotas removidas pela D-31 respondem 404, mesmo com a '
      'capability legada ligada', () async {
    for (final (method, path, code) in [
      ('POST', '/ai/weakness-analysis', 'capability_route_unclassified'),
      ('POST', '/ai/simulate-matchup', 'capability_route_unclassified'),
      ('POST', '/decks/{deck}/recommendations', null),
      ('GET', '/decks/{deck}/simulate', null),
    ]) {
      final uri = Uri.parse('$baseUrl${path.replaceAll('{deck}', deckId)}');
      final response =
          method == 'GET'
              ? await http.get(uri, headers: headers())
              : await http.post(uri, headers: headers(), body: '{}');
      expect(response.statusCode, 404, reason: '$method $path');
      if (code != null) {
        expect(json(response)['error'], code, reason: '$method $path');
      }
    }
  }, skip: skipReason);

  test('as rotas que ficaram seguem respondendo', () async {
    // Análise determinística do deck, sob a mesma capability do Analyze.
    final analysis = await http.get(
      Uri.parse('$baseUrl/decks/$deckId/analysis'),
      headers: headers(),
    );
    expect(analysis.statusCode, 200, reason: analysis.body);

    // A rota legada que ficou com o BT-AI-027 existe (conta comum não é
    // administradora, mas a rota responde).
    final mlStatus = await http.get(
      Uri.parse('$baseUrl/ai/ml-status'),
      headers: headers(),
    );
    expect(mlStatus.statusCode, isNot(404), reason: mlStatus.body);
  }, skip: skipReason);
}
