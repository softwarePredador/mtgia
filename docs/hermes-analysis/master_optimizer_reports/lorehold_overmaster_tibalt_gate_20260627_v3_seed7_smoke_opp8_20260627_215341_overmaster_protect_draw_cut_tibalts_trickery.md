# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T21:53:54Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `7`
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
| 1 |  | Lorehold synergy package: overmaster_protect_draw_cut_tibalts_trickery (`synergy_overmaster_protect_draw_cut_tibalts_trickery`) | synergy-package | 8 | 3 | 5 | 0 | 37.50% | 13.67 | 5 | 3 | 1 | 1 | 1 | 1 | 0 | 6 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 8 | 1 | 7 | 0 | 12.50% | 13.00 | 4 | 3 | 1 | 2 | 2 | 2 | 0 | 5 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: overmaster_protect_draw_cut_tibalts_trickery (`synergy_overmaster_protect_draw_cut_tibalts_trickery`)

- objective: not available in structural matrix
- result: `3W/5L/0S`, WR `37.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 12.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 12.00 | approach=1 |
| Kenrith, the Returned King #113 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=106, lorehold_spell_cast=91, lorehold_upkeep_rummage=33, miracle_cast=15, topdeck_manipulation_activated=14, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2, lorehold_spell_rummage=11, discard_to_top_replacement=1, lorehold_spell_rummage_discard_to_top=1

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/7L/0S`, WR `12.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 0 | 0 | 100.00% | 13.00 | approach=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=56, lorehold_spell_cast=44, lorehold_upkeep_rummage=26, miracle_cast=9, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2, topdeck_manipulation_activated=5, discard_to_top_replacement=17, lorehold_rummage_discard_to_top=8, lorehold_spell_rummage=9, lorehold_spell_rummage_discard_to_top=9
