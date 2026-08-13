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
    expect(entrypoint, contains(r'${BATTLE_JOB_WORKER_ENABLED:-false}'));
    expect(entrypoint, contains('--release-capability-status'));
    expect(deploy, contains('--env-add BATTLE_JOB_WORKER_ENABLED=false'));
    expect(deploy, isNot(contains('--env-add BATTLE_JOB_WORKER_ENABLED=true')));
    expect(
      deploy,
      contains(
        'MANALOOM_RELEASE_ENABLE_BATTLE_LIVE_SPECTATOR deve permanecer 0',
      ),
    );
    expect(
      deploy,
      contains('MANALOOM_RELEASE_ENABLE_INTERACTIVE_BATTLE deve permanecer 0'),
    );
    expect(deploy, contains('runtime_battle_worker'));
    expect(deploy, contains(r'$runtime_battle_worker" != "false'));
    expect(
      deploy,
      contains(
        'manaloom_load_release_capabilities_from_git "\$ROOT_DIR" "\$sha"',
      ),
    );
    expect(
      deploy.indexOf('manaloom_load_release_capabilities_from_git'),
      lessThan(deploy.indexOf('docker service update \\')),
    );
    expect(
      deploy,
      isNot(contains('require_xmage_interactive_release_contract "\$sha"')),
    );
    for (final check
        in const {
          'battle_job_worker': 'battle_batch',
          'battle_runtime': 'battle_batch',
          'ai_runtime': 'ai_analyze_optimize_advisory',
          'battle_live_spectator': 'battle_live',
          'interactive_battle': 'battle_coach',
        }.entries) {
      expect(
        deploy,
        contains('disabled_by_policy(.checks.${check.key}; "${check.value}")'),
      );
    }
    expect(deploy, isNot(contains('.checks.ai_runtime.status == "healthy"')));
    expect(
      deploy,
      isNot(contains('.checks.battle_runtime.engines.xmage.status')),
    );
  });

  test('worker checks battle_batch before connecting or claiming', () {
    final source = File('bin/battle_job_worker.dart').readAsStringSync();
    final policyLoad = source.indexOf('ReleaseCapabilityPolicy.load()');
    final capabilityGate = source.indexOf(
      "if (!workerRequested || !releasePolicy.isAllowed('battle_batch'))",
    );
    final database = source.indexOf('final database = Database()');

    expect(policyLoad, greaterThanOrEqualTo(0));
    expect(capabilityGate, greaterThan(policyLoad));
    expect(capabilityGate, lessThan(database));
    expect(source, contains("'BATTLE_JOB_WORKER_ENABLED'"));
    expect(source, contains('--release-capability-status'));
  });

  test(
    'legacy enable flag cannot bypass a closed or invalid release policy',
    () async {
      final workerEntrypoint = File('bin/battle_job_worker.dart').absolute.path;

      final closedPolicy = await Process.run(
        Platform.resolvedExecutable,
        ['run', workerEntrypoint],
        environment: const {'BATTLE_JOB_WORKER_ENABLED': 'true'},
      );
      expect(closedPolicy.exitCode, 0);
      expect(
        '${closedPolicy.stdout}${closedPolicy.stderr}',
        contains('refusing database connection and queue claim'),
      );

      final missingPolicyDirectory = Directory.systemTemp.createTempSync(
        'brewtact-battle-worker-invalid-policy-',
      );
      addTearDown(() => missingPolicyDirectory.deleteSync(recursive: true));
      final invalidPolicy = await Process.run(
        Platform.resolvedExecutable,
        ['run', workerEntrypoint],
        workingDirectory: missingPolicyDirectory.path,
        environment: const {'BATTLE_JOB_WORKER_ENABLED': 'true'},
      );

      expect(invalidPolicy.exitCode, 78);
      expect(
        '${invalidPolicy.stdout}${invalidPolicy.stderr}',
        contains('refusing database connection and queue claim'),
      );
      expect(
        '${invalidPolicy.stdout}${invalidPolicy.stderr}',
        isNot(contains('database connection failed')),
      );
    },
  );

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
