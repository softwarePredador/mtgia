# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T17:52:33Z`
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

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 |  | Lorehold synergy package: brainstone_topdeck_miracle_cut_squelcher (`synergy_brainstone_topdeck_miracle_cut_squelcher`) | synergy-package | 9 | 5 | 4 | 0 | 55.56% | 21.20 | 8 | 5 | 3 | 4 | 3 | 3 | 0 | 7 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 2 | 1 | 3 | 0 | 0 | 0 | 0 | 8 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: brainstone_topdeck_miracle_cut_squelcher (`synergy_brainstone_topdeck_miracle_cut_squelcher`)

- objective: not available in structural matrix
- result: `5W/4L/0S`, WR `55.56%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 22.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 3 | 0 | 0 | 100.00% | 23.00 | elimination=3 |

**Strategic event counts:** lorehold_cost_paid=140, lorehold_spell_cast=110, lorehold_upkeep_rummage=40, topdeck_manipulation_activated=29, squee_to_graveyard=8, miracle_cast=27, lorehold_spell_rummage=3, discard_to_top_replacement=18, lorehold_spell_rummage_discard_to_top=3, lorehold_rummage_discard_to_top=15, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5, thor_cost_paid=2, thor_spell_cast=2

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

**Strategic event counts:** lorehold_cost_paid=64, lorehold_spell_cast=48, lorehold_upkeep_rummage=38, discard_to_top_replacement=14, lorehold_rummage_discard_to_top=14, topdeck_manipulation_activated=3, miracle_cast=4, lorehold_spell_rummage=2, thor_cost_paid=1, thor_spell_cast=1
