# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T12:24:17Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `45.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_current_pg247_gate_seed42_g3_20260628_v1_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold 607 Squee current PG247 candidate (`candidate_607_squee_current_pg247_v1`) | 607-squee-current-pg247 | 9 | 4 | 5 | 0 | 44.44% | 18.25 | 5 | 6 | 4 | 3 | 3 | 3 | 0 | 8 | 0 | 0 | none | none |
| 2 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 4 | 5 | 0 | 44.44% | 15.25 | 8 | 3 | 4 | 0 | 0 | 0 | 0 | 8 | 5 | 0 | unattributed: events=5, restricted=5, tax=0 | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 Squee current PG247 candidate (`candidate_607_squee_current_pg247_v1`)

- objective: not available in structural matrix
- result: `4W/5L/0S`, WR `44.44%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 3 | 0 | 0 | 100.00% | 18.67 | elimination=3 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 17.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=21, graveyard_upkeep_return_self_to_hand=5, lorehold_cost_paid=140, lorehold_rummage_discard_to_top=21, lorehold_rummage_discards_squee=2, lorehold_spell_cast=113, lorehold_spell_rummage=20, lorehold_spell_rummage_discards_squee=4, lorehold_upkeep_rummage=53, miracle_cast=14, squee_return_after_known_graveyard_entry=5, squee_to_graveyard=7, squee_upkeep_return=5, topdeck_manipulation_activated=24

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/5L/0S`, WR `44.44%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 17.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 15.00 | elimination=2 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=26, lorehold_cost_paid=109, lorehold_rummage_discard_to_top=26, lorehold_spell_cast=88, lorehold_spell_rummage=2, lorehold_upkeep_rummage=58, miracle_cast=26, thor_cost_paid=1, thor_noncreature_damage=4, thor_noncreature_damage_amount=26, topdeck_manipulation_activated=16

**Lorehold attack restriction telemetry:** events=5, attackers_before=11, attackers_after=6, attackers_restricted=5, tax_paid=0, sources=unattributed: events=5, restricted=5, tax=0

