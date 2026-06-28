# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T08:36:18.295708+00:00`
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
- package_definition_files: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260628_v1_package_manifest.json`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_protection_ready_gate_20260628_v1_20260628_095000.json`
- package_status_counts: `{"preflight_ready": 3}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| chaos_warp_interaction_benchmark_cut_stroke_of_midnight | interaction_removal_benchmark | Chaos Warp | Stroke of Midnight | `clear` | - | - | +0.00 | - | - | preflight_ready |
| lightning_bolt_interaction_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Lightning Bolt | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |
| ol_rin_s_searing_light_interaction_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Olórin's Searing Light | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |

## Package Notes

### chaos_warp_interaction_benchmark_cut_stroke_of_midnight

- family: interaction_removal_benchmark
- hypothesis: Chaos Warp is an active-rule Lorehold variant interaction card. This benchmarks it as a same-lane replacement for measured moderate-exposure Stroke of Midnight before any deck promotion; high-exposure interaction slots remain protected.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### lightning_bolt_interaction_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Lightning Bolt is an active-rule Lorehold variant interaction card. This benchmarks it as a same-lane replacement for measured moderate-exposure Winds of Abandon before any deck promotion; high-exposure interaction slots remain protected.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### ol_rin_s_searing_light_interaction_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Olórin's Searing Light is an active-rule Lorehold variant interaction card. This benchmarks it as a same-lane replacement for measured moderate-exposure Winds of Abandon before any deck promotion; high-exposure interaction slots remain protected.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
