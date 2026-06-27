# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:53:05.186703+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brainstone_topdeck_miracle_cut_squelcher | topdeck_setup | Brainstone | Hexing Squelcher | 8/1/0 `88.89%` | 1/8/0 `11.11%` | -77.78 | cost -67, spell -57, spell mana +0, birgi mana +0, miracle -21, topdeck -27, discard-to-top -11, rummage-to-top -8, spell-rummage-to-top -3, hand to top +0, spell rummage -19, squee gy -1, squee return -3, squee explained -3 | reject_or_rework |
| ghostly_prison_pressure_cut_squelcher | pressure_absorber | Ghostly Prison | Hexing Squelcher | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -47, spell -29, spell mana +0, birgi mana +0, miracle -16, topdeck -21, discard-to-top -16, rummage-to-top -13, spell-rummage-to-top -3, hand to top +0, spell rummage -2, squee gy -5, squee return -4, squee explained -4 | reject_or_rework |
| one_ring_protection_draw_cut_squelcher | draw_protection | The One Ring | Hexing Squelcher | 8/1/0 `88.89%` | 1/8/0 `11.11%` | -77.78 | cost -63, spell -54, spell mana +0, birgi mana +0, miracle -20, topdeck -27, discard-to-top -16, rummage-to-top -13, spell-rummage-to-top -3, hand to top +0, spell rummage -7, squee gy -4, squee return -3, squee explained -3 | reject_or_rework |

## Package Notes

### brainstone_topdeck_miracle_cut_squelcher

- family: topdeck_setup
- hypothesis: Brainstone failed when it cut Bender's Waterskin; this variant preserves ramp and tests whether a cheap one-shot topdeck engine can help seed 7 find the Library/topdeck conversion line.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brainstone": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher.json`
- gate_returncode: `0`

### ghostly_prison_pressure_cut_squelcher

- family: pressure_absorber
- hypothesis: Ghostly Prison directly attacks the seed-20260625 failure mode: the deck can put Approach on top but dies to combat pressure before conversion. This retest avoids the prior bad High Noon cut.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Ghostly Prison": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher.json`
- gate_returncode: `0`

### one_ring_protection_draw_cut_squelcher

- family: draw_protection
- hypothesis: The One Ring may buy the exact turn seed 20260625 lacks while adding repeatable draw. This preserves the three-mana ramp shell and cuts the narrower anti-counter creature instead.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"The One Ring": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.json`
- gate_returncode: `0`
