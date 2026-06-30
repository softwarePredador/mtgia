# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T03:50:33Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260629`
- simulation_seed: `20260630`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3_game_checkpoint.json`
- opponents: `Thrasios, Triton Hero #76 (real), Rograkh, Son of Rohgahh #95 (real), K-9, Mark I #34 (real), Winota, Joiner of Forces #73 (real), Thrasios, Triton Hero #101 (real), Kinnan, Bonder Prodigy #72 (real), Kefka, Court Mage #112 (real), Kraum, Ludevic's Opus #81 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`) | 607-chaos-warp-stroke-of-midnight | 24 | 12 | 12 | 0 | 50.00% | 18.75 | 17 | 10 | 3 | 0 | 0 | 0 | 0 | 16 | 0 | 0 | none | recursion_role, tutor_role |
| 2 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 11 | 12 | 1 | 45.83% | 15.64 | 17 | 9 | 4 | 0 | 0 | 0 | 0 | 17 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `12W/12L/0S`, WR `50.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 1 | 2 | 0 | 33.33% | 25.00 | elimination=1 |
| Rograkh, Son of Rohgahh #95 (real) | 2 | 1 | 0 | 66.67% | 15.50 | approach=1, elimination=1 |
| K-9, Mark I #34 (real) | 2 | 1 | 0 | 66.67% | 13.50 | elimination=2 |
| Winota, Joiner of Forces #73 (real) | 2 | 1 | 0 | 66.67% | 19.50 | approach=2 |
| Thrasios, Triton Hero #101 (real) | 3 | 0 | 0 | 100.00% | 19.00 | elimination=3 |
| Kinnan, Bonder Prodigy #72 (real) | 1 | 2 | 0 | 33.33% | 25.00 | elimination=1 |
| Kefka, Court Mage #112 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kraum, Ludevic's Opus #81 (real) | 1 | 2 | 0 | 33.33% | 21.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=26, lorehold_cost_paid=290, lorehold_rummage_discard_to_top=19, lorehold_spell_cast=231, lorehold_spell_rummage=11, lorehold_spell_rummage_discard_to_top=7, lorehold_upkeep_rummage=76, miracle_cast=62, scarlet_static_cost_reduction_casts=5, scarlet_static_cost_reduction_total=9, static_cost_reduction_casts=36, static_cost_reduction_total=57, thor_cost_paid=3, thor_noncreature_damage=2, thor_noncreature_damage_amount=8, topdeck_manipulation_activated=52

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

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
