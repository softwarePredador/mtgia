import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/ui_runtime_evidence.dart';

const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

List<int> _proofPng(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if ((x + y).isEven) {
        image.setPixelRgba(x, y, 15, 17, 21, 255);
      } else {
        image.setPixelRgba(x, y, 220, 160, 35, 255);
      }
    }
  }
  return img.encodePng(image);
}

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('manaloom-ui-evidence-');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('extracts complete PNG checkpoints and binds them to source digest', () {
    final png = _proofPng(4, 6);
    final log = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        _runtimeLog(<String, List<int>>{
          'battle_coach_00_welcome': png,
          'battle_coach_01_active': png,
        }),
      );

    final result = extractUiRuntimeEvidence(
      logFile: log,
      repoRoot: temp,
      outputRelativePath: 'docs/qa/ui-live/current/battle-coach-android',
      expectedSourceDigest: _digest,
      generatedAt: DateTime.utc(2026, 7, 27, 18),
    );

    expect(result.manifest['status'], 'PASS_RUNTIME');
    expect(result.manifest['source_digest'], _digest);
    expect(result.manifest['checkpoint_count'], 2);
    expect(result.manifestFile.existsSync(), isTrue);
    final screenshots = (result.manifest['screenshots'] as List).cast<Map>();
    expect(screenshots.map((entry) => entry['width']), everyElement(4));
    expect(screenshots.map((entry) => entry['height']), everyElement(6));
  });

  test('indexes screenshot directories from a real runtime log', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/web_mobile',
    )..createSync(recursive: true);
    final png = _proofPng(390, 844);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final log = File('${temp.path}/web-mobile.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'web_mobile_390x844',
          target: 'web_real_build',
          deviceContract: 'Chrome 150',
          checkpoints: const ['login_empty'],
        ),
      );

    final result = indexUiRuntimeScreenshotDirectory(
      screenshotDirectory: screenshotDirectory,
      runtimeLog: log,
      repoRoot: temp,
      manifestRelativePath: 'docs/qa/ui-live/current/p0-matrix/web-mobile.json',
      expectedSourceDigest: _digest,
      surface: 'authenticated_p0_matrix',
      profile: 'web_mobile_390x844',
      runtime: 'flutter_drive',
      target: 'web_real_build',
      deviceContract: 'Chrome 150',
      generatedAt: DateTime.utc(2026, 7, 27, 18),
    );

    expect(result.manifest['checkpoint_count'], 1);
    expect(result.manifest['profile'], 'web_mobile_390x844');
    final screenshots = (result.manifest['screenshots'] as List).cast<Map>();
    expect(screenshots.single['checkpoint'], 'login_empty');
    expect(
      screenshots.single['path'],
      'app/test/ui/goldens/runtime/web_mobile/login_empty.png',
    );
  });

  test('rejects visually blank screenshots before runtime credit', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_emulator',
    )..createSync(recursive: true);
    File(
      '${screenshotDirectory.path}/life_counter_initial.png',
    ).writeAsBytesSync(img.encodePng(img.Image(width: 1080, height: 2400)));

    expect(
      () => validateRuntimeScreenshotDirectory(screenshotDirectory),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains('visually blank or uniform'),
        ),
      ),
    );
  });

  test('rejects an otherwise uniform screenshot with one outlier pixel', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_emulator',
    )..createSync(recursive: true);
    final image = img.Image(width: 1080, height: 2400);
    img.fill(image, color: img.ColorRgb8(15, 17, 21));
    image.setPixelRgba(1079, 2399, 220, 160, 35, 255);
    File(
      '${screenshotDirectory.path}/life_counter_initial.png',
    ).writeAsBytesSync(img.encodePng(image));

    expect(
      () => validateRuntimeScreenshotDirectory(screenshotDirectory),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains('visually blank or uniform'),
        ),
      ),
    );
  });

  test('rejects stale directory evidence instead of relabeling its digest', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/web_mobile',
    )..createSync(recursive: true);
    final png = _proofPng(390, 844);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final log = File('${temp.path}/web-mobile.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'web_mobile_390x844',
          target: 'web_real_build',
          deviceContract: 'Chrome real Web build',
          checkpoints: const ['login_empty'],
          sourceDigest:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
      );

    expect(
      () => indexUiRuntimeScreenshotDirectory(
        screenshotDirectory: screenshotDirectory,
        runtimeLog: log,
        repoRoot: temp,
        manifestRelativePath:
            'docs/qa/ui-live/current/p0-matrix/web-mobile.json',
        expectedSourceDigest: _digest,
        surface: 'authenticated_p0_matrix',
        profile: 'web_mobile_390x844',
        runtime: 'flutter_drive',
        target: 'web_real_build',
        deviceContract: 'Chrome real Web build',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('rejects an Android target that contradicts its device contract', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_emulator',
    )..createSync(recursive: true);
    final png = _proofPng(1080, 2400);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final log = File('${temp.path}/android.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'android_emulator_manaloom_api34',
          target: 'android_physical',
          deviceContract: 'Pixel 6, Android 14, emulator runtime',
          checkpoints: const ['login_empty'],
        ),
      );

    expect(
      () => indexUiRuntimeScreenshotDirectory(
        screenshotDirectory: screenshotDirectory,
        runtimeLog: log,
        repoRoot: temp,
        manifestRelativePath: 'docs/qa/ui-live/current/p0-matrix/android.json',
        expectedSourceDigest: _digest,
        surface: 'authenticated_p0_matrix',
        profile: 'android_emulator_manaloom_api34',
        runtime: 'flutter_drive',
        target: 'android_physical',
        deviceContract: 'Pixel 6, Android 14, emulator runtime',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('rejects an emulator target for a physical Android profile', () {
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_physical',
    )..createSync(recursive: true);
    final png = _proofPng(1080, 2408);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final log = File('${temp.path}/android-physical.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'android_physical_sm_a135m',
          target: 'android_emulator',
          deviceContract: 'SM-A135M, Android 14, physical runtime',
          checkpoints: const ['login_empty'],
        ),
      );

    expect(
      () => indexUiRuntimeScreenshotDirectory(
        screenshotDirectory: screenshotDirectory,
        runtimeLog: log,
        repoRoot: temp,
        manifestRelativePath:
            'docs/qa/ui-live/current/p0-matrix/android-physical.json',
        expectedSourceDigest: _digest,
        surface: 'authenticated_p0_matrix',
        profile: 'android_physical_sm_a135m',
        runtime: 'flutter_drive',
        target: 'android_emulator',
        deviceContract: 'SM-A135M, Android 14, physical runtime',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('rejects missing checkpoints instead of accepting partial proof', () {
    final png = _proofPng(2, 2);
    final log = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        _runtimeLog(
          <String, List<int>>{'battle_coach_00_welcome': png},
          required: const ['battle_coach_00_welcome', 'battle_coach_01_active'],
        ),
      );

    expect(
      () => extractUiRuntimeEvidence(
        logFile: log,
        repoRoot: temp,
        outputRelativePath: 'docs/qa/ui-live/current/battle-coach-android',
        expectedSourceDigest: _digest,
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('rejects runtime image failures even when screenshots exist', () {
    final png = _proofPng(2, 2);
    final log = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        '${_runtimeLog(<String, List<int>>{'battle_coach_00_welcome': png})}[🖼️ CachedCardImage] falha ao carregar fixture\n',
      );

    expect(
      () => extractUiRuntimeEvidence(
        logFile: log,
        repoRoot: temp,
        outputRelativePath: 'docs/qa/ui-live/current/battle-coach-android',
        expectedSourceDigest: _digest,
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('R10 native DataTransport request is a reproducible egress failure', () {
    final assessment = assessAndroidNetworkEgress(
      '08-27 13:25:00.000 25921 25999 I TRuntime.CctTransportBackend: '
      'Making request to: '
      'https://firebaselogging-pa.googleapis.com/v1/firelog/legacy/batchlog\n'
      '08-27 13:25:00.200 25921 25999 I TRuntime.CctTransportBackend: '
      'Status Code: 200\n',
    );

    expect(assessment.isClean, isFalse);
    expect(
      assessment.findings.join('\n'),
      contains('firebaselogging-pa.googleapis.com'),
    );
  });

  test('Android egress detector accepts only exact loopback attempts', () {
    final clean = assessAndroidNetworkEgress(
      'Making request to: http://127.0.0.1:8080/api/ready\n'
      'SocketException: connection refused, host=::1\n'
      'Making request to: http://localhost:9090/app/\n',
    );
    final deniedDns = assessAndroidNetworkEgress(
      'UnknownHostException: Unable to resolve host '
      '"firebaselogging-pa.googleapis.com"\n',
    );

    expect(clean.isClean, isTrue);
    expect(clean.loopbackAttempts, 3);
    expect(deniedDns.isClean, isFalse);
  });

  test('seals and verifies a same-run physical Android egress receipt', () {
    const runId = 'android-egress-test-pass-0001';
    final policy = _writeAndroidPolicy(temp);
    final runtime = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        'Making request to: http://127.0.0.1:8080/api/ready\n',
      );
    final native = File('${temp.path}/native.log')
      ..writeAsStringSync(
        _androidNativeWindow(
          runId,
          body:
              '1700000000.100 10342 4242 4243 I ManaLoomRuntime: '
              'Making request to: http://localhost:9090/app/\n',
        ),
      );
    final support = _writeAndroidEgressSupport(temp, runId);
    final receipt = File('${temp.path}/receipt.json')
      ..writeAsStringSync(
        jsonEncode(_androidReceiptCandidate(temp, runId, native, support)),
      );

    final sealed = sealAndroidEgressReceipt(
      receiptFile: receipt,
      runtimeLog: runtime,
      nativeLog: native,
      pidTrace: support['pidTrace']!,
      policyFile: policy,
      expectedRunId: runId,
      expectedSourceDigest: _digest,
      expectedProfile: 'android_physical_sm_a135m',
      expectedTarget: 'android_physical',
    );
    final verified = verifyAndroidEgressReceipt(
      receiptFile: receipt,
      runtimeLog: runtime,
      policyFile: policy,
      expectedRunId: runId,
      expectedSourceDigest: _digest,
      expectedProfile: 'android_physical_sm_a135m',
      expectedTarget: 'android_physical',
    );

    expect(sealed.receipt['status'], 'PASS_ANDROID_EGRESS');
    expect(verified.receiptSha256, sealed.receiptSha256);
    expect((verified.receipt['network_egress'] as Map)['loopback_attempts'], 2);
  });

  test('external attempt seals FAIL and forged or cross-run receipt fails', () {
    const runId = 'android-egress-test-fail-0001';
    final policy = _writeAndroidPolicy(temp);
    final runtime = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        'TRuntime.CctTransportBackend: Making request to: '
        'https://firebaselogging-pa.googleapis.com/v1/firelog\n',
      );
    final native = File('${temp.path}/native.log')
      ..writeAsStringSync(_androidNativeWindow(runId));
    final support = _writeAndroidEgressSupport(temp, runId);
    final receipt = File('${temp.path}/receipt.json')
      ..writeAsStringSync(
        jsonEncode(_androidReceiptCandidate(temp, runId, native, support)),
      );

    expect(
      () => sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: native,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
    expect(
      (jsonDecode(receipt.readAsStringSync()) as Map)['status'],
      'FAIL_ANDROID_EGRESS',
    );
    expect(
      () => verifyAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        policyFile: policy,
        expectedRunId: 'android-egress-other-run-0002',
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test(
    'stale egress before BEGIN is excluded but an in-window R10 event fails',
    () {
      const cleanRunId = 'android-egress-window-clean-0001';
      final policy = _writeAndroidPolicy(temp);
      final runtime = File('${temp.path}/runtime.log')
        ..writeAsStringSync('ok\n');
      final staleNative = File('${temp.path}/native.log')
        ..writeAsStringSync(
          '1699999999.000 10342 9999 9999 I TRuntime.CctTransportBackend: '
          'Making request to: https://firebaselogging-pa.googleapis.com/v1/log\n'
          '${_androidNativeWindow(cleanRunId)}',
        );
      final support = _writeAndroidEgressSupport(temp, cleanRunId);
      final receipt = File('${temp.path}/receipt.json')
        ..writeAsStringSync(
          jsonEncode(
            _androidReceiptCandidate(temp, cleanRunId, staleNative, support),
          ),
        );

      final sealed = sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: staleNative,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: cleanRunId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      );
      expect(sealed.receipt['status'], 'PASS_ANDROID_EGRESS');

      const failRunId = 'android-egress-window-fail-0002';
      final second = Directory('${temp.path}/second')..createSync();
      final secondPolicy = _writeAndroidPolicy(second);
      final secondRuntime = File('${second.path}/runtime.log')
        ..writeAsStringSync('ok\n');
      final offensiveNative = File('${second.path}/native.log')
        ..writeAsStringSync(
          _androidNativeWindow(
            failRunId,
            body:
                '1700000000.100 10342 4242 4243 I '
                'TRuntime.CctTransportBackend: Making request to: '
                'https://firebaselogging-pa.googleapis.com/v1/log\n',
          ),
        );
      final secondSupport = _writeAndroidEgressSupport(second, failRunId);
      final secondReceipt = File('${second.path}/receipt.json')
        ..writeAsStringSync(
          jsonEncode(
            _androidReceiptCandidate(
              second,
              failRunId,
              offensiveNative,
              secondSupport,
            ),
          ),
        );
      expect(
        () => sealAndroidEgressReceipt(
          receiptFile: secondReceipt,
          runtimeLog: secondRuntime,
          nativeLog: offensiveNative,
          pidTrace: secondSupport['pidTrace']!,
          policyFile: secondPolicy,
          expectedRunId: failRunId,
          expectedSourceDigest: _digest,
          expectedProfile: 'android_physical_sm_a135m',
          expectedTarget: 'android_physical',
        ),
        throwsA(isA<UiRuntimeEvidenceException>()),
      );
      expect(
        (jsonDecode(secondReceipt.readAsStringSync()) as Map)['status'],
        'FAIL_ANDROID_EGRESS',
      );
    },
  );

  test('v1, duplicate markers and incomplete PID traces are ineligible', () {
    const runId = 'android-egress-v2-negative-0001';
    final policy = _writeAndroidPolicy(temp);
    final runtime = File('${temp.path}/runtime.log')..writeAsStringSync('ok\n');
    final native = File('${temp.path}/native.log')
      ..writeAsStringSync(
        '${_androidNativeWindow(runId)}${_androidNativeWindow(runId)}',
      );
    final support = _writeAndroidEgressSupport(temp, runId);
    final candidate = _androidReceiptCandidate(temp, runId, native, support);
    candidate['schema_version'] = 'manaloom.android_ui_egress_receipt.v1';
    final receipt = File('${temp.path}/receipt.json')
      ..writeAsStringSync(jsonEncode(candidate));

    expect(
      () => sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: native,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );

    candidate['schema_version'] = 'manaloom.android_ui_egress_receipt.v2';
    receipt.writeAsStringSync(jsonEncode(candidate));
    expect(
      () => sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: native,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );

    final singleNative = File('${temp.path}/single-native.log')
      ..writeAsStringSync(_androidNativeWindow(runId));
    (candidate['artifacts'] as Map<String, Object>)['native_log_path'] =
        singleNative.absolute.path;
    support['pidTrace']!.writeAsStringSync(
      'sample\tcontinuous\t1700000000\t10342\t4242\t'
      'com.mtgia.mtg_app\t$runId\n',
    );
    receipt.writeAsStringSync(jsonEncode(candidate));
    expect(
      () => sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: singleNative,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );

    support['pidTrace']!.writeAsStringSync(
      _writeAndroidEgressSupport(temp, runId)['pidTrace']!
          .readAsStringSync()
          .replaceAll(runId, 'android-egress-foreign-run-0002'),
    );
    receipt.writeAsStringSync(jsonEncode(candidate));
    expect(
      () => sealAndroidEgressReceipt(
        receiptFile: receipt,
        runtimeLog: runtime,
        nativeLog: singleNative,
        pidTrace: support['pidTrace']!,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('missing, malformed and symlink egress receipts fail closed', () {
    const runId = 'android-egress-test-invalid-0001';
    final policy = _writeAndroidPolicy(temp);
    final runtime = File('${temp.path}/runtime.log')..writeAsStringSync('ok\n');
    final missing = File('${temp.path}/missing.json');

    expect(
      () => verifyAndroidEgressReceipt(
        receiptFile: missing,
        runtimeLog: runtime,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );

    final malformed = File('${temp.path}/malformed.json')
      ..writeAsStringSync('{');
    expect(
      () => verifyAndroidEgressReceipt(
        receiptFile: malformed,
        runtimeLog: runtime,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );

    final target = File('${temp.path}/target.json')..writeAsStringSync('{}');
    final link = Link('${temp.path}/receipt-link.json')
      ..createSync(target.path);
    expect(
      () => verifyAndroidEgressReceipt(
        receiptFile: File(link.path),
        runtimeLog: runtime,
        policyFile: policy,
        expectedRunId: runId,
        expectedSourceDigest: _digest,
        expectedProfile: 'android_physical_sm_a135m',
        expectedTarget: 'android_physical',
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });

  test('aggregate rejects a forged physical Android receipt summary', () {
    const runId = 'android-egress-aggregate-0001';
    final policy = _writeAndroidPolicy(temp);
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_physical',
    )..createSync(recursive: true);
    final png = _proofPng(8, 10);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final runtime = File('${temp.path}/android-physical.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'android_physical_sm_a135m',
          target: 'android_physical',
          deviceContract: 'Samsung SM-A135M Android 14 physical USB device',
          checkpoints: const ['login_empty'],
        ),
      );
    final native = File('${temp.path}/android-physical-native.log')
      ..writeAsStringSync(_androidNativeWindow(runId));
    final support = _writeAndroidEgressSupport(temp, runId);
    final receipt = File('${temp.path}/android-physical-receipt.json')
      ..writeAsStringSync(
        jsonEncode(_androidReceiptCandidate(temp, runId, native, support)),
      );
    sealAndroidEgressReceipt(
      receiptFile: receipt,
      runtimeLog: runtime,
      nativeLog: native,
      pidTrace: support['pidTrace']!,
      policyFile: policy,
      expectedRunId: runId,
      expectedSourceDigest: _digest,
      expectedProfile: 'android_physical_sm_a135m',
      expectedTarget: 'android_physical',
    );
    final extraction = indexUiRuntimeScreenshotDirectory(
      screenshotDirectory: screenshotDirectory,
      runtimeLog: runtime,
      repoRoot: temp,
      manifestRelativePath:
          'docs/qa/ui-live/current/p0-matrix/android_physical.json',
      expectedSourceDigest: _digest,
      surface: 'authenticated_p0_matrix',
      profile: 'android_physical_sm_a135m',
      runtime: 'flutter_drive',
      target: 'android_physical',
      deviceContract: 'Samsung SM-A135M Android 14 physical USB device',
      androidEgressReceipt: receipt,
      androidEgressRunId: runId,
      generatedAt: DateTime.utc(2026, 8, 28, 12),
    );
    final manifest = extraction.manifest;
    final screenshots = (manifest['screenshots'] as List).cast<Map>();
    final review = File('${temp.path}/docs/qa/ui-live/latest.json');

    void writeReview() {
      review.parent.createSync(recursive: true);
      final manifestHash = sha256
          .convert(extraction.manifestFile.readAsBytesSync())
          .toString();
      review.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, Object>{
          'schema_version': 'manaloom_ui_live_review_v1',
          'status': 'PASS',
          'source_digest': _digest,
          'automated': <String, Object>{
            'status': 'PASS_AUTOMATED',
            'verified_at': '2026-08-28T12:00:00Z',
            'commands': <String>['flutter test'],
          },
          'runtime': <String, Object>{
            'status': 'PASS_RUNTIME',
            'capture_manifest': <String, Object>{
              'path':
                  'docs/qa/ui-live/current/p0-matrix/'
                  'android_physical.json',
              'sha256': manifestHash,
            },
          },
          'visual_review': <String, Object>{
            'status': 'PASS_VISUAL_REVIEWED',
            'reviewed_at': '2026-08-28T12:05:00Z',
            'reviewer': <String, String>{'kind': 'agent', 'name': 'Codex'},
            'visual_thesis': 'Physical Android proof.',
            'content_plan': 'Identity, state, action and recovery.',
            'interaction_thesis': 'The next action remains explicit.',
            'criteria': <String, Object>{
              for (final criterion in uiLiveEvidenceCriteria)
                criterion: <String, String>{
                  'status': 'pass',
                  'note': 'Inspected and coherent.',
                },
            },
            'reviewed_checkpoints': screenshots
                .map((entry) => entry['checkpoint']!)
                .toList(),
            'reviewed_screenshot_sha256': screenshots
                .map((entry) => entry['sha256']!)
                .toList(),
            'blocking_findings': const <String>[],
          },
        }),
      );
    }

    writeReview();
    expect(
      verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ).screenshotCount,
      1,
    );

    final forged =
        jsonDecode(extraction.manifestFile.readAsStringSync())
            as Map<String, dynamic>;
    final egress = forged['android_network_egress'] as Map<String, dynamic>;
    egress['receipt_schema'] = 'manaloom.android_ui_egress_receipt.v1';
    egress['uid'] = 0;
    egress['observed_pids'] = <int>[4242, 4242];
    extraction.manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(forged)}\n',
    );
    writeReview();
    expect(
      () => verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains(
            'physical Android capture lacks a clean bound egress receipt',
          ),
        ),
      ),
    );
  });

  test('verifies all three evidence levels and every reviewed screenshot', () {
    final png = _proofPng(5, 7);
    final log = File('${temp.path}/runtime.log')
      ..writeAsStringSync(
        _runtimeLog(<String, List<int>>{
          'battle_coach_00_welcome': png,
          'battle_coach_01_active': png,
        }),
      );
    final extraction = extractUiRuntimeEvidence(
      logFile: log,
      repoRoot: temp,
      outputRelativePath: 'docs/qa/ui-live/current/battle-coach-android',
      expectedSourceDigest: _digest,
      generatedAt: DateTime.utc(2026, 7, 27, 18),
    );
    final manifestBytes = extraction.manifestFile.readAsBytesSync();
    final screenshots = (extraction.manifest['screenshots'] as List)
        .cast<Map<String, Object>>();
    final review = File('${temp.path}/docs/qa/ui-live/latest.json');
    review.parent.createSync(recursive: true);
    review.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_review_v1',
        'status': 'PASS',
        'source_digest': _digest,
        'automated': {
          'status': 'PASS_AUTOMATED',
          'verified_at': '2026-07-27T18:00:00Z',
          'commands': ['flutter test test/features/battle'],
        },
        'runtime': {
          'status': 'PASS_RUNTIME',
          'capture_manifest': {
            'path':
                'docs/qa/ui-live/current/battle-coach-android/'
                'capture-manifest.json',
            'sha256': sha256.convert(manifestBytes).toString(),
          },
        },
        'visual_review': {
          'status': 'PASS_VISUAL_REVIEWED',
          'reviewed_at': '2026-07-27T18:05:00Z',
          'reviewer': {'kind': 'agent', 'name': 'Codex'},
          'visual_thesis': 'Obsidian table with brass priority.',
          'content_plan': 'Status, board, decision, outcome.',
          'interaction_thesis': 'Priority makes the next action explicit.',
          'criteria': {
            for (final criterion in uiLiveEvidenceCriteria)
              criterion: {'status': 'pass', 'note': 'Inspected and coherent.'},
          },
          'reviewed_checkpoints': screenshots
              .map((entry) => entry['checkpoint']!)
              .toList(),
          'reviewed_screenshot_sha256': screenshots
              .map((entry) => entry['sha256']!)
              .toList(),
          'blocking_findings': const <String>[],
        },
      }),
    );
    final verification = verifyUiLiveEvidence(
      reviewFile: review,
      repoRoot: temp,
      expectedSourceDigest: _digest,
    );

    expect(verification.screenshotCount, 2);
    expect(verification.surface, 'battle_coach');
    expect(verification.toJson()['evidence_levels'], <String>[
      'PASS_AUTOMATED',
      'PASS_RUNTIME',
      'PASS_VISUAL_REVIEWED',
    ]);
  });

  test('verifies multiple runtime profiles through their manifest hashes', () {
    final png = _proofPng(8, 10);
    final references = <Map<String, Object>>[];
    for (final profile in const ['web_mobile', 'android_emulator']) {
      final screenshotDirectory = Directory(
        '${temp.path}/app/test/ui/goldens/runtime/$profile',
      )..createSync(recursive: true);
      File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
      final log = File('${temp.path}/$profile.log')
        ..writeAsStringSync(
          _directoryRuntimeLog(
            profile: profile,
            target: profile == 'android_emulator'
                ? 'android_emulator'
                : 'web_real_build',
            deviceContract: profile == 'android_emulator'
                ? 'Pixel 6, Android 14, emulator runtime'
                : 'Chrome real Web build',
            checkpoints: const ['login_empty'],
          ),
        );
      final extraction = indexUiRuntimeScreenshotDirectory(
        screenshotDirectory: screenshotDirectory,
        runtimeLog: log,
        repoRoot: temp,
        manifestRelativePath: 'docs/qa/ui-live/current/p0-matrix/$profile.json',
        expectedSourceDigest: _digest,
        surface: 'authenticated_p0_matrix',
        profile: profile,
        runtime: 'flutter_drive',
        target: profile == 'android_emulator'
            ? 'android_emulator'
            : 'web_real_build',
        deviceContract: profile == 'android_emulator'
            ? 'Pixel 6, Android 14, emulator runtime'
            : 'Chrome real Web build',
        generatedAt: DateTime.utc(2026, 7, 27, 18),
      );
      references.add(<String, Object>{
        'path':
            'docs/qa/ui-live/current/p0-matrix/'
            '$profile.json',
        'sha256': sha256
            .convert(extraction.manifestFile.readAsBytesSync())
            .toString(),
      });
    }

    final review = File('${temp.path}/docs/qa/ui-live/latest.json');
    review.parent.createSync(recursive: true);
    review.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_review_v1',
        'status': 'PASS',
        'source_digest': _digest,
        'automated': {
          'status': 'PASS_AUTOMATED',
          'verified_at': '2026-07-27T18:00:00Z',
          'commands': ['flutter test'],
        },
        'runtime': {'status': 'PASS_RUNTIME', 'capture_manifests': references},
        'visual_review': {
          'status': 'PASS_VISUAL_REVIEWED',
          'reviewed_at': '2026-07-27T18:05:00Z',
          'reviewer': {'kind': 'agent', 'name': 'Codex'},
          'visual_thesis': 'One coherent product across target surfaces.',
          'content_plan': 'Context, state, action and recovery.',
          'interaction_thesis': 'The next action remains explicit.',
          'criteria': {
            for (final criterion in uiLiveEvidenceCriteria)
              criterion: {'status': 'pass', 'note': 'Inspected and coherent.'},
          },
          'reviewed_capture_manifest_sha256': references
              .map((reference) => reference['sha256']!)
              .toList(),
          'reviewed_profiles': const ['web_mobile', 'android_emulator'],
          'reviewed_screenshot_count': 2,
          'blocking_findings': const <String>[],
        },
      }),
    );
    final policy = File(
      '${temp.path}/app/test/ui/fixtures/ui_live_evidence_policy.json',
    );
    policy.parent.createSync(recursive: true);
    policy.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_evidence_policy_v1',
        'surfaces': [
          {
            'id': 'authenticated_p0_matrix',
            'required_profiles': {'web_mobile': 1, 'android_emulator': 1},
            'android_runtime_contract': {
              'accepted_targets': ['android_emulator', 'android_physical'],
              'emulator_must_not_be_reported_as_physical': true,
              'current_profile': 'android_emulator',
            },
          },
        ],
      }),
    );

    final verification = verifyUiLiveEvidence(
      reviewFile: review,
      repoRoot: temp,
      expectedSourceDigest: _digest,
    );

    expect(verification.screenshotCount, 2);
    expect(verification.surface, 'authenticated_p0_matrix');

    policy.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_evidence_policy_v1',
        'surfaces': [
          {
            'id': 'authenticated_p0_matrix',
            'required_profiles': {
              'web_mobile': 1,
              'web_desktop': 1,
              'android_emulator': 1,
            },
            'android_runtime_contract': {
              'accepted_targets': ['android_emulator'],
              'emulator_must_not_be_reported_as_physical': true,
              'current_profile': 'android_emulator',
            },
          },
        ],
      }),
    );
    expect(
      () => verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains('web_desktop must contain exactly 1 screenshots'),
        ),
      ),
    );

    policy.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_evidence_policy_v1',
        'surfaces': [
          {
            'id': 'authenticated_p0_matrix',
            'required_profiles': {'web_mobile': 1, 'android_emulator': 1},
            'android_runtime_contract': {
              'accepted_targets': ['android_emulator'],
              'emulator_must_not_be_reported_as_physical': true,
              'current_profile': 'android_emulator',
            },
          },
          {
            'id': 'battle_live',
            'required_profiles': {'web_battle_live_1440x900': 5},
          },
        ],
      }),
    );
    expect(
      () => verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains(
            'web_battle_live_1440x900 must contain exactly 5 screenshots',
          ),
        ),
      ),
    );
  });

  test('rejects physical release credit backed only by emulator captures', () {
    final png = _proofPng(8, 10);
    final screenshotDirectory = Directory(
      '${temp.path}/app/test/ui/goldens/runtime/android_emulator',
    )..createSync(recursive: true);
    File('${screenshotDirectory.path}/login_empty.png').writeAsBytesSync(png);
    final log = File('${temp.path}/android.log')
      ..writeAsStringSync(
        _directoryRuntimeLog(
          profile: 'android_emulator',
          target: 'android_emulator',
          deviceContract: 'Pixel 6, Android 14, emulator runtime',
          checkpoints: const ['login_empty'],
        ),
      );
    final extraction = indexUiRuntimeScreenshotDirectory(
      screenshotDirectory: screenshotDirectory,
      runtimeLog: log,
      repoRoot: temp,
      manifestRelativePath:
          'docs/qa/ui-live/current/p0-matrix/android_emulator.json',
      expectedSourceDigest: _digest,
      surface: 'authenticated_p0_matrix',
      profile: 'android_emulator',
      runtime: 'flutter_drive',
      target: 'android_emulator',
      deviceContract: 'Pixel 6, Android 14, emulator runtime',
      generatedAt: DateTime.utc(2026, 7, 27, 18),
    );
    final manifestHash = sha256
        .convert(extraction.manifestFile.readAsBytesSync())
        .toString();
    final review = File('${temp.path}/docs/qa/ui-live/latest.json');
    review.parent.createSync(recursive: true);
    review.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_review_v1',
        'status': 'PASS',
        'source_digest': _digest,
        'automated': {
          'status': 'PASS_AUTOMATED',
          'verified_at': '2026-07-27T18:00:00Z',
          'commands': ['flutter test'],
        },
        'runtime': {
          'status': 'PASS_RUNTIME',
          'capture_manifest': {
            'path':
                'docs/qa/ui-live/current/p0-matrix/'
                'android_emulator.json',
            'sha256': manifestHash,
          },
        },
        'visual_review': {
          'status': 'PASS_VISUAL_REVIEWED',
          'reviewed_at': '2026-07-27T18:05:00Z',
          'reviewer': {'kind': 'agent', 'name': 'Codex'},
          'visual_thesis': 'Coherent emulator runtime.',
          'content_plan': 'One representative state.',
          'interaction_thesis': 'The action remains explicit.',
          'criteria': {
            for (final criterion in uiLiveEvidenceCriteria)
              criterion: {'status': 'pass', 'note': 'Inspected.'},
          },
          'reviewed_checkpoints': ['login_empty'],
          'reviewed_screenshot_sha256': [
            (extraction.manifest['screenshots'] as List)
                .cast<Map>()
                .single['sha256'],
          ],
          'blocking_findings': const <String>[],
        },
        'release_checks': {
          'battle_coach_android_physical': 'pass_current_digest',
        },
      }),
    );
    final policy = File(
      '${temp.path}/app/test/ui/fixtures/ui_live_evidence_policy.json',
    );
    policy.parent.createSync(recursive: true);
    policy.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 'manaloom_ui_live_evidence_policy_v1',
        'surfaces': [
          {
            'id': 'authenticated_p0_matrix',
            'required_profiles': {'android_emulator': 1},
            'android_runtime_contract': {
              'accepted_targets': ['android_emulator', 'android_physical'],
              'emulator_must_not_be_reported_as_physical': true,
              'current_profile': 'android_emulator',
            },
          },
        ],
      }),
    );

    expect(
      () => verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ),
      throwsA(
        isA<UiRuntimeEvidenceException>().having(
          (error) => error.message,
          'message',
          contains('without a physical capture'),
        ),
      ),
    );
  });

  test('rejects a review whose inspected hashes do not cover the capture', () {
    final review = File('${temp.path}/review.json')
      ..writeAsStringSync(
        jsonEncode(<String, Object>{
          'schema_version': 'manaloom_ui_live_review_v1',
          'status': 'PASS',
          'source_digest': _digest,
        }),
      );

    expect(
      () => verifyUiLiveEvidence(
        reviewFile: review,
        repoRoot: temp,
        expectedSourceDigest: _digest,
      ),
      throwsA(isA<UiRuntimeEvidenceException>()),
    );
  });
}

String _runtimeLog(
  Map<String, List<int>> screenshots, {
  List<String>? required,
}) {
  final requiredCheckpoints = required ?? screenshots.keys.toList();
  final lines = <String>[
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'battle_coach', 'source_digest': _digest, 'profile': 'android_emulator', 'runtime': 'flutter_integration_test', 'target': 'android_emulator', 'device_contract': 'android emulator runtime', 'required_checkpoints': requiredCheckpoints})}',
  ];
  for (final entry in screenshots.entries) {
    final encoded = base64Encode(entry.value);
    lines
      ..add('SCREENSHOT_BEGIN ${entry.key}')
      ..add('SCREENSHOT_CHUNK ${entry.key} $encoded')
      ..add('SCREENSHOT_END ${entry.key}');
  }
  return '${lines.join('\n')}\n';
}

String _directoryRuntimeLog({
  required String profile,
  required String target,
  required String deviceContract,
  required List<String> checkpoints,
  String sourceDigest = _digest,
}) {
  final context = <String, Object>{
    'schema_version': 'manaloom_ui_runtime_context_v1',
    'surface': 'authenticated_p0_matrix',
    'source_digest': sourceDigest,
    'profile': profile,
    'runtime': 'flutter_drive',
    'target': target,
    'device_contract': deviceContract,
    'required_checkpoints': checkpoints,
  };
  return 'VISUAL_PROOF_CONTEXT ${jsonEncode(context)}\nAll tests passed.\n';
}

File _writeAndroidPolicy(Directory root) {
  final policy = File(
    '${root.path}/app/test/ui/fixtures/ui_live_evidence_policy.json',
  );
  policy.parent.createSync(recursive: true);
  policy.writeAsStringSync(
    jsonEncode(<String, Object>{
      'schema_version': 'manaloom_ui_live_evidence_policy_v1',
      'android_physical_egress': {
        'receipt_schema': 'manaloom.android_ui_egress_receipt.v2',
        'package': 'com.mtgia.mtg_app',
        'allowed_loopback_hosts': ['127.0.0.1', 'localhost', '::1'],
      },
      'surfaces': <Object>[
        <String, Object>{
          'id': 'authenticated_p0_matrix',
          'required_profiles': <String, int>{'android_physical_sm_a135m': 1},
          'android_runtime_contract': <String, Object>{
            'accepted_targets': <String>['android_physical'],
            'emulator_must_not_be_reported_as_physical': true,
            'current_profile': 'android_physical_sm_a135m',
          },
        },
      ],
    }),
  );
  return policy;
}

Map<String, Object> _androidReceiptCandidate(
  Directory runRoot,
  String runId,
  File nativeLog,
  Map<String, File> support,
) => <String, Object>{
  'schema_version': 'manaloom.android_ui_egress_receipt.v2',
  'status': 'PENDING_DERIVED_ASSESSMENT',
  'run_id': runId,
  'run_root': runRoot.resolveSymbolicLinksSync(),
  'source_digest': _digest,
  'profile': 'android_physical_sm_a135m',
  'target': 'android_physical',
  'identity': <String, Object>{
    'serial': 'R58T300SREH',
    'model': 'SM-A135M',
    'api': 34,
    'package': 'com.mtgia.mtg_app',
    'uid': 10342,
    'sampled_pids': <int>[4242, 4243],
    'logged_pids': <int>[],
    'observed_pids': <int>[],
  },
  'detector': const <String, Object>{
    'temporal_anchor': '-T 1',
    'log_format': 'epoch_uid',
    'logcat_started_before_begin': true,
    'begin_marker_count': 1,
    'end_marker_count': 1,
    'begin_before_child': true,
    'end_after_force_stop_and_drain': true,
    'sampler_started_before_launch': true,
    'sampler_failures': 0,
    'samples_before_launch': 1,
    'samples_during_journey': 2,
    'drain_samples': 6,
    'consecutive_zero_samples_before_end': 3,
    'consecutive_zero_samples_after_end': 3,
    'all_uid_pids_enumerated': true,
  },
  'app_data': const <String, Object>{
    'pre_launch_clean': true,
    'post_run_clean': true,
    'datatransport_store_absent': true,
  },
  'network': const <String, Object>{
    'snapshot_complete': true,
    'isolation_confirmed': true,
    'adb_usb_preserved': true,
    'reverse_loopback_only': true,
    'restored_exactly': true,
    'api_port': 58001,
    'web_port': 58002,
  },
  'presentation': <String, Object>{
    'snapshot_complete': true,
    'rotation_and_immersive_restored_exactly': true,
    'before_sha256': sha256
        .convert(support['stateBefore']!.readAsBytesSync())
        .toString(),
    'isolated_sha256': sha256
        .convert(support['stateIsolated']!.readAsBytesSync())
        .toString(),
    'restored_sha256': sha256
        .convert(support['stateAfter']!.readAsBytesSync())
        .toString(),
  },
  'cleanup': const <String, Object>{
    'app_processes': 0,
    'sampler_processes': 0,
    'logcat_processes': 0,
    'external_routes': 0,
    'restore_failures': 0,
    'guard_processes': 0,
    'state_dir_absent': true,
  },
  'artifacts': <String, Object>{
    'native_log_path': nativeLog.absolute.path,
    'pid_trace_path': support['pidTrace']!.absolute.path,
    'state_before_path': support['stateBefore']!.absolute.path,
    'state_isolated_path': support['stateIsolated']!.absolute.path,
    'state_after_path': support['stateAfter']!.absolute.path,
  },
};

String _androidNativeWindow(String runId, {String body = ''}) =>
    '1700000000.000 10342 4242 4242 I ManaLoomEgress: '
    'MANALOOM_ANDROID_EGRESS_BEGIN run_id=$runId uid=10342\n'
    '$body'
    '1700000001.000 10342 4243 4243 I ManaLoomEgress: '
    'MANALOOM_ANDROID_EGRESS_END run_id=$runId uid=10342\n';

Map<String, File> _writeAndroidEgressSupport(Directory root, String runId) {
  final pidTrace = File('${root.path}/pids.tsv')
    ..writeAsStringSync(
      'empty\tpre_launch\t1700000000\t10342\t0\t-\t$runId\n'
      'sample\tcontinuous\t1700000000\t10342\t4242\t'
      'com.mtgia.mtg_app\t$runId\n'
      'sample\tcontinuous\t1700000000\t10342\t4243\t'
      'com.mtgia.mtg_app:remote\t$runId\n'
      'empty\tdrain_before_end\t1700000001\t10342\t0\t-\t$runId\n'
      'empty\tdrain_before_end\t1700000001\t10342\t0\t-\t$runId\n'
      'empty\tdrain_before_end\t1700000001\t10342\t0\t-\t$runId\n'
      'empty\tdrain_after_end\t1700000002\t10342\t0\t-\t$runId\n'
      'empty\tdrain_after_end\t1700000002\t10342\t0\t-\t$runId\n'
      'empty\tdrain_after_end\t1700000002\t10342\t0\t-\t$runId\n',
    );
  final restored =
      '${jsonEncode(<String, Object>{
        'network': <String, Object>{
          'wifi_on': '1',
          'mobile_data': '1',
          'airplane_mode_on': '0',
          'reverse_sha256': sha256.convert(const <int>[]).toString(),
          'routes4_sha256': sha256.convert(utf8.encode('default via 192.168.2.1 dev wlan0\n')).toString(),
          'routes6_sha256': sha256.convert(utf8.encode('default via fe80::1 dev wlan0\n')).toString(),
          'connectivity_sha256': sha256.convert(utf8.encode('cellular_connected=0\nvpn_connected=0\nwifi_connected=1\n')).toString(),
          'adb_reverse': <String>[],
          'routes4': <String>['default via 192.168.2.1 dev wlan0'],
          'routes6': <String>['default via fe80::1 dev wlan0'],
          'connectivity': <String>['cellular_connected=0', 'vpn_connected=0', 'wifi_connected=1'],
        },
        'presentation': <String, Object>{
          'accelerometer_rotation': <String, Object>{'present': true, 'value': '1'},
          'user_rotation': <String, Object>{'present': true, 'value': '3'},
          'immersive_mode_confirmations': <String, Object>{'present': true, 'value': 'immersive'},
        },
      })}\n';
  final stateBefore = File('${root.path}/state-before.json')
    ..writeAsStringSync(restored);
  final stateIsolated = File('${root.path}/state-isolated.json')
    ..writeAsStringSync(
      '${jsonEncode(<String, Object>{
        'network': <String, Object>{
          'wifi_on': '0',
          'mobile_data': '0',
          'airplane_mode_on': '0',
          'reverse_sha256': sha256.convert(utf8.encode('R58T300SREH tcp:58001 tcp:58001\nR58T300SREH tcp:58002 tcp:58002\n')).toString(),
          'routes4_sha256': sha256.convert(const <int>[]).toString(),
          'routes6_sha256': sha256.convert(const <int>[]).toString(),
          'connectivity_sha256': sha256.convert(utf8.encode('cellular_connected=0\nvpn_connected=0\nwifi_connected=0\n')).toString(),
          'adb_reverse': <String>['R58T300SREH tcp:58001 tcp:58001', 'R58T300SREH tcp:58002 tcp:58002'],
          'routes4': <String>[],
          'routes6': <String>[],
          'connectivity': <String>['cellular_connected=0', 'vpn_connected=0', 'wifi_connected=0'],
        },
        'presentation': <String, Object>{
          'accelerometer_rotation': <String, Object>{'present': true, 'value': '0'},
          'user_rotation': <String, Object>{'present': true, 'value': '0'},
          'immersive_mode_confirmations': <String, Object>{'present': true, 'value': 'confirmed'},
        },
      })}\n',
    );
  final stateAfter = File('${root.path}/state-after.json')
    ..writeAsStringSync(restored);
  return <String, File>{
    'pidTrace': pidTrace,
    'stateBefore': stateBefore,
    'stateIsolated': stateIsolated,
    'stateAfter': stateAfter,
  };
}
