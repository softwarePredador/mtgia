# Lorehold Equal Battle Gate

- generated_at: `2026-07-04T23:00:52Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `30.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_pressure_mana_conversion_fixed607_gate_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Lorehold From-Scratch Spell Pressure Mana Conversion v1 (`challenger_lorehold_spell_pressure_mana_conversion_v1`) | from-scratch-spell-pressure-mana-conversion | 4 | 2 | 2 | 0 | 50.00% | 12.00 | 3 | 2 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | recursion_role, tutor_role |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 4 | 0 | 4 | 0 | 0.00% | 0.00 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | none | draw_role, recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold From-Scratch Spell Pressure Mana Conversion v1 (`challenger_lorehold_spell_pressure_mana_conversion_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `2W/2L/0S`, WR `50.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `15`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 13.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=28, lorehold_spell_cast=26, lorehold_upkeep_rummage=7, miracle_cast=8, topdeck_manipulation_activated=6

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/4L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=27, lorehold_spell_cast=22, lorehold_upkeep_rummage=5, miracle_cast=4, static_cost_reduction_casts=2, static_cost_reduction_total=2, topdeck_manipulation_activated=5

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
