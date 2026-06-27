# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:30:04.314903+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| primal_amulet_spell_engine | cost_reduce_copy | Primal Amulet // Primal Wellspring | Bender's Waterskin | 8/1/0 `88.89%` | 4/5/0 `44.44%` | -44.45 | cost -33, spell -28, spell mana +0, birgi mana +0, ritual -2, miracle -14, topdeck -17, discard-to-top -14, rummage-to-top -12, spell-rummage-to-top -2, hand to top +0, spell rummage -14, squee gy -6, squee return -5, squee explained -5 | reject_or_rework |

## Package Notes

### primal_amulet_spell_engine

- family: cost_reduce_copy
- hypothesis: Primal Amulet reduces instant/sorcery costs and can transform into a spell-copying mana land, matching the deck's expensive spell plan.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Primal Amulet // Primal Wellspring": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1_primal_amulet_spell_engine/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1_primal_amulet_spell_engine.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1_primal_amulet_spell_engine.json`
- gate_returncode: `0`
