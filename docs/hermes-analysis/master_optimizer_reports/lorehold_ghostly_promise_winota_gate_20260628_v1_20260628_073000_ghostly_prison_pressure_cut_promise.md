# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T07:26:45Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `2`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260628`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_winota_gate_20260628_v1_20260628_073000_ghostly_prison_pressure_cut_promise_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`) | synergy-package | 16 | 6 | 10 | 0 | 37.50% | 15.50 | 13 | 9 | 3 | 7 | 6 | 6 | 1 | 13 | 0 | 0 | none | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 4 | 12 | 0 | 25.00% | 11.50 | 10 | 6 | 2 | 4 | 4 | 4 | 0 | 14 | 7 | 0 | unattributed: events=7, restricted=7, tax=0 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`)

- objective: not available in structural matrix
- result: `6W/10L/0S`, WR `37.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 1 | 0 | 50.00% | 13.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 1 | 0 | 50.00% | 17.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 2 | 0 | 0 | 100.00% | 16.50 | approach=1, elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 1 | 0 | 50.00% | 13.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 1 | 0 | 50.00% | 17.00 | approach=1 |

**Strategic event counts:** discard_to_top_replacement=10, graveyard_upkeep_return_self_to_hand=14, lorehold_cost_paid=256, lorehold_rummage_discard_to_top=10, lorehold_rummage_discards_squee=9, lorehold_spell_cast=219, lorehold_spell_rummage=29, lorehold_spell_rummage_discards_squee=7, lorehold_upkeep_rummage=80, miracle_cast=36, squee_return_after_known_graveyard_entry=13, squee_return_without_known_graveyard_entry=1, squee_to_graveyard=18, squee_upkeep_return=14, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=29

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/12L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 2 | 0 | 0 | 100.00% | 11.50 | elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 1 | 0 | 50.00% | 11.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 1 | 0 | 50.00% | 12.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=12, graveyard_upkeep_return_self_to_hand=15, lorehold_cost_paid=148, lorehold_rummage_discard_to_top=9, lorehold_rummage_discards_squee=8, lorehold_spell_cast=123, lorehold_spell_rummage=15, lorehold_spell_rummage_discard_to_top=3, lorehold_spell_rummage_discards_squee=7, lorehold_upkeep_rummage=63, miracle_cast=22, squee_return_after_known_graveyard_entry=15, squee_to_graveyard=17, squee_upkeep_return=15, topdeck_manipulation_activated=15

**Lorehold attack restriction telemetry:** events=7, attackers_before=24, attackers_after=17, attackers_restricted=7, tax_paid=0, sources=unattributed: events=7, restricted=7, tax=0
