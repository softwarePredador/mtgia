import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _flutterBin =
    '/Users/desenvolvimentomobile/.manaloom/toolchains/'
    'flutter-3.44.6/bin/flutter';

void main() {
  test('adapter preflight derives the exact three lock pins offline', () async {
    final root = Directory.current.parent;
    final adapter = File(
      '${root.path}/scripts/manaloom_gradle_dynamic_selector_adapter.sh',
    );
    final outputRoot = Directory.systemTemp.createTempSync(
      'manaloom-gradle-adapter-contract-',
    );
    addTearDown(() {
      if (outputRoot.existsSync()) outputRoot.deleteSync(recursive: true);
    });
    final attestation = File('${outputRoot.path}/inputs.json');
    final protected = <File>[
      File('android/settings.gradle.kts'),
      File('android/app/gradle.lockfile'),
      File('android/gradle/verification-metadata.xml'),
      File(
        '/Users/desenvolvimentomobile/.manaloom/toolchains/'
        'flutter-3.44.6/packages/integration_test/android/build.gradle.kts',
      ),
    ];
    final before = <String, String>{
      for (final file in protected) file.path: _sha256(file),
    };

    final result = await Process.run('/bin/bash', <String>[
      adapter.path,
      'preflight',
      '--flutter-bin',
      _flutterBin,
      '--app-dir',
      Directory.current.path,
      '--gradle-source-home',
      '${Platform.environment['HOME']}/.gradle',
      '--output',
      attestation.path,
    ], workingDirectory: root.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('PASS_GRADLE_DYNAMIC_SELECTOR_PREFLIGHT'));
    expect(
      await Process.run('jq', <String>[
        '-e',
        '.selectors == {"androidx.test.espresso:espresso-core":"3.3+",'
            '"androidx.test:rules":"1.2+",'
            '"androidx.test:runner":"1.2+"} and '
            '.pins == {"androidx.test.espresso:espresso-core":"3.5.0",'
            '"androidx.test:rules":"1.2.0",'
            '"androidx.test:runner":"1.5.1"} and '
            '(.profile_configurations | length) == 4 and '
            '(.cache_files | length) == 6',
        attestation.path,
      ]).then((value) => value.exitCode),
      0,
    );
    expect(<String, String>{
      for (final file in protected) file.path: _sha256(file),
    }, before);
  });

  test('lock drift is rejected before a Gradle process can start', () async {
    final root = Directory.current.parent;
    final fixture = Directory.systemTemp.createTempSync(
      'manaloom-gradle-adapter-lock-negative-',
    );
    addTearDown(() {
      if (fixture.existsSync()) fixture.deleteSync(recursive: true);
    });
    for (final path in <String>[
      'android/settings.gradle.kts',
      'android/app/gradle.lockfile',
      'android/gradle/verification-metadata.xml',
    ]) {
      final target = File('${fixture.path}/$path');
      target.parent.createSync(recursive: true);
      File(path).copySync(target.path);
    }
    final lock = File('${fixture.path}/android/app/gradle.lockfile');
    lock.writeAsStringSync('${lock.readAsStringSync()}# drift\n');
    final output = File('${fixture.path}/attestation.json');
    final result = await Process.run('/bin/bash', <String>[
      '${root.path}/scripts/manaloom_gradle_dynamic_selector_adapter.sh',
      'preflight',
      '--flutter-bin',
      _flutterBin,
      '--app-dir',
      fixture.path,
      '--gradle-source-home',
      '${Platform.environment['HOME']}/.gradle',
      '--output',
      output.path,
    ], workingDirectory: root.path);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('application Gradle lock hash drift'));
    expect(output.existsSync(), isFalse);
  });

  test('init contract rejects any fourth dynamic selector and extra root', () {
    final adapter = File(
      '../scripts/manaloom_gradle_dynamic_selector_adapter.sh',
    ).readAsStringSync();
    final init = File(
      '../scripts/lib/manaloom_gradle_dynamic_selector_pins.init.gradle',
    ).readAsStringSync();

    expect(adapter, contains('if dynamic != expected_selectors:'));
    expect(adapter, contains('dynamic selector set is not exact'));
    expect(adapter, contains('if len(event_files) != 2:'));
    expect(
      adapter,
      contains('Gradle settings root set is missing, duplicate or unexpected'),
    );
    expect(init, contains('selectors.size() != 3 || pins.size() != 3'));
    expect(init, contains('Unexpected dynamic Gradle plugin selector'));
    expect(init, contains('Unexpected dynamic dependency declaration'));
    expect(init, contains('Unexpected dynamic dependency constraint'));
    expect(
      init,
      contains("[':app', ':integration_test'].contains(project.path)"),
    );
    expect(init, contains('versionConstraint.requiredVersion'));
    expect(init, contains('versionConstraint.preferredVersion'));
    expect(init, contains('versionConstraint.strictVersion'));
    expect(init, contains('versionConstraint.rejectedVersions'));
    expect(init, contains("['[', '(', ']'].contains(first)"));
    expect(init, contains('Unexpected Gradle settings root'));
    expect(
      adapter,
      contains(
        'required_graph_keys = {\n'
        '    (":integration_test", "profileCompileClasspath"),',
      ),
    );
    expect(adapter, contains('snapshot_tree_inventory'));
    expect(adapter, contains('snapshot_ephemeral_dependency_artifacts'));
    expect(
      adapter,
      contains('MANALOOM_GRADLE_NETWORK_ATTEMPT run_id=\$run_id'),
    );
    expect(
      adapter,
      contains('run_bound_sandbox_decision_canary_plus_build_log_v3'),
    );
    expect(adapter, isNot(contains('/usr/bin/logger "\$telemetry_canary"')));
    expect(
      adapter,
      contains(
        '(remote ip \\"localhost:9\\") (with telemetry) '
        '(with message \\"\$telemetry_canary\\")',
      ),
    );
    expect(
      adapter,
      contains('/usr/bin/sandbox-exec -f "\$sandbox_profile" /usr/bin/python3'),
    );
    expect(adapter, contains('canary_entries'));
    expect(adapter, contains('os.setsid()'));
    expect(adapter, contains('adapter_stop_build_processes'));
    expect(adapter, contains('remaining_processes'));
    expect(
      adapter,
      contains('work and evidence paths must be pairwise distinct'),
    );
    expect(adapter, contains('snapshot_optional_build_tree'));
    expect(adapter, contains('adapter_cleanup_build_tree'));
    expect(adapter, contains('fresh_app_build_tree'));
  });

  test('run-bound sandbox telemetry rejects any denied attempt', () async {
    final root = Directory.current.parent;
    final adapter = File(
      '${root.path}/scripts/manaloom_gradle_dynamic_selector_adapter.sh',
    );
    final fixture = Directory.systemTemp.createTempSync(
      'manaloom-gradle-telemetry-contract-',
    );
    addTearDown(() {
      if (fixture.existsSync()) fixture.deleteSync(recursive: true);
    });
    const runId = 'gradle-profile-20260828T120000Z-123-456';
    final emptyLog = File('${fixture.path}/empty.json')
      ..writeAsStringSync(
        '[{"eventMessage":"Sandbox: Python(123) deny(1) network-outbound '
        'remote:*:9\\nMANALOOM_GRADLE_TELEMETRY_CANARY run_id=$runId",'
        '"processImagePath":"/kernel"}]\n',
      );
    final emptySummary = File('${fixture.path}/empty-summary.json');
    final emptyResult = await Process.run('/bin/bash', <String>[
      adapter.path,
      'telemetry-check',
      '--telemetry-log',
      emptyLog.path,
      '--run-id',
      runId,
      '--output',
      emptySummary.path,
    ], workingDirectory: root.path);
    expect(
      emptyResult.exitCode,
      0,
      reason: '${emptyResult.stdout}\n${emptyResult.stderr}',
    );
    expect(
      await Process.run('jq', <String>[
        '-e',
        '--arg',
        'run_id',
        runId,
        '.schema_version == "manaloom.gradle_sandbox_telemetry.v2" and '
            '.run_id == \$run_id and .canary_entries == 1 and '
            '.canary_source == "sandbox_denied_loopback_probe" and '
            '.canary_process == "/kernel" and '
            '.network_attempt_entries == 0 and .total_entries == 1 and '
            '.findings == []',
        emptySummary.path,
      ]).then((value) => value.exitCode),
      0,
    );

    final deniedLog = File('${fixture.path}/denied.json')
      ..writeAsStringSync(
        '[{"eventMessage":"Sandbox: Python(123) deny(1) network-outbound '
        'remote:*:9\\nMANALOOM_GRADLE_TELEMETRY_CANARY run_id=$runId",'
        '"processImagePath":"/kernel"},'
        '{"eventMessage":"Sandbox: java(456) deny(1) network-outbound '
        'remote:*:443\\nMANALOOM_GRADLE_NETWORK_ATTEMPT run_id=$runId",'
        '"processImagePath":"/kernel"}]\n',
      );
    final deniedSummary = File('${fixture.path}/denied-summary.json');
    final deniedResult = await Process.run('/bin/bash', <String>[
      adapter.path,
      'telemetry-check',
      '--telemetry-log',
      deniedLog.path,
      '--run-id',
      runId,
      '--output',
      deniedSummary.path,
    ], workingDirectory: root.path);
    expect(deniedResult.exitCode, isNot(0));
    expect(
      deniedResult.stderr,
      contains('sandbox unified log records network attempts'),
    );
    expect(deniedSummary.existsSync(), isFalse);

    final missingCanaryLog = File('${fixture.path}/missing-canary.json')
      ..writeAsStringSync('[]\n');
    final missingCanarySummary = File(
      '${fixture.path}/missing-canary-summary.json',
    );
    final missingCanaryResult = await Process.run('/bin/bash', <String>[
      adapter.path,
      'telemetry-check',
      '--telemetry-log',
      missingCanaryLog.path,
      '--run-id',
      runId,
      '--output',
      missingCanarySummary.path,
    ], workingDirectory: root.path);
    expect(missingCanaryResult.exitCode, isNot(0));
    expect(
      missingCanaryResult.stderr,
      contains('unified-log canary was not delivered exactly once'),
    );
    expect(missingCanarySummary.existsSync(), isFalse);
  });

  test('adapter owns build quarantine and runner traps before staging', () {
    final adapter = File(
      '../scripts/manaloom_gradle_dynamic_selector_adapter.sh',
    ).readAsStringSync();
    final runner = File(
      '../scripts/manaloom_p0_runtime_capture.sh',
    ).readAsStringSync();

    expect(
      adapter,
      contains('ADAPTER_APP_BUILD_BACKUP="\$WORK_DIR/preexisting-app-build"'),
    );
    expect(
      adapter,
      contains('mv "\$ADAPTER_APP_BUILD_ROOT" "\$ADAPTER_APP_BUILD_BACKUP"'),
    );
    expect(
      adapter,
      contains('mv "\$ADAPTER_APP_BUILD_BACKUP" "\$ADAPTER_APP_BUILD_ROOT"'),
    );
    expect(adapter, contains('fresh-app-build-owned'));
    expect(adapter, contains('RECOVERY_REQUIRED'));
    expect(adapter, contains('quarantine_planned'));
    expect(adapter, contains('original_quarantined'));
    expect(
      adapter.indexOf('ADAPTER_BUILD_PID="\$!" ADAPTER_BUILD_PGID="\$!"'),
      lessThan(adapter.indexOf('for _ in {1..100}')),
    );
    expect(adapter, contains('kill -TERM -- "-\$ADAPTER_BUILD_PGID"'));
    expect(adapter, contains('kill -TERM "\$ADAPTER_BUILD_PID"'));
    expect(adapter, contains('kill -KILL -- "-\$ADAPTER_BUILD_PGID"'));
    expect(adapter, contains('wait "\$ADAPTER_BUILD_PID"'));
    expect(adapter, contains('PASS_EXACT_RESTORE_OR_ABSENCE'));
    expect(
      adapter.indexOf('trap adapter_finalize EXIT'),
      lessThan(adapter.indexOf('mkdir -p "\$WORK_DIR"')),
    );
    expect(
      runner.indexOf('trap cleanup EXIT'),
      lessThan(runner.indexOf('staging_dir="\$(mktemp')),
    );
    expect(runner, contains('local apk_path="\$staging_dir/profile-app.apk"'));
    expect(
      runner,
      contains(
        'local merged_manifest="\$staging_dir/profile-merged-manifest.xml"',
      ),
    );
    expect(runner, isNot(contains('PREEXISTING_APP_BUILD_BACKUP=')));
    expect(runner, contains('preserved adapter recovery'));
    expect(runner, contains('Gradle adapter receipt artifact binding failed'));
    expect(runner, contains('validate_android_child_contract'));
  });
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();
