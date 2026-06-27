# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T22:15:22.223831+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `7`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | `clear` | 1/7/0 `12.50%` | 4/4/0 `50.00%` | +37.50 | cost +63, spell +59, spell mana +0, birgi mana +0, ritual +2, miracle +16, tutor -5, random discard +0, topdeck +12, discard-to-top -12, rummage-to-top -3, spell-rummage-to-top -9, hand to top +0, spell rummage +1, squee gy -1, squee return -1, squee explained -1 | promote_to_deeper_gate |

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
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v2_seed7_smoke_opp8_20260627_221507_ghostly_prison_pressure_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v2_seed7_smoke_opp8_20260627_221507_ghostly_prison_pressure_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v2_seed7_smoke_opp8_20260627_221507_ghostly_prison_pressure_cut_promise.json`
- gate_returncode: `0`

