# Lorehold 607 Research Candidate squee_v1

- generated_at: `2026-06-28T12:22:05.082883+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260628_squee_v1_current/knowledge_candidate.db`
- candidate_hash: `c857064e44b93b9405f2f088195fd3cf5d28645f280e542196c7af8a4222c422`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Regenerate the current Squee champion candidate from the live deck_607 baseline. This preserves the rest of the 607 shell and replaces the expensive Insurrection finisher with repeatable graveyard recursion fodder for Lorehold rummage lines.

## External Signals

- The local active-learning registry marks +Squee, -Insurrection as the current champion after repeated equal gates.
- Squee has a verified/auto graveyard upkeep return rule in the local battle runtime.
- Earlier Squee diagnostics showed the swap is promising but still needs current-state confirmation and access-density follow-up.

## Swaps

| In | Out |
| --- | --- |
| Squee, Goblin Nabob | Insurrection |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 8
- `early_plan`: 36
- `graveyard_recursion`: 9
- `hand_filter`: 15
- `pressure_absorber`: 19
- `protection_window`: 17
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 12
