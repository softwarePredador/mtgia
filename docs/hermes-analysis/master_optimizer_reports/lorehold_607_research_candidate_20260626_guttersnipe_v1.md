# Lorehold 607 Research Candidate guttersnipe_v1

- generated_at: `2026-06-26T19:42:33.957740+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_guttersnipe_v1/knowledge_candidate.db`
- candidate_hash: `29c2d8fdc8ea9a991f1e641f083273cce490195661024b3946a86212c9832aaa`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test Guttersnipe as an instant/sorcery payoff sidegrade. This keeps Molecule Man, pressure absorption, board wipes, and expensive finishers intact while replacing the closest nonprotected spell-cast payoff creature.

## External Signals

- Local Lorehold variants 615 and 616 include Guttersnipe as a wincon/spell payoff.
- Guttersnipe and Prismari Pianist both reward repeated instant/sorcery casting with multiplayer pressure.
- The registry marks Guttersnipe lower priority because Longshot failed a similar payoff lane, so this test isolates the payoff swap only.

## Swaps

| In | Out |
| --- | --- |
| Guttersnipe | Prismari Pianist |

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
- `spell_chain_conversion`: 44
- `topdeck_miracle_setup`: 12
