# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T19:51:37Z`
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
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_definitive_learning_v1_recursion_discard_engine_confirm8x3_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 6 | 18 | 0 | 25.00% | 18.17 | 9 | 7 | 1 | 0 | 0 | 0 | 0 | 16 | 3 | 0 | unattributed: events=3, restricted=3, tax=0 | recursion_role, tutor_role |
| 2 | 4 | Lorehold From-Scratch Recursion Discard Engine v1 (`challenger_lorehold_recursion_discard_engine_v1`) | from-scratch-recursion-discard-engine | 24 | 4 | 20 | 0 | 16.67% | 13.50 | 12 | 8 | 3 | 1 | 1 | 1 | 0 | 13 | 0 | 0 | none | recursion_role, tutor_role |

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

**Lorehold attack restriction telemetry:** events=3, attackers_before=9, attackers_after=6, attackers_restricted=3, tax_paid=0, sources=unattributed: events=3, restricted=3, tax=0

### 2. Lorehold From-Scratch Recursion Discard Engine v1 (`challenger_lorehold_recursion_discard_engine_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/20L/0S`, WR `16.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `21`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 17.00 | elimination=1 |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 12.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** birgi_spell_cast_mana=5, discard_to_top_replacement=24, graveyard_upkeep_return_self_to_hand=3, hand_to_topdeck_activation=1, lorehold_cost_paid=165, lorehold_rummage_discard_to_top=24, lorehold_rummage_discards_squee=3, lorehold_spell_cast=143, lorehold_upkeep_rummage=63, miracle_cast=26, spell_cast_mana_trigger=5, squee_return_after_known_graveyard_entry=3, squee_to_graveyard=3, squee_upkeep_return=3, static_cost_reduction_casts=3, static_cost_reduction_total=3, topdeck_manipulation_activated=30

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
