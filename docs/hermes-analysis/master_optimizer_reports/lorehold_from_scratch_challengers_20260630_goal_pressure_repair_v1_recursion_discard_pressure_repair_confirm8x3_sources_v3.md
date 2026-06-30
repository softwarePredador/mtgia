# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T20:11:20Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_confirm8x3_sources_v3_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 6 | 18 | 0 | 25.00% | 18.17 | 9 | 7 | 1 | 0 | 0 | 0 | 0 | 16 | 3 | 0 | Promise of Loyalty: events=3, restricted=3, tax=0 | recursion_role, tutor_role |
| 2 | 4 | Lorehold From-Scratch Recursion Discard Pressure Repair v1 (`challenger_lorehold_recursion_discard_pressure_repair_v1`) | from-scratch-recursion-discard-pressure-repair | 24 | 3 | 21 | 0 | 12.50% | 16.00 | 11 | 3 | 1 | 3 | 3 | 3 | 1 | 13 | 59 | 0 | Crawlspace: events=1, restricted=1, tax=0, Promise of Loyalty: events=6, restricted=6, tax=0, Silent Arbiter: events=19, restricted=52, tax=0 | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `6W/18L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 34.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 18.50 | elimination=2 |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 2 | 1 | 0 | 66.67% | 13.50 | approach=2 |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=15, lorehold_cost_paid=214, lorehold_rummage_discard_to_top=15, lorehold_spell_cast=183, lorehold_spell_rummage=5, lorehold_upkeep_rummage=74, miracle_cast=40, scarlet_static_cost_reduction_casts=4, scarlet_static_cost_reduction_total=7, static_cost_reduction_casts=11, static_cost_reduction_total=22, thor_cost_paid=2, thor_noncreature_damage=8, thor_noncreature_damage_amount=29, topdeck_manipulation_activated=26

**Lorehold attack restriction telemetry:** events=3, attackers_before=9, attackers_after=6, attackers_restricted=3, tax_paid=0, sources=Promise of Loyalty: events=3, restricted=3, tax=0

### 2. Lorehold From-Scratch Recursion Discard Pressure Repair v1 (`challenger_lorehold_recursion_discard_pressure_repair_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/21L/0S`, WR `12.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `17`, removal `14`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 25.00 | elimination=1 |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 8.00 | approach=1 |

**Strategic event counts:** birgi_spell_cast_mana=7, discard_to_top_replacement=9, graveyard_upkeep_return_self_to_hand=13, lorehold_cost_paid=156, lorehold_rummage_discard_to_top=9, lorehold_rummage_discards_squee=7, lorehold_spell_cast=127, lorehold_upkeep_rummage=52, miracle_cast=25, scarlet_static_cost_reduction_casts=1, scarlet_static_cost_reduction_total=2, spell_cast_mana_trigger=7, squee_return_after_known_graveyard_entry=11, squee_return_without_known_graveyard_entry=2, squee_to_graveyard=12, squee_upkeep_return=13, static_cost_reduction_casts=8, static_cost_reduction_total=9, topdeck_manipulation_activated=18

**Lorehold attack restriction telemetry:** events=26, attackers_before=86, attackers_after=27, attackers_restricted=59, tax_paid=0, sources=Crawlspace: events=1, restricted=1, tax=0, Promise of Loyalty: events=6, restricted=6, tax=0, Silent Arbiter: events=19, restricted=52, tax=0
