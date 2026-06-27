# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T21:39:17Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `2`
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
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 4 | 12 | 0 | 25.00% | 16.50 | 8 | 2 | 3 | 5 | 5 | 5 | 0 | 10 | wincon_role |
| 2 |  | Lorehold synergy package: brass_bounty_cut_boros_signet (`synergy_brass_bounty_cut_boros_signet`) | synergy-package | 16 | 4 | 12 | 0 | 25.00% | 17.00 | 8 | 3 | 2 | 5 | 5 | 5 | 0 | 10 | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/12L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 1 | 0 | 50.00% | 28.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 2 | 0 | 0 | 100.00% | 13.50 | elimination=1, approach=1 |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 1 | 0 | 50.00% | 11.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=127, lorehold_spell_cast=92, lorehold_upkeep_rummage=51, miracle_cast=30, topdeck_manipulation_activated=24, squee_to_graveyard=5, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5, discard_to_top_replacement=26, lorehold_rummage_discard_to_top=23, lorehold_spell_rummage=5, lorehold_spell_rummage_discard_to_top=3

### 2. Lorehold synergy package: brass_bounty_cut_boros_signet (`synergy_brass_bounty_cut_boros_signet`)

- objective: not available in structural matrix
- result: `4W/12L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 1 | 0 | 50.00% | 28.00 | elimination=1 |
| Kenrith, the Returned King #113 (real) | 2 | 0 | 0 | 100.00% | 13.50 | elimination=1, approach=1 |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 1 | 0 | 50.00% | 13.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=127, lorehold_spell_cast=91, lorehold_upkeep_rummage=48, miracle_cast=30, topdeck_manipulation_activated=25, squee_to_graveyard=5, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5, discard_to_top_replacement=16, lorehold_rummage_discard_to_top=16, lorehold_spell_rummage=2, thor_cost_paid=1, thor_spell_cast=1
