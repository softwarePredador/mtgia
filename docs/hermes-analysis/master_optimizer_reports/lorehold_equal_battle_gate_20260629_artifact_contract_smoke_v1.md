# Lorehold Equal Battle Gate

- generated_at: `2026-06-29T19:41:31Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `45.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_equal_battle_gate_20260629_artifact_contract_smoke_v1_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 1 | 1 | 0 | 0 | 100.00% | 14.00 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 4 | 0 | unattributed: events=4, restricted=4, tax=0 | recursion_role, tutor_role |
| 2 | 3 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 1 | 1 | 0 | 0 | 100.00% | 13.00 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | removal_role, protection_role, recursion_role |
| 3 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 1 | 1 | 0 | 0 | 100.00% | 12.00 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | removal_role, recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=1, lorehold_cost_paid=17, lorehold_rummage_discard_to_top=1, lorehold_spell_cast=14, lorehold_upkeep_rummage=1, miracle_cast=1, topdeck_manipulation_activated=2

**Lorehold attack restriction telemetry:** events=4, attackers_before=12, attackers_after=8, attackers_restricted=4, tax_paid=0, sources=unattributed: events=4, restricted=4, tax=0

### 2. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

- objective: Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.
- result: `1W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `33`, ramp `22`, removal `8`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 13.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=11, lorehold_spell_cast=7, lorehold_upkeep_rummage=3, miracle_cast=2, topdeck_manipulation_activated=8

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 3. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `1W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 12.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=11, lorehold_spell_cast=8, lorehold_upkeep_rummage=2, miracle_cast=1

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
