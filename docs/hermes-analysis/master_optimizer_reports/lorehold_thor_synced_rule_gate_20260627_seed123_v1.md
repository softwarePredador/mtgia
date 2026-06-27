# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T17:04:53Z`
- source_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `123`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `30.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_thor_synced_rule_gate_20260627_seed123_v1_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 3 | 1 | 2 | 0 | 33.33% | 10.00 | 3 | 1 | 0 | 0 | 0 | 0 | 3 | wincon_role |
| 2 |  | Lorehold deck 6 with synced Thor runtime rule (`deck_6_thor_synced`) | thor-rule-sync-audit | 3 | 1 | 2 | 0 | 33.33% | 10.00 | 3 | 1 | 0 | 0 | 0 | 0 | 3 | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 10.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=32, lorehold_spell_cast=25, lorehold_upkeep_rummage=16, miracle_cast=6, thor_cost_paid=1, thor_spell_cast=1, lorehold_spell_rummage=3, topdeck_manipulation_activated=2

### 2. Lorehold deck 6 with synced Thor runtime rule (`deck_6_thor_synced`)

- objective: not available in structural matrix
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 10.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=32, lorehold_spell_cast=24, lorehold_upkeep_rummage=16, miracle_cast=6, thor_cost_paid=1, thor_noncreature_damage=1, thor_noncreature_damage_amount=7, lorehold_spell_rummage=3, topdeck_manipulation_activated=2
