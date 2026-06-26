# Lorehold 607 Research Candidate longshot_v1

- generated_at: `2026-06-26T17:53:05.180911+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_longshot_v1/knowledge_candidate.db`
- candidate_hash: `90832661271eba82433779ef1c60b4beb4b51671f05fb3880d361f1f34e7645d`
- strategy_version: `lorehold_strategy_profile_v2_2026_06_26`
- commander_intent_score: `100.0`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Test one external-learning payoff swap: replace a ten-mana token finisher with a lower-curve noncreature-spell payoff that also reduces noncreature spell costs. This preserves the deck_607 defensive shell.

## External Signals

- EDHREC and public Lorehold lists surface Longshot-style noncreature spell payoff as a recent spellslinger lane.
- Internal Lorehold variant 615 includes Longshot and ranked second in the intent matrix after deck_607.
- Local battle_card_rules has a verified auto rule for Longshot's noncreature-spell damage trigger.

## Swaps

| In | Out |
| --- | --- |
| Longshot, Rebel Bowman | Storm Herd |

## Counts

- row_count: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Strategy Package Counts

- `deterministic_finisher`: 9
- `early_plan`: 37
- `graveyard_recursion`: 8
- `hand_filter`: 15
- `pressure_absorber`: 19
- `protection_window`: 17
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 12
