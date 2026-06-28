# ManaLoom Log Learning Audit

- generated_at: `2026-06-28T19:22:03Z`
- reports_dir: `docs/hermes-analysis/master_optimizer_reports`
- files_scanned: `7653`
- issue_count: `2287`
- superseded_issue_count: `6`
- postgres_writes: `False`
- source_db_mutated: `False`

## Severity Counts

- critical: `127`
- high: `1300`
- low: `2`
- medium: `858`

## Category Counts

- battle_rhythm_gap: `5`
- battle_runtime_quality: `16`
- blocked_workflow: `90`
- evidence_gap: `10`
- log_quality_gap: `2`
- postgres_sync_gap: `2`
- runtime_or_test_failure: `269`
- runtime_rule_gap: `569`
- xmage_mapping_gap: `1324`

## Action Queue

1. `critical` `runtime_rule_gap` `coherence_critical_high_findings` count=565 next=`prioritize_cards_with_no_active_or_no_trusted_rules_in_current_deck_scope`
   - coherence audit has critical=1, high=392 [docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_current_explicit_20260628_123905.json]
     top_lorehold_cards: `Chrome Mox, Lion's Eye Diamond, Apex of Power, Volcanic Vision, Dance with Calamity`
     top_lorehold_runtime_missing: `Planetarium of Wan Shi Tong, Invincible Hymn, Heroes Remembered, Boros Reckoner, Beacon of Immortality`
     top_lorehold_runtime_waived_pending_pg: `Verge Rangers, Twinflame Tyrant, Terror of the Peaks, Goliath Daydreamer, Taunt from the Rampart`
     top_finding_codes: `review_only_or_needs_review_rule=214, no_active_battle_rule=173, no_trusted_executable_rule=97, generic_effect_without_model_scope=59, missing_oracle_identity=1`
   - coherence audit has critical=1, high=340 [docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_postsync_v1_combined_coherence.json]
     top_lorehold_cards: `Chrome Mox, Lion's Eye Diamond, Apex of Power, Volcanic Vision, Penance`
     top_lorehold_runtime_missing: `Penance, Planetarium of Wan Shi Tong, Magmakin Artillerist, Invincible Hymn, Heroes Remembered`
     top_lorehold_runtime_waived_pending_pg: `Verge Rangers, Twinflame Tyrant, Goliath Daydreamer, Terror of the Peaks, Taunt from the Rampart`
     top_finding_codes: `review_only_or_needs_review_rule=180, no_active_battle_rule=155, no_trusted_executable_rule=77, generic_effect_without_model_scope=53, missing_oracle_identity=1`
2. `critical` `runtime_or_test_failure` `text_runtime_traceback` count=8 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains runtime_traceback [docs/hermes-analysis/master_optimizer_reports/slot_optimizer_pg231_velomachus_runtime_v1_stderr.txt]
   - text log contains runtime_traceback [docs/hermes-analysis/master_optimizer_reports/pg107_commit_ready_sync_pg_selection_test_20260623.out]
3. `critical` `runtime_or_test_failure` `top_level_status` count=7 next=`inspect_failure_and_add_focused_regression_test`
   - report status is fail [docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg242_magmakin_presync_v1.json]
   - report status is fail [docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg241_penance_presync_v1.json]
4. `critical` `postgres_sync_gap` `top_level_status` count=1 next=`resolve_pg_connectivity_or_apply_state_before_claiming_sync`
   - report status is postgres_unreachable_pg_isready_no_response [docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_precheck_probe_20260628_103331.json]
5. `critical` `postgres_sync_gap` `top_level_status` count=1 next=`resolve_pg_connectivity_or_apply_state_before_claiming_sync`
   - report status is postgres_precheck_blocked_connection_closed [docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_precheck_blocked.json]
6. `high` `xmage_mapping_gap` `missing_xmage_source_or_class` count=733 next=`isolate_cards_without_local_xmage_source_and_keep_them_out_of_auto_mapper_batch`
   - XMage mapping blockers: missing_source=4, missing_class=0 [docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg242_magmakin_postsync_v1.json]
   - XMage mapping blockers: missing_source=4, missing_class=4 [docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg242_magmakin_postsync_v1_manifest.json]
7. `high` `blocked_workflow` `text_blocked` count=87 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.md]
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.md]
8. `high` `battle_runtime_quality` `text_timeout` count=14 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains timeout [docs/hermes-analysis/master_optimizer_reports/lorehold_learning_evidence_ledger_20260628_v1.md]
   - text log contains timeout [docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_candidate_exposure_profile_20260627_v1.md]
9. `high` `blocked_workflow` `top_level_status` count=3 next=`resolve_blocker_or_remove_from_active_queue`
   - report status is blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_smoke.json]
   - report status is blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_best_deck_review_snapshot_20260620_174509.json]
10. `high` `runtime_rule_gap` `squee_graveyard_anomaly` count=2 next=`fix_squee_zone_accounting_before_using_recursion_results`
   - synergy_ghostly_prison_pressure_cut_promise has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_winota_gate_20260628_v1_20260628_073000_ghostly_prison_pressure_cut_promise.json]
   - synergy_ghostly_prison_pressure_cut_promise has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_champion_gate_20260628_v1_20260628_072510_ghostly_prison_pressure_cut_promise.json]
11. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
12. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Mana Vault [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_deck607_replay_20260628.json]
13. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is needs_more_evidence [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.json]
14. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is inconclusive_candidate_unobserved [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
15. `high` `runtime_rule_gap` `squee_graveyard_anomaly` count=1 next=`fix_squee_zone_accounting_before_using_recursion_results`
   - synergy_overmaster_protect_draw_cut_tibalts_trickery has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v2_smoke_opp8_20260627_215233_overmaster_protect_draw_cut_tibalts_trickery.json]
16. `high` `runtime_rule_gap` `squee_graveyard_anomaly` count=1 next=`fix_squee_zone_accounting_before_using_recursion_results`
   - synergy_brainstone_topdeck_miracle has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout_brainstone_topdeck_miracle.json]
17. `medium` `xmage_mapping_gap` `manual_or_blocked_rules` count=591 next=`group_manual_rows_by_effect_family_and_create_mapper_or_runtime_family_test`
   - XMage pipeline still has 53 manual or blocked rows [docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v18_boros_pg_candidate.json]
   - XMage pipeline still has 53 manual or blocked rows [docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v17_boros_runtime_families.json]
18. `medium` `runtime_or_test_failure` `text_warning` count=249 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.md]
   - text log contains warning [docs/hermes-analysis/master_optimizer_reports/pgc006_formidable_speaker_annotation_only_executor_guard_package.md]
19. `medium` `battle_rhythm_gap` `prior_rhythm_flags` count=3 next=`calibrate_or_quarantine_gate_metrics_before_treating_winrate_as_strategy_signal`
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
20. `medium` `evidence_gap` `focus_card_library_only` count=2 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: The Mind Stone [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
   - focus card traced but not accessed: The Mind Stone [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
21. `medium` `runtime_or_test_failure` `gate_row_status` count=2 next=`inspect_gate_row_error_and_add_or_fix_runtime_test`
   - candidate_607_reprieve_v1 row status is executed [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_reprieve_v1.json]
   - candidate_607_reprieve_v1 row status is blocked_tbd_swap [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_smoke.json]
22. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.json]
23. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is battle_prior_warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
24. `medium` `battle_runtime_quality` `stalled_games` count=1 next=`rerun_with_checkpoint_trace_and_fix_loop_or_decision_dead_end`
   - synergy_core_challenge_past_over_tragic has 1 stalled games [docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v2_seed7_smoke_opp8_20260627_215812_core_challenge_past_over_tragic.json]
25. `medium` `battle_runtime_quality` `stalled_games` count=1 next=`rerun_with_checkpoint_trace_and_fix_loop_or_decision_dead_end`
   - candidate_v7 has 1 stalled games [docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_finalists_20260626_v1.json]
26. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
27. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Library of Leng [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
28. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Jeska's Will [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
29. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Squee, Goblin Nabob [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
30. `medium` `runtime_or_test_failure` `gate_row_status` count=1 next=`inspect_gate_row_error_and_add_or_fix_runtime_test`
   - candidate_607_guttersnipe_v1 row status is executed [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_guttersnipe_v1.json]
31. `medium` `runtime_or_test_failure` `gate_row_status` count=1 next=`inspect_gate_row_error_and_add_or_fix_runtime_test`
   - candidate_607_ghostly_prison_v1 row status is executed [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_ghostly_prison_v1.json]
32. `medium` `runtime_or_test_failure` `gate_row_status` count=1 next=`inspect_gate_row_error_and_add_or_fix_runtime_test`
   - candidate_607_galvanoth_v1 row status is executed [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_galvanoth_v1.json]
33. `low` `log_quality_gap` `json_extra_data` count=2 next=`normalize_artifact_writer_to_emit_single_json_document`
   - JSON parsed with warning: extra_json_after_first_object [docs/hermes-analysis/master_optimizer_reports/local_battle_replay_pg114_emerias_call_20260623_200501/summary_20260623_201031.json]
   - JSON parsed with warning: extra_json_after_first_object [docs/hermes-analysis/master_optimizer_reports/local_battle_replay_deck6_pg108_pg109_pg110_post_sync_20260623/summary_20260623_185610.json]
