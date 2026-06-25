# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T02:57:36+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=614`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `91`
- critical: `0`
- high: `20`
- medium: `2`
- low: `0`
- pass: `69`

## Finding Counts

- `review_only_or_needs_review_rule`: `22`
- `no_trusted_executable_rule`: `11`
- `trusted_rule_without_oracle_hash`: `8`
- `generic_effect_without_model_scope`: `4`

## Top 22 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Akroma's Will` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `indestructible`, `pump_all` |
| `high` | `battle_critical` | 7051 | `Authority of the Consuls` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bolt Bend` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Dance with Calamity` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `exile_value` |
| `high` | `battle_critical` | 7051 | `Deflecting Palm` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Dragon's Rage Channeler` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Galvanoth` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Heroes Remembered` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Invincible Hymn` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Penance` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Reckless Handling` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Ultima` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Volcanic Vision` | 1 | 1 | `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_support` | 7051 | `Chrome Mox` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Currency Converter` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Helm of Awakening` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Mana Geyser` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Radiant Scrollwielder` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `overload_recursion` |
| `high` | `battle_support` | 7051 | `Treasonous Ogre` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_ritual` |
| `high` | `support_or_passive` | 7051 | `Goliath Daydreamer` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `medium` | `land_or_mana_base` | 4051 | `Cavern of Souls` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Conduit Pylons` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
