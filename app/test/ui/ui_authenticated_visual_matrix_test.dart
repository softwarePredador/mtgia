import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File('test/ui/fixtures/ui_authenticated_visual_matrix.json');
  final matrix = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  test(
    'authenticated visual matrix owns every required platform and state',
    () {
      expect(matrix['schema_version'], 1);
      expect(matrix['status'], anyOf('in_progress', 'pass'));

      final platforms = (matrix['platforms'] as List)
          .cast<Map<String, dynamic>>();
      final platformIds = platforms
          .map((platform) => platform['id'] as String)
          .toSet();
      expect(
        platformIds,
        containsAll(<String>{
          'web_mobile',
          'web_desktop',
          'web_wide',
          'android_physical',
        }),
      );
      expect(
        platforms.where((platform) => platform['kind'] == 'web_real_build'),
        hasLength(3),
      );
      expect(
        platforms.where(
          (platform) => platform['kind'] == 'android_physical_profile',
        ),
        hasLength(1),
      );

      for (final platform in platforms) {
        expect(platform['capture_count'], 20);
        expect(platform['human_review'], 'approved');
      }

      final android = platforms.singleWhere(
        (platform) => platform['id'] == 'android_physical',
      );
      expect(android['capture_width'], 1080);
      expect(android['capture_height'], 2408);
      expect(android['device_contract'], contains('SM-A135M'));
      expect(android['runner_constraint'], contains('kDebugMode=false'));

      final requiredStates = (matrix['required_states'] as List).cast<String>();
      expect(requiredStates.toSet(), <String>{
        'success',
        'empty',
        'error',
        'modal',
        'above_fold',
        'below_fold',
      });
      final coveredStates = (matrix['checkpoints'] as List)
          .cast<Map<String, dynamic>>()
          .expand((checkpoint) => (checkpoint['states'] as List).cast<String>())
          .toSet();
      expect(coveredStates, containsAll(requiredStates));
    },
  );

  test('capture fixture is disposable, seeded and production-safe', () {
    expect(
      File(
        '../scripts/manaloom_authenticated_visual_qa_isolated.sh',
      ).existsSync(),
      isTrue,
    );
    final fixture = matrix['fixture'] as Map<String, dynamic>;
    expect(fixture['scope'], 'disposable_loopback_postgresql_api');
    expect(fixture['seed_transport'], 'authenticated_local_api');
    expect(fixture['capture_flow_contains_signup'], isFalse);
    expect(fixture['production_coordinates_allowed'], isFalse);
    expect(
      (fixture['required_entities'] as List).cast<String>(),
      containsAll(<String>['user', 'card', 'deck']),
    );
    expect(fixture['cleanup'], contains('drop disposable database'));

    final harness = File(
      '../scripts/manaloom_authenticated_visual_qa_isolated.sh',
    ).readAsStringSync();
    expect(harness, contains('MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true'));
    expect(harness, contains('MANALOOM_VISUAL_FIXTURE_MODE=true'));
    expect(harness, contains('app/assets/assets/symbols/logo.png'));
    expect(harness, contains("'S3-07 Visual Fixture Set'"));
    expect(harness, contains("set_code = 'TST'"));
    expect(harness, contains('capture_flow_contains_signup: false'));

    final backendHarness = File(
      '../scripts/manaloom_server_contract_e2e_isolated.sh',
    ).readAsStringSync();
    expect(backendHarness, contains('exec dart build/bin/server.dart'));
  });

  test(
    'every visual checkpoint has a live source, route and stable anchor',
    () {
      final checkpoints = (matrix['checkpoints'] as List)
          .cast<Map<String, dynamic>>();
      final ids = checkpoints
          .map((checkpoint) => checkpoint['id'] as String)
          .toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(checkpoints.length, greaterThanOrEqualTo(20));

      final findings = <String>[];
      for (final checkpoint in checkpoints) {
        final id = checkpoint['id'] as String;
        final route = checkpoint['route']?.toString() ?? '';
        final anchor = checkpoint['anchor']?.toString() ?? '';
        final sourcePath = checkpoint['source']?.toString() ?? '';
        if (!route.startsWith('/')) findings.add('$id has invalid route');
        if (anchor.isEmpty) findings.add('$id has no anchor');

        final source = File(sourcePath);
        if (!source.existsSync()) {
          findings.add('$id missing source $sourcePath');
        } else if (!source.readAsStringSync().contains(anchor)) {
          findings.add('$id missing anchor $anchor in $sourcePath');
        }
      }

      expect(
        findings,
        isEmpty,
        reason:
            'Visual checkpoints must stay bound to current UI:\n'
            '${findings.join('\n')}',
      );
    },
  );

  test(
    'visual gate requires pixel diff, console cleanliness and human review',
    () {
      final gate = matrix['visual_gate'] as Map<String, dynamic>;
      expect(gate['runner'], 'tool/authenticated_visual_diff.dart');
      expect(File(gate['runner'] as String).existsSync(), isTrue);
      expect(gate['baseline_root'], 'test/ui/goldens/runtime');
      expect(gate['failure_root'], 'test/ui/failures/runtime');
      expect(gate['maximum_changed_pixel_ratio'], 0.001);
      expect(gate['required_console_levels'], <String>['warning', 'error']);
      expect(gate['maximum_console_entries'], 0);
      expect(gate['human_review'], anyOf('pending', 'approved'));

      if (matrix['status'] == 'pass') {
        expect(gate['human_review'], 'approved');
        expect(
          gate['approved_build_sha256'],
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
        expect(
          gate['approved_capture_manifest_sha256'],
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
        expect(gate['baseline_files'], 80);

        final diff = gate['pixel_diff'] as Map<String, dynamic>;
        expect(diff['status'], 'pass');
        expect(diff['passed_files'], 80);
        expect(diff['failed_files'], 0);
        expect(diff['maximum_observed_changed_pixel_ratio'], 0.0);

        final console = gate['web_console_observation'] as Map<String, dynamic>;
        expect(console['warning_or_error_entries'], 0);

        final android = gate['android_run'] as Map<String, dynamic>;
        expect(android['mode'], 'profile');
        expect(android['result'], 'pass');
        expect(android['tests_passed'], greaterThan(0));
        expect(android['adb_reverse_after_run'], 0);

        final baseline = Directory(gate['baseline_root'] as String);
        final baselineFiles = baseline
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'))
            .toList();
        expect(baselineFiles, hasLength(80));
      }
    },
  );
}
