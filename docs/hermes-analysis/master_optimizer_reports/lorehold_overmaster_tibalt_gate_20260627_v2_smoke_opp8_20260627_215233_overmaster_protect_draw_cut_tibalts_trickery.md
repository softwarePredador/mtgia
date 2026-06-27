# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T21:52:48Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
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
| 1 |  | Lorehold synergy package: overmaster_protect_draw_cut_tibalts_trickery (`synergy_overmaster_protect_draw_cut_tibalts_trickery`) | synergy-package | 8 | 4 | 4 | 0 | 50.00% | 19.50 | 8 | 4 | 3 | 5 | 5 | 5 | 1 | 7 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 8 | 2 | 6 | 0 | 25.00% | 22.50 | 3 | 1 | 0 | 0 | 0 | 0 | 0 | 4 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: overmaster_protect_draw_cut_tibalts_trickery (`synergy_overmaster_protect_draw_cut_tibalts_trickery`)

- objective: not available in structural matrix
- result: `4W/4L/0S`, WR `50.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 22.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 23.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 0 | 0 | 100.00% | 18.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=171, lorehold_spell_cast=138, lorehold_upkeep_rummage=56, miracle_cast=29, topdeck_manipulation_activated=36, thor_cost_paid=2, thor_spell_cast=2, squee_to_graveyard=7, graveyard_upkeep_return_self_to_hand=7, squee_upkeep_return=7, squee_return_after_known_graveyard_entry=6, lorehold_spell_rummage=23, discard_to_top_replacement=20, lorehold_spell_rummage_discard_to_top=13, lorehold_rummage_discard_to_top=7, squee_return_without_known_graveyard_entry=1

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `2W/6L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 28.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=95, lorehold_spell_cast=78, lorehold_upkeep_rummage=20, miracle_cast=11, topdeck_manipulation_activated=10, lorehold_spell_rummage=3
