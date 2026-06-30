# Lorehold Equal Battle Gate

- generated_at: `2026-06-30T16:18:49Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- forced_access_mode: `opening_hand`
- game_checkpoint_json: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_aware_gate_queue_20260630_post_pg282_final_eight_current_run_20260630_161841_austere_command_wipe_over_emeria_tradeoff_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold synergy package: austere_command_wipe_over_emeria_tradeoff (`synergy_austere_command_wipe_over_emeria_tradeoff`) | synergy-package | 3 | 2 | 1 | 0 | 66.67% | 12.50 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | none | none |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 3 | 1 | 2 | 0 | 33.33% | 15.00 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | none | recursion_role, tutor_role |

## Deck Detail

### 1. Lorehold synergy package: austere_command_wipe_over_emeria_tradeoff (`synergy_austere_command_wipe_over_emeria_tradeoff`)

- objective: not available in structural matrix
- result: `2W/1L/0S`, WR `66.67%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 16.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 9.00 | approach=1 |

**Strategic event counts:** lorehold_cost_paid=34, lorehold_spell_cast=31, lorehold_upkeep_rummage=7, miracle_cast=7, scarlet_static_cost_reduction_casts=1, scarlet_static_cost_reduction_total=2, static_cost_reduction_casts=6, static_cost_reduction_total=7, topdeck_manipulation_activated=8

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=23, lorehold_spell_cast=23, miracle_cast=4, scarlet_static_cost_reduction_casts=2, scarlet_static_cost_reduction_total=4, static_cost_reduction_casts=4, static_cost_reduction_total=13, topdeck_manipulation_activated=6

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
