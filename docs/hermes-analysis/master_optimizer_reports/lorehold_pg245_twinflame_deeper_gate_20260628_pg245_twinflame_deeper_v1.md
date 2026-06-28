# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T02:10:58.656003+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| pg245_twinflame_damage_payoff_cut_thor | static_damage_modifier | Twinflame Tyrant | Thor, God of Thunder | `override_locked_cut_safety` | 7/2/0 `77.78%` | 4/5/0 `44.44%` | -33.34 | cost -35, spell -16, spell mana +0, birgi mana +0, ritual -3, miracle -16, tutor -2, random discard +2, topdeck -10, discard-to-top +8, rummage-to-top +3, spell-rummage-to-top +5, hand to top +0, spell rummage +2, squee gy -7, squee return -5, squee explained -5 | reject_or_rework |

## Package Notes

### pg245_twinflame_damage_payoff_cut_thor

- family: static_damage_modifier
- hypothesis: PG245 gives Twinflame Tyrant an executable XMage-backed static damage-doubling model. This is a same-mana-value damage payoff diagnostic over Thor, not a promotion, because prior Thor cuts failed when the replacement was not a direct damage payoff.
- status: `gated`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "PG245 same-slot damage payoff benchmark; isolated candidate only", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Twinflame Tyrant": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1_pg245_twinflame_damage_payoff_cut_thor/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1_pg245_twinflame_damage_payoff_cut_thor.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1_pg245_twinflame_damage_payoff_cut_thor.json`
- gate_returncode: `0`
