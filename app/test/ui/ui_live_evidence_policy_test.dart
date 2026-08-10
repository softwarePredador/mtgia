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
    final p0Runtime = File(
      'integration_test/app_existing_user_visual_audit_test.dart',
    ).readAsStringSync();
    expect(p0Runner, contains('android_emulator_manaloom_api34'));
    expect(p0Runner, contains('android_physical_sm_a135m'));
    expect(p0Runner, contains('expected_runtime_kind="physical"'));
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
    expect(p0Runtime, contains('_prepareDeckImportDetectedState(tester)'));
    expect(
      p0Runtime,
      contains('deck_import_detected must visibly retain the imported list'),
    );
    expect(
      p0Runtime,
      contains('the detected-card status must be inside the captured viewport'),
    );
    expect(runtimeContract, contains('manaloom_web_runtime_device_contract'));
    expect(runtimeContract, contains('web_binder_import_mobile_390x844'));
    expect(runtimeContract, contains('web_binder_import_desktop_1440x900'));
    expect(runtimeContract, contains('web_binder_import_wide_1920x1080'));
    expect(runtimeContract, contains('web_deck_workshop_mobile_390x844'));
    expect(runtimeContract, contains('web_deck_workshop_desktop_1440x900'));
    expect(runtimeContract, contains('web_deck_workshop_wide_1920x1080'));
    expect(runtimeContract, contains('web_battle_learning_mobile_390x844'));
    expect(runtimeContract, contains('web_battle_learning_desktop_1440x900'));
    expect(runtimeContract, contains('web_battle_learning_wide_1920x1080'));
    expect(runtimeContract, contains('web_social_trade_mobile_390x844'));
    expect(runtimeContract, contains('web_social_trade_desktop_1440x900'));
    expect(runtimeContract, contains('web_social_trade_wide_1920x1080'));
    expect(runtimeContract, contains('web_onboarding_intent_mobile_390x844'));
    expect(runtimeContract, contains('web_onboarding_intent_desktop_1440x900'));
    expect(runtimeContract, contains('web_onboarding_intent_wide_1920x1080'));
    expect(runtimeContract, contains('web_visual_system_mobile_390x844'));
    expect(runtimeContract, contains('web_visual_system_desktop_1440x900'));
    expect(runtimeContract, contains('web_visual_system_wide_1920x1080'));
    expect(runtimeContract, contains('web_critical_overlays_mobile_390x844'));
    expect(runtimeContract, contains('web_critical_overlays_desktop_1440x900'));
    expect(runtimeContract, contains('web_critical_overlays_wide_1920x1080'));
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
    final binderImportCapture = File(
      '../scripts/manaloom_binder_import_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['binder_import_capture_command'],
      '../scripts/manaloom_binder_import_visual_qa.sh',
    );
    expect(
      binderImportCapture,
      contains('binder_import_visual_runtime_proof_test.dart'),
    );
    expect(binderImportCapture, contains('web_binder_import_mobile_390x844'));
    expect(
      binderImportCapture,
      contains('MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true'),
    );
    final deckWorkshopCapture = File(
      '../scripts/manaloom_deck_workshop_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['deck_workshop_capture_command'],
      '../scripts/manaloom_deck_workshop_visual_qa.sh',
    );
    expect(
      deckWorkshopCapture,
      contains('deck_workshop_visual_runtime_proof_test.dart'),
    );
    expect(deckWorkshopCapture, contains('web_deck_workshop_mobile_390x844'));
    expect(
      deckWorkshopCapture,
      contains('MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true'),
    );
    final battleLearningCapture = File(
      '../scripts/manaloom_battle_learning_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['battle_learning_capture_command'],
      '../scripts/manaloom_battle_learning_visual_qa.sh',
    );
    expect(
      battleLearningCapture,
      contains('battle_learning_visual_runtime_proof_test.dart'),
    );
    expect(
      battleLearningCapture,
      contains('web_battle_learning_mobile_390x844'),
    );
    final socialTradeCapture = File(
      '../scripts/manaloom_social_trade_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['social_trade_capture_command'],
      '../scripts/manaloom_social_trade_visual_qa.sh',
    );
    expect(
      socialTradeCapture,
      contains('social_trade_visual_runtime_proof_test.dart'),
    );
    expect(socialTradeCapture, contains('web_social_trade_mobile_390x844'));
    expect(
      socialTradeCapture,
      contains('MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true'),
    );
    final onboardingIntentCapture = File(
      '../scripts/manaloom_onboarding_intent_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['onboarding_intent_capture_command'],
      '../scripts/manaloom_onboarding_intent_visual_qa.sh',
    );
    expect(
      onboardingIntentCapture,
      contains('onboarding_intent_visual_runtime_proof_test.dart'),
    );
    expect(
      onboardingIntentCapture,
      contains('web_onboarding_intent_mobile_390x844'),
    );
    final visualSystemCapture = File(
      '../scripts/manaloom_visual_system_workspace_qa.sh',
    ).readAsStringSync();
    expect(
      gate['visual_system_workspace_capture_command'],
      '../scripts/manaloom_visual_system_workspace_qa.sh',
    );
    expect(
      visualSystemCapture,
      contains('visual_system_workspace_runtime_proof_test.dart'),
    );
    expect(visualSystemCapture, contains('web_visual_system_mobile_390x844'));
    final criticalOverlaysCapture = File(
      '../scripts/manaloom_critical_overlays_states_visual_qa.sh',
    ).readAsStringSync();
    expect(
      gate['critical_overlays_states_capture_command'],
      '../scripts/manaloom_critical_overlays_states_visual_qa.sh',
    );
    expect(
      criticalOverlaysCapture,
      contains('critical_overlays_states_runtime_proof_test.dart'),
    );
    expect(
      criticalOverlaysCapture,
      contains('web_critical_overlays_mobile_390x844'),
    );
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
    expect(
      digest,
      contains(
        'app/integration_test/binder_import_visual_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/deck_workshop_visual_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/battle_learning_visual_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/social_trade_visual_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/onboarding_intent_visual_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/visual_system_workspace_runtime_proof_test.dart',
      ),
    );
    expect(
      digest,
      contains(
        'app/integration_test/critical_overlays_states_runtime_proof_test.dart',
      ),
    );
    expect(digest, contains('app/test/ui/fixtures/ui_surface_inventory.json'));
    expect(digest, contains('scripts/manaloom_binder_import_visual_qa.sh'));
    expect(digest, contains('scripts/manaloom_deck_workshop_visual_qa.sh'));
    expect(digest, contains('scripts/manaloom_battle_learning_visual_qa.sh'));
    expect(digest, contains('scripts/manaloom_social_trade_visual_qa.sh'));
    expect(digest, contains('scripts/manaloom_onboarding_intent_visual_qa.sh'));
    expect(digest, contains('scripts/manaloom_visual_system_workspace_qa.sh'));
    expect(
      digest,
      contains('scripts/manaloom_critical_overlays_states_visual_qa.sh'),
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
        final sourcePaths = surface['sources'] is List
            ? (surface['sources'] as List).cast<String>()
            : <String>[surface['source'] as String];
        final sources = sourcePaths.map(File.new).toList(growable: false);
        final automated = File(surface['automated_test'] as String);
        final automatedTests = surface['automated_tests'] is List
            ? (surface['automated_tests'] as List).cast<String>()
            : <String>[surface['automated_test'] as String];
        final runtime = File(surface['runtime_test'] as String);
        for (final source in sources) {
          if (!source.existsSync()) {
            findings.add('$id source is missing: ${source.path}');
          }
        }
        if (!automated.existsSync()) {
          findings.add('$id automated test is missing');
        }
        for (final automatedTest in automatedTests) {
          if (!File(automatedTest).existsSync()) {
            findings.add('$id automated test is missing: $automatedTest');
          }
        }
        if (!runtime.existsSync()) {
          findings.add('$id runtime test is missing');
        }
        if (sources.any((source) => !source.existsSync()) ||
            !runtime.existsSync()) {
          continue;
        }

        final sourceText = sources
            .map((source) => source.readAsStringSync())
            .join('\n');
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
      final binderImport = surfaces.singleWhere(
        (surface) => surface['id'] == 'binder_import',
      );
      final deckWorkshop = surfaces.singleWhere(
        (surface) => surface['id'] == 'deck_workshop',
      );
      final battleLearning = surfaces.singleWhere(
        (surface) => surface['id'] == 'battle_learning',
      );
      final socialTrade = surfaces.singleWhere(
        (surface) => surface['id'] == 'social_trade',
      );
      final onboardingIntent = surfaces.singleWhere(
        (surface) => surface['id'] == 'onboarding_intent',
      );
      final visualSystem = surfaces.singleWhere(
        (surface) => surface['id'] == 'visual_system_workspace',
      );
      final criticalOverlays = surfaces.singleWhere(
        (surface) => surface['id'] == 'critical_overlays_states',
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
      expect(binderImport['required_profiles'], <String, dynamic>{
        'web_binder_import_mobile_390x844': 7,
        'web_binder_import_desktop_1440x900': 7,
        'web_binder_import_wide_1920x1080': 7,
      });
      expect(
        (binderImport['required_checkpoints'] as List).cast<String>(),
        <String>[
          'binder_import_00_source',
          'binder_import_01_review_duplicates',
          'binder_import_02_plan',
          'binder_import_03_confirmation',
          'binder_import_04_partial_failure',
          'binder_import_05_retry_success',
          'binder_import_06_history',
        ],
      );
      expect(deckWorkshop['required_profiles'], <String, dynamic>{
        'web_deck_workshop_mobile_390x844': 9,
        'web_deck_workshop_desktop_1440x900': 9,
        'web_deck_workshop_wide_1920x1080': 9,
      });
      expect(
        (deckWorkshop['required_checkpoints'] as List).cast<String>(),
        <String>[
          'deck_workshop_00_commander',
          'deck_workshop_01_import_preflight',
          'deck_workshop_02_sources',
          'deck_workshop_03_paired_swaps',
          'deck_workshop_04_partial_selection',
          'deck_workshop_05_card_reader',
          'deck_workshop_06_history_undo',
          'deck_workshop_07_conflict',
          'deck_workshop_08_sample_hand_continuity',
        ],
      );
      expect(battleLearning['required_profiles'], <String, dynamic>{
        'web_battle_learning_mobile_390x844': 10,
        'web_battle_learning_desktop_1440x900': 10,
        'web_battle_learning_wide_1920x1080': 10,
      });
      expect(
        (battleLearning['required_checkpoints'] as List).cast<String>(),
        <String>[
          'battle_learning_00_play_entry',
          'battle_learning_01_active_session',
          'battle_learning_02_live_table',
          'battle_learning_03_reconnect',
          'battle_learning_04_timeout',
          'battle_learning_05_completed',
          'battle_learning_06_replay_evidence',
          'battle_learning_07_postgame_signals',
          'battle_learning_08_postgame_receipt',
          'battle_learning_09_optimize_evidence',
        ],
      );
      expect(socialTrade['required_profiles'], <String, dynamic>{
        'web_social_trade_mobile_390x844': 16,
        'web_social_trade_desktop_1440x900': 16,
        'web_social_trade_wide_1920x1080': 16,
      });
      expect(
        (socialTrade['required_checkpoints'] as List).cast<String>(),
        <String>[
          'social_trade_00_matches_populated',
          'social_trade_01_marketplace_populated',
          'social_trade_02_marketplace_empty',
          'social_trade_03_trade_create_rehydrated',
          'social_trade_04_trade_create_review',
          'social_trade_05_trade_create_unavailable',
          'social_trade_06_trade_pending_actions',
          'social_trade_07_trade_counter_draft',
          'social_trade_08_trade_declined',
          'social_trade_09_trade_error',
          'social_trade_10_trade_completed',
          'social_trade_11_trade_inbox_empty',
          'social_trade_12_messages_empty',
          'social_trade_13_users_empty_results',
          'social_trade_14_community_context_comment',
          'social_trade_15_matches_empty',
        ],
      );
      expect(onboardingIntent['required_profiles'], <String, dynamic>{
        'web_onboarding_intent_mobile_390x844': 5,
        'web_onboarding_intent_desktop_1440x900': 5,
        'web_onboarding_intent_wide_1920x1080': 5,
      });
      expect(
        (onboardingIntent['required_checkpoints'] as List).cast<String>(),
        <String>[
          'onboarding_intent_00_first_run',
          'onboarding_intent_01_build_path',
          'onboarding_intent_02_resumed_plan',
          'onboarding_intent_03_skipped_home',
          'onboarding_intent_04_completed_home',
        ],
      );
      expect(visualSystem['required_profiles'], <String, dynamic>{
        'web_visual_system_mobile_390x844': 10,
        'web_visual_system_desktop_1440x900': 10,
        'web_visual_system_wide_1920x1080': 10,
      });
      expect(
        (visualSystem['required_checkpoints'] as List).cast<String>(),
        <String>[
          'visual_system_00_profile_clean',
          'visual_system_01_profile_dirty',
          'visual_system_02_profile_saving',
          'visual_system_03_profile_error',
          'visual_system_04_profile_saved',
          'visual_system_05_public_profile',
          'visual_system_06_decks_first_use',
          'visual_system_07_no_results',
          'visual_system_08_offline',
          'visual_system_09_unavailable',
        ],
      );
      expect(criticalOverlays['required_profiles'], <String, dynamic>{
        'web_critical_overlays_mobile_390x844': 22,
        'web_critical_overlays_desktop_1440x900': 22,
        'web_critical_overlays_wide_1920x1080': 22,
      });
      final criticalCheckpoints =
          (criticalOverlays['required_checkpoints'] as List).cast<String>();
      expect(criticalCheckpoints, hasLength(22));
      expect(
        criticalCheckpoints.first,
        'ux_pack08_00_profile_security_below_fold',
      );
      expect(criticalCheckpoints.last, 'ux_pack08_21_permission_denied');
      expect(p0Matrix['required_profiles'], <String, dynamic>{
        'web_mobile_390x844': 54,
        'web_desktop_1440x900': 53,
        'web_wide_1920x1080': 53,
        'android_physical_sm_a135m': 54,
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
      expect(androidRuntime['current_profile'], 'android_physical_sm_a135m');
      final p0Checkpoints = (p0Matrix['required_checkpoints'] as List)
          .cast<String>()
          .toSet();
      expect(p0Checkpoints, hasLength(54));
      expect(p0Checkpoints, contains('decks_empty'));
    },
  );

  test('Pack 08 checkpoints bind state, anchor, flow and mutation safety', () {
    final critical = (policy['surfaces'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((surface) => surface['id'] == 'critical_overlays_states');
    final required = (critical['required_checkpoints'] as List).cast<String>();
    final contracts = (critical['checkpoint_contracts'] as List)
        .cast<Map<String, dynamic>>();
    final contractIds = contracts
        .map((contract) => contract['id'] as String)
        .toList(growable: false);
    expect(contractIds, required);

    const allowedStages = <String>{
      'before',
      'open',
      'intermediate',
      'error',
      'recovered',
      'final',
    };
    const allowedMutationPolicies = <String>{
      'read_only',
      'cancelled',
      'validation_only',
      'intercepted_failure',
      'synthetic_contract_state',
    };
    final runtimeText = File(
      critical['runtime_test'] as String,
    ).readAsStringSync();
    final findings = <String>[];

    for (final contract in contracts) {
      final id = contract['id'] as String;
      final sourcePath = contract['source'] as String;
      final source = File(sourcePath);
      final anchor = contract['anchor'] as String;
      final automatedTests = (contract['automated_tests'] as List)
          .cast<String>();
      if ((contract['domain'] as String).trim().isEmpty ||
          (contract['state'] as String).trim().isEmpty ||
          (contract['flow_id'] as String).trim().isEmpty) {
        findings.add('$id has an empty semantic contract field');
      }
      if (!allowedStages.contains(contract['stage'])) {
        findings.add('$id has unsupported stage ${contract['stage']}');
      }
      if (!allowedMutationPolicies.contains(contract['mutation_policy'])) {
        findings.add(
          '$id has unsafe mutation policy ${contract['mutation_policy']}',
        );
      }
      if (!source.existsSync()) {
        findings.add('$id source is missing: $sourcePath');
        continue;
      }
      if (!source.readAsStringSync().contains(anchor) &&
          !runtimeText.contains(anchor)) {
        findings.add('$id anchor is missing from source and runtime: $anchor');
      }
      if (!runtimeText.contains(id)) {
        findings.add('$id is missing from runtime proof');
      }
      if (automatedTests.isEmpty) {
        findings.add('$id has no automated test');
      }
      for (final testPath in automatedTests) {
        if (!File(testPath).existsSync()) {
          findings.add('$id automated test is missing: $testPath');
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: 'Pack 08 checkpoint contract drift:\n${findings.join('\n')}',
    );
  });

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
