# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:57:34.381342+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| galvanoth_topdeck_freecast_cut_thor | topdeck_freecast | Galvanoth | Thor, God of Thunder | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -57, spell -53, spell mana +0, birgi mana +0, ritual -4, miracle -19, tutor -5, random discard +0, topdeck -24, discard-to-top -9, rummage-to-top -6, spell-rummage-to-top -3, hand to top +0, spell rummage -18, squee gy -2, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### galvanoth_topdeck_freecast_cut_thor

- family: topdeck_freecast
- hypothesis: Galvanoth is the current topdeck/freecast lane with a weak-seed signal but bad prior cuts. This retest preserves Bender's Waterskin, Hexing Squelcher, Victory Chimes, the protection shell, and the medallions, cutting Thor only as a same-plan diagnostic because Thor has local runtime exposure but no proven win-rate lift yet.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2_galvanoth_topdeck_freecast_cut_thor/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2_galvanoth_topdeck_freecast_cut_thor.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2_galvanoth_topdeck_freecast_cut_thor.json`
- gate_returncode: `0`

