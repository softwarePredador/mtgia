@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_job.dart';
import '../lib/auth_service.dart';
import '../routes/ai/optimize/jobs/[id].dart' as jobs_route;
import 'support/privacy_db_fixture.dart';

/// `GET /ai/optimize/jobs/latest` em PostgreSQL descartável, chamando o handler
/// da rota. Não ter job é resposta normal (200 `{"job": null}`), e o navegador
/// deixa de registrar erro no console quando a folha de otimização abre. O 404
/// fica para o `deck_id` que não é da conta, não existe ou nem é UUID.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado (usa a fixture de três contas da privacidade).
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
    OptimizeJobStore.reset();
    fixture = await PrivacyDbFixture.seed(
      pool,
      passwordHash: AuthService().hashPassword('Senha!Latest-2026'),
    );
  });

  Future<(int, Map<String, dynamic>)> latest(
    String userId, {
    String method = 'GET',
    String? deckId,
    bool active = true,
  }) async {
    final uri = Uri.parse('http://localhost/ai/optimize/jobs/latest').replace(
      queryParameters: {
        if (deckId != null) 'deck_id': deckId,
        'active': active ? 'true' : 'false',
      },
    );
    final response = await jobs_route.onRequest(
      _JobsRequestContext(Request(method, uri), pool, userId),
      'latest',
    );
    final text = await response.body();
    return (
      response.statusCode,
      text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>,
    );
  }

  Future<String> activeJob(String userId, String deckId) =>
      OptimizeJobStore.create(
        pool: pool,
        deckId: deckId,
        archetype: 'midrange',
        userId: userId,
      );

  test('deck da conta sem job ativo (a fixture tem um concluído): 200 com '
      'job nulo', () async {
    final (status, body) = await latest(fixture.userA, deckId: fixture.deckA1);
    expect(status, 200, reason: '$body');
    expect(body, {'job': null});
  }, skip: skipReason);

  test('deck da conta com job ativo: 200 com o job, como antes', () async {
    final jobId = await activeJob(fixture.userA, fixture.deckA1);
    final (status, body) = await latest(fixture.userA, deckId: fixture.deckA1);
    expect(status, 200, reason: '$body');
    expect(body['job_id'], jobId);
    expect(body['deck_id'], fixture.deckA1);
    expect(body['archetype'], 'midrange');
    expect(body.containsKey('job'), isFalse);
  }, skip: skipReason);

  test('job que terminou: some com active=true e aparece sem ele', () async {
    final jobId = await activeJob(fixture.userA, fixture.deckA1);
    await OptimizeJobStore.complete(pool, jobId, result: const {'ok': true});

    final (activeStatus, activeBody) = await latest(
      fixture.userA,
      deckId: fixture.deckA1,
    );
    expect(activeStatus, 200);
    expect(activeBody, {'job': null});

    final (anyStatus, anyBody) = await latest(
      fixture.userA,
      deckId: fixture.deckA1,
      active: false,
    );
    expect(anyStatus, 200);
    expect(anyBody['job_id'], jobId);
  }, skip: skipReason);

  test('deck de outra conta: 404, mesmo com job ativo nele', () async {
    await activeJob(fixture.userB, fixture.deckB1Public);
    final (status, body) = await latest(
      fixture.userA,
      deckId: fixture.deckB1Public,
    );
    expect(status, 404);
    expect(body['error_code'], 'deck_not_found');
    expect(body.containsKey('job_id'), isFalse);
  }, skip: skipReason);

  test('deck que não existe ou id que não é UUID: 404, não 500', () async {
    for (final deckId in const [
      '00000000-0000-4000-8000-00000000d0e5',
      'nao-e-um-uuid',
      "' OR 1=1 --",
    ]) {
      final (status, body) = await latest(fixture.userA, deckId: deckId);
      expect(status, 404, reason: deckId);
      expect(body['error_code'], 'deck_not_found', reason: deckId);
    }
  }, skip: skipReason);

  test('sem deck_id: o job mais recente da conta, ou job nulo', () async {
    var (status, body) = await latest(fixture.userA);
    expect(status, 200);
    expect(body, {'job': null});

    final jobId = await activeJob(fixture.userA, fixture.deckA1);
    (status, body) = await latest(fixture.userA);
    expect(status, 200);
    expect(body['job_id'], jobId);
    // O job de outra conta nunca aparece.
    (status, body) = await latest(fixture.userB);
    expect(status, 200);
    expect(body, {'job': null});
  }, skip: skipReason);

  test('DELETE em latest continua 405', () async {
    final (status, _) = await latest(fixture.userA, method: 'DELETE');
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
