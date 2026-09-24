@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';
import '../lib/public_error_contract.dart';

/// BT-AUTH-001 de ponta a ponta, por HTTP contra uma API local (a mesma do
/// E2E do convite: modo `invite`, e-mail verificado exigido, cadastro e decks
/// ligados num manifesto isolado). Corpus de falhas: cada erro sai com código
/// estável, o request-id no header e no corpo (o mesmo que o cliente mandou)
/// e nenhum detalhe interno.
///
/// Requer `RUN_PUBLIC_ERROR_E2E_TESTS=1`, `TEST_API_BASE_URL` e as variáveis
/// `DB_*` do mesmo banco da API (a conta do teste entra por convite).
void main() {
  final enabled = Platform.environment['RUN_PUBLIC_ERROR_E2E_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer API local em modo invite e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late String token;
  var sequence = 0;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

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
    final email = '${unique('erros')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-erros',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('erros'),
        'email': email,
        'password': 'Convite!Beta-2026',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
        'invite_code': sent[email],
      }),
    );
    expect(created.statusCode, 201, reason: created.body);
    token =
        (jsonDecode(created.body) as Map<String, dynamic>)['token'] as String;
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.close();
  });

  /// Cada chamada leva um request-id próprio, que o erro tem de devolver.
  Map<String, String> headers({bool auth = false, bool json = true}) => {
    'x-request-id': 'e2e-erro-${++sequence}',
    if (json) 'Content-Type': 'application/json',
    if (auth) 'Authorization': 'Bearer $token',
  };

  /// O contrato de todo erro: status, código estável (em `error`, `code` ou
  /// `error_code`), request-id igual ao enviado no header e no corpo, e
  /// nenhum detalhe interno.
  Map<String, dynamic> expectTypedError(
    http.Response response,
    int status, {
    String? code,
  }) {
    expect(response.statusCode, status, reason: response.body);
    final requestId = response.request!.headers['x-request-id'];
    expect(response.headers['x-request-id'], requestId);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['request_id'], requestId, reason: response.body);
    final codes = [
      body['error'],
      body['code'],
      body['error_code'],
    ].where(isStablePublicErrorCode);
    expect(codes, isNotEmpty, reason: response.body);
    if (code != null) expect(codes, contains(code), reason: response.body);
    expect(containsInternalDetail(body), isFalse, reason: response.body);
    return body;
  }

  test('login com JSON quebrado: 400 com a frase e o código', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers(),
      body: '{"email": "a@example.invalid", "password": ',
    );
    final body = expectTypedError(response, 400, code: 'request_invalid');
    expect(body['message'], 'Dados inválidos.');
  }, skip: skipReason);

  test('login com senha errada: 401 com código, sem detalhe', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers(),
      body: jsonEncode({
        'email': '${unique('ninguem')}@example.invalid',
        'password': 'Senha-Errada-2026!',
      }),
    );
    expectTypedError(response, 401, code: 'auth_unauthorized');
  }, skip: skipReason);

  test('cadastro com corpo que não é objeto: 400 tipado', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(),
      body: jsonEncode(['nao', 'e', 'objeto']),
    );
    expectTypedError(response, 400);
  }, skip: skipReason);

  test('rota protegida sem token: 401 com código', () async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks'),
      headers: headers(),
    );
    expectTypedError(response, 401);
  }, skip: skipReason);

  test('carta em deck que não existe: 404 deck_not_found', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/decks/00000000-0000-4000-8000-000000000000/cards'),
      headers: headers(auth: true),
      body: jsonEncode({
        'card_id': '00000000-0000-4000-8000-000000000001',
        'quantity': 1,
      }),
    );
    final body = expectTypedError(response, 404, code: 'deck_not_found');
    expect(body['error'], 'Deck não encontrado.');
  }, skip: skipReason);

  test('deck que não existe na leitura: 404 com código', () async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks/00000000-0000-4000-8000-000000000000'),
      headers: headers(auth: true),
    );
    expectTypedError(response, 404);
  }, skip: skipReason);

  test('método não permitido: 405 method_not_allowed', () async {
    // A capability de decks cobre o caminho; o handler não tem PATCH.
    final response = await http.patch(
      Uri.parse('$baseUrl/decks'),
      headers: headers(auth: true),
      body: '{}',
    );
    expectTypedError(response, 405, code: 'method_not_allowed');
  }, skip: skipReason);

  test(
    'método fora do manifesto: 404 da capability, com request-id',
    () async {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
      );
      expectTypedError(response, 404, code: 'capability_route_unclassified');
    },
    skip: skipReason,
  );

  test('rota fora do manifesto: 404 com código', () async {
    final response = await http.get(
      Uri.parse('$baseUrl/rota-que-nao-existe'),
      headers: headers(),
    );
    expectTypedError(response, 404);
  }, skip: skipReason);

  test('origem que o CORS nega: 403 cors_origin_denied', () async {
    final response = await http.get(
      Uri.parse('$baseUrl/decks'),
      headers: {...headers(), 'Origin': 'https://evil.example'},
    );
    expectTypedError(response, 403, code: 'cors_origin_denied');
  }, skip: skipReason);
}
