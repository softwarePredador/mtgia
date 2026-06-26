# Hermes Master Optimizer Confirmation

- deck_id: 607
- baseline_id: 11
- baseline_wr: 33.3%
- phase: confirmation
- games_per_opponent: 1
- tested: 1
- blocked: 0
- skipped: 0

## Battle Replay Gate

- audit_summary: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- audit_run_dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_111525`
- battle_replay_final_status: `review_required`
- battle_replay_final_status_reason: `one_or_more_mandatory_gates_require_review`
- battle_gate_weight: `required_for_optimizer_wr_evidence`
- mandatory_gate_divergences: `["event_contract_static=review_required"]`
- mandatory_gate_statuses: `{"action_critic": "pass", "decision_trace_taxonomy": "pass", "effect_coverage": "pass", "event_contract_static": "review_required", "focused_template_dispatch": "pass", "forensic_audit": "pass", "replay_decision_audit": "pass", "strategy_audit": "pass", "table_intent": "pass", "target_pressure": "pass", "unknown_template_backlog": "pass"}`
- strategy_learning_confidence_counts: `{"high_confidence_replay": 13, "low_confidence_replay": 3}`
- strategy_low_confidence_seed_sample: `["63261406", "63261407", "63261416"]`
- strategy_high_confidence_learning_seed_sample: `["63261404", "63261405", "63261408", "63261409", "63261410", "63261411", "63261412", "63261413"]`
- global_learning_eligibility_policy: `requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- global_learning_eligible_seed_sample: `[]`
- global_not_learning_eligible_seed_sample: `["63261404", "63261405", "63261406", "63261407", "63261408", "63261409", "63261410", "63261411"]`
- focused_template_dispatch_status: `focused_template_dispatch_ready`
- focused_template_evidence_ready: `24`
- focused_template_evidence_not_ready_unwaived: `0`
- effect_coverage_residual_status: `effect_coverage_residual_accepted`
- effect_coverage_residual_raw_flag_total: `502`
- effect_coverage_residual_accepted_unaccepted_rows: `272/0`
- effect_coverage_residual_scope_note: `accepted_residual_is_not_full_runtime_coverage`
- review_rule_denominators: `review_only=1349 needs_review=1349 non_runtime_safe=1349 runtime_safe=1893`
- review_rule_denominator_scope_note: `review_only_zero_is_not_review_backlog_zero`
- review_status_counts: `{"active": 84, "needs_review": 1349, "verified": 1809}`
- decision_trace_taxonomy_scope: `rows=2601 observed=12/18 uncovered=6`
- decision_trace_static_uncovered_types: `["activated_sacrifice_damage", "activated_self_counter_growth", "attack_trigger_artifact_tutor", "board_wipe", "utility_creature_activation", "worldfire_reset"]`
- forensic_lineage_status: `complete`
- forensic_card_id_present_missing: `575/1520`
- forensic_card_id_missing_accepted_unaccepted: `1520/0`
- forensic_semantic_hash_present_missing: `575/1520`
- forensic_semantic_hash_missing_accepted_unaccepted: `1520/0`
- forensic_rule_logical_key_present_missing: `2039/56`
- forensic_rule_logical_key_missing_accepted_unaccepted: `56/0`
- forensic_lineage_scope_note: `complete_means_zero_unaccepted_missing_not_full_identity_coverage`
- forensic_lineage_missing_waiver_reasons: `{"battle_rule_registry_without_card_identity_columns": 2342, "land_played_curated_runtime_rule_without_pg_card_identity": 576, "manual_runtime_waiver_without_pg_identity": 10, "type_line_creature_fact_no_rule_identity": 168}`

## Tested

| Add | Cut | Category | Scan WR | Confirm WR | Delta | Record | Warnings |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| Flashback | Emeria's Call // Emeria, Shattered Skyclave | engine | 33.3% | 33.3% | +0.0pp | 1W/2L/0S | - |

## Blocked

| Add | Cut | Scan WR | Reasons |
| --- | --- | ---: | --- |

## Skipped

| Add | Cut | Scan WR | Reason |
| --- | --- | ---: | --- |
