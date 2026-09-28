@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai_generate_job.dart';
import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/legal_policy.dart';

/// `GET /ai/generate/jobs/latest` de ponta a ponta, por HTTP contra a API
/// local com `account_registration` e `ai_generate_rebuild` ligadas no
/// manifesto isolado. Sem job ativo, a tela de geração recebe 200 com
/// `{"job": null}`, e o navegador não registra erro no console. O 404 fica para
/// o id concreto que não existe ou é de outra conta.
///
/// Requer `RUN_GENERATE_JOB_LATEST_E2E_TESTS=1`, `TEST_API_BASE_URL` e as
/// variáveis `DB_*` do mesmo banco da API.
void main() {
  final enabled =
      Platform.environment['RUN_GENERATE_JOB_LATEST_E2E_TESTS'] == '1';
  final skipReason = enabled ? null : 'Requer API local e banco descartável.';
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  late Pool pool;
  late ({String token, String userId}) owner;
  late ({String token, String userId}) stranger;

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Map<String, dynamic> json(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<({String token, String userId})> account() async {
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
    final email = '${unique('genlatest')}@example.invalid';
    await issuer.issue(
      await issuer.plan([email]),
      batchLabel: 'teste-generate-latest',
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    final created = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': unique('genlatest'),
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
    return (
      token: body['token'] as String,
      userId: (body['user'] as Map<String, dynamic>)['id'] as String,
    );
  }

  Future<http.Response> get(String token, String id, {bool? active}) =>
      http.get(
        Uri.parse('$baseUrl/ai/generate/jobs/$id').replace(
          queryParameters: {
            if (active != null) 'active': active ? 'true' : 'false',
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

  test('sem job: 200 com job nulo, com e sem active', () async {
    for (final active in const [true, null]) {
      final response = await get(owner.token, 'latest', active: active);
      expect(response.statusCode, 200, reason: response.body);
      expect(json(response), {'job': null});
    }
  }, skip: skipReason);

  test('com job ativo: 200 com o job, e a outra conta segue com job nulo', () async {
    final jobId = await AiGenerateJobStore.create(
      pool: pool,
      cacheKey: unique('cache'),
      format: 'commander',
      userId: owner.userId,
    );
    final response = await get(owner.token, 'latest', active: true);
    expect(response.statusCode, 200, reason: response.body);
    expect(json(response)['job_id'], jobId);
    expect(json(response)['status'], anyOf('pending', 'processing'));

    final other = await get(stranger.token, 'latest', active: true);
    expect(other.statusCode, 200, reason: other.body);
    expect(json(other), {'job': null});

    // O id concreto de outra conta segue 404, com request_id.
    final foreign = await get(stranger.token, jobId);
    expect(foreign.statusCode, 404, reason: foreign.body);
    expect(json(foreign)['request_id'], isNotEmpty);
  }, skip: skipReason);

  test('id que não existe: 404, não 500', () async {
    for (final id in const ['job-que-nao-existe', 'nao%20e%20um%20id']) {
      final response = await get(owner.token, id);
      expect(response.statusCode, 404, reason: '$id ${response.body}');
      expect(json(response).containsKey('job'), isFalse);
    }
  }, skip: skipReason);
}
