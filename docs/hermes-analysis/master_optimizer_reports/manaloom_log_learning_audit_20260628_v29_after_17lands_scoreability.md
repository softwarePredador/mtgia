# ManaLoom Log Learning Audit

- generated_at: `2026-06-28T22:33:23Z`
- reports_dir: `docs/hermes-analysis/master_optimizer_reports`
- files_scanned: `2`
- issue_count: `4`
- superseded_issue_count: `0`
- postgres_writes: `False`
- source_db_mutated: `False`

## Severity Counts

- high: `3`
- medium: `1`

## Category Counts

- battle_rhythm_gap: `1`
- blocked_workflow: `1`
- evidence_gap: `2`

## Action Queue

1. `high` `blocked_workflow` `text_blocked` count=1 next=`inspect_text_log_and_convert_recurring_pattern_to_structured_gate_field`
   - text log contains blocked [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_birgi_scoreability_20260628_v1.md]
2. `high` `evidence_gap` `candidate_unobserved` count=1 next=`do_not_score_swap_until_forced_or_natural_access_sample_exists`
   - candidate card was not observed: Birgi, God of Storytelling // Harnfel, Horn of Bounty [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_birgi_scoreability_20260628_v1.json]
3. `high` `evidence_gap` `top_level_status` count=1 next=`rerun_with_candidate_observation_or_min_used_sample`
   - report status is inconclusive_candidate_unobserved [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_birgi_scoreability_20260628_v1.json]
4. `medium` `battle_rhythm_gap` `prior_rhythm_flags` count=1 next=`calibrate_or_quarantine_gate_metrics_before_treating_winrate_as_strategy_signal`
   - battle prior emitted 4 rhythm flags [docs/hermes-analysis/master_optimizer_reports/seventeenlands_battle_prior_compare_birgi_scoreability_20260628_v1.json]
