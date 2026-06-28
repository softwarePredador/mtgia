# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T07:40:43.910190+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `2`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `20260628`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_dynamic_package_manifest_20260628_v1.json`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| past_in_flames_recast_cut_big_score | graveyard_recast | Past in Flames | Big Score | `clear` | 4/12/0 `25.00%` | 1/15/0 `6.25%` | -18.75 | cost -6, spell -9, spell mana +0, birgi mana +0, ritual +1, miracle -12, tutor -1, random discard -2, topdeck -2, shield +0, discard-to-top +16, rummage-to-top +15, spell-rummage-to-top +1, hand to top +0, spell rummage -8, squee gy -16, squee return -15, squee explained -15 | reject_or_rework |

## Package Notes

### past_in_flames_recast_cut_big_score

- family: graveyard_recast
- hypothesis: Past in Flames had positive signal when tested over Bender's Waterskin, but Bender is protected by the current registry/cut-safety guard. This follow-up preserves the protected ramp shell and tests Past in Flames over Big Score, a one-shot discard/draw/Treasure card-flow slot in the same spell-velocity lane.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Big Score`
- added_rule_counts: `{"Past in Flames": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_dynamic_safe_cut_gate_20260628_v1_20260628_092500_past_in_flames_recast_cut_big_score/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_dynamic_safe_cut_gate_20260628_v1_20260628_092500_past_in_flames_recast_cut_big_score.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_dynamic_safe_cut_gate_20260628_v1_20260628_092500_past_in_flames_recast_cut_big_score.json`
- gate_returncode: `0`
