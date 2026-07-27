import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/ui_runtime_evidence.dart';

const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('manaloom-ui-evidence-');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('extracts complete PNG checkpoints and binds them to source digest', () {
    final png = img.encodePng(img.Image(width: 4, height: 6));
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

  test('rejects missing checkpoints instead of accepting partial proof', () {
    final png = img.encodePng(img.Image(width: 2, height: 2));
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
    final png = img.encodePng(img.Image(width: 2, height: 2));
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
    final png = img.encodePng(img.Image(width: 5, height: 7));
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
