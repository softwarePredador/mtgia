# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T09:10:30.954812+00:00`
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
- package_definition_files: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_generator_20260628_v4_package_manifest.json`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json`
- package_status_counts: `{"preflight_ready": 4}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Pyretic Ritual | Bender's Waterskin | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Locket of Yesterdays | Bender's Waterskin | `override_locked_cut_safety` | - | - | +0.00 | - | - | preflight_ready |
| razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Razorgrass Ambush // Razorgrass Field | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |
| witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | `clear` | - | - | +0.00 | - | - | preflight_ready |

## Package Notes

### pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin

- family: ramp_benchmark
- hypothesis: Pyretic Ritual is an active-rule Lorehold variant ramp card. This benchmarks it as a same-function replacement for Bender's Waterskin before any deck promotion; registry-protected cards remain protected unless this lane wins.
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

### locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin

- family: ramp_benchmark
- hypothesis: Locket of Yesterdays is an active-rule Lorehold variant ramp card. This benchmarks it as a same-function replacement for Bender's Waterskin before any deck promotion; registry-protected cards remain protected unless this lane wins.
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

### razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Razorgrass Ambush // Razorgrass Field is an active-rule Lorehold variant spot removal card. This benchmarks it as a same-function replacement for Winds of Abandon before any deck promotion; registry-protected cards remain protected unless this lane wins.
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

### witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon

- family: interaction_removal_benchmark
- hypothesis: Witch Enchanter // Witch-Blessed Meadow is an active-rule Lorehold variant spot removal card. This benchmarks it as a same-function replacement for Winds of Abandon before any deck promotion; registry-protected cards remain protected unless this lane wins.
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
