# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:07:24.818142+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `7`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| angel_grace_life_floor_cut_dawn | life_floor_protection | Angel's Grace | Dawn's Truce | 0/9/0 `0.00%` | 0/9/0 `0.00%` | +0.00 | cost +15, spell +9, spell mana +0, birgi mana +0, miracle -2, topdeck -2, discard-to-top +11, rummage-to-top +11, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +0, squee return +0, squee explained +0 | tie_watch_strategy_regression |

## Package Notes

### angel_grace_life_floor_cut_dawn

- family: life_floor_protection
- hypothesis: The loss classifier shows early life-zero deaths even when the deck sometimes finds topdeck or Approach setup. Angel's Grace is a one-mana life-floor effect with executable runtime rules; this tests a same-lane protection swap over Dawn's Truce without cutting ramp, High Noon, Hexing Squelcher, or Storm Herd.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Angel's Grace": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1_angel_grace_life_floor_cut_dawn/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.json`
- gate_returncode: `0`
