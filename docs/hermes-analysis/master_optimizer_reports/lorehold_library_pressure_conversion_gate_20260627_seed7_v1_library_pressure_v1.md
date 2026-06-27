# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:52:54.775073+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `7`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brainstone_topdeck_miracle_cut_squelcher | topdeck_setup | Brainstone | Hexing Squelcher | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | cost +18, spell +19, spell mana +0, birgi mana +0, miracle +5, topdeck +5, discard-to-top +6, rummage-to-top +3, spell-rummage-to-top +3, hand to top +0, spell rummage +2, squee gy +1, squee return +1, squee explained +1 | promote_to_deeper_gate |
| ghostly_prison_pressure_cut_squelcher | pressure_absorber | Ghostly Prison | Hexing Squelcher | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | cost +24, spell +23, spell mana +0, birgi mana +0, miracle +12, topdeck +2, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -1, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |
| one_ring_protection_draw_cut_squelcher | draw_protection | The One Ring | Hexing Squelcher | 0/9/0 `0.00%` | 0/9/0 `0.00%` | +0.00 | cost +18, spell +11, spell mana +0, birgi mana +0, miracle +2, topdeck +9, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +1, squee return +1, squee explained +1 | tie_promote_to_deeper_gate |

## Package Notes

### brainstone_topdeck_miracle_cut_squelcher

- family: topdeck_setup
- hypothesis: Brainstone failed when it cut Bender's Waterskin; this variant preserves ramp and tests whether a cheap one-shot topdeck engine can help seed 7 find the Library/topdeck conversion line.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brainstone": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_brainstone_topdeck_miracle_cut_squelcher.json`
- gate_returncode: `0`

### ghostly_prison_pressure_cut_squelcher

- family: pressure_absorber
- hypothesis: Ghostly Prison directly attacks the seed-20260625 failure mode: the deck can put Approach on top but dies to combat pressure before conversion. This retest avoids the prior bad High Noon cut.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Ghostly Prison": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_ghostly_prison_pressure_cut_squelcher.json`
- gate_returncode: `0`

### one_ring_protection_draw_cut_squelcher

- family: draw_protection
- hypothesis: The One Ring may buy the exact turn seed 20260625 lacks while adding repeatable draw. This preserves the three-mana ramp shell and cuts the narrower anti-counter creature instead.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"The One Ring": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.json`
- gate_returncode: `0`
