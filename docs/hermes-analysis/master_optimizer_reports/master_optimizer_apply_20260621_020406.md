# Hermes Master Optimizer Apply

- deck_id: 6
- swap_benchmark_id: 3
- applied: `Windborn Muse` over `Guttersnipe`
- confirmation_wr: 6.2%
- confirmation_delta: +3.1pp
- before_hash: `66cc04ccfc3d5bc6d0f920e3e63ad6cb1cd4d77965725aa7c2479f671837b35a`
- after_hash: `145f04b766b5ae5617b33e1c7a11037f6db43b44f42f99f9f193e7e9ceb2a0ba`
- before_semantics_hash: `7ca629b6977317e1893966617cf4666071649fc498252d8f5e6eafd20acafc76`
- after_semantics_hash: `d2f91b6a1c99a73c78172c8d72bfce7780ca4592e907bd67d14941c96029f014`
- before_ruleset_hash: `b11ec9dda7c9401126b2879d4df128c1b9c7b5ef76fbfa1fcde0bd53ecdc4f0f`
- after_ruleset_hash: `425b3dea36c477b36f025711dd80db856b679be6b9fed91f89f9e9ed7fd0d696`
- rollback_path: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260621T020406839706+0000.json`
- deck_cards_after: 100
- lands_after: 33
- avg_cmc_after: 2.567

## Battle Replay Gate

- audit_summary: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- audit_run_dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_015127`
- battle_replay_final_status: `trusted_for_strategy_learning`
- battle_replay_final_status_reason: `all_mandatory_gates_pass`
- battle_gate_weight: `required_for_optimizer_wr_evidence`
- mandatory_gate_divergences: `[]`
- mandatory_gate_statuses: `{"action_critic": "pass", "decision_trace_taxonomy": "pass", "effect_coverage": "pass", "event_contract_static": "pass", "focused_template_dispatch": "pass", "forensic_audit": "pass", "replay_decision_audit": "pass", "strategy_audit": "pass", "table_intent": "pass", "target_pressure": "pass", "unknown_template_backlog": "pass"}`
- strategy_learning_confidence_counts: `{"high_confidence_replay": 52, "low_confidence_replay": 12}`
- strategy_low_confidence_seed_sample: `["63212310", "63212315", "63212317", "63212323", "63212326", "63212329", "63212330", "63212331"]`
- strategy_high_confidence_learning_seed_sample: `["63212311", "63212312", "63212313", "63212314", "63212316", "63212318", "63212319", "63212320"]`
- global_learning_eligibility_policy: `requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- global_learning_eligible_seed_sample: `["63212311", "63212312", "63212313", "63212314", "63212316", "63212318", "63212319", "63212320"]`
- global_not_learning_eligible_seed_sample: `["63212310", "63212315", "63212317", "63212323", "63212326", "63212329", "63212330", "63212331"]`
- focused_template_dispatch_status: `focused_template_dispatch_ready`
- focused_template_evidence_ready: `29`
- focused_template_evidence_not_ready_unwaived: `0`
- effect_coverage_residual_status: `effect_coverage_residual_accepted`
- effect_coverage_residual_raw_flag_total: `521`
- effect_coverage_residual_accepted_unaccepted_rows: `280/0`
- effect_coverage_residual_scope_note: `accepted_residual_is_not_full_runtime_coverage`
- review_rule_denominators: `review_only=1424 needs_review=1424 non_runtime_safe=1424 runtime_safe=1760`
- review_rule_denominator_scope_note: `review_only_zero_is_not_review_backlog_zero`
- review_status_counts: `{"active": 56, "needs_review": 1424, "verified": 1704}`
- decision_trace_taxonomy_scope: `rows=8628 observed=12/15 uncovered=3`
- decision_trace_static_uncovered_types: `["activated_sacrifice_damage", "attack_trigger_artifact_tutor", "worldfire_reset"]`
- forensic_lineage_status: `complete`
- forensic_card_id_present_missing: `1811/3628`
- forensic_card_id_missing_accepted_unaccepted: `3628/0`
- forensic_semantic_hash_present_missing: `1811/3628`
- forensic_semantic_hash_missing_accepted_unaccepted: `3628/0`
- forensic_rule_logical_key_present_missing: `5157/282`
- forensic_rule_logical_key_missing_accepted_unaccepted: `282/0`
- forensic_lineage_scope_note: `complete_means_zero_unaccepted_missing_not_full_identity_coverage`
- forensic_lineage_missing_waiver_reasons: `{"battle_rule_registry_without_card_identity_columns": 4564, "land_played_curated_runtime_rule_without_pg_card_identity": 2006, "manual_runtime_waiver_without_pg_identity": 122, "type_line_creature_fact_no_rule_identity": 846}`

No production database was mutated. This applies only to the Hermes local SQLite knowledge deck.
