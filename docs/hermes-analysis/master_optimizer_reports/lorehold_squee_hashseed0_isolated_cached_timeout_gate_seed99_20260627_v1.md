# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T15:28:28Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `99`
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
| 1 |  | Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`) | strategy-first-squee-cached-timeout | 9 | 2 | 7 | 0 | 22.22% | 14.50 | 6 | 3 | 1 | 1 | 1 | 0 | 8 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 1 | 8 | 0 | 11.11% | 15.00 | 7 | 5 | 0 | 0 | 0 | 0 | 4 | wincon_role |
| 3 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 7 | 3 | 0 | 0 | 0 | 0 | 9 | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`)

- objective: not available in structural matrix
- result: `2W/7L/0S`, WR `22.22%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=103, lorehold_spell_cast=84, lorehold_upkeep_rummage=41, miracle_cast=14, topdeck_manipulation_activated=13, lorehold_spell_rummage=21, squee_to_graveyard=1, graveyard_upkeep_return_self_to_hand=1, squee_upkeep_return=1, squee_return_after_known_graveyard_entry=1

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/8L/0S`, WR `11.11%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=90, lorehold_spell_cast=72, lorehold_upkeep_rummage=19, topdeck_manipulation_activated=14, miracle_cast=13

### 3. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=74, lorehold_spell_cast=57, lorehold_spell_rummage=2, lorehold_upkeep_rummage=27, topdeck_manipulation_activated=8, miracle_cast=11
