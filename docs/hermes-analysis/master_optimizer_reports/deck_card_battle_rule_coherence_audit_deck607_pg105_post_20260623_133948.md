# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T13:42:29+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=607`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `94`
- critical: `0`
- high: `11`
- medium: `4`
- low: `0`
- pass: `79`

## Finding Counts

- `no_active_battle_rule`: `6`
- `no_trusted_executable_rule`: `5`
- `review_only_or_needs_review_rule`: `5`
- `trusted_rule_without_oracle_hash`: `4`
- `generic_effect_without_model_scope`: `1`

## Top 15 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Everything Comes to Dust` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Fated Clash` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Promise of Loyalty` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Starfall Invocation` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_support` | 7051 | `Pearl Medallion` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Emeria's Call // Emeria, Shattered Skyclave` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Molecule Man` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Mind Stone` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Scarlet Witch` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Thor, God of Thunder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tragic Arrogance` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_support` | 4051 | `Bender's Waterskin` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Victory Chimes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `support_or_passive` | 4051 | `Monument to Endurance` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Surge to Victory` | 1 | 1 | `trusted_rule_without_oracle_hash` | `pump_all` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
