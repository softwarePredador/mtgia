# ManaLoom Log Learning Audit

- generated_at: `2026-06-28T18:48:20Z`
- reports_dir: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports`
- files_scanned: `350`
- issue_count: `35`
- superseded_issue_count: `0`
- postgres_writes: `False`
- source_db_mutated: `False`

## Severity Counts

- high: `29`
- medium: `6`

## Category Counts

- battle_rhythm_gap: `5`
- blocked_workflow: `2`
- evidence_gap: `4`
- runtime_or_test_failure: `1`
- runtime_rule_gap: `23`

## Action Queue

1. `high` `runtime_rule_gap` `coherence_critical_high_findings` count=23 next=`prioritize_cards_with_no_active_or_no_trusted_rules_in_current_deck_scope`
   - coherence audit has critical=0, high=378 [docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260628_184538.json]
     top_lorehold_cards: `Chrome Mox, Lion's Eye Diamond, Verge Rangers, Twinflame Tyrant, Terror of the Peaks`
     top_lorehold_runtime_missing: `Goliath Daydreamer, Taunt from the Rampart, Semblance Anvil, Planetarium of Wan Shi Tong, Invincible Hymn`
     top_lorehold_runtime_waived_pending_pg: `Verge Rangers, Twinflame Tyrant, Terror of the Peaks, Ephemerate`
     top_finding_codes: `review_only_or_needs_review_rule=200, no_active_battle_rule=172, no_trusted_executable_rule=98, generic_effect_without_model_scope=50, missing_oracle_text=1`
   - coherence audit has critical=0, high=378 [docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260628_184205.json]
     top_lorehold_cards: `Chrome Mox, Lion's Eye Diamond, Verge Rangers, Twinflame Tyrant, Terror of the Peaks`
     top_lorehold_runtime_missing: `Goliath Daydreamer, Taunt from the Rampart, Semblance Anvil, Planetarium of Wan Shi Tong, Invincible Hymn`
     top_lorehold_runtime_waived_pending_pg: `Verge Rangers, Twinflame Tyrant, Terror of the Peaks, Ephemerate`
     top_finding_codes: `review_only_or_needs_review_rule=200, no_active_battle_rule=172, no_trusted_executable_rule=98, generic_effect_without_model_scope=50, missing_oracle_text=1`
2. `high` `blocked_workflow` `text_blocked` count=2 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.md]
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.md]
3. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
4. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Mana Vault [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_deck607_replay_20260628.json]
5. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is needs_more_evidence [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628.json]
6. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is inconclusive_candidate_unobserved [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
7. `medium` `battle_rhythm_gap` `prior_rhythm_flags` count=3 next=`calibrate_or_quarantine_gate_metrics_before_treating_winrate_as_strategy_signal`
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate_17lands_prior.json]
8. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.json]
9. `medium` `battle_rhythm_gap` `top_level_status` count=1 next=`inspect_rhythm_flags_before_using_gate_for_deckbuilder`
   - report status is battle_prior_warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate_17lands_prior.json]
10. `medium` `runtime_or_test_failure` `text_warning` count=1 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains warning [docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628.md]
