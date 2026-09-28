@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_job.dart';
import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// `GET /ai/optimize/jobs/latest` de ponta a ponta, por HTTP contra a API
/// local com `account_registration`, `decks_private` e
/// `ai_analyze_optimize_advisory` ligadas no manifesto isolado. Sem job
/// ativo, a folha de otimização recebe 200 com `{"job": null}`, e o navegador
/// não registra erro no console. O 404 fica para o deck que não é da conta,
/// não existe ou nem é UUID.
///
/// Requer `RUN_OPTIMIZE_JOB_LATEST_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled =
      Platform.environment['RUN_OPTIMIZE_JOB_LATEST_E2E_TESTS'] == '1';
  final skipReason = enabled ? null : 'Requer API local e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late ({String token, String userId, String deckId}) owner;
  late ({String token, String userId, String deckId}) stranger;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<({String token, String userId, String deckId})> account() async {
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
    final email = '${unique('latest')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-latest',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('latest'),
        'email': email,
        'password': 'Convite!Beta-2026',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
        'invite_code': sent[email],
      }),
    );
    expect(created.statusCode, 201, reason: created.body);
    final body = json(created);
    final token = body['token'] as String;
    final userId = (body['user'] as Map<String, dynamic>)['id'] as String;
    final deck = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': unique('deck'), 'format': 'commander'}),
    );
    expect(deck.statusCode, anyOf(200, 201), reason: deck.body);
    final deckId = ((json(deck)['deck'] ?? json(deck)) as Map)['id'] as String;
    return (token: token, userId: userId, deckId: deckId);
  }

  Future<http.Response> latest(String token, {String? deckId}) => http.get(
    Uri.parse('$baseUrl/ai/optimize/jobs/latest').replace(
      queryParameters: {
        if (deckId != null) 'deck_id': deckId,
        'active': 'true',
      },
    ),
    headers: {'Authorization': 'Bearer $token'},
  );

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
    owner = await account();
    stranger = await account();
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  test(
    'sem job ativo: 200 com job nulo, para o deck e para a conta',
    () async {
      for (final deckId in [owner.deckId, null]) {
        final response = await latest(owner.token, deckId: deckId);
        expect(response.statusCode, 200, reason: response.body);
        expect(json(response), {'job': null});
      }
    },
    skip: skipReason,
  );

  test('com job ativo: 200 com o job, como antes', () async {
    final jobId = await OptimizeJobStore.create(
      pool: pool,
      deckId: owner.deckId,
      archetype: 'midrange',
      userId: owner.userId,
    );
    final response = await latest(owner.token, deckId: owner.deckId);
    expect(response.statusCode, 200, reason: response.body);
    expect(json(response)['job_id'], jobId);
    expect(json(response)['status'], anyOf('pending', 'processing'));

    // A outra conta continua sem job, e o job da primeira não aparece.
    final other = await latest(stranger.token);
    expect(other.statusCode, 200, reason: other.body);
    expect(json(other), {'job': null});
  }, skip: skipReason);

  test('deck de outra conta, inexistente ou que não é UUID: 404', () async {
    for (final deckId in [
      owner.deckId,
      '00000000-0000-4000-8000-00000000d0e5',
      'nao-e-um-uuid',
    ]) {
      final response = await latest(stranger.token, deckId: deckId);
      expect(response.statusCode, 404, reason: '$deckId ${response.body}');
      expect(json(response)['error_code'], 'deck_not_found');
      expect(json(response)['request_id'], isNotEmpty);
    }
  }, skip: skipReason);
}
