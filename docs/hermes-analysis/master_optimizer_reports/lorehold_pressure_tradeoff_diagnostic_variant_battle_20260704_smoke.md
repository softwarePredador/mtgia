# Lorehold Equal Battle Gate

- generated_at: `2026-07-04T22:10:23Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260704`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `12.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_tradeoff_diagnostic_variant_battle_20260704_smoke_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Kraum, Ludevic's Opus #51 (real), The Emperor of Palamecia #42 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`candidate_607_pressure_payoff_diagnostic_tradeoff_v1`) | 607-pressure-payoff-diagnostic-tradeoff | 4 | 3 | 1 | 0 | 75.00% | 15.67 | 2 | 2 | 1 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | none | draw_role, recursion_role, tutor_role |
| 2 | 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 4 | 3 | 1 | 0 | 75.00% | 18.67 | 4 | 2 | 1 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | none | draw_role, recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`candidate_607_pressure_payoff_diagnostic_tradeoff_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/1L/0S`, WR `75.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `23`, removal `6`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 1 | 0 | 0 | 100.00% | 18.00 | elimination=1 |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kraum, Ludevic's Opus #51 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |
| The Emperor of Palamecia #42 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=3, lorehold_cost_paid=69, lorehold_rummage_discard_to_top=3, lorehold_spell_cast=50, lorehold_upkeep_rummage=16, miracle_cast=5, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, static_cost_reduction_casts=20, static_cost_reduction_total=28, topdeck_manipulation_activated=4

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/1L/0S`, WR `75.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| Kraum, Ludevic's Opus #51 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| The Emperor of Palamecia #42 (real) | 1 | 0 | 0 | 100.00% | 22.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=11, lorehold_cost_paid=73, lorehold_rummage_discard_to_top=11, lorehold_spell_cast=58, lorehold_upkeep_rummage=19, miracle_cast=20, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, static_cost_reduction_casts=12, static_cost_reduction_total=22, thor_cost_paid=1, thor_noncreature_damage=4, thor_noncreature_damage_amount=6, topdeck_manipulation_activated=19

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

