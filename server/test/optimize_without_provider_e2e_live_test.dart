@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';
import 'support/optimize_no_provider_fixture.dart';

/// D-82 de ponta a ponta, por HTTP contra a API local sem `OPENAI_API_KEY`
/// e com as capabilities `account_registration`, `decks_private` e
/// `ai_analyze_optimize_advisory` ligadas no manifesto isolado. A conta
/// entra por convite; o teste semeia os dois decks da fixture no banco da
/// API e pede `POST /ai/optimize` como o app pede.
///
/// Requer `RUN_OPTIMIZE_NO_PROVIDER_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled =
      Platform.environment['RUN_OPTIMIZE_NO_PROVIDER_E2E_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer API local sem provedor e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late String token;
  late String deckWithShortlist;
  late String deckWithoutShortlist;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<http.Response> optimize(String deckId) => http.post(
    Uri.parse('$baseUrl/ai/optimize'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'deck_id': deckId,
      'archetype': 'midrange',
      'bracket': 2,
      'keep_theme': true,
    }),
  );

  Future<int> deckCardRows(String deckId) async {
    final rows = await pool.execute(
      Sql.named(
        'SELECT COALESCE(SUM(quantity), 0)::int FROM deck_cards '
        'WHERE deck_id = CAST(@deckId AS uuid)',
      ),
      parameters: {'deckId': deckId},
    );
    return rows.single[0]! as int;
  }

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
    final email = '${unique('d82')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-d82',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('d82'),
        'email': email,
        'password': 'Convite!Beta-2026',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
        'invite_code': sent[email],
      }),
    );
    expect(created.statusCode, 201, reason: created.body);
    final body = jsonDecode(created.body) as Map<String, dynamic>;
    token = body['token'] as String;
    final userId = (body['user'] as Map<String, dynamic>)['id'] as String;

    await seedOptimizeNoProviderCatalog(pool);
    deckWithShortlist = await insertOptimizeNoProviderDeck(
      pool,
      userId,
      blue: true,
    );
    deckWithoutShortlist = await insertOptimizeNoProviderDeck(
      pool,
      userId,
      blue: false,
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  test(
    'com shortlist: 200 com as trocas determinísticas, só na prévia',
    () async {
      final response = await optimize(deckWithShortlist);
      expect(response.statusCode, 200, reason: response.body);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      expect(body['outcome_code'], 'optimized');
      expect(body['strategy_source'], 'deterministic_first');
      expect(body['is_mock'], isNot(true));
      expect(body['ai_provider'], {'configured': false, 'attempted': false});
      final additions = (body['additions'] as List).cast<String>();
      expect(additions, isNotEmpty);
      expect(body['removals'], hasLength(additions.length));
      expect(body['swap_integrity'], isA<Map>());
      expect(body['apply_authorization'], isA<Map>());
      // A prévia não grava: o deck continua com as 100 cartas de antes.
      expect(await deckCardRows(deckWithShortlist), 100);
    },
    skip: skipReason,
  );

  test('sem shortlist: continua o mock não acionável', () async {
    final response = await optimize(deckWithoutShortlist);
    expect(response.statusCode, 200, reason: response.body);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    expect(body['outcome_code'], 'mock_non_actionable');
    expect(body['is_mock'], isTrue);
    expect(body['can_apply'], isFalse);
    expect(body['ai_provider'], {'configured': false, 'attempted': false});
  }, skip: skipReason);
}
