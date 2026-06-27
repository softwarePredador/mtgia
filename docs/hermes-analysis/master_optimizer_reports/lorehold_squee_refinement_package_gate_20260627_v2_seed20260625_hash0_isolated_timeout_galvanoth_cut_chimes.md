# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:16:02.796759+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `20260625`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| galvanoth_topdeck_freecast_cut_chimes | topdeck_freecast | Galvanoth | Victory Chimes | 0/9/0 `0.00%` | 3/6/0 `33.33%` | +33.33 | cost +36, spell +33, spell mana +0, birgi mana +0, miracle +12, topdeck +10, hand to top +0, spell rummage +14, squee gy +6, squee return +6, squee explained +6 | promote_to_deeper_gate |

## Package Notes

### galvanoth_topdeck_freecast_cut_chimes

- family: topdeck_freecast
- hypothesis: Galvanoth was the only aggregate-positive topdeck package, but the Bender's Waterskin cut broke the seed-42 success case and the Hexing Squelcher cut was worse. This retest preserves both colored ramp and anti-counter pressure, cutting the more generic colorless three-mana ramp slot instead.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed20260625_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed20260625_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v2_seed20260625_hash0_isolated_timeout_galvanoth_cut_chimes_galvanoth_topdeck_freecast_cut_chimes.json`
- gate_returncode: `0`
