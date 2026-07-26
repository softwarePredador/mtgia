import 'dart:async';

import 'battle_job_runner.dart';

typedef BattleJobIdleWait = Future<void> Function(Duration duration);

class BattleJobWorkerDaemon {
  BattleJobWorkerDaemon({
    required BattleJobRunner runner,
    this.idleDelay = const Duration(milliseconds: 750),
    BattleJobIdleWait? wait,
  }) : _runner = runner,
       _wait = wait ?? Future<void>.delayed {
    if (idleDelay <= Duration.zero) {
      throw ArgumentError.value(idleDelay, 'idleDelay', 'Must be positive.');
    }
  }

  final BattleJobRunner _runner;
  final Duration idleDelay;
  final BattleJobIdleWait _wait;
  bool _stopping = false;

  bool get isStopping => _stopping;

  void stop() {
    _stopping = true;
  }

  Future<void> run() async {
    while (!_stopping) {
      final result = await _runner.runNext();
      if (result.state == BattleJobRunState.persistenceUnrecorded) {
        throw StateError(
          'Battle job ${result.jobId ?? 'unknown'} reached an '
          'unrecorded terminal state.',
        );
      }
      if (result.state == BattleJobRunState.idle && !_stopping) {
        await _wait(idleDelay);
      }
    }
  }
}
