# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T22:14:55Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `2`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 |  | Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`) | synergy-package | 16 | 7 | 9 | 0 | 43.75% | 14.43 | 9 | 3 | 4 | 2 | 2 | 2 | 0 | 12 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 3 | 13 | 0 | 18.75% | 18.67 | 9 | 3 | 3 | 1 | 1 | 1 | 0 | 13 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`)

- objective: not available in structural matrix
- result: `7W/9L/0S`, WR `43.75%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 1 | 0 | 50.00% | 17.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 1 | 0 | 50.00% | 9.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 1 | 0 | 50.00% | 14.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 2 | 0 | 0 | 100.00% | 16.50 | elimination=2 |
| Umbris, Fear Manifest #114 (real) | 1 | 1 | 0 | 50.00% | 14.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 1 | 0 | 50.00% | 14.00 | approach=1 |
| Tannuk, Memorial Ensign #40 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=179, lorehold_spell_cast=142, lorehold_upkeep_rummage=56, miracle_cast=28, discard_to_top_replacement=12, lorehold_rummage_discard_to_top=12, squee_to_graveyard=3, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2, lorehold_spell_rummage=8, topdeck_manipulation_activated=14

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/13L/0S`, WR `18.75%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 0 | 0 | 100.00% | 23.00 | elimination=2 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 1 | 0 | 50.00% | 10.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=156, lorehold_spell_cast=121, lorehold_upkeep_rummage=79, miracle_cast=21, topdeck_manipulation_activated=17, squee_to_graveyard=1, graveyard_upkeep_return_self_to_hand=1, squee_upkeep_return=1, squee_return_after_known_graveyard_entry=1, discard_to_top_replacement=23, lorehold_rummage_discard_to_top=23, lorehold_spell_rummage=1

