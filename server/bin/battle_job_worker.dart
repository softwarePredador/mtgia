import 'dart:async';
import 'dart:io';

import '../lib/battle/battle_job_executor.dart';
import '../lib/battle/battle_job_runner.dart';
import '../lib/battle/battle_job_store.dart';
import '../lib/battle/battle_job_worker_daemon.dart';
import '../lib/database.dart';
import '../lib/runtime_environment.dart';

Future<void> main() async {
  final environment = loadRuntimeEnvironment();
  final database = Database();
  await database.connect();
  if (!database.isConnected) {
    stderr.writeln(
      '[battle-job-worker] database connection failed; refusing to start',
    );
    exitCode = 78;
    return;
  }

  final leaseSeconds = _boundedInt(
    environment['BATTLE_JOB_LEASE_SECONDS'],
    fallback: 30,
    minimum: 10,
    maximum: 300,
  );
  final heartbeatSeconds = _boundedInt(
    environment['BATTLE_JOB_HEARTBEAT_SECONDS'],
    fallback: 10,
    minimum: 2,
    maximum: leaseSeconds - 1,
  );
  final idleMilliseconds = _boundedInt(
    environment['BATTLE_JOB_IDLE_POLL_MS'],
    fallback: 750,
    minimum: 100,
    maximum: 10000,
  );
  final workerId =
      (environment['BATTLE_JOB_WORKER_ID'] ?? '').trim().isNotEmpty
          ? environment['BATTLE_JOB_WORKER_ID']!.trim()
          : '${Platform.localHostname}-${pid.toString()}';

  final runner = BattleJobRunner(
    store: BattleJobStore(database.connection),
    executor: PersistentBattleJobExecutor(
      database.connection,
      environment: Map<String, String>.unmodifiable({
        for (final key in _battleRuntimeEnvironmentKeys)
          if (environment[key] case final value?) key: value,
      }),
    ),
    workerId: workerId,
    leaseDuration: Duration(seconds: leaseSeconds),
    heartbeatInterval: Duration(seconds: heartbeatSeconds),
  );
  final daemon = BattleJobWorkerDaemon(
    runner: runner,
    idleDelay: Duration(milliseconds: idleMilliseconds),
  );

  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    subscriptions.add(
      signal.watch().listen((_) {
        daemon.stop();
      }),
    );
  }

  stdout.writeln(
    '[battle-job-worker] started worker_id=$workerId '
    'lease_seconds=$leaseSeconds heartbeat_seconds=$heartbeatSeconds',
  );
  try {
    await daemon.run();
  } catch (error, stackTrace) {
    stderr.writeln(
      '[battle-job-worker] fatal type=${error.runtimeType}: $error',
    );
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await database.close();
  }
}

const _battleRuntimeEnvironmentKeys = <String>[
  'BATTLE_ENGINE',
  'XMAGE_SIDECAR_URL',
  'FORGE_SIDECAR_URL',
  'NATIVE_BATTLE_SIDECAR_URL',
  'XMAGE_EXPECTED_COMMIT',
  'FORGE_EXPECTED_COMMIT',
  'XMAGE_EXPECTED_VERSION',
  'FORGE_EXPECTED_VERSION',
  'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
];

int _boundedInt(
  String? raw, {
  required int fallback,
  required int minimum,
  required int maximum,
}) {
  final parsed = int.tryParse(raw?.trim() ?? '');
  return parsed != null && parsed >= minimum && parsed <= maximum
      ? parsed
      : fallback.clamp(minimum, maximum);
}
