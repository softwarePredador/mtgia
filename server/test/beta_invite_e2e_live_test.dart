@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/legal_policy.dart';

/// BT-AUTH-006 de ponta a ponta, por HTTP contra uma API local em modo
/// `invite` (MANALOOM_REGISTRATION_ADMISSION=invite) com e-mail verificado
/// exigido (MANALOOM_REQUIRE_VERIFIED_EMAIL=true) e as capacidades de
/// cadastro e decks ligadas num manifesto isolado. Os convites são emitidos
/// pelo mesmo código do script do dono, no banco descartável da API.
///
/// Cobre convite válido (e o e-mail verificado liberando `POST /decks`,
/// D-56), sem convite, inválido, expirado, replay e concorrência.
///
/// Requer `RUN_BETA_INVITE_E2E_TESTS=1`, `TEST_API_BASE_URL` e as variáveis
/// `DB_*` do mesmo banco da API.
void main() {
  final enabled = Platform.environment['RUN_BETA_INVITE_E2E_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer API local em modo invite e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late BetaInviteIssuer issuer;
  final sent = <String, String>{};

  setUpAll(() {
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
    issuer = BetaInviteIssuer(
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
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<String> invite(String email) async {
    final outcomes = await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-e2e',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    expect(outcomes.single.status, 'novo');
    return sent[email]!;
  }

  Future<http.Response> register(
    String email, {
    String? code,
    String? username,
  }) => http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username ?? unique('e2e'),
      'email': email,
      'password': 'Convite!Beta-2026',
      'legal_accepted': true,
      'terms_version': currentTermsVersion,
      'privacy_version': currentPrivacyVersion,
      if (code != null) 'invite_code': code,
    }),
  );

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  test('convite válido: conta verificada escreve deck (D-56)', () async {
    final email = '${unique('valido')}@example.invalid';
    final code = await invite(email);

    final created = await register(email, code: code.toLowerCase());

    expect(created.statusCode, 201, reason: created.body);
    final body = json(created);
    expect(body['admission'], 'invite');
    expect((body['user'] as Map<String, dynamic>)['email_verified'], isTrue);
    final token = body['token'] as String;
    final me = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    expect(me.statusCode, 200, reason: me.body);
    expect(
      (json(me)['user'] as Map<String, dynamic>)['email_verified'],
      isTrue,
    );
    final deck = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': 'Deck do convite', 'format': 'commander'}),
    );
    expect(deck.statusCode, 200, reason: deck.body);
  }, skip: skipReason);

  test('sem convite: 403 invite_required, com request-id', () async {
    final response = await register('${unique('sem')}@example.invalid');

    expect(response.statusCode, 403, reason: response.body);
    expect(json(response)['error'], 'invite_required');
    expect(response.headers['x-request-id'], isNotEmpty);
  }, skip: skipReason);

  test('inválido: código que ninguém emitiu', () async {
    final response = await register(
      '${unique('invalido')}@example.invalid',
      code: newBetaInviteCode(),
    );

    expect(response.statusCode, 403, reason: response.body);
    expect(json(response)['error'], 'invite_invalid');
  }, skip: skipReason);

  test('expirado: 403 invite_expired e nenhuma conta', () async {
    final email = '${unique('expirado')}@example.invalid';
    final code = await invite(email);
    await pool.execute(
      Sql.named('''
        UPDATE beta_invites
        SET issued_at = issued_at - INTERVAL '30 days',
            expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
        WHERE email_digest = @d
      '''),
      parameters: {'d': betaInviteEmailDigest(email)},
    );

    final response = await register(email, code: code);

    expect(response.statusCode, 403, reason: response.body);
    expect(json(response)['error'], 'invite_expired');
    final accounts = await pool.execute(
      Sql.named('SELECT COUNT(*)::int FROM users WHERE email = @e'),
      parameters: {'e': email},
    );
    expect(accounts.single[0], 0);
  }, skip: skipReason);

  test('replay: o segundo cadastro com o mesmo convite é negado', () async {
    final email = '${unique('replay')}@example.invalid';
    final code = await invite(email);
    expect((await register(email, code: code)).statusCode, 201);

    final replay = await register(email, code: code);

    expect(replay.statusCode, 403, reason: replay.body);
    expect(json(replay)['error'], 'invite_already_used');
  }, skip: skipReason);

  test('concorrência: 10 cadastros ao mesmo tempo, uma conta só', () async {
    final email = '${unique('corrida')}@example.invalid';
    final code = await invite(email);

    final responses = await Future.wait([
      for (var i = 0; i < 10; i++)
        register(email, code: code, username: unique('corrida$i')),
    ]);

    expect(
      responses.where((response) => response.statusCode == 201),
      hasLength(1),
    );
    for (final response in responses.where((r) => r.statusCode != 201)) {
      expect(response.statusCode, 403, reason: response.body);
      expect(json(response)['error'], 'invite_already_used');
    }
    final accounts = await pool.execute(
      Sql.named('SELECT COUNT(*)::int FROM users WHERE email = @e'),
      parameters: {'e': email},
    );
    expect(accounts.single[0], 1);
  }, skip: skipReason);
}
