# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T17:16:02Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
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

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 |  | Lorehold synergy package: galvanoth_topdeck_freecast_cut_chimes (`synergy_galvanoth_topdeck_freecast_cut_chimes`) | synergy-package | 9 | 3 | 6 | 0 | 33.33% | 17.33 | 7 | 3 | 3 | 3 | 3 | 0 | 6 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 2 | 1 | 0 | 0 | 0 | 0 | 8 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: galvanoth_topdeck_freecast_cut_chimes (`synergy_galvanoth_topdeck_freecast_cut_chimes`)

- objective: not available in structural matrix
- result: `3W/6L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `17`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 19.00 | elimination=1, approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=100, lorehold_spell_cast=81, lorehold_upkeep_rummage=26, miracle_cast=16, squee_to_graveyard=6, graveyard_upkeep_return_self_to_hand=6, squee_upkeep_return=6, squee_return_after_known_graveyard_entry=6, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=13, lorehold_spell_rummage=16

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=48, lorehold_upkeep_rummage=38, topdeck_manipulation_activated=3, miracle_cast=4, lorehold_spell_rummage=2, thor_cost_paid=1, thor_spell_cast=1
