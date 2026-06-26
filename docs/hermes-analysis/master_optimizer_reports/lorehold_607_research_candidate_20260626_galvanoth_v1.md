# Lorehold 607 Research Candidate galvanoth_v1

- generated_at: `2026-06-26T19:24:04.162927+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_galvanoth_v1/knowledge_candidate.db`
- candidate_hash: `3687ffab76464a16df6df5d8a558eb4f37eb540f0a7fd05bdd57621e3ae7c339`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test Galvanoth as an expensive topdeck/free-cast value sidegrade. This preserves Molecule Man, pressure absorption, board wipes, and the high-impact discover/cascade package while replacing the closest five-mana one-shot topdeck free-cast spell.

## External Signals

- Local Lorehold variants 611, 613, 614, and 615 include Galvanoth as a draw/topdeck engine.
- Creative Technique and Galvanoth both occupy expensive topdeck/free-cast value space around mana value five.
- The registry marked Galvanoth as a topdeck/miracle-aligned test only if the cut stayed in the expensive topdeck/value lane.

## Swaps

| In | Out |
| --- | --- |
| Galvanoth | Creative Technique |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 36
- `graveyard_recursion`: 8
- `hand_filter`: 15
- `pressure_absorber`: 19
- `protection_window`: 17
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 12
