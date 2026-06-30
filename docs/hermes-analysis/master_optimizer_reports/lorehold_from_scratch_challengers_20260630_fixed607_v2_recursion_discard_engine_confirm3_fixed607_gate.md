# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T18:57:20Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_recursion_discard_engine_confirm3_fixed607_gate_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 12 | 5 | 7 | 0 | 41.67% | 13.00 | 10 | 5 | 1 | 0 | 0 | 0 | 0 | 7 | 0 | 0 | none | recursion_role, tutor_role |
| 2 | 4 | Lorehold From-Scratch Recursion Discard Engine v1 (`challenger_lorehold_recursion_discard_engine_v1`) | from-scratch-recursion-discard-engine | 12 | 3 | 9 | 0 | 25.00% | 14.33 | 5 | 5 | 3 | 2 | 2 | 2 | 0 | 7 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/7L/0S`, WR `41.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 11.00 | approach=1, elimination=1 |

**Strategic event counts:** discard_to_top_replacement=12, lorehold_cost_paid=126, lorehold_rummage_discard_to_top=12, lorehold_spell_cast=96, lorehold_spell_rummage=1, lorehold_upkeep_rummage=47, miracle_cast=23, scarlet_static_cost_reduction_casts=4, scarlet_static_cost_reduction_total=8, static_cost_reduction_casts=18, static_cost_reduction_total=34, topdeck_manipulation_activated=13

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold From-Scratch Recursion Discard Engine v1 (`challenger_lorehold_recursion_discard_engine_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/9L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `21`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 20.00 | elimination=1 |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 10.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 13.00 | approach=1 |

**Strategic event counts:** birgi_spell_cast_mana=13, discard_to_top_replacement=10, graveyard_upkeep_return_self_to_hand=6, lorehold_cost_paid=114, lorehold_rummage_discard_to_top=10, lorehold_rummage_discards_squee=7, lorehold_spell_cast=95, lorehold_upkeep_rummage=30, miracle_cast=7, spell_cast_mana_trigger=13, squee_return_after_known_graveyard_entry=6, squee_to_graveyard=7, squee_upkeep_return=6, static_cost_reduction_casts=13, static_cost_reduction_total=31, topdeck_manipulation_activated=26

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

