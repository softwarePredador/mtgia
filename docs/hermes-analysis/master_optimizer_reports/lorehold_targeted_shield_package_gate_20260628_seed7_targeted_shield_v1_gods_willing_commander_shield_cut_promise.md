# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T04:45:09Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `7`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1_gods_willing_commander_shield_cut_promise_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 |  | Lorehold synergy package: gods_willing_commander_shield_cut_promise (`synergy_gods_willing_commander_shield_cut_promise`) | synergy-package | 3 | 1 | 2 | 0 | 33.33% | 16.00 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | none |
| 2 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 3 | 0 | 3 | 0 | 0.00% | 0.00 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | wincon_role |

## Deck Detail

### 1. Lorehold synergy package: gods_willing_commander_shield_cut_promise (`synergy_gods_willing_commander_shield_cut_promise`)

- objective: not available in structural matrix
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 16.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=33, lorehold_spell_cast=27, lorehold_spell_rummage=6, lorehold_upkeep_rummage=10, miracle_cast=5, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=7

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `0W/3L/0S`, WR `0.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=11, lorehold_spell_cast=8, lorehold_upkeep_rummage=3

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

