import 'package:server/ai/optimize_route_async_support.dart';
import 'package:server/ai/optimize_runtime_support.dart';
import 'package:test/test.dart';

void main() {
  const aggressive = OptimizeIntensityConfig(
    selected: 'aggressive',
    requested: 'aggressive',
    source: 'request',
    targetMin: 4,
    targetMax: 8,
  );

  test('buildOptimizeModeAsyncAcceptedBody preserves polling contract', () {
    final body = buildOptimizeModeAsyncAcceptedBody(
      deckId: 'deck-1',
      requestMode: 'optimize',
      jobId: 'job-1',
      elapsedMs: 123,
      telemetrySnapshot: {
        'stages_ms': {'request.deck_access': 7},
      },
      intensity: aggressive,
    );

    expect(body['job_id'], 'job-1');
    expect(body['status'], 'pending');
    expect(body['mode'], 'optimize');
    expect(body['poll_url'], '/ai/optimize/jobs/job-1');
    expect(body['poll_interval_ms'], 1000);
    expect(body['job_timeout_ms'], const Duration(minutes: 6).inMilliseconds);
    expect(body['async'], {
      'accepted_ms': 123,
      'executor': 'optimize_async_job',
    });
    expect(body['timings'], same(body['stage_telemetry']));
    expect(body['timings'], {
      'deck_id': 'deck-1',
      'request_mode': 'optimize',
      'job_id': 'job-1',
      'total_ms': 123,
      'accepted_ms': 123,
      'stages_ms': {'request.deck_access': 7},
    });
    expect((body['optimize_intensity'] as Map)['selected'], 'aggressive');
  });

  test(
    'buildCompleteModeAsyncAcceptedBody preserves complete polling contract',
    () {
      final telemetry = {
        'stages_ms': {'complete.setup': 5},
      };
      final body = buildCompleteModeAsyncAcceptedBody(
        jobId: 'job-complete',
        telemetrySnapshot: telemetry,
        intensity: aggressive,
      );

      expect(body['job_id'], 'job-complete');
      expect(body['status'], 'pending');
      expect(body['poll_url'], '/ai/optimize/jobs/job-complete');
      expect(body['poll_interval_ms'], 2000);
      expect(body['job_timeout_ms'], const Duration(minutes: 6).inMilliseconds);
      expect(body['timings'], same(telemetry));
      expect(body['stage_telemetry'], same(telemetry));
      expect((body['optimize_intensity'] as Map)['returned_swaps'], 0);
    },
  );
}
