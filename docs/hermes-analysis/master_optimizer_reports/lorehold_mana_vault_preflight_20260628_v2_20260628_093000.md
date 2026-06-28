# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T07:38:58.350232+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- apply_only: `False`
- no_game_checkpoint: `False`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `-`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json`
- package_status_counts: `{"skipped_prior_evidence": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| mana_vault_fast_mana_cut_arcane_signet | fast_mana | Mana Vault | Arcane Signet | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |

## Package Notes

### mana_vault_fast_mana_cut_arcane_signet

- family: fast_mana
- hypothesis: Mana Vault is legal, battle-ready fast mana and appears in multiple Lorehold variants. This tests whether one-mana colorless burst accelerates commander and expensive spell windows more than Arcane Signet's colored fixing, without cutting protected medallions, Bender's Waterskin, Victory Chimes, or Jeska's Will.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Mana Vault"], "adds_signature": ["mana vault"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 24.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 30, "lorehold_spell_cast": 25, "lorehold_upkeep_rummage": 9, "miracle_cast": 7, "topdeck_manipulation_activated": 11}, "win_rate": 33.33, "wins": 1}, "cuts": ["Arcane Signet"], "cuts_signature": ["arcane signet"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "fast_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000_mana_vault_fast_mana_cut_arcane_signet.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000_mana_vault_fast_mana_cut_arcane_signet.md", "gate_returncode": 0, "package_key": "mana_vault_fast_mana_cut_arcane_signet", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -31, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -28, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -6, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -1, "tutor_resolved": -2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
