@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai_generate_job.dart';
import '../lib/auth_service.dart';
import '../routes/ai/generate/jobs/[id].dart' as jobs_route;
import 'support/privacy_db_fixture.dart';

/// `GET /ai/generate/jobs/latest` em PostgreSQL descartável, chamando o
/// handler da rota. Como no Optimize (`BT-AI-031`), não ter job é resposta
/// normal (200 `{"job": null}`), e o navegador deixa de registrar erro no
/// console quando a tela de geração abre. O Generate não tem deck: a busca é
/// da conta. O 404 fica para o id concreto que não existe ou é de outra conta.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado (usa a fixture de três contas da privacidade, em que
/// a conta A tem um job de geração concluído).
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  late Pool pool;
  late PrivacyDbFixture fixture;

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = openPrivacyTestPool();
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  setUp(() async {
    if (!enabled) return;
    fixture = await PrivacyDbFixture.seed(
      pool,
      passwordHash: AuthService().hashPassword('Senha!Latest-2026'),
    );
  });

  Future<(int, Map<String, dynamic>)> call(
    String userId,
    String id, {
    String method = 'GET',
    bool? active,
  }) async {
    final uri = Uri.parse('http://localhost/ai/generate/jobs/$id').replace(
      queryParameters: {if (active != null) 'active': active ? 'true' : 'false'},
    );
    final response = await jobs_route.onRequest(
      _JobsRequestContext(Request(method, uri), pool, userId),
      id,
    );
    final text = await response.body();
    return (
      response.statusCode,
      text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>,
    );
  }

  Future<String> activeJob(String userId) => AiGenerateJobStore.create(
    pool: pool,
    cacheKey: 'latest-${DateTime.now().microsecondsSinceEpoch}',
    format: 'commander',
    userId: userId,
  );

  test('conta sem job ativo (a fixture tem um concluído): 200 com job '
      'nulo', () async {
    final (status, body) = await call(fixture.userA, 'latest', active: true);
    expect(status, 200, reason: '$body');
    expect(body, {'job': null});
  }, skip: skipReason);

  test('conta sem job nenhum: 200 com job nulo, com e sem active', () async {
    for (final active in const [true, false, null]) {
      final (status, body) = await call(fixture.userB, 'latest', active: active);
      expect(status, 200, reason: 'active=$active $body');
      expect(body, {'job': null}, reason: 'active=$active');
    }
  }, skip: skipReason);

  test('job ativo: 200 com o job na raiz, como antes', () async {
    final jobId = await activeJob(fixture.userA);
    final (status, body) = await call(fixture.userA, 'latest', active: true);
    expect(status, 200, reason: '$body');
    expect(body['job_id'], jobId);
    expect(body['status'], 'pending');
    expect(body['format'], 'commander');
    expect(body.containsKey('job'), isFalse);
  }, skip: skipReason);

  test('job que terminou: some com active=true e aparece sem ele', () async {
    final jobId = await activeJob(fixture.userB);
    expect(
      await AiGenerateJobStore.complete(
        pool,
        jobId,
        statusCode: 200,
        result: const {'ok': true},
      ),
      isTrue,
    );

    final (activeStatus, activeBody) = await call(
      fixture.userB,
      'latest',
      active: true,
    );
    expect(activeStatus, 200);
    expect(activeBody, {'job': null});

    final (anyStatus, anyBody) = await call(fixture.userB, 'latest');
    expect(anyStatus, 200);
    expect(anyBody['job_id'], jobId);
    expect(anyBody['status'], 'completed');
  }, skip: skipReason);

  test('o job de outra conta nunca aparece no latest', () async {
    await activeJob(fixture.userB);
    final (status, body) = await call(fixture.userC, 'latest', active: true);
    expect(status, 200, reason: '$body');
    expect(body, {'job': null});
  }, skip: skipReason);

  test('id concreto de outra conta, inexistente ou estranho: 404, não 500', () async {
    final otherJob = await activeJob(fixture.userB);
    for (final id in [
      otherJob,
      'job-que-nao-existe',
      "' OR 1=1 --",
      '00000000-0000-4000-8000-00000000d0e5',
    ]) {
      final (status, body) = await call(fixture.userA, id);
      expect(status, 404, reason: id);
      expect(body.containsKey('job'), isFalse, reason: id);
      expect(body['job_id'], id, reason: id);
    }
    // O dono continua vendo o próprio job pelo id.
    final (status, body) = await call(fixture.userB, otherJob);
    expect(status, 200);
    expect(body['job_id'], otherJob);
  }, skip: skipReason);

  test('DELETE em latest continua 405', () async {
    final (status, _) = await call(fixture.userA, 'latest', method: 'DELETE');
    expect(status, 405);
  }, skip: skipReason);
}

class _JobsRequestContext implements RequestContext {
  _JobsRequestContext(this.request, this.pool, this.userId);

  @override
  final Request request;
  final Pool pool;
  final String userId;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return userId as T;
    throw StateError('Sem provedor de $T no teste da rota de jobs');
  }
}
