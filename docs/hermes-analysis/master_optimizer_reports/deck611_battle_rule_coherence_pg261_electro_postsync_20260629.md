# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T17:36:15+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=611`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `90`
- critical: `0`
- high: `3`
- medium: `1`
- low: `0`
- pass: `86`

## Finding Counts

- `shadow_rule_preserved_for_history`: `5`
- `trusted_rule_without_oracle_hash`: `3`
- `generic_effect_without_model_scope`: `2`
- `no_trusted_executable_rule`: `1`
- `review_only_or_needs_review_rule`: `1`

## Top 4 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Alhammarret's Archive` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Arcane Bombardment` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Wheel of Fate` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `medium` | `battle_critical` | 4051 | `Ashling, Flame Dancer` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature`, `finisher` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
