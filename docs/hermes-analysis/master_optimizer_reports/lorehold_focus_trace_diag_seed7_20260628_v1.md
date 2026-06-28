# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T02:52:07Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `7`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 2 | 7 | 0 | 22.22% | 17.50 | 3 | 4 | 0 | 0 | 0 | 0 | 0 | 5 | 42 | 31 | Sphere of Safety: events=5, restricted=0, tax=5, Windborn Muse: events=8, restricted=12, tax=26, unattributed: events=11, restricted=30, tax=0 | wincon_role |
| 2 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 1 | 8 | 0 | 11.11% | 9.00 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 6 | 10 | 0 | unattributed: events=10, restricted=10, tax=0 | recursion_role, tutor_role |
| 3 |  | Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`) | strategy-first-squee-cached-timeout | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 4 | 1 | 0 | 0 | 0 | 0 | 0 | 9 | 0 | 0 | none | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `2W/7L/0S`, WR `22.22%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 19.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=95, lorehold_spell_cast=80, lorehold_upkeep_rummage=10, topdeck_manipulation_activated=11, miracle_cast=9

**Lorehold attack restriction telemetry:** events=24, attackers_before=71, attackers_after=29, attackers_restricted=42, tax_paid=31, sources=Sphere of Safety: events=5, restricted=0, tax=5, Windborn Muse: events=8, restricted=12, tax=26, unattributed: events=11, restricted=30, tax=0

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/8L/0S`, WR `11.11%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=83, lorehold_spell_cast=65, lorehold_upkeep_rummage=36, miracle_cast=12

**Lorehold attack restriction telemetry:** events=10, attackers_before=29, attackers_after=19, attackers_restricted=10, tax_paid=0, sources=unattributed: events=10, restricted=10, tax=0

### 3. Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`)

- objective: not available in structural matrix
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=53, lorehold_spell_cast=42, lorehold_upkeep_rummage=27, topdeck_manipulation_activated=2, miracle_cast=4, lorehold_spell_rummage=2

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
