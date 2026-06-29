# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T17:46:23+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=612`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `100`
- critical: `0`
- high: `4`
- medium: `2`
- low: `0`
- pass: `94`

## Finding Counts

- `shadow_rule_preserved_for_history`: `8`
- `no_trusted_executable_rule`: `3`
- `review_only_or_needs_review_rule`: `3`
- `generic_effect_without_model_scope`: `2`
- `trusted_rule_without_oracle_hash`: `2`
- `no_active_battle_rule`: `1`

## Top 6 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Ancient Gold Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Gisela, Blade of Goldnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_support` | 7051 | `Cloud Key` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Charmbreaker Devils` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_support` | 4051 | `Helm of Awakening` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Lion's Eye Diamond` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
