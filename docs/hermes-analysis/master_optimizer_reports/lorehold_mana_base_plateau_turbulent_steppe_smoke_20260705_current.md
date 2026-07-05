# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T00:49:43Z`
- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `generic+fixed_deck`
- opponent_seed: `20260705`
- fixed_opponent_deck_ids: `607`
- simulation_seed: `20260705`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `30.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_steppe_smoke_20260705_current_game_checkpoint.json`
- opponents: `Fixed Lorehold deck 607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold 607 mana base: Plateau over Turbulent Steppe (`candidate_607_plateau_turbulent_steppe_mana_base_v1`) | mana-base-diagnostic | 1 | 0 | 1 | 0 | 0.00% | 0.00 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | none |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 1 | 0 | 1 | 0 | 0.00% | 0.00 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold 607 mana base: Plateau over Turbulent Steppe (`candidate_607_plateau_turbulent_steppe_mana_base_v1`)

- objective: not available in structural matrix
- result: `0W/1L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=9, lorehold_spell_cast=9, lorehold_upkeep_rummage=6, miracle_cast=2

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/1L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Fixed Lorehold deck 607 | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=3, lorehold_spell_cast=4

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
