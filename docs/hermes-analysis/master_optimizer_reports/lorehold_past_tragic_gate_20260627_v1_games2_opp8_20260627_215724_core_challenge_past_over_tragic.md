# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T21:57:50Z`
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
| 1 |  | Lorehold synergy package: core_challenge_past_over_tragic (`synergy_core_challenge_past_over_tragic`) | synergy-package | 16 | 5 | 11 | 0 | 31.25% | 16.00 | 10 | 3 | 3 | 1 | 1 | 1 | 0 | 15 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 3 | 13 | 0 | 18.75% | 18.67 | 9 | 3 | 3 | 1 | 1 | 1 | 0 | 13 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: core_challenge_past_over_tragic (`synergy_core_challenge_past_over_tragic`)

- objective: not available in structural matrix
- result: `5W/11L/0S`, WR `31.25%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 1 | 0 | 50.00% | 19.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 1 | 0 | 50.00% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 1 | 0 | 50.00% | 10.00 | approach=1 |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 1 | 1 | 0 | 50.00% | 21.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 1 | 0 | 50.00% | 15.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=193, lorehold_spell_cast=161, lorehold_upkeep_rummage=69, miracle_cast=25, topdeck_manipulation_activated=17, thor_cost_paid=2, thor_spell_cast=2, discard_to_top_replacement=25, lorehold_rummage_discard_to_top=18, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2, lorehold_spell_rummage=11, lorehold_spell_rummage_discard_to_top=7

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
