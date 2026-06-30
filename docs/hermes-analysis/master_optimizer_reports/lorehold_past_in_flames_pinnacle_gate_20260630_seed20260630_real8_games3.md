# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T04:06:39Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260629`
- simulation_seed: `20260630`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3_game_checkpoint.json`
- opponents: `Thrasios, Triton Hero #76 (real), Rograkh, Son of Rohgahh #95 (real), K-9, Mark I #34 (real), Winota, Joiner of Forces #73 (real), Thrasios, Triton Hero #101 (real), Kinnan, Bonder Prodigy #72 (real), Kefka, Court Mage #112 (real), Kraum, Ludevic's Opus #81 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 11 | 12 | 1 | 45.83% | 15.64 | 17 | 9 | 4 | 0 | 0 | 0 | 0 | 17 | 0 | 0 | none | recursion_role, tutor_role |
| 2 | 2 | Lorehold 607 + Past in Flames over Pinnacle Monk v1 (`candidate_607_past_in_flames_pinnacle_monk_v1`) | 607-past-in-flames-pinnacle-monk | 24 | 8 | 16 | 0 | 33.33% | 22.12 | 19 | 12 | 7 | 0 | 0 | 0 | 0 | 19 | 4 | 0 | unattributed: events=4, restricted=4, tax=0 | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `11W/12L/1S`, WR `45.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 1 | 2 | 0 | 33.33% | 22.00 | elimination=1 |
| Rograkh, Son of Rohgahh #95 (real) | 1 | 2 | 0 | 33.33% | 22.00 | elimination=1 |
| K-9, Mark I #34 (real) | 1 | 2 | 0 | 33.33% | 19.00 | elimination=1 |
| Winota, Joiner of Forces #73 (real) | 2 | 1 | 0 | 66.67% | 13.00 | elimination=2 |
| Thrasios, Triton Hero #101 (real) | 3 | 0 | 0 | 100.00% | 13.67 | elimination=3 |
| Kinnan, Bonder Prodigy #72 (real) | 1 | 2 | 0 | 33.33% | 14.00 | elimination=1 |
| Kefka, Court Mage #112 (real) | 1 | 2 | 0 | 33.33% | 13.00 | approach=1 |
| Kraum, Ludevic's Opus #81 (real) | 1 | 1 | 1 | 33.33% | 15.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=14, lorehold_cost_paid=254, lorehold_rummage_discard_to_top=14, lorehold_spell_cast=240, lorehold_spell_rummage=6, lorehold_upkeep_rummage=95, miracle_cast=48, scarlet_static_cost_reduction_casts=1, scarlet_static_cost_reduction_total=2, static_cost_reduction_casts=33, static_cost_reduction_total=70, thor_cost_paid=2, thor_noncreature_damage=4, thor_noncreature_damage_amount=11, topdeck_manipulation_activated=32

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold 607 + Past in Flames over Pinnacle Monk v1 (`candidate_607_past_in_flames_pinnacle_monk_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #95 (real) | 2 | 1 | 0 | 66.67% | 34.00 | approach=1, elimination=1 |
| K-9, Mark I #34 (real) | 2 | 1 | 0 | 66.67% | 20.00 | elimination=2 |
| Winota, Joiner of Forces #73 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Thrasios, Triton Hero #101 (real) | 2 | 1 | 0 | 66.67% | 15.00 | approach=1, elimination=1 |
| Kinnan, Bonder Prodigy #72 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kefka, Court Mage #112 (real) | 1 | 2 | 0 | 33.33% | 17.00 | elimination=1 |
| Kraum, Ludevic's Opus #81 (real) | 1 | 2 | 0 | 33.33% | 22.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=51, lorehold_cost_paid=363, lorehold_rummage_discard_to_top=32, lorehold_spell_cast=307, lorehold_spell_rummage=60, lorehold_spell_rummage_discard_to_top=19, lorehold_upkeep_rummage=131, miracle_cast=67, scarlet_static_cost_reduction_casts=11, scarlet_static_cost_reduction_total=22, static_cost_reduction_casts=60, static_cost_reduction_total=124, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=5, topdeck_manipulation_activated=61

**Lorehold attack restriction telemetry:** events=4, attackers_before=11, attackers_after=7, attackers_restricted=4, tax_paid=0, sources=unattributed: events=4, restricted=4, tax=0
