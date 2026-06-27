# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T15:34:49Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `123`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 |  | Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`) | strategy-first-squee-cached-timeout | 9 | 5 | 4 | 0 | 55.56% | 14.40 | 6 | 4 | 0 | 0 | 0 | 0 | 8 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 5 | 4 | 0 | 55.56% | 17.80 | 7 | 5 | 0 | 0 | 0 | 0 | 7 | wincon_role |
| 3 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 3 | 6 | 0 | 33.33% | 13.00 | 5 | 1 | 0 | 0 | 0 | 0 | 5 | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`)

- objective: not available in structural matrix
- result: `5W/4L/0S`, WR `55.56%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 15.50 | elimination=2 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 15.50 | approach=1, elimination=1 |

**Strategic event counts:** lorehold_cost_paid=105, lorehold_spell_cast=87, lorehold_upkeep_rummage=46, miracle_cast=19, topdeck_manipulation_activated=11

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/4L/0S`, WR `55.56%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 3 | 0 | 0 | 100.00% | 16.00 | approach=2, elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 28.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=124, lorehold_spell_cast=99, topdeck_manipulation_activated=20, lorehold_upkeep_rummage=14, miracle_cast=17

### 3. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/6L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 16.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 12.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=89, lorehold_spell_cast=72, lorehold_upkeep_rummage=25, miracle_cast=16, topdeck_manipulation_activated=2
