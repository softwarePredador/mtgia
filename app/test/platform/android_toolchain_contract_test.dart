import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android toolchain supports Flutter compile SDK and browser plugin', () {
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final wrapper = File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync();
    final appBuild = File('android/app/build.gradle.kts').readAsStringSync();
    final patrolRunner = File(
      'android/app/src/androidTest/java/com/mtgia/mtg_app/MainActivityTest.java',
    ).readAsStringSync();

    expect(
      settings,
      contains('id("com.android.application") version "8.11.1"'),
    );
    expect(
      settings,
      contains('id("org.jetbrains.kotlin.android") version "2.2.20"'),
    );
    expect(wrapper, contains('gradle-8.14-all.zip'));
    expect(appBuild, contains('JavaVersion.VERSION_17'));
    expect(appBuild, isNot(contains('JavaVersion.VERSION_11')));
    expect(appBuild, contains('compileSdk = flutter.compileSdkVersion'));
    expect(appBuild, contains('targetSdk = flutter.targetSdkVersion'));
    expect(
      appBuild,
      contains(
        'testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"',
      ),
    );
    expect(appBuild, contains('execution = "ANDROIDX_TEST_ORCHESTRATOR"'));
    expect(
      appBuild,
      contains('androidTestUtil("androidx.test:orchestrator:1.5.1")'),
    );
    expect(
      appBuild,
      contains('"dev.flutter.plugins.integration_test.IntegrationTestPlugin"'),
    );
    expect(appBuild, contains('"pl.leancode.patrol.PatrolPlugin"'));
    expect(
      appBuild,
      contains('patched.lastIndexOf(registerMethodEnd)'),
      reason:
          'Profile builds must inject optional test plugin registration even '
          'when Flutter omits the direct generated registration line.',
    );
    expect(
      appBuild,
      contains('} else if (!patched.contains(reflectionMarker)) {'),
    );
    expect(patrolRunner, contains('instrumentation.setUp(MainActivity.class)'));
    expect(patrolRunner, contains('instrumentation.listDartTests()'));
    expect(patrolRunner, contains('instrumentation.runDartTest(dartTestName)'));
  });

  test(
    'profile capture manifest removes every native telemetry initializer',
    () {
      final profile = File(
        'android/app/src/profile/AndroidManifest.xml',
      ).readAsStringSync();
      final release = File(
        'android/app/src/release/AndroidManifest.xml',
      ).readAsStringSync();
      const forbidden = <String>[
        'FlutterFirebaseMessagingBackgroundService',
        'FlutterFirebaseMessagingService',
        'FlutterFirebaseMessagingReceiver',
        'ComponentDiscoveryService',
        'FlutterFirebaseMessagingInitProvider',
        'FirebaseInstanceIdReceiver',
        'FirebaseMessagingService',
        'SessionLifecycleService',
        'FirebaseInitProvider',
        'MlKitComponentDiscoveryService',
        'MlKitInitProvider',
        'TransportBackendDiscovery',
        'JobInfoSchedulerService',
        'AlarmManagerSchedulerBroadcastReceiver',
        'SentryPerformanceProvider',
      ];
      for (final component in forbidden) {
        expect(profile, contains(component));
      }
      expect(RegExp(r'tools:node="remove"').allMatches(profile).length, 15);
      for (final entry in const <String, String>{
        'firebase_performance_collection_deactivated': 'true',
        'firebase_messaging_auto_init_enabled': 'false',
        'firebase_sessions_enabled': 'false',
        'io.sentry.auto-init': 'false',
      }.entries) {
        expect(profile, contains('android:name="${entry.key}"'));
        expect(profile, contains('android:value="${entry.value}"'));
        expect(release, isNot(contains(entry.key)));
      }
    },
  );

  test(
    'physical runner and index gate publish only after terminal receipt',
    () {
      final runner = File(
        '../scripts/manaloom_p0_runtime_capture.sh',
      ).readAsStringSync();
      final gate = File(
        '../scripts/manaloom_ui_live_evidence_gate.sh',
      ).readAsStringSync();
      final guard = File(
        '../scripts/manaloom_android_ui_egress_guard.sh',
      ).readAsStringSync();
      final adapter = File(
        '../scripts/manaloom_gradle_dynamic_selector_adapter.sh',
      ).readAsStringSync();
      final init = File(
        '../scripts/lib/manaloom_gradle_dynamic_selector_pins.init.gradle',
      ).readAsStringSync();

      expect(runner, contains('build_and_attest_physical_profile_apk'));
      expect(
        runner,
        contains('manaloom_gradle_dynamic_selector_adapter.sh" run'),
      );
      expect(runner, isNot(contains('gradle.startParameter.offline = true')));
      expect(runner, contains('--no-android-gradle-daemon'));
      expect(runner, isNot(contains('GRADLE_OPTS=')));
      expect(runner, contains('--use-application-binary='));
      expect(runner, contains('--keep-app-running'));
      expect(adapter, contains('/usr/bin/sandbox-exec'));
      expect(
        adapter,
        contains('MANALOOM_GRADLE_NETWORK_ATTEMPT run_id=\$run_id'),
      );
      expect(adapter, contains('/usr/bin/log show'));
      expect(
        adapter,
        contains('run_bound_sandbox_decision_canary_plus_build_log_v3'),
      );
      expect(adapter, contains('GRADLE_USER_HOME="\$gradle_home"'));
      expect(adapter, contains('GRADLE_RO_DEP_CACHE="\$ro_cache"'));
      expect(init, contains('gradle.startParameter.offline = true'));
      expect(init, contains('details.useVersion(pins[coordinate])'));
      expect(init, contains('Unexpected dynamic resolved selector'));
      expect(runner, contains('verify-android-egress-receipt'));
      expect(
        runner.indexOf('verify-android-egress-receipt'),
        lessThan(runner.indexOf('cp "\$staging_dir"/*.png')),
      );
      expect(
        gate.indexOf('verify-android-egress-receipt'),
        lessThan(gate.indexOf('index_profile \\\n    web_mobile_390x844')),
      );
      expect(guard, contains("trap 'signal_exit 130' INT"));
      expect(
        guard.indexOf('trap finalize EXIT'),
        lessThan(guard.indexOf('STATE_DIR="\$(mktemp')),
      );
      expect(guard, contains('ps -A -n -o UID,PID,NAME'));
      expect(guard, contains('MANALOOM_ANDROID_EGRESS_BEGIN'));
      expect(guard, contains('MANALOOM_ANDROID_EGRESS_END'));
      expect(guard, contains('manaloom.android_ui_egress_receipt.v2'));
      expect(guard, contains('reverse --remove-all'));
      expect(guard, contains('force_stop_and_clear'));
      expect(guard, contains('seal-android-egress-receipt'));
      expect(guard, contains('restore_network'));
      expect(
        runner.indexOf('trap cleanup EXIT'),
        lessThan(runner.indexOf('staging_dir="\$(mktemp')),
      );
    },
  );

  test('physical child is bound to governed staging and adapter receipt', () async {
    final root = Directory.systemTemp.createTempSync(
      'manaloom-android-child-contract-',
    );
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final staging = Directory.systemTemp.createTempSync('manaloom_p0_capture.');
    addTearDown(() {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    });
    final apk = File('${staging.path}/profile-app.apk')
      ..writeAsBytesSync(<int>[0x50, 0x4b, 0x03, 0x04]);
    final canonicalApkPath = apk.resolveSymbolicLinksSync();
    final receipt = File('${root.path}/adapter-receipt.json');
    receipt.writeAsStringSync(
      '${jsonEncode(<String, Object?>{
        'schema_version': 'manaloom.gradle_dynamic_selector_adapter_receipt.v1',
        'status': 'PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER',
        'artifact': <String, Object?>{'apk_path': canonicalApkPath, 'apk_sha256': _sha256(apk)},
        'network': <String, Object?>{
          'resolver_or_egress_attempts': 0,
          'unified_log': <String, Object?>{'canary_entries': 1, 'network_attempt_entries': 0},
        },
        'mutation': <String, Object?>{
          'app_build': <String, Object?>{'restored_exactly': true},
        },
        'build': <String, Object?>{
          'process_group': <String, Object?>{'waited': true, 'remaining_processes': 0},
        },
      })}\n',
    );
    final runner = File(
      '../scripts/manaloom_p0_runtime_capture.sh',
    ).absolute.path;
    Future<ProcessResult> validate({
      String? stagingPath,
      String? apkPath,
      String? apkSha,
      String? receiptPath,
      String? receiptSha,
    }) => Process.run(
      '/bin/bash',
      <String>[runner, '--validate-android-child-contract'],
      environment: <String, String>{
        ...Platform.environment,
        'MANALOOM_ANDROID_EGRESS_CHILD': '1',
        'MANALOOM_ANDROID_EGRESS_RUN_ID':
            'android-egress-20260828T120000Z-123-456',
        'MANALOOM_ANDROID_STAGING_DIR': stagingPath ?? staging.path,
        'MANALOOM_ANDROID_APPLICATION_BINARY': apkPath ?? apk.path,
        'MANALOOM_ANDROID_APPLICATION_SHA256': apkSha ?? _sha256(apk),
        'MANALOOM_ANDROID_ADAPTER_RECEIPT': receiptPath ?? receipt.path,
        'MANALOOM_ANDROID_ADAPTER_RECEIPT_SHA256':
            receiptSha ?? _sha256(receipt),
      },
      workingDirectory: Directory.current.path,
    );

    final positive = await validate();
    expect(
      positive.exitCode,
      0,
      reason: '${positive.stdout}\n${positive.stderr}',
    );
    expect(positive.stdout, contains('PASS_ANDROID_CHILD_CONTRACT'));

    final outside = Directory('${root.path}/unsafe-staging')..createSync();
    final outsideApk = File('${outside.path}/profile-app.apk')
      ..writeAsBytesSync(apk.readAsBytesSync());
    expect(
      (await validate(
        stagingPath: outside.path,
        apkPath: outsideApk.path,
        apkSha: _sha256(outsideApk),
      )).exitCode,
      isNot(0),
    );

    final stagingLink = Link('${root.path}/manaloom_p0_capture.link')
      ..createSync(staging.path);
    expect((await validate(stagingPath: stagingLink.path)).exitCode, isNot(0));
    expect(
      (await validate(apkSha: List<String>.filled(64, '0').join())).exitCode,
      isNot(0),
    );

    final crossArtifactReceipt = File('${root.path}/cross-artifact.json')
      ..writeAsStringSync(
        receipt.readAsStringSync().replaceFirst(
          canonicalApkPath,
          '${staging.path}/other.apk',
        ),
      );
    expect(
      (await validate(
        receiptPath: crossArtifactReceipt.path,
        receiptSha: _sha256(crossArtifactReceipt),
      )).exitCode,
      isNot(0),
    );
  });

  test(
    'fake ADB proves snapshot, isolation, receipt and exact restoration',
    () async {
      final fixture = await _createFakeAdbFixture();
      addTearDown(() {
        if (fixture.root.existsSync()) fixture.root.deleteSync(recursive: true);
      });
      final runtime = File('${fixture.root.path}/runtime.log');
      final native = File('${fixture.root.path}/native.log');
      final pidTrace = File('${fixture.root.path}/pids.tsv');
      final receipt = File('${fixture.root.path}/receipt.json');
      final result = await Process.run(
        '/bin/bash',
        <String>[
          '../scripts/manaloom_android_ui_egress_guard.sh',
          'run',
          '--run-id',
          'android-egress-fake-pass-0001',
          '--serial',
          'R58T300SREH',
          '--package',
          'com.mtgia.mtg_app',
          '--source-digest',
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          '--profile',
          'android_physical_sm_a135m',
          '--runtime-log',
          runtime.path,
          '--native-log',
          native.path,
          '--pid-trace',
          pidTrace.path,
          '--receipt',
          receipt.path,
          '--api-port',
          '58001',
          '--web-port',
          '58002',
          '--',
          '/bin/bash',
          '-c',
          'printf 4242 >"\$FAKE_ADB_STATE/pid"; '
              'printf "Making request to: http://127.0.0.1:58001/ready\\n" '
              '>"\$FAKE_RUNTIME_LOG"; sleep 0.6',
        ],
        workingDirectory: Directory.current.path,
        environment: <String, String>{
          ...Platform.environment,
          'MANALOOM_ADB_BIN': fixture.adb.path,
          'MANALOOM_DART_BIN':
              '/Users/desenvolvimentomobile/.manaloom/toolchains/'
              'flutter-3.44.6/bin/cache/dart-sdk/bin/dart',
          'FAKE_ADB_STATE': fixture.state.path,
          'FAKE_RUNTIME_LOG': runtime.path,
        },
      );

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      _expectFakeDeviceRestored(fixture);
      expect(receipt.existsSync(), isTrue);
      expect(receipt.readAsStringSync(), contains('PASS_ANDROID_EGRESS'));
      expect(
        receipt.readAsStringSync(),
        contains('manaloom.android_ui_egress_receipt.v2'),
      );
      expect(pidTrace.readAsStringSync(), contains('\t4242\t'));
    },
  );

  test(
    'fake ADB signal path restores state and never emits PASS receipt',
    () async {
      final fixture = await _createFakeAdbFixture();
      addTearDown(() {
        if (fixture.root.existsSync()) fixture.root.deleteSync(recursive: true);
      });
      final runtime = File('${fixture.root.path}/runtime.log');
      final native = File('${fixture.root.path}/native.log');
      final pidTrace = File('${fixture.root.path}/pids.tsv');
      final receipt = File('${fixture.root.path}/receipt.json');
      final process = await Process.start(
        '/bin/bash',
        <String>[
          '../scripts/manaloom_android_ui_egress_guard.sh',
          'run',
          '--run-id',
          'android-egress-fake-term-0001',
          '--serial',
          'R58T300SREH',
          '--package',
          'com.mtgia.mtg_app',
          '--source-digest',
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          '--profile',
          'android_physical_sm_a135m',
          '--runtime-log',
          runtime.path,
          '--native-log',
          native.path,
          '--pid-trace',
          pidTrace.path,
          '--receipt',
          receipt.path,
          '--api-port',
          '58003',
          '--web-port',
          '58004',
          '--',
          '/bin/bash',
          '-c',
          'printf 4242 >"\$FAKE_ADB_STATE/pid"; '
              'printf ok >"\$FAKE_RUNTIME_LOG"; sleep 30',
        ],
        workingDirectory: Directory.current.path,
        environment: <String, String>{
          ...Platform.environment,
          'MANALOOM_ADB_BIN': fixture.adb.path,
          'MANALOOM_DART_BIN':
              '/Users/desenvolvimentomobile/.manaloom/toolchains/'
              'flutter-3.44.6/bin/cache/dart-sdk/bin/dart',
          'FAKE_ADB_STATE': fixture.state.path,
          'FAKE_RUNTIME_LOG': runtime.path,
        },
      );
      for (var attempt = 0; attempt < 100; attempt++) {
        if (File('${fixture.state.path}/wifi').readAsStringSync() == '0') break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      process.kill(ProcessSignal.sigterm);
      final exit = await process.exitCode.timeout(const Duration(seconds: 10));

      expect(exit, isNot(0));
      _expectFakeDeviceRestored(fixture);
      expect(receipt.existsSync(), isFalse);
    },
  );

  test('fake ADB child error restores exact state without PASS', () async {
    final fixture = await _createFakeAdbFixture();
    addTearDown(() {
      if (fixture.root.existsSync()) fixture.root.deleteSync(recursive: true);
    });
    final runtime = File('${fixture.root.path}/runtime-error.log');
    final receipt = File('${fixture.root.path}/receipt-error.json');
    final result = await Process.run(
      '/bin/bash',
      <String>[
        '../scripts/manaloom_android_ui_egress_guard.sh',
        'run',
        '--run-id',
        'android-egress-fake-error-0001',
        '--serial',
        'R58T300SREH',
        '--package',
        'com.mtgia.mtg_app',
        '--source-digest',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        '--profile',
        'android_physical_sm_a135m',
        '--runtime-log',
        runtime.path,
        '--native-log',
        '${fixture.root.path}/native-error.log',
        '--pid-trace',
        '${fixture.root.path}/pids-error.tsv',
        '--receipt',
        receipt.path,
        '--api-port',
        '58005',
        '--web-port',
        '58006',
        '--',
        '/bin/bash',
        '-c',
        'printf 4242 >"\$FAKE_ADB_STATE/pid"; '
            'printf ok >"\$FAKE_RUNTIME_LOG"; sleep 0.4; exit 37',
      ],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'MANALOOM_ADB_BIN': fixture.adb.path,
        'MANALOOM_DART_BIN':
            '/Users/desenvolvimentomobile/.manaloom/toolchains/'
            'flutter-3.44.6/bin/cache/dart-sdk/bin/dart',
        'FAKE_ADB_STATE': fixture.state.path,
        'FAKE_RUNTIME_LOG': runtime.path,
      },
    );

    expect(result.exitCode, 37, reason: '${result.stdout}\n${result.stderr}');
    _expectFakeDeviceRestored(fixture);
    expect(receipt.existsSync(), isFalse);
  });

  test('fake ADB restores a mutation whose command reports failure', () async {
    final fixture = await _createFakeAdbFixture();
    addTearDown(() {
      if (fixture.root.existsSync()) fixture.root.deleteSync(recursive: true);
    });
    final runtime = File('${fixture.root.path}/runtime-mutation.log');
    final receipt = File('${fixture.root.path}/receipt-mutation.json');
    final result = await Process.run(
      '/bin/bash',
      <String>[
        '../scripts/manaloom_android_ui_egress_guard.sh',
        'run',
        '--run-id',
        'android-egress-fake-mutation-0001',
        '--serial',
        'R58T300SREH',
        '--package',
        'com.mtgia.mtg_app',
        '--source-digest',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        '--profile',
        'android_physical_sm_a135m',
        '--runtime-log',
        runtime.path,
        '--native-log',
        '${fixture.root.path}/native-mutation.log',
        '--pid-trace',
        '${fixture.root.path}/pids-mutation.tsv',
        '--receipt',
        receipt.path,
        '--api-port',
        '58007',
        '--web-port',
        '58008',
        '--',
        '/bin/true',
      ],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'MANALOOM_ADB_BIN': fixture.adb.path,
        'MANALOOM_DART_BIN':
            '/Users/desenvolvimentomobile/.manaloom/toolchains/'
            'flutter-3.44.6/bin/cache/dart-sdk/bin/dart',
        'FAKE_ADB_STATE': fixture.state.path,
        'FAKE_RUNTIME_LOG': runtime.path,
        'FAKE_ADB_FAIL_AFTER_WIFI_DISABLE': '1',
      },
    );

    expect(result.exitCode, isNot(0));
    _expectFakeDeviceRestored(fixture);
    expect(receipt.existsSync(), isFalse);
  });

  test('fake ADB rejects a surviving same-UID remote process', () async {
    final fixture = await _createFakeAdbFixture();
    addTearDown(() {
      if (fixture.root.existsSync()) fixture.root.deleteSync(recursive: true);
    });
    final runtime = File('${fixture.root.path}/runtime-survivor.log');
    final receipt = File('${fixture.root.path}/receipt-survivor.json');
    final result = await Process.run(
      '/bin/bash',
      <String>[
        '../scripts/manaloom_android_ui_egress_guard.sh',
        'run',
        '--run-id',
        'android-egress-fake-survivor-0001',
        '--serial',
        'R58T300SREH',
        '--package',
        'com.mtgia.mtg_app',
        '--source-digest',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        '--profile',
        'android_physical_sm_a135m',
        '--runtime-log',
        runtime.path,
        '--native-log',
        '${fixture.root.path}/native-survivor.log',
        '--pid-trace',
        '${fixture.root.path}/pids-survivor.tsv',
        '--receipt',
        receipt.path,
        '--api-port',
        '58009',
        '--web-port',
        '58010',
        '--',
        '/bin/bash',
        '-c',
        'printf "4242 4343" >"\$FAKE_ADB_STATE/pid"; '
            'touch "\$FAKE_ADB_STATE/sticky_enabled"; '
            'printf ok >"\$FAKE_RUNTIME_LOG"; sleep 0.5',
      ],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'MANALOOM_ADB_BIN': fixture.adb.path,
        'MANALOOM_DART_BIN':
            '/Users/desenvolvimentomobile/.manaloom/toolchains/'
            'flutter-3.44.6/bin/cache/dart-sdk/bin/dart',
        'FAKE_ADB_STATE': fixture.state.path,
        'FAKE_RUNTIME_LOG': runtime.path,
      },
    );

    expect(result.exitCode, isNot(0));
    expect(
      '${result.stdout}\n${result.stderr}',
      contains('cleanup/receipt failed'),
    );
    _expectFakeDeviceRestored(fixture, expectAppPidsEmpty: false);
    expect(File('${fixture.state.path}/pid').readAsStringSync(), '4343');
    expect(receipt.existsSync(), isFalse);
  });
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

class _FakeAdbFixture {
  const _FakeAdbFixture(this.root, this.state, this.adb);

  final Directory root;
  final Directory state;
  final File adb;
}

void _expectFakeDeviceRestored(
  _FakeAdbFixture fixture, {
  bool expectAppPidsEmpty = true,
}) {
  expect(File('${fixture.state.path}/wifi').readAsStringSync(), '1');
  expect(File('${fixture.state.path}/data').readAsStringSync(), '1');
  expect(
    File('${fixture.state.path}/accelerometer_rotation').readAsStringSync(),
    '1',
  );
  expect(File('${fixture.state.path}/user_rotation').readAsStringSync(), '3');
  expect(
    File(
      '${fixture.state.path}/immersive_mode_confirmations',
    ).readAsStringSync(),
    'immersive',
  );
  expect(File('${fixture.state.path}/reverse').readAsStringSync(), isEmpty);
  if (expectAppPidsEmpty) {
    expect(File('${fixture.state.path}/pid').readAsStringSync(), isEmpty);
  }
  expect(
    fixture.root.listSync().where(
      (entity) => entity.path
          .split(Platform.pathSeparator)
          .last
          .startsWith('.android-egress-state.'),
    ),
    isEmpty,
  );
}

Future<_FakeAdbFixture> _createFakeAdbFixture() async {
  final root = Directory.systemTemp.createTempSync('manaloom-fake-adb-');
  final state = Directory('${root.path}/state')..createSync();
  for (final entry in const <String, String>{
    'wifi': '1',
    'data': '1',
    'airplane': '0',
    'accelerometer_rotation': '1',
    'user_rotation': '3',
    'immersive_mode_confirmations': 'immersive',
    'pid': '',
    'reverse': '',
    'markers': '',
  }.entries) {
    File('${state.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final adb = File('${root.path}/adb')
    ..writeAsStringSync(r'''#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_ADB_STATE:?}"
reset_app_pids() {
  if [[ -e "$state/sticky_enabled" ]]; then
    printf '4343' >"$state/pid"
  else
    : >"$state/pid"
  fi
}
if [[ "${1:-}" == "devices" ]]; then
  printf 'List of devices attached\nR58T300SREH device usb:2-1 model:SM_A135M\n'
  exit 0
fi
if [[ "${1:-}" == "-s" ]]; then shift 2; fi
case "${1:-}" in
  get-state) printf 'device\n' ;;
  get-serialno) printf 'R58T300SREH\n' ;;
  reverse)
    case "${2:-}" in
      --list) cat "$state/reverse" ;;
      --remove-all) : >"$state/reverse" ;;
      --remove) sed -i '' "\\#${3:-}#d" "$state/reverse" ;;
      tcp:*) printf 'R58T300SREH %s %s\n' "$2" "$3" >>"$state/reverse" ;;
    esac
    ;;
  logcat)
    trap 'exit 0' TERM INT
    seen=0
    while :; do
      current="$(wc -l <"$state/markers" | tr -d '[:space:]')"
      if [[ "$current" -gt "$seen" ]]; then
        awk -v start="$seen" 'NR > start {print}' "$state/markers"
        seen="$current"
      fi
      sleep 0.05
    done
    ;;
  shell)
    shift
    case "$*" in
      'getprop ro.product.model') printf 'SM-A135M\n' ;;
      'getprop ro.build.version.sdk') printf '34\n' ;;
      'getprop ro.build.version.release') printf '14\n' ;;
      'getprop ro.kernel.qemu'|'getprop ro.boot.qemu') printf '0\n' ;;
      'dumpsys package com.mtgia.mtg_app') printf '  userId=10342\n' ;;
      'settings get global wifi_on') cat "$state/wifi"; printf '\n' ;;
      'settings get global mobile_data') cat "$state/data"; printf '\n' ;;
      'settings get global airplane_mode_on') cat "$state/airplane"; printf '\n' ;;
      'settings list system')
        printf 'accelerometer_rotation=%s\n' "$(<"$state/accelerometer_rotation")"
        printf 'user_rotation=%s\n' "$(<"$state/user_rotation")"
        ;;
      'settings list secure')
        printf 'immersive_mode_confirmations=%s\n' "$(<"$state/immersive_mode_confirmations")"
        ;;
      settings\ put\ system\ accelerometer_rotation\ *)
        printf '%s' "${5:-}" >"$state/accelerometer_rotation"
        ;;
      settings\ put\ system\ user_rotation\ *)
        printf '%s' "${5:-}" >"$state/user_rotation"
        ;;
      settings\ put\ secure\ immersive_mode_confirmations\ *)
        printf '%s' "${5:-}" >"$state/immersive_mode_confirmations"
        ;;
      'settings delete system accelerometer_rotation')
        : >"$state/accelerometer_rotation"
        ;;
      'settings delete system user_rotation') : >"$state/user_rotation" ;;
      'settings delete secure immersive_mode_confirmations')
        : >"$state/immersive_mode_confirmations"
        ;;
      'svc wifi disable')
        printf 0 >"$state/wifi"
        [[ "${FAKE_ADB_FAIL_AFTER_WIFI_DISABLE:-0}" != 1 ]] || exit 73
        ;;
      'svc wifi enable') printf 1 >"$state/wifi" ;;
      'svc data disable') printf 0 >"$state/data" ;;
      'svc data enable') printf 1 >"$state/data" ;;
      'ip -o route show table all')
        if [[ "$(<"$state/wifi")" == 1 || "$(<"$state/data")" == 1 ]]; then
          printf 'default via 192.168.2.1 dev wlan0\n192.168.2.0/24 dev wlan0\n'
        fi
        ;;
      'ip -6 -o route show table all')
        if [[ "$(<"$state/wifi")" == 1 || "$(<"$state/data")" == 1 ]]; then
          printf 'default via fe80::1 dev wlan0\nfe80::/64 dev wlan0\n'
        fi
        ;;
      'dumpsys connectivity')
        if [[ "$(<"$state/wifi")" == 1 || "$(<"$state/data")" == 1 ]]; then
          printf 'NetworkAgentInfo WIFI CONNECTED VALIDATED\n'
        fi
        ;;
      'am force-stop com.mtgia.mtg_app') reset_app_pids ;;
      'cmd jobscheduler cancel -u 0 com.mtgia.mtg_app') : ;;
      'dumpsys jobscheduler') : ;;
      'pm clear com.mtgia.mtg_app') reset_app_pids; printf 'Success\n' ;;
      'pidof com.mtgia.mtg_app') cat "$state/pid"; [[ ! -s "$state/pid" ]] || printf '\n' ;;
      'ps -A -n -o UID,PID,NAME')
        printf 'UID PID NAME\n'
        if [[ -s "$state/pid" ]]; then
          for app_pid in $(<"$state/pid"); do
            app_name='com.mtgia.mtg_app'
            [[ "$app_pid" != 4343 ]] || app_name='com.mtgia.mtg_app:remote'
            printf '10342 %s %s\n' "$app_pid" "$app_name"
          done
        fi
        ;;
      run-as\ com.mtgia.mtg_app\ /system/bin/log\ -t\ ManaLoomEgress\ *)
        marker="${*:6}"
        printf '1700000000.000 10342 4242 4242 I ManaLoomEgress: %s\n' \
          "$marker" >>"$state/markers"
        ;;
      run-as*) exit 0 ;;
      *) printf 'unexpected fake adb command: %s\n' "$*" >&2; exit 64 ;;
    esac
    ;;
  *) printf 'unexpected fake adb argv: %s\n' "$*" >&2; exit 64 ;;
esac
''')
    ..setLastModifiedSync(DateTime.now());
  await Process.run('/bin/chmod', <String>['700', adb.path]);
  return _FakeAdbFixture(root, state, adb);
}
