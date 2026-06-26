# Lorehold 607 Research Candidate ghostly_prison_v1

- generated_at: `2026-06-26T19:33:52.945181+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_ghostly_prison_v1/knowledge_candidate.db`
- candidate_hash: `8ddaea06ecd8e4dfd5aa9d79c6179e175f61592891f03c96fbcf481adc2feac3`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test Ghostly Prison as a pressure-absorber stax sidegrade. This keeps Molecule Man, board wipes, miracle/topdeck setup, and protected pressure pieces intact while replacing the closest nonprotected enchantment tax slot.

## External Signals

- Local Lorehold variants 613 and 616 tag Ghostly Prison as protection/stax.
- High Noon and Ghostly Prison are both low-cost enchantment stax pieces, but Ghostly Prison maps directly to combat pressure absorption.
- The registry requires Ghostly Prison to be tested only as a pressure/stax replacement, not as a spell-density cut.

## Swaps

| In | Out |
| --- | --- |
| Ghostly Prison | High Noon |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 35
- `graveyard_recursion`: 8
- `hand_filter`: 16
- `pressure_absorber`: 19
- `protection_window`: 18
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 12
