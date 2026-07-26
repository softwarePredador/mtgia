import 'dart:io';

import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_runner.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/battle_job_worker_daemon.dart';
import 'package:test/test.dart';

void main() {
  test('daemon polls an idle queue and stops cooperatively', () async {
    late BattleJobWorkerDaemon daemon;
    var waits = 0;
    final runner = BattleJobRunner(
      store: _IdleStore(),
      executor: _UnexpectedExecutor(),
      workerId: 'worker-daemon-test',
      leaseDuration: const Duration(minutes: 1),
      heartbeatInterval: const Duration(seconds: 10),
    );
    daemon = BattleJobWorkerDaemon(
      runner: runner,
      idleDelay: const Duration(milliseconds: 1),
      wait: (_) async {
        waits++;
        daemon.stop();
      },
    );

    await daemon.run();

    expect(waits, 1);
    expect(daemon.isStopping, isTrue);
  });

  test('production image compiles and fail-closed supervises the worker', () {
    final dockerfile = File('Dockerfile').readAsStringSync();
    final entrypoint = File('bin/api_with_battle_worker.sh').readAsStringSync();
    final deploy =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();

    expect(dockerfile, contains('dart compile exe bin/battle_job_worker.dart'));
    expect(dockerfile, contains('/out/manaloom-battle-worker'));
    expect(dockerfile, contains('api_with_battle_worker.sh'));
    expect(entrypoint, contains('/app/server/manaloom-server'));
    expect(entrypoint, contains('/app/server/manaloom-battle-worker'));
    expect(entrypoint, contains(r'kill -0 "$worker_pid"'));
    expect(entrypoint, contains(r'${BATTLE_JOB_WORKER_ENABLED:-true}'));
    expect(deploy, contains('--env-add BATTLE_JOB_WORKER_ENABLED=true'));
    expect(deploy, contains('runtime_battle_worker'));
  });

  test('daemon refuses an unrecorded terminal transition', () {
    final source =
        File('lib/battle/battle_job_worker_daemon.dart').readAsStringSync();

    expect(source, contains('BattleJobRunState.persistenceUnrecorded'));
    expect(source, contains('unrecorded terminal state'));
  });
}

class _IdleStore implements BattleJobWorkerStore {
  @override
  Future<BattleJobClaim?> claimNext({
    required String workerId,
    Duration leaseDuration = battleJobDefaultLease,
  }) async => null;

  @override
  Future<BattleJobHeartbeat> heartbeat(
    BattleJobClaim claim, {
    Duration leaseDuration = battleJobDefaultLease,
    String? stage,
    int? progressCurrent,
    int? progressTotal,
  }) async => const BattleJobHeartbeat(active: false, cancelRequested: false);

  @override
  Future<bool> markPersistenceError(
    BattleJobClaim claim, {
    required String errorCode,
    String? engine,
    String? engineProcessId,
    DateTime? engineProcessStartedAt,
  }) async => false;

  @override
  Future<bool> markRunning(
    BattleJobClaim claim, {
    String stage = 'starting_engine',
  }) async => false;

  @override
  Future<bool> transitionTerminal(
    BattleJobClaim claim,
    BattleJobTerminalUpdate update,
  ) async => false;
}

class _UnexpectedExecutor implements BattleJobExecutor {
  @override
  Future<BattleJobExecutionResult> execute(
    BattleJob job,
    BattleJobExecutionControl control,
  ) {
    throw StateError('An idle daemon must not execute a job.');
  }
}
