# Global Commander Contextual Usage Trace Scout

- generated_at: `2026-07-05T21:26:46.549894+00:00`
- status: `contextual_usage_trace_scout_no_current_trace_evidence`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- contextual_card_count: `3`
- occurrence_count: `163`
- current_usage_trace_evidence_count: `0`
- non_proof_reference_count: `163`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_run_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `generate_or_import_current_scope_usage_trace_before_reclassification`

## Evidence By Card

| Card | Current Usage Trace | Non-Proof References |
| --- | ---: | ---: |
| `Professional Face-Breaker` | 0 | 61 |
| `Diabolic Intent` | 0 | 68 |
| `Ornithopter of Paradise` | 0 | 34 |

## Current Usage Trace Occurrences

- none

## Non-Proof Occurrence Sample

- `Diabolic Intent`: `historical_or_cross_deck_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260608_seed970_989_after_lorehold_optimizer_blockers_v4.json` line `194`
- `Diabolic Intent`: `historical_or_cross_deck_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260608_seed990_1029_after_lorehold_optimizer_blockers_v3.json` line `281`
- `Diabolic Intent`: `current_scope_non_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deck619_battle_rule_coherence_pg200_trouble_in_pairs_postsync_v1.json` line `1355`
- `Diabolic Intent`: `current_scope_non_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deck619_battle_rule_coherence_pg200_trouble_in_pairs_postsync_v1.json` line `1378`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `61`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `76`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `22`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `32`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.json` line `1799`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.json` line `1807`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md` line `63`
- `Diabolic Intent`: `planning_reference_not_usage_trace` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1.json` line `1613`

## Blockers

- `no_current_scope_usage_trace_evidence_for_contextual_stage_cuts`

## Policy

- scout_boundary: This scout searches existing artifacts only; it does not run a battle.
- proof_boundary: Planning, rule-coherence, and cross-deck occurrences do not prove a contextual cut is safe.
- reclassification_boundary: Even current-scope trace evidence requires manual value-safe review before candidate copy.
