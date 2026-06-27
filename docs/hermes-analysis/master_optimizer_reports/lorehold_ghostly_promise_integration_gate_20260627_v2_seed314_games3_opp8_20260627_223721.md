# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T22:37:58.992874+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `314`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | `clear` | 6/18/0 `25.00%` | 8/16/0 `33.33%` | +8.33 | cost +36, spell +30, spell mana +0, birgi mana +0, ritual +0, miracle +4, tutor -4, random discard -1, topdeck -3, discard-to-top +10, rummage-to-top +10, spell-rummage-to-top +0, hand to top +0, spell rummage +5, squee gy +1, squee return +1, squee explained +1 | promote_to_deeper_gate |

## Package Notes

### ghostly_prison_pressure_cut_promise

- family: pressure_absorber
- hypothesis: Ghostly Prison previously failed when it cut protected Hexing Squelcher. This retest keeps Hexing Squelcher and Fated Clash, then checks whether a static attack tax is better than a slower pressure cleanup spell against the combat-pressure deaths. This is an explicit pressure-lane benchmark, not a generic cut of the big-spell miracle plan.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Promise of Loyalty`
- added_rule_counts: `{"Ghostly Prison": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721_ghostly_prison_pressure_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721_ghostly_prison_pressure_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721_ghostly_prison_pressure_cut_promise.json`
- gate_returncode: `0`

