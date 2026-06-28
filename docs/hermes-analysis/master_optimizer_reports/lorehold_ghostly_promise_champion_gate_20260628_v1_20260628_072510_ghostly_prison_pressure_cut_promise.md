# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T07:20:48Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `2`
- opponent_kind: `real`
- opponent_seed: `20260628`
- simulation_seed: `20260628`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_champion_gate_20260628_v1_20260628_072510_ghostly_prison_pressure_cut_promise_game_checkpoint.json`
- opponents: `Etali, Primal Conqueror #105 (real), Kinnan, Bonder Prodigy #72 (real), Kinnan, Bonder Prodigy #84 (real), The Cabbage Merchant #47 (real), Thrasios, Triton Hero #76 (real), Lumra, Bellow of the Woods #49 (real), Kraum, Ludevic's Opus #83 (real), Yorion, Sky Nomad #38 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`) | synergy-package | 16 | 5 | 11 | 0 | 31.25% | 13.40 | 10 | 9 | 6 | 2 | 2 | 2 | 1 | 15 | 7 | 28 | Ghostly Prison: events=7, restricted=7, tax=28 | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 3 | 13 | 0 | 18.75% | 18.67 | 10 | 8 | 4 | 4 | 4 | 4 | 0 | 15 | 2 | 0 | unattributed: events=2, restricted=2, tax=0 | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: ghostly_prison_pressure_cut_promise (`synergy_ghostly_prison_pressure_cut_promise`)

- objective: not available in structural matrix
- result: `5W/11L/0S`, WR `31.25%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Etali, Primal Conqueror #105 (real) | 1 | 1 | 0 | 50.00% | 15.00 | elimination=1 |
| Kinnan, Bonder Prodigy #72 (real) | 1 | 1 | 0 | 50.00% | 16.00 | elimination=1 |
| Kinnan, Bonder Prodigy #84 (real) | 1 | 1 | 0 | 50.00% | 12.00 | approach=1 |
| The Cabbage Merchant #47 (real) | 1 | 1 | 0 | 50.00% | 12.00 | elimination=1 |
| Thrasios, Triton Hero #76 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Lumra, Bellow of the Woods #49 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kraum, Ludevic's Opus #83 (real) | 1 | 1 | 0 | 50.00% | 12.00 | elimination=1 |
| Yorion, Sky Nomad #38 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=56, graveyard_upkeep_return_self_to_hand=17, lorehold_cost_paid=222, lorehold_rummage_discard_to_top=31, lorehold_rummage_discards_squee=10, lorehold_spell_cast=204, lorehold_spell_rummage=39, lorehold_spell_rummage_discard_to_top=25, lorehold_spell_rummage_discards_squee=6, lorehold_upkeep_rummage=92, miracle_cast=44, squee_return_after_known_graveyard_entry=16, squee_return_without_known_graveyard_entry=1, squee_to_graveyard=16, squee_upkeep_return=17, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=37

**Lorehold attack restriction telemetry:** events=7, attackers_before=21, attackers_after=14, attackers_restricted=7, tax_paid=28, sources=Ghostly Prison: events=7, restricted=7, tax=28

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/13L/0S`, WR `18.75%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Etali, Primal Conqueror #105 (real) | 1 | 1 | 0 | 50.00% | 19.00 | elimination=1 |
| Kinnan, Bonder Prodigy #72 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kinnan, Bonder Prodigy #84 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| The Cabbage Merchant #47 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Thrasios, Triton Hero #76 (real) | 1 | 1 | 0 | 50.00% | 15.00 | approach=1 |
| Lumra, Bellow of the Woods #49 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kraum, Ludevic's Opus #83 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Yorion, Sky Nomad #38 (real) | 1 | 1 | 0 | 50.00% | 22.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=18, graveyard_upkeep_return_self_to_hand=12, lorehold_cost_paid=181, lorehold_rummage_discard_to_top=10, lorehold_rummage_discards_squee=5, lorehold_spell_cast=146, lorehold_spell_rummage=22, lorehold_spell_rummage_discard_to_top=8, lorehold_spell_rummage_discards_squee=6, lorehold_upkeep_rummage=75, miracle_cast=31, squee_return_after_known_graveyard_entry=12, squee_to_graveyard=13, squee_upkeep_return=12, thor_cost_paid=2, thor_spell_cast=2, topdeck_manipulation_activated=35

**Lorehold attack restriction telemetry:** events=2, attackers_before=5, attackers_after=3, attackers_restricted=2, tax_paid=0, sources=unattributed: events=2, restricted=2, tax=0
