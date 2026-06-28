# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T08:56:54.787357+00:00`
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
- package_definition_files: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_generator_20260628_v2_package_manifest.json`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json`
- package_status_counts: `{"preflight_ready": 6}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| seething_song_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Seething Song | Bender's Waterskin | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| mana_vault_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Mana Vault | Bender's Waterskin | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| invoke_calamity_same_lane_benchmark_cut_creative_technique | big_spell_value_benchmark | Invoke Calamity | Creative Technique | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| velomachus_lorehold_same_lane_benchmark_cut_creative_technique | big_spell_value_benchmark | Velomachus Lorehold | Creative Technique | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| crackle_with_power_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Crackle with Power | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |
| lightning_helix_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Lightning Helix | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |

## Package Notes

### seething_song_same_lane_benchmark_cut_bender_s_waterskin

- family: ramp_benchmark
- hypothesis: Seething Song is an active-rule Lorehold variant ramp card. This benchmarks it as a same-function replacement for Bender's Waterskin before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "registry allows only a same-function replacement benchmark; candidate_role=ramp cut_role=ramp", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### mana_vault_same_lane_benchmark_cut_bender_s_waterskin

- family: ramp_benchmark
- hypothesis: Mana Vault is an active-rule Lorehold variant ramp card. This benchmarks it as a same-function replacement for Bender's Waterskin before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "registry allows only a same-function replacement benchmark; candidate_role=ramp cut_role=ramp", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### invoke_calamity_same_lane_benchmark_cut_creative_technique

- family: big_spell_value_benchmark
- hypothesis: Invoke Calamity is an active-rule Lorehold variant big spell value card. This benchmarks it as a same-function replacement for Creative Technique before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Creative Technique", "current_lane": "finisher_or_big_spell", "effective_role": "big_spell_value", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "registry allows only a same-function replacement benchmark; candidate_role=big_spell_value cut_role=big_spell_value", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### velomachus_lorehold_same_lane_benchmark_cut_creative_technique

- family: big_spell_value_benchmark
- hypothesis: Velomachus Lorehold is an active-rule Lorehold variant big spell value card. This benchmarks it as a same-function replacement for Creative Technique before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Creative Technique", "current_lane": "finisher_or_big_spell", "effective_role": "big_spell_value", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "registry allows only a same-function replacement benchmark; candidate_role=big_spell_value cut_role=big_spell_value", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- exposure_summary: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### crackle_with_power_same_lane_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Crackle with Power is an active-rule Lorehold variant spot removal card. This benchmarks it as a same-function replacement for Winds of Abandon before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
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

### lightning_helix_same_lane_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Lightning Helix is an active-rule Lorehold variant spot removal card. This benchmarks it as a same-function replacement for Winds of Abandon before any deck promotion; registry-protected cards remain protected unless this lane wins.
- status: `preflight_ready`
- forced_access_mode: `none`
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
