# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T16:23:46Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `7`
- python_hash_seed: `unset`
- deck_process_isolation: `False`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_rule_materialized_equal_gate_20260627_v1_20260627_162333_squee_goblin_nabob_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 1 | 8 | 0 | 11.11% | 9.00 | 5 | 0 | 0 | 0 | 0 | 0 | 6 | recursion_role, tutor_role |
| 2 |  | Lorehold 607 Squee, Goblin Nabob equal gate (`candidate_607_squee_goblin_nabob_equal_gate`) | optimizer-equal-gate | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 4 | 1 | 0 | 0 | 0 | 0 | 9 | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/8L/0S`, WR `11.11%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=83, lorehold_spell_cast=65, lorehold_upkeep_rummage=36, miracle_cast=12

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

**Strategic event counts:** lorehold_cost_paid=53, lorehold_spell_cast=42, lorehold_upkeep_rummage=27, topdeck_manipulation_activated=2, miracle_cast=4, lorehold_spell_rummage=2
