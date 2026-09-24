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
/// o banco não cresce. Os pedidos com cabeçalho mentiroso vão por socket
/// cru, porque o cliente HTTP calcula o Content-Length sozinho.
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

  /// Pedido por socket cru: manda só o que o teste escreve e lê até a API
  /// fechar a conexão (ou até o corpo declarado da resposta chegar).
  Future<(int, Map<String, String>, Map<String, dynamic>)> raw(
    String head, {
    List<int> body = const [],
  }) async {
    final uri = Uri.parse(baseUrl);
    final socket = await Socket.connect(uri.host, uri.port);
    socket.add(utf8.encode(head));
    if (body.isNotEmpty) socket.add(body);
    await socket.flush();
    final received = <int>[];
    final done = Completer<void>();
    final subscription = socket.listen(
      received.addAll,
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object _) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    await subscription.cancel();
    socket.destroy();
    final text = utf8.decode(received, allowMalformed: true);
    final split = text.indexOf('\r\n\r\n');
    final lines = text.substring(0, split).split('\r\n');
    final status = int.parse(lines.first.split(' ')[1]);
    final headers = {
      for (final line in lines.skip(1))
        line.substring(0, line.indexOf(':')).toLowerCase():
            line.substring(line.indexOf(':') + 1).trim(),
    };
    final decoded =
        jsonDecode(text.substring(split + 4)) as Map<String, dynamic>;
    return (status, headers, decoded);
  }

  String postHead(String path, Map<String, String> extra) {
    final host = Uri.parse(baseUrl).authority;
    return [
      'POST $path HTTP/1.1',
      'Host: $host',
      'Content-Type: application/json',
      'Authorization: Bearer $token',
      for (final entry in extra.entries) '${entry.key}: ${entry.value}',
      '',
      '',
    ].join('\r\n');
  }

  test('corpo declarado acima de 1 MB: 413 sem ler, banco igual', () async {
    final before = await deckCount();
    final (status, headers, body) = await raw(
      postHead('/decks', {
        'Content-Length': '${2 * 1024 * 1024}',
        'x-request-id': 'e2e-limite-1',
      }),
      body: utf8.encode('{"name": "'),
    );
    expect(status, 413);
    expect(body['error'], 'request_body_too_large');
    expect(body['limit'], 1024 * 1024);
    expect(body['request_id'], 'e2e-limite-1');
    expect(headers['x-request-id'], 'e2e-limite-1');
    expect(await deckCount(), before);
  }, skip: skipReason);

  test('corpo em partes: 411; comprimido: 415; banco igual', () async {
    final before = await deckCount();
    final (chunked, _, chunkedBody) = await raw(
      postHead('/decks', {'Transfer-Encoding': 'chunked'}),
      body: utf8.encode('2\r\n{}\r\n0\r\n\r\n'),
    );
    expect(chunked, 411);
    expect(chunkedBody['error'], 'request_body_length_required');

    final gzipped = gzip.encode(utf8.encode(jsonEncode({'name': 'Deck'})));
    final (compressed, _, compressedBody) = await raw(
      postHead('/decks', {
        'Content-Encoding': 'gzip',
        'Content-Length': '${gzipped.length}',
      }),
      body: gzipped,
    );
    expect(compressed, 415);
    expect(compressedBody['error'], 'request_body_encoding_unsupported');
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
