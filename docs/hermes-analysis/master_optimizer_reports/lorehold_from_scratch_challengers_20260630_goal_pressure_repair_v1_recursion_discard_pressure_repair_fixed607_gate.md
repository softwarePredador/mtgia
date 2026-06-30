# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T19:53:22Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real+fixed_deck`
- opponent_seed: `20260626`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `42`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `45.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_fixed607_gate_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607, Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 4 | Lorehold From-Scratch Recursion Discard Pressure Repair v1 (`challenger_lorehold_recursion_discard_pressure_repair_v1`) | from-scratch-recursion-discard-pressure-repair | 4 | 1 | 3 | 0 | 25.00% | 28.00 | 1 | 2 | 0 | 0 | 0 | 0 | 0 | 1 | 25 | 0 | unattributed: events=13, restricted=25, tax=0 | recursion_role, tutor_role |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 4 | 1 | 3 | 0 | 25.00% | 15.00 | 4 | 1 | 1 | 0 | 0 | 0 | 0 | 4 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold From-Scratch Recursion Discard Pressure Repair v1 (`challenger_lorehold_recursion_discard_pressure_repair_v1`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/3L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `17`, removal `14`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 28.00 | elimination=1 |

**Strategic event counts:** birgi_spell_cast_mana=4, lorehold_cost_paid=47, lorehold_spell_cast=44, lorehold_upkeep_rummage=1, miracle_cast=10, scarlet_static_cost_reduction_casts=1, scarlet_static_cost_reduction_total=2, spell_cast_mana_trigger=4, static_cost_reduction_casts=9, static_cost_reduction_total=23, topdeck_manipulation_activated=15

**Lorehold attack restriction telemetry:** events=13, attackers_before=38, attackers_after=13, attackers_restricted=25, tax_paid=0, sources=unattributed: events=13, restricted=25, tax=0

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/3L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=22, lorehold_cost_paid=49, lorehold_rummage_discard_to_top=22, lorehold_spell_cast=43, lorehold_spell_rummage=4, lorehold_upkeep_rummage=35, miracle_cast=12, static_cost_reduction_casts=1, static_cost_reduction_total=8, topdeck_manipulation_activated=3

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
