# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T16:24:00Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260625`
- python_hash_seed: `unset`
- deck_process_isolation: `False`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_rule_materialized_equal_gate_20260627_v1_20260627_162346_squee_goblin_nabob_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 4 | 5 | 0 | 44.44% | 14.75 | 7 | 2 | 0 | 0 | 0 | 0 | 7 | recursion_role, tutor_role |
| 2 |  | Lorehold 607 Squee, Goblin Nabob equal gate (`candidate_607_squee_goblin_nabob_equal_gate`) | optimizer-equal-gate | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 2 | 1 | 0 | 0 | 0 | 0 | 8 | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/5L/0S`, WR `44.44%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 3 | 0 | 0 | 100.00% | 16.00 | elimination=3 |

**Strategic event counts:** lorehold_cost_paid=97, lorehold_spell_cast=84, lorehold_upkeep_rummage=46, miracle_cast=25, topdeck_manipulation_activated=17

### 2. Lorehold 607 Squee, Goblin Nabob equal gate (`candidate_607_squee_goblin_nabob_equal_gate`)

- objective: not available in structural matrix
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=48, lorehold_upkeep_rummage=38, topdeck_manipulation_activated=3, miracle_cast=4, lorehold_spell_rummage=2
