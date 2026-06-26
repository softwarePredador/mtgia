# Lorehold 607 Research Candidate birgi_v1

- generated_at: `2026-06-26T18:23:17.632625+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_birgi_v1/knowledge_candidate.db`
- candidate_hash: `32f91cf53fbf8191b82927e2bedbf45214d2041f7b370c4618adb0f3298ec017`
- strategy_version: `lorehold_strategy_profile_v3_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test Birgi as a same-function mana/engine sidegrade. This keeps the deck_607 pressure, wincon, protection, and miracle package intact while replacing a three-mana mana artifact with a spell-chain mana engine.

## External Signals

- Birgi is structurally aligned with spellslinger shells because it converts every spell cast into red mana.
- Local battle_card_rules has an active auto rule for the front-face spell-cast red mana trigger.
- Prior Birgi-containing packages failed, but Birgi itself has not been tested as an isolated sidegrade.

## Swaps

| In | Out |
| --- | --- |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 36
- `graveyard_recursion`: 8
- `hand_filter`: 16
- `pressure_absorber`: 19
- `protection_window`: 17
- `spell_chain_conversion`: 44
- `topdeck_miracle_setup`: 12
