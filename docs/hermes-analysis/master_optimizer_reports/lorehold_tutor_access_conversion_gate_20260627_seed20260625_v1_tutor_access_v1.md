# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:40:34.307930+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `20260625`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_approach_access_cut_creative | tutor_access | Gamble | Creative Technique | 0/9/0 `0.00%` | 3/6/0 `33.33%` | +33.33 | cost +51, spell +44, spell mana +0, birgi mana +0, ritual -2, miracle +9, tutor +2, random discard +3, topdeck +17, discard-to-top -8, rummage-to-top -8, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +6, squee return +4, squee explained +4 | promote_to_deeper_gate |

## Package Notes

### gamble_approach_access_cut_creative

- family: tutor_access
- hypothesis: The loss classifier shows topdeck/miracle turns failing to find or recast Approach before combat pressure. Gamble tests a cheap universal tutor over a five-mana demonstrate/free-cast slot while preserving the existing protection, ramp, medallion, Bender's Waterskin, Hexing Squelcher, and Storm Herd shell.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Creative Technique`
- added_rule_counts: `{"Gamble": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed20260625_v1_tutor_access_v1_gamble_approach_access_cut_creative/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed20260625_v1_tutor_access_v1_gamble_approach_access_cut_creative.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed20260625_v1_tutor_access_v1_gamble_approach_access_cut_creative.json`
- gate_returncode: `0`
