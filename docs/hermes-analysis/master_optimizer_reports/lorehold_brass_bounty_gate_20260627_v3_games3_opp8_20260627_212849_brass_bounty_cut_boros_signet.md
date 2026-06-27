# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T21:29:30Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `120.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 |  | Lorehold synergy package: brass_bounty_cut_boros_signet (`synergy_brass_bounty_cut_boros_signet`) | synergy-package | 24 | 11 | 13 | 0 | 45.83% | 17.73 | 18 | 12 | 10 | 6 | 6 | 6 | 0 | 22 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 24 | 9 | 15 | 0 | 37.50% | 17.89 | 17 | 7 | 4 | 4 | 3 | 3 | 0 | 17 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: brass_bounty_cut_boros_signet (`synergy_brass_bounty_cut_boros_signet`)

- objective: not available in structural matrix
- result: `11W/13L/0S`, WR `45.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 2 | 1 | 0 | 66.67% | 24.00 | elimination=2 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 16.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 17.00 | approach=1 |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 2 | 1 | 0 | 66.67% | 16.50 | elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 2 | 1 | 0 | 66.67% | 21.00 | elimination=2 |

**Strategic event counts:** lorehold_cost_paid=315, lorehold_spell_cast=247, lorehold_upkeep_rummage=139, miracle_cast=71, topdeck_manipulation_activated=47, squee_to_graveyard=12, graveyard_upkeep_return_self_to_hand=10, squee_upkeep_return=10, squee_return_after_known_graveyard_entry=10, discard_to_top_replacement=63, lorehold_rummage_discard_to_top=52, lorehold_spell_rummage=18, lorehold_spell_rummage_discard_to_top=11, thor_cost_paid=1, thor_spell_cast=1

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `9W/15L/0S`, WR `37.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 3 | 0 | 0 | 100.00% | 19.33 | elimination=3 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 18.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 13.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 26.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 8.00 | approach=1 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=300, lorehold_spell_cast=239, lorehold_upkeep_rummage=77, miracle_cast=45, topdeck_manipulation_activated=33, squee_to_graveyard=6, graveyard_upkeep_return_self_to_hand=4, squee_upkeep_return=4, squee_return_after_known_graveyard_entry=4, thor_cost_paid=3, thor_spell_cast=3, discard_to_top_replacement=20, lorehold_rummage_discard_to_top=20
