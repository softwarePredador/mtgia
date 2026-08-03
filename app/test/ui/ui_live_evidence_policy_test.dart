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
    final p0Runner = File(
      '../scripts/manaloom_p0_runtime_capture.sh',
    ).readAsStringSync();
    final liveGate = File(
      '../scripts/manaloom_ui_live_evidence_gate.sh',
    ).readAsStringSync();
    final runtimeContract = File(
      '../scripts/lib/manaloom_ui_runtime_contract.sh',
    ).readAsStringSync();
    expect(p0Runner, contains('android_emulator_manaloom_api34'));
    expect(p0Runner, contains('NATIVE_SCREENSHOT_READY'));
    expect(p0Runner, contains('ADB_SCREENSHOT_CAPTURED'));
    expect(p0Runner, contains('MANALOOM_CHROMEDRIVER_BIN'));
    expect(p0Runner, contains('ChromeDriver major'));
    expect(p0Runner, contains('chromedriver_pid'));
    expect(p0Runner, contains('VISUAL_PROOF_CONTEXT'));
    expect(p0Runner, contains('required_checkpoints'));
    expect(p0Runner, contains('runtime-without-context.log'));
    expect(p0Runner, contains("sed '/VISUAL_PROOF_CONTEXT /d'"));
    expect(p0Runner, contains('manaloom_ui_runtime_contract.sh'));
    expect(liveGate, contains('manaloom_ui_runtime_contract.sh'));
    expect(runtimeContract, contains('manaloom_web_runtime_device_contract'));
    expect(
      runtimeContract,
      contains('manaloom_android_runtime_device_contract'),
    );
    expect(runtimeContract, contains(r'display $display_size'));
    expect(p0Runner, contains('--profile'));
    expect(p0Runner, contains('--ready-manifest'));
    expect(
      gate['p0_capture_command'],
      contains('manaloom_p0_runtime_capture.sh'),
    );
    expect(
      gate['battle_live_capture_command'],
      '../scripts/manaloom_ui_live_evidence_gate.sh '
      '--capture-battle-live-web',
    );
    expect(liveGate, contains('--capture-battle-live-web'));
    expect(liveGate, contains('battle_live_visual_runtime_proof_test.dart'));
    expect(liveGate, contains('web_battle_live_1440x900'));
    expect(File('../docs/qa/ui-live/latest.json').existsSync(), isTrue);

    final crop = gate['web_host_margin_crop'] as Map<String, dynamic>;
    expect(crop['strategy'], 'crop_only_symmetric_near_white_host_margins');
    expect(crop['keeps_full_surface_when_uncertain'], isTrue);
    final driver = File('test_driver/integration_test.dart').readAsStringSync();
    final digest = File(
      '../scripts/manaloom_ui_source_digest.sh',
    ).readAsStringSync();
    expect(driver, contains("import 'runtime_screenshot_crop.dart';"));
    expect(driver, contains('SCREENSHOT_VIEWPORT_CROP'));
    expect(
      File('test_driver/runtime_screenshot_crop.dart').existsSync(),
      isTrue,
    );
    expect(digest, contains('app/test_driver/runtime_screenshot_crop.dart'));
    expect(
      digest,
      contains(
        'app/integration_test/battle_live_visual_runtime_proof_test.dart',
      ),
    );
    expect(digest, contains('scripts/manaloom_p0_runtime_capture.sh'));
    expect(digest, contains('scripts/lib/manaloom_ui_runtime_contract.sh'));
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
      final battleLive = surfaces.singleWhere(
        (surface) => surface['id'] == 'battle_live',
      );
      expect(battleLive['required_profiles'], <String, dynamic>{
        'web_battle_live_1440x900': 5,
      });
      expect(
        (battleLive['required_checkpoints'] as List).cast<String>(),
        <String>[
          'battle_live_00_waiting',
          'battle_live_01_active_feed',
          'battle_live_02_recoverable_reconnect',
          'battle_live_03_timeout_terminal',
          'battle_live_04_completed_replay',
        ],
      );
      expect(
        (battleLive['stable_keys'] as List).cast<String>().toSet(),
        containsAll(<String>{
          'battle-live-progress',
          'battle-live-table',
          'battle-live-timeline',
          'battle-live-reconnect-banner',
          'battle-live-terminal-state',
          'battle-live-new-attempt-button',
          'battle-live-open-replay-button',
        }),
      );
      expect(p0Matrix['required_profiles'], <String, dynamic>{
        'web_mobile_390x844': 54,
        'web_desktop_1440x900': 53,
        'web_wide_1920x1080': 53,
        'android_emulator_manaloom_api34': 54,
      });
      final androidRuntime =
          p0Matrix['android_runtime_contract'] as Map<String, dynamic>;
      expect((androidRuntime['accepted_targets'] as List).toSet(), {
        'android_emulator',
        'android_physical',
      });
      expect(androidRuntime['must_be_attested_from_adb'], isTrue);
      expect(
        androidRuntime['emulator_must_not_be_reported_as_physical'],
        isTrue,
      );
      expect(
        androidRuntime['current_profile'],
        'android_emulator_manaloom_api34',
      );
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
    expect(accessibility['android_hardware_smoke'], 'pending_physical_device');
    expect(
      accessibility['emulator_runtime_is_valid_for_current_scope'],
      isTrue,
    );
    expect(
      accessibility['agent_visual_review_does_not_replace_screen_reader'],
      isTrue,
    );
    expect(accessibility['ios_voiceover'], 'DEFERRED_BY_SCOPE');
  });
}
