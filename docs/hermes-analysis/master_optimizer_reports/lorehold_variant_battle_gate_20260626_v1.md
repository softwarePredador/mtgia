# Lorehold Equal Battle Gate

- generated_at: `2026-06-26T15:27:18Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 3 | 1 | 2 | 0 | 33.33% | 18.00 | 2 | 3 | wincon_role |
| 2 | 8 | VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`) | submitted-variant | 3 | 1 | 2 | 0 | 33.33% | 14.00 | 3 | 1 | deterministic_finisher, removal_role, protection_role, recursion_role, tutor_role, wincon_role, high_land_count |
| 3 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 3 | 1 | 2 | 0 | 33.33% | 14.00 | 2 | 1 | recursion_role, tutor_role |
| 4 | 13 | VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`) | battle-variant | 3 | 1 | 2 | 0 | 33.33% | 14.00 | 1 | 0 | protection_window, deterministic_finisher, land_role, removal_role, protection_role, recursion_role, board_wipe_role, wincon_role |
| 5 | 1 | Lorehold strategy-first candidate v7 (`candidate_v7`) | strategy-first-candidate | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 0 | 1 | none |
| 6 | 7 | VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`) | battle-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 2 | 2 | land_role, protection_role, recursion_role, low_land_count |
| 7 | 11 | VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`) | artifact-control-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 1 | 0 | protection_window, deterministic_finisher, land_role, draw_role, removal_role, protection_role, recursion_role, wincon_role |
| 8 | 9 | VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`) | big-spells-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 2 | 1 | protection_window, removal_role, protection_role, recursion_role |
| 9 | 12 | VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`) | spell-copy-combo-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 0 | 1 | protection_window, land_role, draw_role, removal_role, protection_role, recursion_role, tutor_role, low_land_count |
| 10 | 4 | VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`) | spell-copy-control-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 1 | 0 | land_role, removal_role, recursion_role |
| 11 | 5 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 1 | 0 | removal_role, protection_role, recursion_role |
| 12 | 3 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 1 | 1 | removal_role, recursion_role, tutor_role |
| 13 | 10 | VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`) | burn-dragon-control-variant | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 0 | 0 | graveyard_recursion, land_role, ramp_role, recursion_role, tutor_role, battle_rule_readiness, low_land_count |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 18.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=42, lorehold_spell_cast=36, topdeck_manipulation_activated=14, miracle_cast=3

### 2. VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `39`, ramp `19`, removal `11`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=42, lorehold_spell_cast=33, miracle_cast=3, topdeck_manipulation_activated=4

### 3. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=36, lorehold_spell_cast=28, miracle_cast=6, topdeck_manipulation_activated=1

### 4. VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `31`, ramp `20`, removal `5`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=17, lorehold_spell_cast=13, miracle_cast=2

### 5. Lorehold strategy-first candidate v7 (`candidate_v7`)

- objective: Strategy-first miracle spellslinger control/combo shell that preserves the active core while tuning lands and package balance.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `52`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=22, lorehold_spell_cast=17, topdeck_manipulation_activated=1

### 6. VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `30`, ramp `15`, removal `11`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=32, lorehold_spell_cast=23, miracle_cast=3, topdeck_manipulation_activated=5

### 7. VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`)

- objective: Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `30`, ramp `20`, removal `9`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=27, lorehold_spell_cast=20, miracle_cast=3

### 8. VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `19`, removal `5`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=29, lorehold_spell_cast=21, miracle_cast=2, topdeck_manipulation_activated=1

### 9. VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`)

- objective: Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `27`, ramp `22`, removal `6`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=19, lorehold_spell_cast=10, topdeck_manipulation_activated=2

### 10. VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`)

- objective: Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `32`, ramp `19`, removal `7`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=13, lorehold_spell_cast=11, miracle_cast=1

### 11. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

- objective: Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `22`, removal `8`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=13, lorehold_spell_cast=12, miracle_cast=1

### 12. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=17, lorehold_spell_cast=13, topdeck_manipulation_activated=1, miracle_cast=1

### 13. VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`)

- objective: Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `29`, ramp `9`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=13, lorehold_spell_cast=8
