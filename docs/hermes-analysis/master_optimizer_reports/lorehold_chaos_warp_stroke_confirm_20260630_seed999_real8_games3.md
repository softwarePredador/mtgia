# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T03:52:55Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260629`
- simulation_seed: `999`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed999_real8_games3_game_checkpoint.json`
- opponents: `Thrasios, Triton Hero #76 (real), Rograkh, Son of Rohgahh #95 (real), K-9, Mark I #34 (real), Winota, Joiner of Forces #73 (real), Thrasios, Triton Hero #101 (real), Kinnan, Bonder Prodigy #72 (real), Kefka, Court Mage #112 (real), Kraum, Ludevic's Opus #81 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 11 | 13 | 0 | 45.83% | 15.82 | 15 | 8 | 4 | 0 | 0 | 0 | 0 | 19 | 0 | 0 | none | recursion_role, tutor_role |
| 2 | 1 | Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`) | 607-chaos-warp-stroke-of-midnight | 24 | 8 | 16 | 0 | 33.33% | 18.50 | 12 | 8 | 3 | 0 | 0 | 0 | 0 | 17 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `11W/13L/0S`, WR `45.83%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #95 (real) | 1 | 2 | 0 | 33.33% | 23.00 | approach=1 |
| K-9, Mark I #34 (real) | 3 | 0 | 0 | 100.00% | 16.33 | elimination=3 |
| Winota, Joiner of Forces #73 (real) | 1 | 2 | 0 | 33.33% | 7.00 | approach=1 |
| Thrasios, Triton Hero #101 (real) | 2 | 1 | 0 | 66.67% | 12.00 | approach=1, elimination=1 |
| Kinnan, Bonder Prodigy #72 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kefka, Court Mage #112 (real) | 3 | 0 | 0 | 100.00% | 19.33 | approach=1, elimination=2 |
| Kraum, Ludevic's Opus #81 (real) | 1 | 2 | 0 | 33.33% | 13.00 | approach=1 |

**Strategic event counts:** discard_to_top_replacement=17, lorehold_cost_paid=265, lorehold_rummage_discard_to_top=16, lorehold_spell_cast=228, lorehold_spell_rummage=7, lorehold_spell_rummage_discard_to_top=1, lorehold_upkeep_rummage=88, miracle_cast=48, scarlet_static_cost_reduction_casts=4, scarlet_static_cost_reduction_total=8, static_cost_reduction_casts=39, static_cost_reduction_total=68, thor_cost_paid=2, topdeck_manipulation_activated=41

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 2 | 1 | 0 | 66.67% | 14.50 | approach=1, elimination=1 |
| Rograkh, Son of Rohgahh #95 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| K-9, Mark I #34 (real) | 2 | 1 | 0 | 66.67% | 18.00 | elimination=2 |
| Winota, Joiner of Forces #73 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Thrasios, Triton Hero #101 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kinnan, Bonder Prodigy #72 (real) | 1 | 2 | 0 | 33.33% | 17.00 | approach=1 |
| Kefka, Court Mage #112 (real) | 2 | 1 | 0 | 66.67% | 22.50 | elimination=2 |
| Kraum, Ludevic's Opus #81 (real) | 1 | 2 | 0 | 33.33% | 21.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=22, lorehold_cost_paid=214, lorehold_rummage_discard_to_top=19, lorehold_spell_cast=174, lorehold_spell_rummage=17, lorehold_spell_rummage_discard_to_top=3, lorehold_upkeep_rummage=82, miracle_cast=47, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, static_cost_reduction_casts=18, static_cost_reduction_total=43, topdeck_manipulation_activated=23

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
