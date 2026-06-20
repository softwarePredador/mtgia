# Hermes Master Optimizer Quality Gate

- deck_id: 6
- baseline_id: 6
- baseline_hash: `be131630b8452d37385f02be49b6b875864aea0fc107bed4c14c0c5e257ccba7`
- baseline_semantics_hash: `8edc5a299230cc393d05bf16da6e36c4e36f25ac66a3970915963f8b0605fed9`
- baseline_ruleset_hash: `c6ff2e0c7cf36a1345faa7be4148462dc4813b80506c508a1f8127605f0c3ac2`
- baseline_wr: 100.0%
- candidates_reviewed: 0

## Battle Replay Gate

- audit_summary: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- audit_run_dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_174219`
- battle_replay_final_status: `review_required`
- battle_replay_final_status_reason: `one_or_more_mandatory_gates_require_review`
- battle_gate_weight: `required_for_optimizer_wr_evidence`
- mandatory_gate_divergences: `["action_critic=review_required", "forensic_audit=review_required", "replay_decision_audit=review_required"]`
- mandatory_gate_statuses: `{"action_critic": "review_required", "decision_trace_taxonomy": "pass", "effect_coverage": "pass", "event_contract_static": "pass", "focused_template_dispatch": "pass", "forensic_audit": "review_required", "replay_decision_audit": "review_required", "strategy_audit": "pass", "unknown_template_backlog": "pass"}`
- strategy_learning_confidence_counts: `{"high_confidence_replay": 14, "low_confidence_replay": 2}`
- strategy_low_confidence_seed_sample: `["63211743", "63211751"]`
- strategy_high_confidence_learning_seed_sample: `["63211742", "63211744", "63211745", "63211746", "63211747", "63211748", "63211749", "63211750"]`
- global_learning_eligibility_policy: `requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- global_learning_eligible_seed_sample: `[]`
- global_not_learning_eligible_seed_sample: `["63211742", "63211743", "63211744", "63211745", "63211746", "63211747", "63211748", "63211749"]`
- focused_template_dispatch_status: `focused_template_dispatch_ready`
- focused_template_evidence_ready: `29`
- focused_template_evidence_not_ready_unwaived: `0`
- effect_coverage_residual_status: `effect_coverage_residual_accepted`
- effect_coverage_residual_raw_flag_total: `536`
- effect_coverage_residual_accepted_unaccepted_rows: `290/0`
- effect_coverage_residual_scope_note: `accepted_residual_is_not_full_runtime_coverage`
- review_rule_denominators: `review_only=1457 needs_review=1457 non_runtime_safe=1457 runtime_safe=1704`
- review_rule_denominator_scope_note: `review_only_zero_is_not_review_backlog_zero`
- review_status_counts: `{"active": 29, "needs_review": 1457, "verified": 1675}`
- decision_trace_taxonomy_scope: `rows=2244 observed=12/15 uncovered=3`
- decision_trace_static_uncovered_types: `["activated_sacrifice_damage", "attack_trigger_artifact_tutor", "worldfire_reset"]`
- forensic_lineage_status: `incomplete`
- forensic_card_id_present_missing: `737/559`
- forensic_card_id_missing_accepted_unaccepted: `558/1`
- forensic_semantic_hash_present_missing: `737/559`
- forensic_semantic_hash_missing_accepted_unaccepted: `558/1`
- forensic_rule_logical_key_present_missing: `1268/28`
- forensic_rule_logical_key_missing_accepted_unaccepted: `28/0`
- forensic_lineage_scope_note: `complete_means_zero_unaccepted_missing_not_full_identity_coverage`
- forensic_lineage_missing_waiver_reasons: `{"battle_rule_registry_without_card_identity_columns": 470, "land_played_curated_runtime_rule_without_pg_card_identity": 586, "manual_runtime_waiver_without_pg_identity": 4, "type_line_creature_fact_no_rule_identity": 84}`

| Status | Category | Add | Cut | Scan WR | Reasons | Warnings |
| --- | --- | --- | --- | ---: | --- | --- |
