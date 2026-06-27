# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T16:09:37Z`
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

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 9 | 8 | 1 | 0 | 88.89% | 15.12 | 8 | 5 | 4 | 2 | 2 | 0 | 7 | wincon_role |
| 2 |  | Lorehold synergy package: birgi_spellchain_cut_squelcher (`synergy_birgi_spellchain_cut_squelcher`) | synergy-package | 9 | 3 | 6 | 0 | 33.33% | 17.33 | 7 | 4 | 2 | 2 | 2 | 0 | 7 | none |

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

**Strategic event counts:** lorehold_cost_paid=148, lorehold_spell_cast=118, lorehold_spell_rummage=19, lorehold_upkeep_rummage=41, miracle_cast=33, topdeck_manipulation_activated=30, squee_to_graveyard=7, graveyard_upkeep_return_self_to_hand=5, squee_upkeep_return=5, squee_return_after_known_graveyard_entry=5

### 2. Lorehold synergy package: birgi_spellchain_cut_squelcher (`synergy_birgi_spellchain_cut_squelcher`)

- objective: not available in structural matrix
- result: `3W/6L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 15.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 18.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=104, lorehold_spell_cast=75, spell_cast_mana_trigger=7, birgi_spell_cast_mana=7, lorehold_upkeep_rummage=37, miracle_cast=17, lorehold_spell_rummage=10, topdeck_manipulation_activated=11, squee_to_graveyard=4, graveyard_upkeep_return_self_to_hand=3, squee_upkeep_return=3, squee_return_after_known_graveyard_entry=3
