# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-24T22:02:13+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=609`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `92`
- critical: `0`
- high: `20`
- medium: `8`
- low: `0`
- pass: `64`

## Finding Counts

- `review_only_or_needs_review_rule`: `23`
- `no_trusted_executable_rule`: `9`
- `trusted_rule_without_oracle_hash`: `6`
- `no_active_battle_rule`: `4`
- `generic_effect_without_model_scope`: `3`

## Top 28 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Apex of Power` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7051 | `Archivist of Oghma` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bolt Bend` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Clever Concealment` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `phase_out` |
| `high` | `battle_critical` | 7051 | `Dance with Calamity` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `exile_value` |
| `high` | `battle_critical` | 7051 | `Dragon's Rage Channeler` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Penance` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Perch Protection` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `extra_turn` |
| `high` | `battle_critical` | 7051 | `Sejiri Shelter // Sejiri Glacier` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Squee, Goblin Nabob` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Sundering Eruption // Volcanic Fissure` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Vandalblast` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Verge Rangers` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Volcanic Vision` | 1 | 1 | `review_only_or_needs_review_rule` | `recursion` |
| `high` | `support_or_passive` | 7051 | `Blood Sun` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Knight of the White Orchid` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Loyal Warhound` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Sand Scout` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Scholar of New Horizons` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Starfield Shepherd` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `support_or_passive` | 4051 | `Soul-Guide Lantern` | 1 | 1 | `trusted_rule_without_oracle_hash` | `hate_artifact` |
| `medium` | `land_or_mana_base` | 4051 | `Ash Barrens` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Boros Garrison` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Glittering Massif` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Guildless Commons` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Lotus Vale` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Radiant Summit` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Scavenger Grounds` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
