# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T08:20:55+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=606`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `81`
- critical: `0`
- high: `0`
- medium: `4`
- low: `0`
- pass: `77`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `4`

## Top 4 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `medium` | `support_or_passive` | 4051 | `Hexing Squelcher` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Ragavan, Nimble Pilferer` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Skyclave Apparition` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Underworld Breach` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
