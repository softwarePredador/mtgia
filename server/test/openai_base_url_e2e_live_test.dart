@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// D-83 (item 3 do `BT-AI-029`) de ponta a ponta, por HTTP contra a API local
/// com `account_registration` e `ai_analyze_optimize_advisory` ligadas, uma
/// chave falsa e a API sob a guarda de egress (só loopback).
///
/// O teste sobe um provedor falso em `127.0.0.1:$FAKE_OPENAI_PORT` e chama
/// `POST /ai/explain`, que fala com o provedor.
///
/// - `OPENAI_BASE_URL_E2E_MODE=loopback`: a API subiu com `OPENAI_BASE_URL`
///   apontando para o falso. A explicação vem dele, e ele recebe a chamada em
///   `/v1/chat/completions` com a chave falsa.
/// - `OPENAI_BASE_URL_E2E_MODE=ignored`: a API subiu com `OPENAI_BASE_URL` fora
///   do loopback. A base é ignorada, a chamada vai para a URL fixa, a guarda
///   recusa a saída, e o falso não recebe nada.
///
/// Requer `RUN_OPENAI_BASE_URL_E2E_TESTS=1`, o modo, `TEST_API_BASE_URL`,
/// `FAKE_OPENAI_PORT`, `FAKE_OPENAI_KEY` e as variáveis `DB_*` do banco da API.
void main() {
  final enabled = Platform.environment['RUN_OPENAI_BASE_URL_E2E_TESTS'] == '1';
  final mode = Platform.environment['OPENAI_BASE_URL_E2E_MODE'] ?? '';
  final skipReason =
      enabled && (mode == 'loopback' || mode == 'ignored')
          ? null
          : 'Requer API local, banco descartável e o modo do teste.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final fakePort =
      int.tryParse(Platform.environment['FAKE_OPENAI_PORT'] ?? '') ?? 58193;
  final fakeKey = Platform.environment['FAKE_OPENAI_KEY'] ?? '';
  late Pool pool;
  late String token;
  late HttpServer fake;
  final received = <({String path, String? authorization, Map body})>[];

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  setUpAll(() async {
    if (skipReason != null) return;
    fake = await HttpServer.bind(InternetAddress.loopbackIPv4, fakePort);
    fake.listen((request) async {
      final body = await utf8.decodeStream(request);
      received.add((
        path: request.uri.path,
        authorization: request.headers.value('authorization'),
        body: jsonDecode(body) as Map,
      ));
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'id': 'chatcmpl-falso',
            'object': 'chat.completion',
            'model': 'modelo-falso',
            'choices': [
              {
                'index': 0,
                'finish_reason': 'stop',
                'message': {
                  'role': 'assistant',
                  'content': 'Explicação do provedor falso local.',
                },
              },
            ],
            'usage': {
              'prompt_tokens': 10,
              'completion_tokens': 5,
              'total_tokens': 15,
            },
          }),
        );
      await request.response.close();
    });

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
    final email = '${unique('baseurl')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-openai-base-url',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('baseurl'),
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
  });

  tearDownAll(() async {
    if (skipReason != null) return;
    await fake.close(force: true);
    await pool.close();
  });

  Future<http.Response> explain() => http.post(
    Uri.parse('$baseUrl/ai/explain'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'card_name': 'Sol Ring',
      'type_line': 'Artifact',
      'oracle_text': '{T}: Add {C}{C}.',
    }),
  );

  test('loopback: a chamada vai para o provedor falso local', () async {
    final response = await explain();
    expect(response.statusCode, 200, reason: response.body);
    expect(json(response)['explanation'], 'Explicação do provedor falso local.');
    expect(json(response)['is_mock'], isFalse);

    expect(received, hasLength(1));
    expect(received.single.path, '/v1/chat/completions');
    expect(received.single.authorization, 'Bearer $fakeKey');
    expect(received.single.body['model'], isA<String>());
    expect(received.single.body['messages'], isA<List>());
  }, skip: mode == 'loopback' ? skipReason : 'Só no modo loopback.');

  test('fora do loopback: a base é ignorada e o falso não recebe nada', () async {
    final response = await explain();
    // A URL fixa não sai da máquina sob a guarda de egress: sem provedor, a
    // rota responde indisponível, e nada chega ao falso local.
    expect(response.statusCode, anyOf(502, 503, 504), reason: response.body);
    expect(json(response).containsKey('explanation'), isFalse);
    expect(received, isEmpty);
  }, skip: mode == 'ignored' ? skipReason : 'Só no modo ignored.');
}
