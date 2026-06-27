# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:15:35.716932+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| galvanoth_topdeck_freecast_cut_chimes | topdeck_freecast | Galvanoth | Victory Chimes | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -34, spell -33, spell mana +0, birgi mana +0, miracle -11, topdeck -6, hand to top +0, spell rummage +4, squee gy -3, squee return -2, squee explained -2 | reject_or_rework |

## Package Notes

### galvanoth_topdeck_freecast_cut_chimes

- family: topdeck_freecast
- hypothesis: Galvanoth was the only aggregate-positive topdeck package, but the Bender's Waterskin cut broke the seed-42 success case and the Hexing Squelcher cut was worse. This retest preserves both colored ramp and anti-counter pressure, cutting the more generic colorless three-mana ramp slot instead.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed42_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed42_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed42_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes.json`
- gate_returncode: `0`
