# Lorehold 607 Research Candidate reprieve_v1

- generated_at: `2026-06-26T19:09:45.602544+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_reprieve_v1/knowledge_candidate.db`
- candidate_hash: `6806c06b91364be9d2614e13b1280a6cac2d16f89944a90fdf47c6e966e1492e`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test Reprieve as a same-function protection/counter sidegrade. This keeps Molecule Man, miracle/topdeck setup, pressure absorption, board wipes, and finishers intact while replacing a two-mana counter with a lower-variance two-mana spell-delay cantrip.

## External Signals

- Local Lorehold variants 612, 613, and 615 include Reprieve as a protection card.
- Reprieve and Tibalt's Trickery are both two-mana instant interaction/protection slots in the local card corpus.
- The registry marked Reprieve as the P1 next test only if the cut stayed same-function and did not remove pressure or miracle payoff.

## Swaps

| In | Out |
| --- | --- |
| Reprieve | Tibalt's Trickery |

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
- `topdeck_miracle_setup`: 11
