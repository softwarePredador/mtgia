# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:39:53.008029+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_approach_access_cut_creative | tutor_access | Gamble | Creative Technique | 8/1/0 `88.89%` | 4/5/0 `44.44%` | -44.45 | cost -49, spell -40, spell mana +0, birgi mana +0, ritual -6, miracle -13, tutor -1, random discard +2, topdeck -21, discard-to-top -16, rummage-to-top -13, spell-rummage-to-top -3, hand to top +0, spell rummage -10, squee gy -6, squee return -4, squee explained -4 | reject_or_rework |

## Package Notes

### gamble_approach_access_cut_creative

- family: tutor_access
- hypothesis: The loss classifier shows topdeck/miracle turns failing to find or recast Approach before combat pressure. Gamble tests a cheap universal tutor over a five-mana demonstrate/free-cast slot while preserving the existing protection, ramp, medallion, Bender's Waterskin, Hexing Squelcher, and Storm Herd shell.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Creative Technique`
- added_rule_counts: `{"Gamble": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v1_tutor_access_v1_gamble_approach_access_cut_creative/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v1_tutor_access_v1_gamble_approach_access_cut_creative.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v1_tutor_access_v1_gamble_approach_access_cut_creative.json`
- gate_returncode: `0`
