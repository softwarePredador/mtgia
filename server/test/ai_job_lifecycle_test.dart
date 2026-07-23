import 'package:server/ai/optimize_job.dart';
import 'package:server/ai/optimize_route_async_support.dart';
import 'package:server/ai/optimize_runtime_support.dart';
import 'package:server/ai_generate_job.dart';
import 'package:server/ai_job_lifecycle.dart';
import 'package:test/test.dart';

void main() {
  group('AI job lifecycle contract', () {
    test('normalizes safe idempotency keys and rejects unsafe keys', () {
      expect(normalizeOptionalAiJobRequestKey(null), isNull);
      expect(
        normalizeOptionalAiJobRequestKey(' generate:abc-123_4.5 '),
        'generate:abc-123_4.5',
      );

      for (final value in <Object>[
        42,
        '',
        'contains whitespace',
        'bad/key',
        'x' * (aiJobRequestKeyMaxLength + 1),
      ]) {
        expect(
          () => normalizeOptionalAiJobRequestKey(value),
          throwsA(isA<AiJobRequestKeyException>()),
          reason: 'value=$value',
        );
      }
    });

    test('server-generated keys are unique and contract-safe', () {
      final first = createServerAiJobRequestKey('optimize');
      final second = createServerAiJobRequestKey('optimize');

      expect(first, startsWith('optimize:'));
      expect(second, isNot(first));
      expect(normalizeOptionalAiJobRequestKey(first), first);
    });

    test('optimize fingerprint is canonical and ignores transport flags', () {
      final first = buildOptimizeAsyncRequestDigest({
        'deck_id': 'deck-1',
        'archetype': 'control',
        'recommendation_context': {'budget': 100, 'prefer_collection': true},
        'request_key': 'request-a',
        'async': true,
      });
      final reordered = buildOptimizeAsyncRequestDigest({
        '_force_sync': false,
        'recommendation_context': {'prefer_collection': true, 'budget': 100},
        'archetype': 'control',
        'deck_id': 'deck-1',
        'request_key': 'request-b',
      });
      final changed = buildOptimizeAsyncRequestDigest({
        'deck_id': 'deck-1',
        'archetype': 'aggro',
      });

      expect(reordered, first);
      expect(changed, isNot(first));
    });

    test(
      'accepted optimize response exposes resume cancel and idempotency',
      () {
        final body = buildCompleteModeAsyncAcceptedBody(
          jobId: 'job-1',
          telemetrySnapshot: const <String, dynamic>{},
          intensity: resolveOptimizeIntensity('focused'),
          requestKey: 'optimize:req-1',
          reused: true,
        );

        expect(body['poll_url'], '/ai/optimize/jobs/job-1');
        expect(body['cancel_url'], '/ai/optimize/jobs/job-1');
        expect(body['resume_url'], '/ai/optimize/jobs/job-1');
        expect(body['idempotency'], {
          'request_key': 'optimize:req-1',
          'reused': true,
        });
      },
    );

    test('job JSON makes active and terminal actions explicit', () {
      final activeGenerate =
          AiGenerateJob(
            id: 'generate-1',
            userId: 'user-1',
            cacheKey: 'cache-1',
            format: 'Commander',
            requestKey: 'generate:req-1',
          ).toJson();
      final cancelledOptimize =
          OptimizeJob(
            id: 'optimize-1',
            deckId: 'deck-1',
            archetype: 'control',
            userId: 'user-1',
            status: 'cancelled',
            cancelledAt: DateTime.utc(2026, 7, 22),
          ).toJson();

      expect(activeGenerate['can_cancel'], isTrue);
      expect(activeGenerate['can_resume'], isTrue);
      expect(activeGenerate['request_key'], 'generate:req-1');
      expect(cancelledOptimize['can_cancel'], isFalse);
      expect(cancelledOptimize['can_resume'], isFalse);
      expect(cancelledOptimize['cancelled_at'], isNotNull);
    });
  });
}
