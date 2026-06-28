# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T02:10:02.458815+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 2}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| pg245_verge_rangers_topdeck_land_cut_waterskin | topdeck_play | Verge Rangers | Bender's Waterskin | `override_risky_cut_safety` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -40, spell -35, spell mana +0, birgi mana +0, ritual -1, miracle -13, tutor -3, random discard -1, topdeck -10, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| pg245_twinflame_damage_payoff_cut_thor | static_damage_modifier | Twinflame Tyrant | Thor, God of Thunder | `override_locked_cut_safety` | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | cost +4, spell +8, spell mana +0, birgi mana +0, ritual -1, miracle -4, tutor -3, random discard +0, topdeck +5, discard-to-top +6, rummage-to-top +6, spell-rummage-to-top +0, hand to top +0, spell rummage -3, squee gy -1, squee return +0, squee explained +0 | tie_watch_strategy_regression |

## Package Notes

### pg245_verge_rangers_topdeck_land_cut_waterskin

- family: topdeck_play
- hypothesis: PG245 gives Verge Rangers an executable XMage-backed topdeck land play model. This same-lane diagnostic challenges Bender's Waterskin only because both occupy the three-mana early-mana/topdeck support slot, while preserving the expensive miracle spell package.
- status: `gated`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "aggregate upside exists, but it broke the known strong seed", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "PG245 same-lane topdeck_play/ramp benchmark; isolated candidate only", "status": "override_risky_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Verge Rangers": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_verge_rangers_topdeck_land_cut_waterskin/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_verge_rangers_topdeck_land_cut_waterskin.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_verge_rangers_topdeck_land_cut_waterskin.json`
- gate_returncode: `0`

### pg245_twinflame_damage_payoff_cut_thor

- family: static_damage_modifier
- hypothesis: PG245 gives Twinflame Tyrant an executable XMage-backed static damage-doubling model. This is a same-mana-value damage payoff diagnostic over Thor, not a promotion, because prior Thor cuts failed when the replacement was not a direct damage payoff.
- status: `gated`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "PG245 same-slot damage payoff benchmark; isolated candidate only", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Twinflame Tyrant": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_twinflame_damage_payoff_cut_thor/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_twinflame_damage_payoff_cut_thor.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1_pg245_twinflame_damage_payoff_cut_thor.json`
- gate_returncode: `0`
