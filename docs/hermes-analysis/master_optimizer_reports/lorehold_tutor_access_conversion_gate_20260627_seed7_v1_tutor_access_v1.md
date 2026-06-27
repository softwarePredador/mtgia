# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:40:12.228321+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `7`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_approach_access_cut_creative | tutor_access | Gamble | Creative Technique | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | cost +36, spell +30, spell mana +0, birgi mana +0, ritual -4, miracle +12, tutor +2, random discard +0, topdeck +11, discard-to-top +4, rummage-to-top +4, spell-rummage-to-top +0, hand to top +0, spell rummage +5, squee gy +1, squee return +1, squee explained +1 | promote_to_deeper_gate |

## Package Notes

### gamble_approach_access_cut_creative

- family: tutor_access
- hypothesis: The loss classifier shows topdeck/miracle turns failing to find or recast Approach before combat pressure. Gamble tests a cheap universal tutor over a five-mana demonstrate/free-cast slot while preserving the existing protection, ramp, medallion, Bender's Waterskin, Hexing Squelcher, and Storm Herd shell.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Creative Technique`
- added_rule_counts: `{"Gamble": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1_gamble_approach_access_cut_creative/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1_gamble_approach_access_cut_creative.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1_gamble_approach_access_cut_creative.json`
- gate_returncode: `0`
