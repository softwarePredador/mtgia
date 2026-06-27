# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T18:57:34Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 8 | 1 | 0 | 88.89% | 15.12 | 8 | 5 | 3 | 4 | 2 | 2 | 0 | 7 | wincon_role |
| 2 |  | Lorehold synergy package: galvanoth_topdeck_freecast_cut_thor (`synergy_galvanoth_topdeck_freecast_cut_thor`) | synergy-package | 9 | 3 | 6 | 0 | 33.33% | 17.67 | 5 | 3 | 1 | 3 | 3 | 3 | 0 | 6 | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/1L/0S`, WR `88.89%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 3 | 0 | 0 | 100.00% | 19.67 | elimination=3 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 1 | 0 | 66.67% | 10.50 | approach=2 |
| Winota, Joiner of Forces #39 (real) | 3 | 0 | 0 | 100.00% | 13.67 | approach=2, elimination=1 |

**Strategic event counts:** lorehold_cost_paid=148, lorehold_spell_cast=118, lorehold_spell_rummage=19, lorehold_upkeep_rummage=41, miracle_cast=33, topdeck_manipulation_activated=30, squee_to_graveyard=7, discard_to_top_replacement=16, lorehold_spell_rummage_discard_to_top=3, lorehold_rummage_discard_to_top=13, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5

### 2. Lorehold synergy package: galvanoth_topdeck_freecast_cut_thor (`synergy_galvanoth_topdeck_freecast_cut_thor`)

- objective: not available in structural matrix
- result: `3W/6L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 17.50 | elimination=2 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 18.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=91, lorehold_spell_cast=65, lorehold_upkeep_rummage=26, discard_to_top_replacement=7, lorehold_rummage_discard_to_top=7, miracle_cast=14, topdeck_manipulation_activated=6, squee_to_graveyard=5, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5, lorehold_spell_rummage=1

