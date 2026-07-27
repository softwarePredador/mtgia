import 'dart:math';

import '../models/battle_job.dart';
import '../models/battle_test_setup.dart';
import 'battle_job_gateway.dart';

typedef BattleSeriesProgressCallback =
    void Function(BattleJobSeriesProgress progress);
typedef BattleSeriesDelay = Future<void> Function(Duration duration);

class BattleJobSeriesCancellation {
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  void requestCancellation() {
    _isCancellationRequested = true;
  }
}

class BattleJobSeriesAttempt {
  const BattleJobSeriesAttempt({
    required this.index,
    required this.total,
    required this.seed,
    required this.idempotencyKey,
    required this.job,
  });

  final int index;
  final int total;
  final int seed;
  final String idempotencyKey;
  final BattleJob job;

  BattleJobSeriesAttempt withJob(BattleJob value) => BattleJobSeriesAttempt(
    index: index,
    total: total,
    seed: seed,
    idempotencyKey: idempotencyKey,
    job: value,
  );
}

class BattleJobSeriesProgress {
  BattleJobSeriesProgress({
    required this.seriesId,
    required this.total,
    required List<BattleJobSeriesAttempt> attempts,
    this.cancellationRequested = false,
  }) : attempts = List<BattleJobSeriesAttempt>.unmodifiable(attempts);

  final String seriesId;
  final int total;
  final List<BattleJobSeriesAttempt> attempts;
  final bool cancellationRequested;

  int get submittedCount => attempts.length;
  int get terminalCount =>
      attempts.where((attempt) => attempt.job.isTerminal).length;
  int get activeCount => submittedCount - terminalCount;
  bool get isComplete => submittedCount == total && terminalCount == total;
}

class BattleJobSeriesRunner {
  BattleJobSeriesRunner({
    required BattleJobGateway gateway,
    BattleSeriesDelay? delay,
    Duration pollInterval = const Duration(seconds: 2),
    Random? random,
  }) : _gateway = gateway,
       _delay = delay ?? Future<void>.delayed,
       _pollInterval = pollInterval,
       _random = random ?? Random.secure();

  final BattleJobGateway _gateway;
  final BattleSeriesDelay _delay;
  final Duration _pollInterval;
  final Random _random;

  /// Runs one canonical job at a time. This leaves room under the current
  /// per-user quota and ensures attempts 4-10 are only submitted after the
  /// previous attempt reaches a terminal state.
  Future<BattleJobSeriesProgress> run({
    required String seriesId,
    required String deckId,
    required BattleTestSetup setup,
    required BattleJobSeriesCancellation cancellation,
    BattleSeriesProgressCallback? onProgress,
    int? seedBase,
  }) async {
    final total = setup.seriesSize.count;
    if (!setup.seriesSize.isSeries) {
      throw const BattleJobContractException('invalid_series_size');
    }

    final normalizedSeriesId = seriesId.trim();
    if (!_seriesIdPattern.hasMatch(normalizedSeriesId)) {
      throw const BattleJobContractException('invalid_series_id');
    }

    final base = seedBase ?? _random.nextInt(0x7fffffff);
    var attempts = <BattleJobSeriesAttempt>[];

    void emit() {
      onProgress?.call(
        BattleJobSeriesProgress(
          seriesId: normalizedSeriesId,
          total: total,
          attempts: attempts,
          cancellationRequested: cancellation.isCancellationRequested,
        ),
      );
    }

    emit();
    for (var offset = 0; offset < total; offset += 1) {
      if (cancellation.isCancellationRequested) break;

      final index = offset + 1;
      final seed = (base + (offset * 104729)) & 0x7fffffff;
      final idempotencyKey =
          'series-$normalizedSeriesId-${index.toString().padLeft(2, '0')}of$total';
      final creation = await _gateway.create(
        BattleJobCreateRequest(
          deckId: deckId,
          setup: setup,
          idempotencyKey: idempotencyKey,
          seed: seed,
        ),
      );
      var attempt = BattleJobSeriesAttempt(
        index: index,
        total: total,
        seed: seed,
        idempotencyKey: idempotencyKey,
        job: creation.job,
      );
      attempts = [...attempts, attempt];
      emit();

      while (!attempt.job.isTerminal && !cancellation.isCancellationRequested) {
        await _delay(_pollInterval);
        if (cancellation.isCancellationRequested) break;
        attempt = attempt.withJob(await _gateway.get(attempt.job.jobId));
        attempts = [...attempts.take(attempts.length - 1), attempt];
        emit();
      }

      if (cancellation.isCancellationRequested &&
          !attempt.job.isTerminal &&
          attempt.job.canCancel) {
        try {
          final cancelled = await _gateway.cancel(attempt.job.jobId);
          attempt = attempt.withJob(cancelled.job);
          attempts = [...attempts.take(attempts.length - 1), attempt];
        } on BattleJobGatewayException {
          // Cancellation is best effort. Already-created jobs remain visible
          // and authoritative in PostgreSQL even if this client disconnects.
        }
        emit();
        break;
      }
    }

    return BattleJobSeriesProgress(
      seriesId: normalizedSeriesId,
      total: total,
      attempts: attempts,
      cancellationRequested: cancellation.isCancellationRequested,
    );
  }
}

final _seriesIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,79}$');
