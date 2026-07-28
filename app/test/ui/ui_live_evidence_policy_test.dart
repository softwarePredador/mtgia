import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final policyFile = File('test/ui/fixtures/ui_live_evidence_policy.json');
  final policy =
      jsonDecode(policyFile.readAsStringSync()) as Map<String, dynamic>;

  test('visual pass requires automated, runtime and inspected-image proof', () {
    expect(policy['schema_version'], 'manaloom_ui_live_evidence_policy_v1');
    final status = policy['status_model'] as Map<String, dynamic>;
    expect(status, containsPair('automated', 'PASS_AUTOMATED'));
    expect(status, containsPair('runtime', 'PASS_RUNTIME'));
    expect(status, containsPair('visual_review', 'PASS_VISUAL_REVIEWED'));
    expect(status, containsPair('aggregate', 'PASS'));
    expect(status['aggregate_requires_all_levels'], isTrue);

    final gate = policy['gate'] as Map<String, dynamic>;
    expect(gate['reviewer_must_open_every_screenshot'], isTrue);
    expect(gate['widget_or_golden_alone_can_pass_visual'], isFalse);
    expect(
      File('../scripts/manaloom_ui_source_digest.sh').existsSync(),
      isTrue,
    );
    expect(
      File('../scripts/manaloom_ui_live_evidence_gate.sh').existsSync(),
      isTrue,
    );
    expect(File('../docs/qa/ui-live/latest.json').existsSync(), isTrue);
  });

  test(
    'every live surface binds source, tests, keys and runtime checkpoints',
    () {
      final findings = <String>[];
      final surfaces = (policy['surfaces'] as List)
          .cast<Map<String, dynamic>>();
      expect(surfaces, isNotEmpty);

      for (final surface in surfaces) {
        final id = surface['id'] as String;
        final source = File(surface['source'] as String);
        final automated = File(surface['automated_test'] as String);
        final runtime = File(surface['runtime_test'] as String);
        if (!source.existsSync()) {
          findings.add('$id source is missing');
        }
        if (!automated.existsSync()) {
          findings.add('$id automated test is missing');
        }
        if (!runtime.existsSync()) {
          findings.add('$id runtime test is missing');
        }
        if (!source.existsSync() || !runtime.existsSync()) {
          continue;
        }

        final sourceText = source.readAsStringSync();
        for (final key in (surface['stable_keys'] as List).cast<String>()) {
          if (!sourceText.contains(key)) {
            findings.add('$id source misses key $key');
          }
        }
        final runtimeText = runtime.readAsStringSync();
        for (final checkpoint
            in (surface['required_checkpoints'] as List).cast<String>()) {
          if (!runtimeText.contains(checkpoint)) {
            findings.add('$id runtime test misses checkpoint $checkpoint');
          }
        }
      }

      expect(
        findings,
        isEmpty,
        reason: 'Live UI surface evidence drift:\n${findings.join('\n')}',
      );

      final p0Matrix = surfaces.singleWhere(
        (surface) => surface['id'] == 'authenticated_p0_matrix',
      );
      expect(p0Matrix['required_profiles'], <String, dynamic>{
        'web_mobile_390x844': 54,
        'web_desktop_1440x900': 53,
        'web_wide_1920x1080': 53,
        'android_physical_sm_a135m': 54,
      });
      final p0Checkpoints = (p0Matrix['required_checkpoints'] as List)
          .cast<String>()
          .toSet();
      expect(p0Checkpoints, hasLength(54));
      expect(p0Checkpoints, contains('decks_empty'));
    },
  );

  test('review rubric stays complete and release readers remain separate', () {
    final criteria = (policy['required_review_criteria'] as List)
        .cast<String>()
        .toSet();
    expect(criteria, hasLength(10));
    expect(
      criteria,
      containsAll(<String>{
        'visual_hierarchy',
        'brand_and_mtg_identity',
        'color_and_contrast',
        'typography',
        'spacing_and_density',
        'responsive_fit',
        'interaction_clarity',
        'state_coverage',
        'accessibility_visual',
        'attractiveness',
      }),
    );

    final accessibility =
        policy['release_accessibility'] as Map<String, dynamic>;
    expect(accessibility['android_talkback'], 'pending_physical_human_review');
    expect(
      accessibility['agent_visual_review_does_not_replace_screen_reader'],
      isTrue,
    );
    expect(accessibility['ios_voiceover'], 'DEFERRED_BY_SCOPE');
  });
}
