# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T02:58:17Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `False`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`) | strategy-first-squee-cached-timeout | 9 | 7 | 2 | 0 | 77.78% | 16.14 | 7 | 5 | 3 | 4 | 2 | 2 | 0 | 6 | 0 | 0 | none | none |

## Deck Detail

### 1. Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`)

- objective: not available in structural matrix
- result: `7W/2L/0S`, WR `77.78%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 3 | 0 | 0 | 100.00% | 19.67 | elimination=3 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 10.50 | approach=2 |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 16.50 | approach=1, elimination=1 |

**Strategic event counts:** lorehold_cost_paid=137, lorehold_spell_cast=107, lorehold_spell_rummage=18, lorehold_upkeep_rummage=39, miracle_cast=32, topdeck_manipulation_activated=30, squee_to_graveyard=7, discard_to_top_replacement=16, lorehold_spell_rummage_discard_to_top=3, lorehold_rummage_discard_to_top=13, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
