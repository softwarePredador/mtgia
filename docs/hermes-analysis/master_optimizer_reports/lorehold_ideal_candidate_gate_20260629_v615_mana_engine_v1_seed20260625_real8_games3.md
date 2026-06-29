# Lorehold Equal Battle Gate

- generated_at: `2026-06-29T20:24:52Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260625`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_gate_20260629_v615_mana_engine_v1_seed20260625_real8_games3_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`) | 607-615-mana-engine-candidate | 24 | 10 | 14 | 0 | 41.67% | 14.60 | 17 | 9 | 4 | 0 | 0 | 0 | 0 | 16 | 0 | 0 | none | none |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 7 | 17 | 0 | 29.17% | 13.71 | 13 | 7 | 6 | 0 | 0 | 0 | 0 | 19 | 1 | 0 | unattributed: events=1, restricted=1, tax=0 | recursion_role, tutor_role |
| 3 | 3 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 24 | 5 | 19 | 0 | 20.83% | 18.20 | 10 | 7 | 1 | 0 | 0 | 0 | 0 | 10 | 0 | 0 | none | removal_role, protection_role, recursion_role |
| 4 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 24 | 5 | 19 | 0 | 20.83% | 16.20 | 13 | 3 | 1 | 0 | 0 | 0 | 0 | 17 | 0 | 0 | none | removal_role, recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`)

- objective: not available in structural matrix
- result: `10W/14L/0S`, WR `41.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `19`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 13.00 | elimination=2 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 16.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 3 | 0 | 0 | 100.00% | 11.33 | approach=2, elimination=1 |
| Umbris, Fear Manifest #114 (real) | 3 | 0 | 0 | 100.00% | 18.33 | approach=1, elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=59, discard_to_top_replacement=37, lorehold_cost_paid=298, lorehold_rummage_discard_to_top=27, lorehold_spell_cast=266, lorehold_spell_rummage=29, lorehold_spell_rummage_discard_to_top=10, lorehold_upkeep_rummage=84, miracle_cast=39, spell_cast_mana_trigger=59, thor_cost_paid=1, thor_noncreature_damage=6, thor_noncreature_damage_amount=22, topdeck_manipulation_activated=35

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `7W/17L/0S`, WR `29.17%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 18.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 2 | 1 | 0 | 66.67% | 10.50 | approach=1, elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 2 | 1 | 0 | 66.67% | 14.00 | elimination=2 |

**Strategic event counts:** discard_to_top_replacement=20, lorehold_cost_paid=212, lorehold_rummage_discard_to_top=11, lorehold_spell_cast=167, lorehold_spell_rummage=16, lorehold_spell_rummage_discard_to_top=9, lorehold_upkeep_rummage=84, miracle_cast=31, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=5, topdeck_manipulation_activated=20

**Lorehold attack restriction telemetry:** events=1, attackers_before=2, attackers_after=1, attackers_restricted=1, tax_paid=0, sources=unattributed: events=1, restricted=1, tax=0

### 3. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

- objective: Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.
- result: `5W/19L/0S`, WR `20.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `22`, removal `8`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 20.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 2 | 1 | 0 | 66.67% | 21.50 | elimination=2 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |

**Strategic event counts:** discard_to_top_replacement=4, hand_to_topdeck_activation=1, lorehold_cost_paid=202, lorehold_rummage_discard_to_top=4, lorehold_spell_cast=162, lorehold_upkeep_rummage=47, miracle_cast=30, topdeck_manipulation_activated=25

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 4. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `5W/19L/0S`, WR `20.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 11.00 | approach=1, elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 17.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 27.00 | approach=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=1, discard_to_top_replacement=8, lorehold_cost_paid=203, lorehold_rummage_discard_to_top=8, lorehold_spell_cast=169, lorehold_upkeep_rummage=85, miracle_cast=27, spell_cast_mana_trigger=1, topdeck_manipulation_activated=5

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
