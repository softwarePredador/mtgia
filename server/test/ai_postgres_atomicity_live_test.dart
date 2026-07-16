@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/optimize_job.dart';
import 'package:server/ai_generate_job.dart';
import 'package:server/ai_plan_reservation_handle.dart';
import 'package:server/ai_plan_reservation_settlement.dart';
import 'package:server/database.dart';
import 'package:server/distributed_rate_limiter.dart';
import 'package:server/plan_service.dart';
import 'package:test/test.dart';

const _approvalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';

void main() {
  final approved =
      Platform.environment['MANALOOM_CONFIRM_POSTGRES_WRITES'] ==
      _approvalPhrase;

  test(
    'quota reservation is atomic and optimize jobs survive memory reset',
    () async {
      Database.resetForTesting();
      final database = Database();
      await database.connect();
      expect(database.isConnected, isTrue, reason: 'PostgreSQL must be ready');
      final pool = database.connection;

      // A prior interrupted run must not contaminate the live database or the
      // quota assertions of the next validation.
      await _cleanupKnownAtomicityFixtures(pool);

      String? userId;
      try {
        final suffix = DateTime.now().microsecondsSinceEpoch;
        final user = await pool.execute(
          Sql.named('''
            INSERT INTO users (username, email, password_hash)
            VALUES (@username, @email, 'live-test-not-a-login-secret')
            RETURNING id::text AS id
          '''),
          parameters: {
            'username': 'ai_atomicity_$suffix',
            'email': 'ai-atomicity-$suffix@example.invalid',
          },
        );
        userId = user.first.toColumnMap()['id'] as String;

        await pool.execute(
          Sql.named('''
            INSERT INTO ai_logs (
              user_id, endpoint, model, latency_ms, success
            )
            SELECT
              CAST(@userId AS uuid),
              'plan:post:/ai/generate',
              'application_action',
              1,
              TRUE
            FROM generate_series(1, 119)
          '''),
          parameters: {'userId': userId},
        );

        await pool.execute(
          Sql.named('''
            INSERT INTO ai_logs (
              user_id,
              endpoint,
              model,
              input_tokens,
              output_tokens,
              latency_ms,
              success,
              created_at
            )
            VALUES
              (
                CAST(@userId AS uuid),
                'plan-reservation:post:/ai/generate',
                'application_action',
                0,
                0,
                0,
                FALSE,
                NOW() - INTERVAL '11 minutes'
              ),
              (
                CAST(@userId AS uuid),
                'optimize',
                'gpt-4o-mini',
                1000,
                1000,
                25,
                TRUE,
                NOW()
              )
          '''),
          parameters: {'userId': userId},
        );

        final planService = PlanService(pool);
        final initialSnapshot = await planService.getSnapshot(userId);
        expect(initialSnapshot.aiRequestsUsed, 119);
        expect(initialSnapshot.estimatedCostUsd, closeTo(0.0008, 0.00001));
        final staleReservations = await pool.execute(
          Sql.named('''
            SELECT COUNT(*)::int
            FROM ai_logs
            WHERE user_id = CAST(@userId AS uuid)
              AND endpoint LIKE 'plan-reservation:%'
          '''),
          parameters: {'userId': userId},
        );
        expect(staleReservations.first[0], 0);

        final rateLimitIdentifier = 'user:$userId';
        final limiter = DistributedRateLimiter(
          pool: pool,
          bucket: 'ai-live-atomicity',
          maxRequests: 2,
          windowSeconds: 60,
        );
        final rateLimitDecisions = await Future.wait(
          List.generate(6, (_) => limiter.isAllowed(rateLimitIdentifier)),
        );
        expect(rateLimitDecisions.where((allowed) => allowed), hasLength(2));
        final persistedRateLimitEvents = await pool.execute(
          Sql.named('''
            SELECT COUNT(*)::int
            FROM rate_limit_events
            WHERE bucket = 'ai-live-atomicity'
              AND identifier = @identifier
          '''),
          parameters: {'identifier': rateLimitIdentifier},
        );
        expect(persistedRateLimitEvents.first[0], 2);

        final decisions = await Future.wait(
          List.generate(
            5,
            (_) => planService.reserveAiAction(
              userId!,
              actionEndpoint: 'plan:post:/ai/optimize',
            ),
          ),
        );
        final accepted = decisions.where((decision) => decision.isAllowed);
        expect(accepted, hasLength(1));
        expect((await planService.getSnapshot(userId)).aiRequestsUsed, 120);

        final firstReservation = accepted.single.reservationId!;
        final failedAsyncHandle = AiPlanReservationHandle(
          userId: userId,
          reservationId: firstReservation,
        )..deferSettlement();
        expect(
          await settleDeferredAiPlanReservation(
            pool: pool,
            handle: failedAsyncHandle,
            successful: false,
          ),
          isTrue,
        );
        expect((await planService.getSnapshot(userId)).aiRequestsUsed, 119);

        final replacement = await planService.reserveAiAction(
          userId,
          actionEndpoint: 'plan:post:/ai/optimize',
        );
        expect(replacement.isAllowed, isTrue);
        final successfulAsyncHandle = AiPlanReservationHandle(
          userId: userId,
          reservationId: replacement.reservationId!,
        )..deferSettlement();
        expect(
          await settleDeferredAiPlanReservation(
            pool: pool,
            handle: successfulAsyncHandle,
            successful: true,
          ),
          isTrue,
        );
        final finalSnapshot = await planService.getSnapshot(userId);
        expect(finalSnapshot.aiRequestsUsed, 120);
        expect(finalSnapshot.aiRequestsRemaining, 0);

        final deck = await pool.execute(
          Sql.named('''
            INSERT INTO decks (user_id, name, format)
            VALUES (CAST(@userId AS uuid), 'Atomic job fixture', 'commander')
            RETURNING id::text AS id
          '''),
          parameters: {'userId': userId},
        );
        final deckId = deck.first.toColumnMap()['id'] as String;

        final jobId = await OptimizeJobStore.create(
          pool: pool,
          deckId: deckId,
          archetype: 'control',
          userId: userId,
        );
        OptimizeJobStore.reset();
        var persisted = await OptimizeJobStore.get(pool, jobId);
        expect(persisted?.status, 'pending');

        await OptimizeJobStore.progress(
          pool,
          jobId,
          stage: 'Validando',
          stageNumber: 2,
        );
        OptimizeJobStore.reset();
        persisted = await OptimizeJobStore.get(pool, jobId);
        expect(persisted?.status, 'processing');
        expect(persisted?.stageNumber, 2);

        await OptimizeJobStore.complete(
          pool,
          jobId,
          result: const {'mode': 'optimize', 'validation': true},
        );
        OptimizeJobStore.reset();
        persisted = await OptimizeJobStore.get(pool, jobId);
        expect(persisted?.status, 'completed');
        expect(persisted?.result?['validation'], isTrue);

        final staleOptimizeJobId = await OptimizeJobStore.create(
          pool: pool,
          deckId: deckId,
          archetype: 'midrange',
          userId: userId,
        );
        await pool.execute(
          Sql.named('''
            UPDATE ai_optimize_jobs
            SET updated_at = NOW() - INTERVAL '7 minutes'
            WHERE id = @id
          '''),
          parameters: {'id': staleOptimizeJobId},
        );
        OptimizeJobStore.reset();
        final staleOptimizeJob = await OptimizeJobStore.get(
          pool,
          staleOptimizeJobId,
        );
        expect(staleOptimizeJob?.status, 'failed');
        expect(staleOptimizeJob?.error, contains('interrompida'));

        final staleGenerateJobId = await AiGenerateJobStore.create(
          pool: pool,
          cacheKey: 'live-atomicity-$suffix',
          format: 'commander',
          userId: userId,
        );
        await pool.execute(
          Sql.named('''
            UPDATE ai_generate_jobs
            SET updated_at = NOW() - INTERVAL '5 minutes'
            WHERE id = @id
          '''),
          parameters: {'id': staleGenerateJobId},
        );
        final staleGenerateJob = await AiGenerateJobStore.get(
          pool,
          staleGenerateJobId,
        );
        expect(staleGenerateJob?.status, 'failed');
        expect(staleGenerateJob?.error, contains('interrompida'));
      } finally {
        OptimizeJobStore.reset();
        try {
          if (userId != null) {
            await _cleanupAtomicityFixtureUser(pool, userId);
          }
        } finally {
          await database.close();
          Database.resetForTesting();
        }
      }
    },
    skip:
        approved
            ? false
            : 'Requires MANALOOM_CONFIRM_POSTGRES_WRITES=$_approvalPhrase.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _cleanupKnownAtomicityFixtures(Pool pool) async {
  final rows = await pool.execute(
    Sql.named('''
    SELECT id::text
    FROM users
    WHERE email LIKE 'ai-atomicity-%@example.invalid'
  '''),
  );
  for (final row in rows) {
    await _cleanupAtomicityFixtureUser(pool, row[0] as String);
  }
}

Future<void> _cleanupAtomicityFixtureUser(Pool pool, String userId) {
  return pool.runTx((session) async {
    final parameters = {'userId': userId};
    // Jobs reference decks, so dependent runtime rows must be removed first.
    await session.execute(
      Sql.named(
        'DELETE FROM ai_optimize_jobs WHERE user_id = CAST(@userId AS uuid)',
      ),
      parameters: parameters,
    );
    await session.execute(
      Sql.named(
        'DELETE FROM ai_generate_jobs WHERE user_id = CAST(@userId AS uuid)',
      ),
      parameters: parameters,
    );
    await session.execute(
      Sql.named('DELETE FROM ai_logs WHERE user_id = CAST(@userId AS uuid)'),
      parameters: parameters,
    );
    await session.execute(
      Sql.named('''
        DELETE FROM rate_limit_events
        WHERE bucket = 'ai-live-atomicity'
          AND identifier = 'user:' || @userId
      '''),
      parameters: parameters,
    );
    await session.execute(
      Sql.named('DELETE FROM decks WHERE user_id = CAST(@userId AS uuid)'),
      parameters: parameters,
    );
    await session.execute(
      Sql.named('DELETE FROM users WHERE id = CAST(@userId AS uuid)'),
      parameters: parameters,
    );
  });
}
