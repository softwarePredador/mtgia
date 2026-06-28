# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T09:03:35.000548+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- apply_only: `False`
- no_game_checkpoint: `False`
- forced_access_mode: `none`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `-`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_protection_ready_gate_20260628_v1_20260628_095000.json`
- package_status_counts: `{"skipped_cut_safety": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| faithless_looting_squee_enabler | discard_rummage_recursion | Faithless Looting | Hexing Squelcher | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | - | skipped_cut_safety |

## Package Notes

### faithless_looting_squee_enabler

- family: discard_rummage_recursion
- hypothesis: Faithless Looting gives the Squee shell a cheap, executable discard outlet plus card flow, testing whether the proven Squee return loop needs more ways to put Squee into the graveyard before Lorehold's topdeck/miracle engine can convert.
- status: `skipped_cut_safety`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Faithless Looting"], "adds_signature": ["faithless looting"], "baseline": {"avg_win_turn": null, "losses": 19, "stalls": 0, "strategic_event_counts": {}, "win_rate": 29.63, "wins": 8}, "candidate": {"avg_win_turn": null, "losses": 23, "stalls": 0, "strategic_event_counts": {}, "win_rate": 14.81, "wins": 4}, "cuts": ["Hexing Squelcher"], "cuts_signature": ["hexing squelcher"], "decision": "reject_or_rework", "delta_pp": -14.82, "exposure_summary": {}, "family": "discard_rummage_recursion", "forced_access_mode": "none", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "faithless_looting_squee_enabler", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json", "source_section": "post_squee_package_gates", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
