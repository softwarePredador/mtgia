import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File('test/ui/fixtures/ui_authenticated_visual_matrix.json');
  final matrix = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  test(
    'authenticated visual matrix owns every required platform and state',
    () {
      expect(matrix['schema_version'], 2);
      expect(matrix['status'], 'governed_by_live_evidence');

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

      expect(
        {
          for (final platform in platforms)
            platform['id'] as String: platform['capture_count'] as int,
        },
        <String, int>{
          'web_mobile': 54,
          'web_desktop': 53,
          'web_wide': 53,
          'android_physical': 54,
        },
      );

      final android = platforms.singleWhere(
        (platform) => platform['id'] == 'android_physical',
      );
      expect(android['width'], 384);
      expect(android['height'], 856);
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
        'disabled',
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
    expect(
      (fixture['required_empty_domains'] as List).cast<String>(),
      contains('decks_for_empty_user'),
    );
    expect(
      (fixture['fixture_users'] as Map).cast<String, String>(),
      containsPair(
        'empty_deck_user',
        'owns no deck and exists only for decks_empty',
      ),
    );
    expect(fixture['cleanup'], contains('drop disposable database'));

    final harness = File(
      '../scripts/manaloom_authenticated_visual_qa_isolated.sh',
    ).readAsStringSync();
    expect(harness, contains('MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true'));
    expect(harness, contains('MANALOOM_VISUAL_FIXTURE_MODE=true'));
    expect(harness, contains('resolve_manaloom_flutter_root'));
    expect(harness, contains('MANALOOM_FLUTTER_ROOT_RESOLVED/bin/flutter'));
    expect(
      harness,
      contains('app/assets/assets/branding/visual_fixture_arcane_ring.webp'),
    );
    expect(harness, contains("'S3-07 Visual Fixture Set'"));
    expect(harness, contains("set_code = 'TST'"));
    expect(harness, contains('capture_flow_contains_signup: false'));
    expect(harness, contains('MANALOOM_VISUAL_EMPTY_EMAIL'));
    expect(harness, contains('empty_user_has_decks: false'));

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
      expect(checkpoints, hasLength(54));
      final emptyDeckCheckpoint = checkpoints.singleWhere(
        (checkpoint) => checkpoint['id'] == 'decks_empty',
      );
      expect(emptyDeckCheckpoint['auth'], 'empty_deck_user');
      expect(emptyDeckCheckpoint['anchor'], 'deck-list-empty-state');

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

  test('visual gate binds the complete baseline to live evidence approval', () {
    final gate = matrix['visual_gate'] as Map<String, dynamic>;
    expect(gate['runner'], 'tool/authenticated_visual_diff.dart');
    expect(File(gate['runner'] as String).existsSync(), isTrue);
    expect(gate['baseline_root'], 'test/ui/goldens/runtime');
    expect(gate['failure_root'], 'test/ui/failures/runtime');
    expect(gate['maximum_changed_pixel_ratio'], 0.001);
    expect(gate['required_console_levels'], <String>['warning', 'error']);
    expect(gate['maximum_console_entries'], 0);
    expect(gate['approval_is_owned_by_live_evidence'], isTrue);
    expect(File(gate['live_evidence_review'] as String).existsSync(), isTrue);
    expect(File(gate['source_digest_command'] as String).existsSync(), isTrue);
    expect(gate['baseline_files'], 214);
    expect(gate['required_profile_counts'], <String, dynamic>{
      'web_mobile': 54,
      'web_desktop': 53,
      'web_wide': 53,
      'android_physical': 54,
    });

    final checkpointIds = (matrix['checkpoints'] as List)
        .cast<Map<String, dynamic>>()
        .map((checkpoint) => checkpoint['id'] as String)
        .toSet();
    final baseline = Directory(gate['baseline_root'] as String);
    final expectedByProfile = <String, Set<String>>{
      'web_mobile': checkpointIds,
      'web_desktop': checkpointIds.difference({'home_quick_actions_scrolled'}),
      'web_wide': checkpointIds.difference({'home_quick_actions_scrolled'}),
      'android_physical': checkpointIds,
    };
    for (final entry in expectedByProfile.entries) {
      final profileDirectory = Directory('${baseline.path}/${entry.key}');
      expect(profileDirectory.existsSync(), isTrue);
      final actualNames = profileDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .map((file) => file.uri.pathSegments.last.replaceFirst('.png', ''))
          .toSet();
      expect(actualNames, entry.value, reason: entry.key);
    }
  });
}
