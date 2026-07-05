# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T13:30:48Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `45.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_spell_pressure_mana_conversion_deoverfill_fixed607_gate_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 8 | 4 | 4 | 0 | 50.00% | 14.25 | 6 | 2 | 1 | 0 | 0 | 0 | 0 | 6 | 1 | 0 | Promise of Loyalty: events=1, restricted=1, tax=0 | draw_role, recursion_role, tutor_role |
| 2 | 1 | Lorehold From-Scratch Spell Pressure Mana Conversion Deoverfill v1 (`challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1`) | from-scratch-spell-pressure-mana-conversion-deoverfill | 8 | 3 | 5 | 0 | 37.50% | 16.33 | 7 | 3 | 1 | 0 | 0 | 0 | 0 | 7 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/4L/0S`, WR `50.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 19.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 13.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=6, lorehold_cost_paid=93, lorehold_rummage_discard_to_top=6, lorehold_spell_cast=80, lorehold_upkeep_rummage=34, miracle_cast=20, static_cost_reduction_casts=9, static_cost_reduction_total=23, thor_cost_paid=1, topdeck_manipulation_activated=4

**Lorehold attack restriction telemetry:** events=1, attackers_before=2, attackers_after=1, attackers_restricted=1, tax_paid=0, sources=Promise of Loyalty: events=1, restricted=1, tax=0

### 2. Lorehold From-Scratch Spell Pressure Mana Conversion Deoverfill v1 (`challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/5L/0S`, WR `37.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `19`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 0 | 0 | 100.00% | 21.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=10, lorehold_cost_paid=79, lorehold_rummage_discard_to_top=10, lorehold_spell_cast=62, lorehold_upkeep_rummage=26, miracle_cast=18, static_cost_reduction_casts=4, static_cost_reduction_total=4, topdeck_manipulation_activated=7

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
