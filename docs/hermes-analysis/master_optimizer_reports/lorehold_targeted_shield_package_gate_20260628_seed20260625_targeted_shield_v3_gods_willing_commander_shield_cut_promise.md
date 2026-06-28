# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T04:48:54Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260625`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_gods_willing_commander_shield_cut_promise_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 3 | 1 | 2 | 0 | 33.33% | 9.00 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 3 | 9 | 0 | unattributed: events=9, restricted=9, tax=0 | wincon_role |
| 2 |  | Lorehold synergy package: gods_willing_commander_shield_cut_promise (`synergy_gods_willing_commander_shield_cut_promise`) | synergy-package | 3 | 1 | 2 | 0 | 33.33% | 11.00 | 3 | 1 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | none | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 9.00 | approach=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=8, lorehold_cost_paid=33, lorehold_rummage_discard_to_top=8, lorehold_spell_cast=27, lorehold_spell_rummage=2, lorehold_upkeep_rummage=14, miracle_cast=2

**Lorehold attack restriction telemetry:** events=9, attackers_before=29, attackers_after=20, attackers_restricted=9, tax_paid=0, sources=unattributed: events=9, restricted=9, tax=0

### 2. Lorehold synergy package: gods_willing_commander_shield_cut_promise (`synergy_gods_willing_commander_shield_cut_promise`)

- objective: not available in structural matrix
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** lorehold_cost_paid=32, lorehold_spell_cast=25, lorehold_upkeep_rummage=13, miracle_cast=5, topdeck_manipulation_activated=3

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

