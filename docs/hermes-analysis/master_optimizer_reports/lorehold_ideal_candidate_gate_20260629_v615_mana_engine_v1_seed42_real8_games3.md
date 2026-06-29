# Lorehold Equal Battle Gate

- generated_at: `2026-06-29T20:20:04Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_gate_20260629_v615_mana_engine_v1_seed42_real8_games3_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`) | 607-615-mana-engine-candidate | 24 | 6 | 18 | 0 | 25.00% | 15.33 | 13 | 8 | 4 | 0 | 0 | 0 | 0 | 15 | 0 | 0 | none | none |
| 2 | 3 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 24 | 4 | 20 | 0 | 16.67% | 21.50 | 10 | 6 | 2 | 0 | 0 | 0 | 0 | 14 | 0 | 0 | none | removal_role, protection_role, recursion_role |
| 3 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 3 | 21 | 0 | 12.50% | 19.67 | 7 | 6 | 1 | 0 | 0 | 0 | 0 | 17 | 0 | 0 | none | recursion_role, tutor_role |
| 4 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 24 | 3 | 21 | 0 | 12.50% | 17.00 | 12 | 8 | 3 | 0 | 0 | 0 | 0 | 18 | 0 | 0 | none | removal_role, recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 + 615 Mana Engine Candidate v1 (`candidate_607_v615_mana_engine_v1`)

- objective: not available in structural matrix
- result: `6W/18L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `19`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 19.00 | elimination=2 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 7.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 25.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 9.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=14, discard_to_top_replacement=21, lorehold_cost_paid=248, lorehold_rummage_discard_to_top=21, lorehold_spell_cast=210, lorehold_spell_rummage=1, lorehold_upkeep_rummage=69, miracle_cast=39, spell_cast_mana_trigger=14, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=6, topdeck_manipulation_activated=38

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

- objective: Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.
- result: `4W/20L/0S`, WR `16.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `22`, removal `8`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 25.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 2 | 1 | 0 | 66.67% | 21.50 | elimination=2 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 18.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=5, hand_to_topdeck_activation=1, lorehold_cost_paid=220, lorehold_rummage_discard_to_top=5, lorehold_spell_cast=143, lorehold_upkeep_rummage=72, miracle_cast=39, topdeck_manipulation_activated=35

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 3. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/21L/0S`, WR `12.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 20.00 | elimination=2 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=9, lorehold_cost_paid=207, lorehold_rummage_discard_to_top=9, lorehold_spell_cast=163, lorehold_upkeep_rummage=67, miracle_cast=16, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=5, topdeck_manipulation_activated=17

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 4. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `3W/21L/0S`, WR `12.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=14, discard_to_top_replacement=27, lorehold_cost_paid=188, lorehold_rummage_discard_to_top=27, lorehold_spell_cast=156, lorehold_upkeep_rummage=96, miracle_cast=25, spell_cast_mana_trigger=14, topdeck_manipulation_activated=28

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
