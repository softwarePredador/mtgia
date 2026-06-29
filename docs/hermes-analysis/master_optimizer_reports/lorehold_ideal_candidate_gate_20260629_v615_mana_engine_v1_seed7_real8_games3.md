# Lorehold Equal Battle Gate

- generated_at: `2026-06-29T20:24:50Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `7`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_gate_20260629_v615_mana_engine_v1_seed7_real8_games3_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 8 | 16 | 0 | 33.33% | 14.50 | 15 | 8 | 6 | 0 | 0 | 0 | 0 | 18 | 5 | 0 | unattributed: events=5, restricted=5, tax=0 | recursion_role, tutor_role |
| 2 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 24 | 8 | 16 | 0 | 33.33% | 15.75 | 13 | 8 | 3 | 0 | 0 | 0 | 0 | 15 | 0 | 0 | none | removal_role, recursion_role, tutor_role |
| 3 | 3 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 24 | 5 | 19 | 0 | 20.83% | 18.40 | 8 | 8 | 2 | 0 | 0 | 0 | 0 | 9 | 0 | 0 | none | removal_role, protection_role, recursion_role |
| 4 |  | Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`) | 607-615-mana-engine-candidate | 24 | 2 | 22 | 0 | 8.33% | 12.50 | 11 | 7 | 4 | 0 | 0 | 0 | 0 | 15 | 11 | 0 | unattributed: events=11, restricted=11, tax=0 | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 8.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 20.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 3 | 0 | 0 | 100.00% | 14.33 | approach=2, elimination=1 |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 2 | 1 | 0 | 66.67% | 17.50 | approach=1, elimination=1 |

**Strategic event counts:** discard_to_top_replacement=36, lorehold_cost_paid=256, lorehold_rummage_discard_to_top=29, lorehold_spell_cast=214, lorehold_spell_rummage=8, lorehold_spell_rummage_discard_to_top=7, lorehold_upkeep_rummage=115, miracle_cast=38, thor_cost_paid=2, thor_noncreature_damage=1, thor_noncreature_damage_amount=7, topdeck_manipulation_activated=43

**Lorehold attack restriction telemetry:** events=5, attackers_before=19, attackers_after=14, attackers_restricted=5, tax_paid=0, sources=unattributed: events=5, restricted=5, tax=0

### 2. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 21.00 | approach=1, elimination=1 |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 2 | 1 | 0 | 66.67% | 16.50 | approach=1, elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=11, discard_to_top_replacement=20, lorehold_cost_paid=274, lorehold_rummage_discard_to_top=20, lorehold_spell_cast=251, lorehold_upkeep_rummage=79, miracle_cast=48, spell_cast_mana_trigger=11, topdeck_manipulation_activated=32

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 3. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

- objective: Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.
- result: `5W/19L/0S`, WR `20.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `22`, removal `8`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 20.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 2 | 1 | 0 | 66.67% | 23.00 | approach=2 |

**Strategic event counts:** discard_to_top_replacement=7, hand_to_topdeck_activation=2, lorehold_cost_paid=159, lorehold_rummage_discard_to_top=7, lorehold_spell_cast=121, lorehold_upkeep_rummage=42, miracle_cast=24, topdeck_manipulation_activated=42

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 4. Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`)

- objective: not available in structural matrix
- result: `2W/22L/0S`, WR `8.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `19`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=14, discard_to_top_replacement=19, lorehold_cost_paid=162, lorehold_rummage_discard_to_top=19, lorehold_spell_cast=141, lorehold_spell_rummage=4, lorehold_upkeep_rummage=69, miracle_cast=20, spell_cast_mana_trigger=14, topdeck_manipulation_activated=9

**Lorehold attack restriction telemetry:** events=11, attackers_before=32, attackers_after=21, attackers_restricted=11, tax_paid=0, sources=unattributed: events=11, restricted=11, tax=0
