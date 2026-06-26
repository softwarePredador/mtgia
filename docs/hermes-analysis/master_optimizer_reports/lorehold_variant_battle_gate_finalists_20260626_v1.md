# Lorehold Equal Battle Gate

- generated_at: `2026-06-26T15:46:38Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 5 | 4 | 0 | 55.56% | 13.60 | 7 | 4 | recursion_role, tutor_role |
| 2 | 1 | Lorehold strategy-first candidate v7 (`candidate_v7`) | strategy-first-candidate | 9 | 3 | 5 | 1 | 33.33% | 18.00 | 6 | 7 | none |
| 3 | 13 | VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`) | battle-variant | 9 | 1 | 8 | 0 | 11.11% | 13.00 | 1 | 0 | protection_window, deterministic_finisher, land_role, removal_role, protection_role, recursion_role, board_wipe_role, wincon_role |
| 4 | 3 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 9 | 1 | 8 | 0 | 11.11% | 18.00 | 2 | 1 | removal_role, recursion_role, tutor_role |
| 5 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 2 | 1 | wincon_role |
| 6 | 8 | VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`) | submitted-variant | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 3 | 1 | deterministic_finisher, removal_role, protection_role, recursion_role, tutor_role, wincon_role, high_land_count |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/4L/0S`, WR `55.56%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 14.50 | elimination=1, approach=1 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 12.50 | elimination=1, approach=1 |

**Strategic event counts:** lorehold_cost_paid=100, lorehold_spell_cast=81, miracle_cast=23, topdeck_manipulation_activated=15

### 2. Lorehold strategy-first candidate v7 (`candidate_v7`)

- objective: Strategy-first miracle spellslinger control/combo shell that preserves the active core while tuning lands and package balance.
- result: `3W/5L/1S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `52`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 7.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 0 | 1 | 66.67% | 23.50 | elimination=1, approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=145, lorehold_spell_cast=111, topdeck_manipulation_activated=21, miracle_cast=24

### 3. VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/8L/0S`, WR `11.11%`
- construction_valid: `True`
- deck shape: size `100`, lands `31`, ramp `20`, removal `5`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=54, lorehold_spell_cast=45, miracle_cast=2

### 4. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `1W/8L/0S`, WR `11.11%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 18.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=57, lorehold_spell_cast=44, topdeck_manipulation_activated=1, miracle_cast=3

### 5. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=47, topdeck_manipulation_activated=5, miracle_cast=4

### 6. VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `39`, ramp `19`, removal `11`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=52, miracle_cast=3, topdeck_manipulation_activated=3
