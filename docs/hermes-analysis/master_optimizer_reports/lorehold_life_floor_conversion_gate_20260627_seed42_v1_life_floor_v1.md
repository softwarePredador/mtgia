# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:07:29.840646+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| angel_grace_life_floor_cut_dawn | life_floor_protection | Angel's Grace | Dawn's Truce | 8/1/0 `88.89%` | 0/9/0 `0.00%` | -88.89 | cost -66, spell -59, spell mana +0, birgi mana +0, miracle -22, topdeck -26, discard-to-top -10, rummage-to-top -7, spell-rummage-to-top -3, hand to top +0, spell rummage -16, squee gy -4, squee return -3, squee explained -3 | reject_or_rework |

## Package Notes

### angel_grace_life_floor_cut_dawn

- family: life_floor_protection
- hypothesis: The loss classifier shows early life-zero deaths even when the deck sometimes finds topdeck or Approach setup. Angel's Grace is a one-mana life-floor effect with executable runtime rules; this tests a same-lane protection swap over Dawn's Truce without cutting ramp, High Noon, Hexing Squelcher, or Storm Herd.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Angel's Grace": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.json`
- gate_returncode: `0`
