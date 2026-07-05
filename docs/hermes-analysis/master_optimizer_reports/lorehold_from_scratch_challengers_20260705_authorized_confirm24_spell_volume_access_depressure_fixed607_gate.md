# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T13:32:57Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_confirm24_spell_volume_access_depressure_fixed607_gate_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 10 | 14 | 0 | 41.67% | 18.50 | 18 | 11 | 8 | 0 | 0 | 0 | 0 | 18 | 0 | 0 | none | draw_role, recursion_role, tutor_role |
| 2 | 1 | Lorehold From-Scratch Spell Volume Access Depressure v1 (`challenger_lorehold_spell_volume_access_depressure_v1`) | from-scratch-spell-volume-access-depressure | 24 | 5 | 19 | 0 | 20.83% | 15.60 | 16 | 12 | 5 | 0 | 0 | 0 | 0 | 18 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `10W/14L/0S`, WR `41.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 24.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 8.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 17.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 2 | 1 | 0 | 66.67% | 26.50 | elimination=2 |
| Aang, at the Crossroads #106 (real) | 2 | 1 | 0 | 66.67% | 13.50 | approach=1, elimination=1 |
| Umbris, Fear Manifest #114 (real) | 2 | 1 | 0 | 66.67% | 16.50 | elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 23.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=38, lorehold_cost_paid=260, lorehold_rummage_discard_to_top=33, lorehold_spell_cast=228, lorehold_spell_rummage=14, lorehold_spell_rummage_discard_to_top=5, lorehold_upkeep_rummage=109, miracle_cast=63, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, static_cost_reduction_casts=26, static_cost_reduction_total=55, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=9, topdeck_manipulation_activated=51

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold From-Scratch Spell Volume Access Depressure v1 (`challenger_lorehold_spell_volume_access_depressure_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/19L/0S`, WR `20.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 15.00 | approach=1 |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 2 | 1 | 0 | 66.67% | 17.00 | approach=1, elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=38, discard_to_top_replacement=42, lorehold_cost_paid=229, lorehold_rummage_discard_to_top=32, lorehold_spell_cast=200, lorehold_spell_rummage=13, lorehold_spell_rummage_discard_to_top=10, lorehold_upkeep_rummage=91, miracle_cast=52, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, spell_cast_mana_trigger=38, static_cost_reduction_casts=6, static_cost_reduction_total=8, topdeck_manipulation_activated=47

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
