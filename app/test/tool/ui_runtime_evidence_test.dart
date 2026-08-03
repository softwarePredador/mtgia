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
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'battle_coach', 'source_digest': _digest, 'profile': 'android_phone', 'runtime': 'flutter_integration_test', 'target': 'android_physical', 'device_contract': 'physical_android', 'required_checkpoints': requiredCheckpoints})}',
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
