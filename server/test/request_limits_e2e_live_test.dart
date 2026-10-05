@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// BT-AUTH-002 de ponta a ponta, por HTTP contra a API local (a mesma do E2E
/// do convite). Corpo declarado acima do limite, em partes ou comprimido é
/// recusado sem ser lido; campo, profundidade e URL acima do teto também; e
/// o banco não cresce. O corpo em partes vai pelo cliente HTTP sem
/// Content-Length (Transfer-Encoding: chunked).
///
/// Requer `RUN_REQUEST_LIMITS_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled = Platform.environment['RUN_REQUEST_LIMITS_E2E_TESTS'] == '1';
  final skipReason = enabled ? null : 'Requer API local e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late String token;

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
    final email = '${unique('limites')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-limites',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('limites'),
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

  Future<int> deckCount() async =>
      (await pool.execute('SELECT COUNT(*)::int FROM decks')).single[0]! as int;

  Map<String, String> headers(String requestId) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'x-request-id': requestId,
  };

  test('corpo de 2 MiB: 413 com o limite, banco igual', () async {
    final before = await deckCount();
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: headers('e2e-limite-1'),
      body: jsonEncode({
        'name': 'x' * (2 * 1024 * 1024),
        'format': 'commander',
      }),
    );
    expect(response.statusCode, 413, reason: response.body);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['error'], 'request_body_too_large');
    expect(body['limit'], 1024 * 1024);
    expect(body['request_id'], 'e2e-limite-1');
    expect(response.headers['x-request-id'], 'e2e-limite-1');
    expect(await deckCount(), before);
  }, skip: skipReason);

  test('corpo em partes (sem Content-Length): 411, banco igual', () async {
    // O cliente manda Transfer-Encoding: chunked; o shelf_io tira esse
    // cabeçalho, e a guarda de entrada falha no primeiro pedaço.
    final before = await deckCount();
    final request = http.StreamedRequest('POST', Uri.parse('$baseUrl/decks'))
      ..headers.addAll(headers('e2e-limite-partes'));
    request.sink.add(utf8.encode('{"name": "Partes", '));
    request.sink.add(utf8.encode('"format": "commander"}'));
    unawaited(request.sink.close());
    final response = await http.Response.fromStream(await request.send());
    expect(response.statusCode, 411, reason: response.body);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['error'], 'request_body_length_required');
    expect(body['request_id'], 'e2e-limite-partes');
    expect(await deckCount(), before);
  }, skip: skipReason);

  test('corpo comprimido: 415, nada é descomprimido', () async {
    final before = await deckCount();
    final response = await http.post(
      Uri.parse('$baseUrl/decks'),
      headers: {...headers('e2e-limite-gzip'), 'Content-Encoding': 'gzip'},
      body: gzip.encode(
        utf8.encode(jsonEncode({'name': 'Deck', 'format': 'commander'})),
      ),
    );
    expect(response.statusCode, 415, reason: response.body);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['error'], 'request_body_encoding_unsupported');
    expect(await deckCount(), before);
  }, skip: skipReason);

  test(
    'campo e profundidade acima do teto: 413; o mesmo deck curto passa',
    () async {
      final before = await deckCount();
      Future<http.Response> create(Object payload) => http.post(
        Uri.parse('$baseUrl/decks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final longName = await create({
        'name': 'x' * (40 * 1024),
        'format': 'commander',
      });
      expect(longName.statusCode, 413, reason: longName.body);
      expect(
        (jsonDecode(longName.body) as Map)['error'],
        'request_field_too_large',
      );

      Object nested = 'folha';
      for (var i = 0; i < 40; i++) {
        nested = [nested];
      }
      final deep = await create({
        'name': 'Profundo',
        'format': 'commander',
        'extra': nested,
      });
      expect(deep.statusCode, 413, reason: deep.body);
      expect((jsonDecode(deep.body) as Map)['error'], 'request_json_too_deep');
      expect(await deckCount(), before);

      final ok = await create({'name': unique('curto'), 'format': 'commander'});
      expect(ok.statusCode, anyOf(200, 201), reason: ok.body);
      expect(await deckCount(), before + 1);
    },
    skip: skipReason,
  );

  test('URL acima de 8 KB: 414 com código', () async {
    final response = await http.get(
      Uri.parse('$baseUrl/cards?q=${'a' * 9000}'),
      headers: const {'x-request-id': 'e2e-limite-url'},
    );
    expect(response.statusCode, 414);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['error'], 'request_uri_too_long');
    expect(body['request_id'], 'e2e-limite-url');
  }, skip: skipReason);
}
