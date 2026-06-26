# Lorehold 607 Research Candidate penance_v1

- generated_at: `2026-06-26T17:44:22.989691+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_penance_v1/knowledge_candidate.db`
- candidate_hash: `29713d8d7d192f3928da6caa9e7262f745716c2f1da837575fe100b5ad468621`
- strategy_version: `lorehold_strategy_profile_v2_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test one external-learning swap: add Penance for topdeck setup and red/black damage prevention while removing one five-mana pressure spell. This protects the deck_607 shell and follows the one-card ablation rule.

## External Signals

- EDHREC average Lorehold lists include Penance as a commander-specific support card.
- Reddit discussion highlights Penance as a Lorehold enabler because it puts cards from hand on top of library.
- Local battle_card_rules has a verified auto rule for Penance.

## Swaps

| In | Out |
| --- | --- |
| Penance | Promise of Loyalty |

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
- `spell_chain_conversion`: 42
- `topdeck_miracle_setup`: 13
