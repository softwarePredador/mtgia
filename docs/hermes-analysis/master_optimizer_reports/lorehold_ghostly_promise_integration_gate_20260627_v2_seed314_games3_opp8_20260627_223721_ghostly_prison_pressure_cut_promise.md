# Lorehold Equal Battle Gate

- generated_at: `2026-06-27T22:37:58Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `314`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `60.0`
- game_checkpoint_json: `None`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`) | synergy-package | 24 | 8 | 16 | 0 | 33.33% | 16.12 | 14 | 6 | 3 | 2 | 2 | 2 | 0 | 18 | 20 | 52 | Ghostly Prison: events=18, restricted=20, tax=52 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 24 | 6 | 18 | 0 | 25.00% | 14.33 | 15 | 12 | 4 | 1 | 1 | 1 | 0 | 20 | 0 | 0 | none | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`)

- objective: not available in structural matrix
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 24.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 2 | 1 | 0 | 66.67% | 14.00 | elimination=2 |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 12.00 | approach=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 28.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 10.00 | approach=1 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=257, lorehold_spell_cast=208, topdeck_manipulation_activated=25, thor_cost_paid=2, thor_spell_cast=2, miracle_cast=33, lorehold_upkeep_rummage=103, discard_to_top_replacement=26, lorehold_rummage_discard_to_top=26, lorehold_spell_rummage=8, squee_to_graveyard=2, graveyard_upkeep_return_self_to_hand=2, squee_upkeep_return=2, squee_return_after_known_graveyard_entry=2

**Lorehold attack restriction telemetry:** events=18, attackers_before=46, attackers_after=26, attackers_restricted=20, tax_paid=52, sources=Ghostly Prison: events=18, restricted=20, tax=52

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `6W/18L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 2 | 0 | 33.33% | 26.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 2 | 0 | 33.33% | 15.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 1 | 2 | 0 | 33.33% | 11.00 | elimination=1 |
| Umbris, Fear Manifest #114 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 2 | 0 | 33.33% | 7.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=221, lorehold_spell_cast=178, topdeck_manipulation_activated=28, miracle_cast=29, thor_cost_paid=2, thor_spell_cast=2, lorehold_upkeep_rummage=74, discard_to_top_replacement=16, lorehold_rummage_discard_to_top=16, lorehold_spell_rummage=3, squee_to_graveyard=1, graveyard_upkeep_return_self_to_hand=1, squee_upkeep_return=1, squee_return_after_known_graveyard_entry=1

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

