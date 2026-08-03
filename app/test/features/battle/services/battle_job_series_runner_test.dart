import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';
import 'package:manaloom/features/battle/services/battle_job_series_runner.dart';

class _SeriesGateway extends BattleJobGateway {
  final List<BattleJobCreateRequest> requests = [];
  final List<String> calls = [];
  final Map<String, BattleJobCreateRequest> _requestsByJob = {};

  @override
  Future<BattleJobCreation> create(BattleJobCreateRequest request) async {
    requests.add(request);
    final jobId = 'job-${requests.length}';
    _requestsByJob[jobId] = request;
    calls.add('create:$jobId');
    return BattleJobCreation(
      job: _job(
        jobId: jobId,
        idempotencyKey: request.idempotencyKey,
        status: BattleJobStatus.queued,
      ),
      created: true,
    );
  }

  @override
  Future<BattleJob> get(String jobId) async {
    calls.add('get:$jobId');
    final request = _requestsByJob[jobId]!;
    return _job(
      jobId: jobId,
      idempotencyKey: request.idempotencyKey,
      status: BattleJobStatus.completed,
    );
  }

  @override
  Future<BattleJobCancellation> cancel(String jobId) async {
    calls.add('cancel:$jobId');
    final request = _requestsByJob[jobId]!;
    return BattleJobCancellation(
      job: _job(
        jobId: jobId,
        idempotencyKey: request.idempotencyKey,
        status: BattleJobStatus.cancelled,
      ),
      accepted: true,
    );
  }
}

void main() {
  group('BattleJobSeriesRunner', () {
    test(
      'creates three sequential independent jobs with unique labels',
      () async {
        final gateway = _SeriesGateway();
        final progress = <BattleJobSeriesProgress>[];
        final result =
            await BattleJobSeriesRunner(
              gateway: gateway,
              delay: (_) async {},
              pollInterval: Duration.zero,
            ).run(
              seriesId: 'sample-1',
              deckId: 'deck-a',
              setup: BattleTestSetup(
                opponentDeckId: 'deck-b',
                seriesSize: BattleSeriesSize.three,
              ),
              cancellation: BattleJobSeriesCancellation(),
              seedBase: 700,
              onProgress: progress.add,
            );

        expect(result.isComplete, isTrue);
        expect(result.terminalCount, 3);
        expect(gateway.requests, hasLength(3));
        expect(
          gateway.requests.map((request) => request.idempotencyKey).toSet(),
          hasLength(3),
        );
        expect(
          gateway.requests.map((request) => request.seed).toSet(),
          hasLength(3),
        );
        expect(gateway.requests.first.idempotencyKey, contains('01of3'));
        expect(gateway.requests.last.idempotencyKey, contains('03of3'));
        expect(gateway.calls, [
          'create:job-1',
          'get:job-1',
          'create:job-2',
          'get:job-2',
          'create:job-3',
          'get:job-3',
        ]);
        expect(progress.last.isComplete, isTrue);
      },
    );

    test(
      'cancels the active job and does not submit remaining samples',
      () async {
        final gateway = _SeriesGateway();
        final cancellation = BattleJobSeriesCancellation();

        final result =
            await BattleJobSeriesRunner(
              gateway: gateway,
              delay: (_) async {},
              pollInterval: Duration.zero,
            ).run(
              seriesId: 'sample-cancel',
              deckId: 'deck-a',
              setup: BattleTestSetup(
                opponentDeckId: 'deck-b',
                seriesSize: BattleSeriesSize.ten,
              ),
              cancellation: cancellation,
              seedBase: 900,
              onProgress: (progress) {
                if (progress.submittedCount == 1 && progress.activeCount == 1) {
                  cancellation.requestCancellation();
                }
              },
            );

        expect(result.cancellationRequested, isTrue);
        expect(result.submittedCount, 1);
        expect(result.attempts.single.job.status, BattleJobStatus.cancelled);
        expect(gateway.calls, ['create:job-1', 'cancel:job-1']);
      },
    );

    test('rejects a single attempt as a series', () async {
      await expectLater(
        BattleJobSeriesRunner(
          gateway: _SeriesGateway(),
          delay: (_) async {},
        ).run(
          seriesId: 'not-a-series',
          deckId: 'deck-a',
          setup: BattleTestSetup(opponentDeckId: 'deck-b'),
          cancellation: BattleJobSeriesCancellation(),
        ),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'invalid_series_size',
          ),
        ),
      );
    });

    test(
      'rejects a series identifier that cannot form an idempotency key',
      () async {
        await expectLater(
          BattleJobSeriesRunner(
            gateway: _SeriesGateway(),
            delay: (_) async {},
          ).run(
            seriesId: 'unsafe/series id',
            deckId: 'deck-a',
            setup: BattleTestSetup(
              opponentDeckId: 'deck-b',
              seriesSize: BattleSeriesSize.three,
            ),
            cancellation: BattleJobSeriesCancellation(),
          ),
          throwsA(
            isA<BattleJobContractException>().having(
              (error) => error.code,
              'code',
              'invalid_series_id',
            ),
          ),
        );
      },
    );
  });
}

BattleJob _job({
  required String jobId,
  required String idempotencyKey,
  required BattleJobStatus status,
}) {
  final terminal = status.isTerminal;
  final completed = status == BattleJobStatus.completed;
  return BattleJob.fromJson({
    'schema_version': 'battle_job_v1',
    'job_id': jobId,
    'idempotency_key': idempotencyKey,
    'status': status.wireValue,
    'stage': status.wireValue,
    'progress': terminal
        ? const {'current': 6, 'total': 6, 'ratio': 1.0}
        : const {'current': 0, 'total': 6, 'ratio': 0.0},
    'deck_a_id': 'deck-a',
    'deck_b_id': 'deck-b',
    'deck_hashes': {
      'schema_version': 'external_battle_deck_hash_v1',
      'algorithm': 'sha256',
      'deck_a': _hash('a'),
      'deck_b': _hash('b'),
    },
    'request_schema_version': battleJobRequestSchemaVersion,
    'request_hash': _hash('c'),
    'requested_engine': 'auto',
    'engine': terminal ? 'manaloom_native_reviewed' : null,
    'timeout_ms': 40000,
    'attempt_count': terminal ? 1 : 0,
    if (terminal) 'attempt_id': 'attempt-$jobId',
    if (completed) 'replay_id': 'replay-$jobId',
    if (terminal) 'terminal_reason': status.wireValue,
    'created_at': '2026-07-26T12:00:00Z',
    'updated_at': terminal ? '2026-07-26T12:00:02Z' : '2026-07-26T12:00:00Z',
    if (terminal) 'finished_at': '2026-07-26T12:00:02Z',
    'can_cancel': status.canCancel,
    'can_resume': !terminal,
    'poll_url': '/ai/battle/jobs/$jobId',
    'cancel_url': '/ai/battle/jobs/$jobId',
  });
}

String _hash(String value) => List<String>.filled(64, value).join();
