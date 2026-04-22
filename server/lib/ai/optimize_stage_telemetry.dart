import '../logger.dart';

class OptimizeStageTelemetry {
  OptimizeStageTelemetry({
    required this.deckId,
    required this.requestMode,
    this.jobId,
  }) : _totalStopwatch = Stopwatch()..start();

  final String deckId;
  final String requestMode;
  final String? jobId;
  final Stopwatch _totalStopwatch;
  final Map<String, int> _stageDurationsMs = <String, int>{};
  final Map<String, Stopwatch> _activeStages = <String, Stopwatch>{};

  T trackSync<T>(String stage, T Function() action) {
    final stopwatch = Stopwatch()..start();
    try {
      return action();
    } finally {
      stopwatch.stop();
      _recordStage(stage, stopwatch.elapsedMilliseconds);
    }
  }

  Future<T> trackAsync<T>(String stage, Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      _recordStage(stage, stopwatch.elapsedMilliseconds);
    }
  }

  void start(String stage) {
    final existing = _activeStages.remove(stage);
    existing?.stop();
    _activeStages[stage] = Stopwatch()..start();
  }

  void stop(String stage) {
    final stopwatch = _activeStages.remove(stage);
    if (stopwatch == null) return;
    stopwatch.stop();
    _recordStage(stage, stopwatch.elapsedMilliseconds);
  }

  int get totalElapsedMs => _totalStopwatch.elapsedMilliseconds;

  Map<String, dynamic> snapshot() {
    final sortedEntries = _stageDurationsMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'deck_id': deckId,
      'request_mode': requestMode,
      if (jobId != null) 'job_id': jobId,
      'total_ms': totalElapsedMs,
      'stages_ms': {
        for (final entry in sortedEntries) entry.key: entry.value,
      },
    };
  }

  void logSummary({String prefix = '[OPTIMIZE_TIMING]'}) {
    final stages = _stageDurationsMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final stageSummary = stages.map((e) => '${e.key}=${e.value}ms').join(' ');
    final jobPart = jobId == null ? '' : ' job_id=$jobId';
    Log.i(
      '$prefix deck_id=$deckId mode=$requestMode${jobPart} total_ms=$totalElapsedMs $stageSummary',
    );
  }

  void _recordStage(String stage, int elapsedMs) {
    _stageDurationsMs[stage] = (_stageDurationsMs[stage] ?? 0) + elapsedMs;
    final jobPart = jobId == null ? '' : ' job_id=$jobId';
    Log.i(
      '[OPTIMIZE_TIMING_STAGE] deck_id=$deckId mode=$requestMode${jobPart} stage=$stage elapsed_ms=$elapsedMs',
    );
  }
}
