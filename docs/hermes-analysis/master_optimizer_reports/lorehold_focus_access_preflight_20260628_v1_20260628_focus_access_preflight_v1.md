# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T03:36:25.720416+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json`
- package_status_counts: `{"skipped_cut_safety": 5}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brainstone_topdeck_miracle_cut_squelcher | topdeck_setup | Brainstone | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| penance_topdeck_protection_cut_squelcher | topdeck_protection | Penance | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| faithless_looting_squee_enabler | discard_rummage_recursion | Faithless Looting | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| gamble_access_cut_thor | tutor_access | Gamble | Thor, God of Thunder | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| enlightened_engine_access_cut_thor | tutor_access | Enlightened Tutor | Thor, God of Thunder | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |

## Package Notes

### brainstone_topdeck_miracle_cut_squelcher

- family: topdeck_setup
- hypothesis: Brainstone failed when it cut Bender's Waterskin; this variant preserves ramp and tests whether a cheap one-shot topdeck engine can help seed 7 find the Library/topdeck conversion line.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### penance_topdeck_protection_cut_squelcher

- family: topdeck_protection
- hypothesis: Penance gives an executable hand-to-library topdeck line plus combat damage prevention. It tests topdeck consistency without relying on land-only placeholder rules such as The Biblioplex or Mirrorpool.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### faithless_looting_squee_enabler

- family: discard_rummage_recursion
- hypothesis: Faithless Looting gives the Squee shell a cheap, executable discard outlet plus card flow, testing whether the proven Squee return loop needs more ways to put Squee into the graveyard before Lorehold's topdeck/miracle engine can convert.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### gamble_access_cut_thor

- family: tutor_access
- hypothesis: Gamble improved weak seeds when it cut Creative Technique but broke seed 42. This retest keeps the modeled free-cast slot and instead cuts Thor, whose local runtime rule has natural exposure but no deck win-rate lift yet, while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, medallions, Bender's Waterskin, and the three-mana ramp shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### enlightened_engine_access_cut_thor

- family: tutor_access
- hypothesis: Enlightened Tutor tests a lower-risk access line than Gamble: it cannot find Approach, but it can put artifact/enchantment engines on top for Lorehold and miracle setup without random discard. Thor is the cut for the same modeled-not-proven reason as the Gamble retest.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
