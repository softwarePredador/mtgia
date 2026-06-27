# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T15:56:50.478425+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `7`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brainstone_topdeck_miracle | topdeck_setup | Brainstone | Bender's Waterskin | 0/9/0 `0.00%` | 0/9/0 `0.00%` | +0.00 | cost +3, spell +2, miracle +0, topdeck +1, spell rummage -2, squee gy +0, squee return +0, squee explained +0 | tie_promote_to_deeper_gate |
| faithless_looting_squee_enabler | discard_rummage_recursion | Faithless Looting | Hexing Squelcher | 0/9/0 `0.00%` | 1/8/0 `11.11%` | +11.11 | cost +16, spell +22, miracle +2, topdeck +4, spell rummage +1, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |
| galvanoth_topdeck_freecast | topdeck_freecast | Galvanoth | Bender's Waterskin | 0/9/0 `0.00%` | 1/8/0 `11.11%` | +11.11 | cost +7, spell +4, miracle +1, topdeck +1, spell rummage -2, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |

## Package Notes

### brainstone_topdeck_miracle

- family: topdeck_setup
- hypothesis: Brainstone is another cheap topdeck manipulation artifact that can turn the first draw into a planned miracle window.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brainstone": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_brainstone_topdeck_miracle/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_brainstone_topdeck_miracle.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_brainstone_topdeck_miracle.json`
- gate_returncode: `0`

### faithless_looting_squee_enabler

- family: discard_rummage_recursion
- hypothesis: Faithless Looting gives the Squee shell a cheap, executable discard outlet plus card flow, testing whether the proven Squee return loop needs more ways to put Squee into the graveyard before Lorehold's topdeck/miracle engine can convert.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Faithless Looting": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_faithless_looting_squee_enabler/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_faithless_looting_squee_enabler.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_faithless_looting_squee_enabler.json`
- gate_returncode: `0`

### galvanoth_topdeck_freecast

- family: topdeck_freecast
- hypothesis: Galvanoth turns topdeck setup into free upkeep casts for the same expensive instant/sorcery package Lorehold wants to miracle.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_galvanoth_topdeck_freecast/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_galvanoth_topdeck_freecast.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout_galvanoth_topdeck_freecast.json`
- gate_returncode: `0`
