# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T12:24:57Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `3`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `99`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `45.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_current_pg247_gate_seed99_g3_20260628_v1_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 9 | 2 | 7 | 0 | 22.22% | 16.50 | 7 | 5 | 1 | 0 | 0 | 0 | 0 | 8 | 0 | 0 | none | recursion_role, tutor_role |
| 2 |  | Lorehold 607 Squee current PG247 candidate (`candidate_607_squee_current_pg247_v1`) | 607-squee-current-pg247 | 9 | 0 | 9 | 0 | 0.00% | 0.00 | 5 | 3 | 0 | 1 | 1 | 1 | 0 | 7 | 0 | 0 | none | none |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `2W/7L/0S`, WR `22.22%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 2 | 0 | 33.33% | 24.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 2 | 0 | 33.33% | 9.00 | approach=1 |

**Strategic event counts:** discard_to_top_replacement=7, lorehold_cost_paid=96, lorehold_rummage_discard_to_top=6, lorehold_spell_cast=75, lorehold_spell_rummage=8, lorehold_spell_rummage_discard_to_top=1, lorehold_upkeep_rummage=28, miracle_cast=14, topdeck_manipulation_activated=11

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold 607 Squee current PG247 candidate (`candidate_607_squee_current_pg247_v1`)

- objective: not available in structural matrix
- result: `0W/9L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 3 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** graveyard_upkeep_return_self_to_hand=2, lorehold_cost_paid=68, lorehold_rummage_discards_squee=3, lorehold_spell_cast=50, lorehold_upkeep_rummage=29, miracle_cast=6, squee_return_after_known_graveyard_entry=2, squee_to_graveyard=3, squee_upkeep_return=2, thor_cost_paid=1, thor_noncreature_damage=2, thor_noncreature_damage_amount=4, topdeck_manipulation_activated=7

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

