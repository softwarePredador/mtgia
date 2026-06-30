# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T03:28:51Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260629`
- simulation_seed: `123`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed123_real8_games3_game_checkpoint.json`
- opponents: `Thrasios, Triton Hero #76 (real), Rograkh, Son of Rohgahh #95 (real), K-9, Mark I #34 (real), Winota, Joiner of Forces #73 (real), Thrasios, Triton Hero #101 (real), Kinnan, Bonder Prodigy #72 (real), Kefka, Court Mage #112 (real), Kraum, Ludevic's Opus #81 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | Lorehold 607 + Boros Charm over Tibalt Trickery v1 (`candidate_607_boros_charm_tibalts_trickery_v1`) | 607-boros-charm-tibalts-trickery | 24 | 8 | 16 | 0 | 33.33% | 15.75 | 14 | 11 | 5 | 0 | 0 | 0 | 0 | 18 | 6 | 0 | unattributed: events=6, restricted=6, tax=0 | recursion_role, tutor_role |
| 2 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 24 | 8 | 16 | 0 | 33.33% | 17.12 | 12 | 11 | 5 | 0 | 0 | 0 | 0 | 19 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 + Boros Charm over Tibalt Trickery v1 (`candidate_607_boros_charm_tibalts_trickery_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 1 | 2 | 0 | 33.33% | 20.00 | elimination=1 |
| Rograkh, Son of Rohgahh #95 (real) | 2 | 1 | 0 | 66.67% | 15.50 | elimination=2 |
| K-9, Mark I #34 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #73 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Thrasios, Triton Hero #101 (real) | 1 | 2 | 0 | 33.33% | 13.00 | elimination=1 |
| Kinnan, Bonder Prodigy #72 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kefka, Court Mage #112 (real) | 2 | 1 | 0 | 66.67% | 18.00 | approach=1, elimination=1 |
| Kraum, Ludevic's Opus #81 (real) | 2 | 1 | 0 | 66.67% | 13.00 | elimination=2 |

**Strategic event counts:** discard_to_top_replacement=34, lorehold_cost_paid=247, lorehold_rummage_discard_to_top=29, lorehold_spell_cast=203, lorehold_spell_rummage=20, lorehold_spell_rummage_discard_to_top=5, lorehold_upkeep_rummage=100, miracle_cast=44, scarlet_static_cost_reduction_casts=5, scarlet_static_cost_reduction_total=10, static_cost_reduction_casts=33, static_cost_reduction_total=69, thor_cost_paid=2, thor_noncreature_damage=1, thor_noncreature_damage_amount=9, topdeck_manipulation_activated=35

**Lorehold attack restriction telemetry:** events=6, attackers_before=19, attackers_after=13, attackers_restricted=6, tax_paid=0, sources=unattributed: events=6, restricted=6, tax=0

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `8W/16L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #76 (real) | 1 | 2 | 0 | 33.33% | 31.00 | elimination=1 |
| Rograkh, Son of Rohgahh #95 (real) | 1 | 2 | 0 | 33.33% | 24.00 | elimination=1 |
| K-9, Mark I #34 (real) | 2 | 1 | 0 | 66.67% | 16.50 | elimination=2 |
| Winota, Joiner of Forces #73 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Thrasios, Triton Hero #101 (real) | 2 | 1 | 0 | 66.67% | 13.00 | elimination=2 |
| Kinnan, Bonder Prodigy #72 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Kefka, Court Mage #112 (real) | 2 | 1 | 0 | 66.67% | 11.50 | elimination=2 |
| Kraum, Ludevic's Opus #81 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=36, lorehold_cost_paid=294, lorehold_rummage_discard_to_top=34, lorehold_spell_cast=261, lorehold_spell_rummage=4, lorehold_spell_rummage_discard_to_top=2, lorehold_upkeep_rummage=110, miracle_cast=41, scarlet_static_cost_reduction_casts=4, scarlet_static_cost_reduction_total=8, static_cost_reduction_casts=27, static_cost_reduction_total=83, thor_cost_paid=2, thor_noncreature_damage=10, thor_noncreature_damage_amount=35, topdeck_manipulation_activated=59

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
