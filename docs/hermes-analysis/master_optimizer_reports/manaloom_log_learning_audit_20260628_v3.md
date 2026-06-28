# ManaLoom Log Learning Audit

- generated_at: `2026-06-28T18:16:00Z`
- reports_dir: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports`
- files_scanned: `900`
- issue_count: `158`
- superseded_issue_count: `2`
- postgres_writes: `False`
- source_db_mutated: `False`

## Severity Counts

- critical: `2`
- high: `117`
- medium: `39`

## Category Counts

- battle_rhythm_gap: `5`
- battle_runtime_quality: `1`
- blocked_workflow: `68`
- evidence_gap: `10`
- postgres_sync_gap: `1`
- runtime_or_test_failure: `6`
- runtime_rule_gap: `45`
- xmage_mapping_gap: `22`

## Action Queue

1. `critical` `runtime_rule_gap` `coherence_critical_high_findings` count=43 next=`prioritize_cards_with_no_active_or_no_trusted_rules_in_current_deck_scope`
   - coherence audit has critical=0, high=379 [docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pgc023_finale_post_20260628_152000.json]
   - coherence audit has critical=0, high=379 [docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_pgc023_finale_post_20260628_151100.json]
2. `critical` `postgres_sync_gap` `top_level_status` count=1 next=`resolve_pg_connectivity_or_apply_state_before_claiming_sync`
   - report status is postgres_unreachable_pg_isready_no_response [docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_precheck_probe_20260628_103331.json]
3. `high` `blocked_workflow` `text_blocked` count=68 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.md]
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.md]
4. `high` `runtime_rule_gap` `squee_graveyard_anomaly` count=2 next=`fix_squee_zone_accounting_before_using_recursion_results`
   - synergy_ghostly_prison_pressure_cut_promise has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_winota_gate_20260628_v1_20260628_073000_ghostly_prison_pressure_cut_promise.json]
   - synergy_ghostly_prison_pressure_cut_promise has 1 Squee graveyard anomalies [docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_champion_gate_20260628_v1_20260628_072510_ghostly_prison_pressure_cut_promise.json]
5. `high` `battle_runtime_quality` `text_timeout` count=1 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains timeout [docs/hermes-analysis/master_optimizer_reports/lorehold_learning_evidence_ledger_20260628_v1.md]
6. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
7. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Mana Vault [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_deck607_replay_20260628.json]
8. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is needs_more_evidence [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.json]
9. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is inconclusive_candidate_unobserved [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
10. `medium` `xmage_mapping_gap` `manual_or_blocked_rules` count=22 next=`group_manual_rows_by_effect_family_and_create_mapper_or_runtime_family_test`
   - XMage pipeline still has 53 manual or blocked rows [docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v18_boros_pg_candidate.json]
   - XMage pipeline still has 53 manual or blocked rows [docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v17_boros_runtime_families.json]
11. `medium` `runtime_or_test_failure` `text_warning` count=6 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.md]
   - text log contains warning [docs/hermes-analysis/master_optimizer_reports/pgc006_formidable_speaker_annotation_only_executor_guard_package.md]
12. `medium` `battle_rhythm_gap` `prior_rhythm_flags` count=3 next=`calibrate_or_quarantine_gate_metrics_before_treating_winrate_as_strategy_signal`
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
13. `medium` `evidence_gap` `focus_card_library_only` count=2 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: The Mind Stone [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
   - focus card traced but not accessed: The Mind Stone [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
14. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.json]
15. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is battle_prior_warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
16. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
17. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Library of Leng [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
18. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Jeska's Will [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
19. `medium` `evidence_gap` `focus_card_library_only` count=1 next=`rerun_targeted_gate_with_forced_focus_access_or_larger_sample`
   - focus card traced but not accessed: Squee, Goblin Nabob [docs/hermes-analysis/master_optimizer_reports/lorehold_birgi_min_sample_forced_probe_20260628_v1_20260628_113410_birgi_spellchain_cut_jeskas_will.json]
