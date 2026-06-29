# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T17:46:23+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=614`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `91`
- critical: `0`
- high: `1`
- medium: `3`
- low: `0`
- pass: `87`

## Finding Counts

- `shadow_rule_preserved_for_history`: `5`
- `trusted_rule_without_oracle_hash`: `3`
- `no_trusted_executable_rule`: `1`
- `review_only_or_needs_review_rule`: `1`
- `generic_effect_without_model_scope`: `1`

## Top 4 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_support` | 7051 | `Currency Converter` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `medium` | `battle_critical` | 4051 | `Akroma's Will` | 1 | 1 | `trusted_rule_without_oracle_hash` | `indestructible`, `pump_all` |
| `medium` | `battle_support` | 4051 | `Helm of Awakening` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Radiant Scrollwielder` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature`, `overload_recursion` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
