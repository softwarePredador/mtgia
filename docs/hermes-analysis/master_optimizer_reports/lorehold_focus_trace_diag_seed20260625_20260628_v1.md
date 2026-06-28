# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T02:52:48Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260625`
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
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 4 | 5 | 0 | 44.44% | 14.75 | 7 | 2 | 1 | 0 | 0 | 0 | 0 | 7 | 10 | 0 | unattributed: events=10, restricted=10, tax=0 | recursion_role, tutor_role |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 3 | 6 | 0 | 33.33% | 17.00 | 5 | 3 | 0 | 0 | 0 | 0 | 0 | 3 | 2 | 4 | Windborn Muse: events=2, restricted=2, tax=4 | wincon_role |
| 3 |  | Lorehold 607 Squee isolated cached timeout candidate v3 (`candidate_607_squee_hashseed0_isolated_cached_timeout_v3`) | strategy-first-squee-cached-timeout | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 2 | 1 | 3 | 0 | 0 | 0 | 0 | 8 | 9 | 0 | unattributed: events=9, restricted=9, tax=0 | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/5L/0S`, WR `44.44%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 3 | 0 | 0 | 100.00% | 16.00 | elimination=3 |

**Strategic event counts:** lorehold_cost_paid=97, lorehold_spell_cast=84, lorehold_upkeep_rummage=46, discard_to_top_replacement=7, lorehold_rummage_discard_to_top=7, miracle_cast=25, topdeck_manipulation_activated=17

**Lorehold attack restriction telemetry:** events=10, attackers_before=24, attackers_after=14, attackers_restricted=10, tax_paid=0, sources=unattributed: events=10, restricted=10, tax=0

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/6L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `51`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 17.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 17.00 | elimination=2 |

**Strategic event counts:** lorehold_cost_paid=100, lorehold_spell_cast=79, topdeck_manipulation_activated=4, miracle_cast=10, lorehold_upkeep_rummage=4, spell_cast_mana_trigger=2, birgi_spell_cast_mana=2

**Lorehold attack restriction telemetry:** events=2, attackers_before=4, attackers_after=2, attackers_restricted=2, tax_paid=4, sources=Windborn Muse: events=2, restricted=2, tax=4

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

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=48, lorehold_upkeep_rummage=38, discard_to_top_replacement=14, lorehold_rummage_discard_to_top=14, topdeck_manipulation_activated=3, miracle_cast=4, lorehold_spell_rummage=2, thor_cost_paid=1, thor_spell_cast=1

**Lorehold attack restriction telemetry:** events=9, attackers_before=29, attackers_after=20, attackers_restricted=9, tax_paid=0, sources=unattributed: events=9, restricted=9, tax=0
