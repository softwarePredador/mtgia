# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T17:46:37+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=74`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `100`
- critical: `0`
- high: `8`
- medium: `9`
- low: `0`
- pass: `83`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `14`
- `shadow_rule_preserved_for_history`: `11`
- `generic_effect_without_model_scope`: `6`
- `no_active_battle_rule`: `3`

## Top 17 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Beseech the Mirror` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Bolas's Citadel` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Entomb` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7051 | `Peer into the Abyss` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Tymna the Weaver` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `support_or_passive` | 7051 | `Delney, Streetwise Lookout` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hope of Ghirapur` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Stitcher's Supplier` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_support` | 4051 | `Altar of Dementia` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent`, `unknown` |
| `medium` | `battle_support` | 4051 | `Defense Grid` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Lion's Eye Diamond` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `support_or_passive` | 4051 | `Altar of the Wretched` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Deadpool, Trading Card` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Goblin Welder` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Greedy Freebooter` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Shambling Ghast` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Vexing Bauble` | 1 | 1 | `trusted_rule_without_oracle_hash` | `hate_artifact` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
