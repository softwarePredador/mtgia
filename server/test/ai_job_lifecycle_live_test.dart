@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:server/ai/optimize_job.dart';
import 'package:server/ai_generate_job.dart';
import 'package:server/ai_job_lifecycle.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovação explícita.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  final userIds = <String>[];

  Map<String, dynamic> decode(http.Response response) =>
      (jsonDecode(response.body) as Map).cast<String, dynamic>();

  Future<Map<String, dynamic>> register(String label) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 's4-04-$label-$suffix@example.com',
        'password': 'BetaQa!2026-Jobs',
        'username': 's4_04_${label}_$suffix',
      }),
    );
    expect(response.statusCode, anyOf(200, 201), reason: response.body);
    final body = decode(response);
    userIds.add((body['user'] as Map<String, dynamic>)['id'] as String);
    return body;
  }

  Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  setUpAll(() async {
    if (skipIntegration != null) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  });

  tearDownAll(() async {
    if (skipIntegration != null) return;
    for (final userId in userIds) {
      await pool.execute(
        Sql.named(
          'DELETE FROM ai_optimize_jobs WHERE user_id = CAST(@user_id AS uuid)',
        ),
        parameters: {'user_id': userId},
      );
      await pool.execute(
        Sql.named(
          'DELETE FROM ai_generate_jobs WHERE user_id = CAST(@user_id AS uuid)',
        ),
        parameters: {'user_id': userId},
      );
      await pool.execute(
        Sql.named('DELETE FROM decks WHERE user_id = CAST(@user_id AS uuid)'),
        parameters: {'user_id': userId},
      );
      await pool.execute(
        Sql.named('DELETE FROM users WHERE id = CAST(@user_id AS uuid)'),
        parameters: {'user_id': userId},
      );
    }
    await pool.close();
    OptimizeJobStore.reset();
  });

  test(
    'idempotency, ownership, cancellation, timeout and late-worker guards',
    () async {
      final owner = await register('owner');
      final stranger = await register('stranger');
      final ownerId = (owner['user'] as Map<String, dynamic>)['id'] as String;
      final ownerToken = owner['token'] as String;
      final strangerToken = stranger['token'] as String;

      final deckRows = await pool.execute(
        Sql.named('''
          INSERT INTO decks (user_id, name, format)
          VALUES (
            CAST(@user_id AS uuid),
            'S4-04 lifecycle fixture',
            'commander'
          )
          RETURNING id::text AS id
        '''),
        parameters: {'user_id': ownerId},
      );
      final deckId = deckRows.first.toColumnMap()['id'] as String;

      final generate = await AiGenerateJobStore.createOrReuse(
        pool: pool,
        cacheKey: 'generate-fingerprint-$suffix',
        format: 'commander',
        userId: ownerId,
        requestKey: 'generate:live-$suffix',
        requestFingerprint: 'generate-fingerprint-$suffix',
      );
      final reusedGenerate = await AiGenerateJobStore.createOrReuse(
        pool: pool,
        cacheKey: 'generate-fingerprint-$suffix',
        format: 'commander',
        userId: ownerId,
        requestKey: 'generate:live-$suffix',
        requestFingerprint: 'generate-fingerprint-$suffix',
      );
      expect(generate.isNew, isTrue);
      expect(reusedGenerate.isNew, isFalse);
      expect(reusedGenerate.jobId, generate.jobId);
      await expectLater(
        () => AiGenerateJobStore.createOrReuse(
          pool: pool,
          cacheKey: 'different-generate-fingerprint',
          format: 'commander',
          userId: ownerId,
          requestKey: 'generate:live-$suffix',
          requestFingerprint: 'different-generate-fingerprint',
        ),
        throwsA(isA<AiJobIdempotencyConflict>()),
      );

      var response = await http.get(
        Uri.parse('$baseUrl/ai/generate/jobs/latest?active=true'),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(decode(response)['job_id'], generate.jobId);

      response = await http.get(
        Uri.parse('$baseUrl/ai/generate/jobs/${generate.jobId}'),
        headers: headers(strangerToken),
      );
      expect(response.statusCode, 404, reason: response.body);
      expect(await AiGenerateJobStore.heartbeat(pool, generate.jobId), isTrue);
      response = await http.delete(
        Uri.parse('$baseUrl/ai/generate/jobs/${generate.jobId}'),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(decode(response)['status'], 'cancelled');
      expect(await AiGenerateJobStore.heartbeat(pool, generate.jobId), isFalse);
      expect(
        await AiGenerateJobStore.progress(
          pool,
          generate.jobId,
          stage: 'late worker',
          stageNumber: 3,
        ),
        isFalse,
      );
      expect(
        await AiGenerateJobStore.complete(
          pool,
          generate.jobId,
          statusCode: 200,
          result: const {'late': true},
        ),
        isFalse,
      );
      expect(
        await AiGenerateJobStore.fail(
          pool,
          generate.jobId,
          error: 'late failure',
        ),
        isFalse,
      );
      expect(
        (await AiGenerateJobStore.get(pool, generate.jobId))?.status,
        'cancelled',
      );

      final optimize = await OptimizeJobStore.createOrReuse(
        pool: pool,
        deckId: deckId,
        archetype: 'control',
        userId: ownerId,
        requestKey: 'optimize:live-$suffix',
        requestFingerprint: 'optimize-fingerprint-$suffix',
      );
      final reusedOptimize = await OptimizeJobStore.createOrReuse(
        pool: pool,
        deckId: deckId,
        archetype: 'control',
        userId: ownerId,
        requestKey: 'optimize:live-$suffix',
        requestFingerprint: 'optimize-fingerprint-$suffix',
      );
      expect(reusedOptimize.isNew, isFalse);
      expect(reusedOptimize.jobId, optimize.jobId);
      await expectLater(
        () => OptimizeJobStore.createOrReuse(
          pool: pool,
          deckId: deckId,
          archetype: 'aggro',
          userId: ownerId,
          requestKey: 'optimize:live-$suffix',
          requestFingerprint: 'different-optimize-fingerprint',
        ),
        throwsA(isA<AiJobIdempotencyConflict>()),
      );

      response = await http.get(
        Uri.parse(
          '$baseUrl/ai/optimize/jobs/latest?active=true&deck_id=$deckId',
        ),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(decode(response)['job_id'], optimize.jobId);
      response = await http.delete(
        Uri.parse('$baseUrl/ai/optimize/jobs/${optimize.jobId}'),
        headers: headers(strangerToken),
      );
      expect(response.statusCode, 404, reason: response.body);
      expect(await OptimizeJobStore.heartbeat(pool, optimize.jobId), isTrue);
      response = await http.delete(
        Uri.parse('$baseUrl/ai/optimize/jobs/${optimize.jobId}'),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(decode(response)['can_resume'], isFalse);
      expect(await OptimizeJobStore.heartbeat(pool, optimize.jobId), isFalse);
      expect(
        await OptimizeJobStore.progress(
          pool,
          optimize.jobId,
          stage: 'late worker',
          stageNumber: 5,
        ),
        isFalse,
      );
      expect(
        await OptimizeJobStore.complete(
          pool,
          optimize.jobId,
          result: const {'late': true},
        ),
        isFalse,
      );
      expect(
        await OptimizeJobStore.fail(
          pool,
          optimize.jobId,
          error: 'late failure',
        ),
        isFalse,
      );

      final staleGenerateId = await AiGenerateJobStore.create(
        pool: pool,
        cacheKey: 'stale-$suffix',
        format: 'commander',
        userId: ownerId,
      );
      await pool.execute(
        Sql.named('''
          UPDATE ai_generate_jobs
          SET created_at = NOW() - INTERVAL '5 minutes',
              updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': staleGenerateId},
      );
      expect(
        (await AiGenerateJobStore.get(pool, staleGenerateId))?.status,
        'failed',
      );
      expect(
        await AiGenerateJobStore.complete(
          pool,
          staleGenerateId,
          statusCode: 200,
          result: const {'late': true},
        ),
        isFalse,
      );

      response = await http.delete(
        Uri.parse('$baseUrl/ai/generate/jobs/latest'),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 405, reason: response.body);
      response = await http.delete(
        Uri.parse('$baseUrl/ai/optimize/jobs/latest'),
        headers: headers(ownerToken),
      );
      expect(response.statusCode, 405, reason: response.body);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
