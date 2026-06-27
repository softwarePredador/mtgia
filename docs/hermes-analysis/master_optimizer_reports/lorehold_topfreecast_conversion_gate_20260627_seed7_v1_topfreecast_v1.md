# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:30:01.360214+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `7`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| primal_amulet_spell_engine | cost_reduce_copy | Primal Amulet // Primal Wellspring | Bender's Waterskin | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | cost +34, spell +34, spell mana +0, birgi mana +0, ritual -3, miracle +3, topdeck -1, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -1, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |

## Package Notes

### primal_amulet_spell_engine

- family: cost_reduce_copy
- hypothesis: Primal Amulet reduces instant/sorcery costs and can transform into a spell-copying mana land, matching the deck's expensive spell plan.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Primal Amulet // Primal Wellspring": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed7_v1_topfreecast_v1_primal_amulet_spell_engine/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed7_v1_topfreecast_v1_primal_amulet_spell_engine.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed7_v1_topfreecast_v1_primal_amulet_spell_engine.json`
- gate_returncode: `0`
