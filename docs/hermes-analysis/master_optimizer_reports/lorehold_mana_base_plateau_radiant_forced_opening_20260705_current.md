# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T00:33:00Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `generic+fixed_deck`
- opponent_seed: `20260705`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `20260705`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `30.0`
- forced_access_mode: `opening_hand`
- game_checkpoint_json: `None`
- opponents: `Fixed Lorehold deck 607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 3 | 2 | 1 | 0 | 66.67% | 10.00 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | none | recursion_role, tutor_role |
| 2 |  | Lorehold 607 mana base: Plateau over Radiant Summit (`candidate_607_plateau_radiant_mana_base_v1`) | mana-base-diagnostic | 3 | 1 | 2 | 0 | 33.33% | 14.00 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | none | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `2W/1L/0S`, WR `66.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 2 | 1 | 0 | 66.67% | 10.00 | approach=1, elimination=1 |

**Strategic event counts:** lorehold_cost_paid=17, lorehold_spell_cast=15, lorehold_upkeep_rummage=9, miracle_cast=3, topdeck_manipulation_activated=4

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold 607 mana base: Plateau over Radiant Summit (`candidate_607_plateau_radiant_mana_base_v1`)

- objective: not available in structural matrix
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=32, lorehold_spell_cast=27, lorehold_upkeep_rummage=10, miracle_cast=3, static_cost_reduction_casts=10, static_cost_reduction_total=10, thor_cost_paid=1, thor_noncreature_damage=1, thor_noncreature_damage_amount=2, topdeck_manipulation_activated=6

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
