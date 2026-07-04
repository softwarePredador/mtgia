# Lorehold Equal Battle Gate

- generated_at: `2026-07-04T22:14:43Z`
- source_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_tradeoff_diagnostic_variant_20260704_current_candidate_db/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260704`
- fixed_opponent_deck_ids: `none`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `12.0`
- forced_access_mode: `opening_hand`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_tradeoff_diagnostic_variant_forced_storm_kiln_20260704_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Kraum, Ludevic's Opus #51 (real), The Emperor of Palamecia #42 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | VARIANT Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`deck_607`) | 607-pressure-payoff-diagnostic-tradeoff | 3 | 1 | 2 | 0 | 33.33% | 22.00 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | draw_role, recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `23`, removal `6`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kraum, Ludevic's Opus #51 (real) | 1 | 0 | 0 | 100.00% | 22.00 | approach=1 |
| The Emperor of Palamecia #42 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=29, lorehold_spell_cast=22, lorehold_spell_rummage=1, lorehold_upkeep_rummage=3, static_cost_reduction_casts=2, static_cost_reduction_total=14

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

