# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T22:17:18Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `99`
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
| 1 |  | Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`) | synergy-package | 24 | 8 | 16 | 0 | 33.33% | 14.38 | 15 | 7 | 2 | 1 | 1 | 1 | 0 | 22 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 24 | 3 | 21 | 0 | 12.50% | 13.33 | 10 | 6 | 5 | 2 | 1 | 1 | 0 | 19 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`)

- objective: not available in structural matrix
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 14.50 | approach=2 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 2 | 1 | 0 | 66.67% | 19.50 | elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=244, lorehold_spell_cast=197, lorehold_spell_rummage=10, lorehold_upkeep_rummage=93, miracle_cast=50, topdeck_manipulation_activated=22, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2, discard_to_top_replacement=5, lorehold_rummage_discard_to_top=4, thor_cost_paid=1, thor_spell_cast=1, lorehold_spell_rummage_discard_to_top=1

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/21L/0S`, WR `12.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 19.00 | approach=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 7.00 | approach=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=242, lorehold_spell_cast=182, lorehold_upkeep_rummage=96, topdeck_manipulation_activated=18, discard_to_top_replacement=25, lorehold_rummage_discard_to_top=21, miracle_cast=19, squee_to_graveyard=6, lorehold_spell_rummage=11, lorehold_spell_rummage_discard_to_top=4, thor_cost_paid=2, thor_spell_cast=2, graveyard_upkeep_return_self_to_hand=4, squee_upkeep_return=4, squee_return_after_known_graveyard_entry=4

