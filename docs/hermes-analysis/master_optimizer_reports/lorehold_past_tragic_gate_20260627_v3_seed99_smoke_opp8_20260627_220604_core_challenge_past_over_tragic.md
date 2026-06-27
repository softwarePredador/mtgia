# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T22:06:16Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
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
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 8 | 5 | 3 | 0 | 62.50% | 16.80 | 6 | 3 | 1 | 1 | 1 | 1 | 0 | 5 | wincon_role |
| 2 |  | Lorehold synergy package: core_challenge_past_over_tragic (`synergy_core_challenge_past_over_tragic`) | synergy-package | 8 | 2 | 6 | 0 | 25.00% | 13.00 | 6 | 2 | 1 | 0 | 0 | 0 | 0 | 6 | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `5W/3L/0S`, WR `62.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 18.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 1 | 0 | 0 | 100.00% | 12.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 0 | 0 | 100.00% | 23.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 0 | 0 | 100.00% | 20.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=79, lorehold_spell_cast=66, lorehold_upkeep_rummage=14, topdeck_manipulation_activated=12, miracle_cast=14, discard_to_top_replacement=1, lorehold_rummage_discard_to_top=1, thor_cost_paid=1, thor_spell_cast=1, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2

### 2. Lorehold synergy package: core_challenge_past_over_tragic (`synergy_core_challenge_past_over_tragic`)

- objective: not available in structural matrix
- result: `2W/6L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 15.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=75, lorehold_spell_cast=59, lorehold_upkeep_rummage=19, miracle_cast=12, discard_to_top_replacement=1, lorehold_rummage_discard_to_top=1, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=3, lorehold_spell_rummage=7
