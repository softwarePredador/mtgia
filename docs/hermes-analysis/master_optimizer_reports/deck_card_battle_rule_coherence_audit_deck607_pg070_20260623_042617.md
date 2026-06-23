# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T04:29:23+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=607`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `94`
- critical: `0`
- high: `30`
- medium: `17`
- low: `0`
- pass: `47`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `28`
- `generic_effect_without_model_scope`: `15`
- `no_trusted_executable_rule`: `13`
- `review_only_or_needs_review_rule`: `13`
- `no_active_battle_rule`: `6`

## Top 47 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Artist's Talent` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Avatar's Wrath` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `silence_opponents` |
| `high` | `battle_critical` | 7051 | `Call Forth the Tempest` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `damage_wipe` |
| `high` | `battle_critical` | 7051 | `Creative Technique` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Dawn's Truce` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Esper Sentinel` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Everything Comes to Dust` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Fated Clash` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Furygale Flocking` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Generous Gift` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `High Noon` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Insurrection` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `steal_all_creatures` |
| `high` | `battle_critical` | 7051 | `Pinnacle Monk // Mystic Peak` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Prismari Pianist` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Promise of Loyalty` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Redirect Lightning` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Reforge the Soul` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Rise of the Eldrazi` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `extra_turn` |
| `high` | `battle_critical` | 7051 | `Starfall Invocation` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Storm Herd` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Stroke of Midnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Tempt with Bunnies` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Winds of Abandon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_support` | 7051 | `Pearl Medallion` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Emeria's Call // Emeria, Shattered Skyclave` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Molecule Man` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Mind Stone` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Scarlet Witch` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Thor, God of Thunder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tragic Arrogance` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_critical` | 4051 | `Farewell` | 1 | 1 | `trusted_rule_without_oracle_hash` | `board_wipe` |
| `medium` | `battle_critical` | 4051 | `Hit the Mother Lode` | 1 | 1 | `trusted_rule_without_oracle_hash` | `draw_cards`, `treasure_maker` |
| `medium` | `battle_critical` | 4051 | `Tibalt's Trickery` | 1 | 1 | `trusted_rule_without_oracle_hash` | `counter` |
| `medium` | `battle_support` | 4051 | `Bender's Waterskin` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Big Score` | 1 | 1 | `trusted_rule_without_oracle_hash` | `treasure_maker` |
| `medium` | `battle_support` | 4051 | `Jeska's Will` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Mizzix's Mastery` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `overload_recursion` |
| `medium` | `battle_support` | 4051 | `Ruby Medallion` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine` |
| `medium` | `battle_support` | 4051 | `Swiftfoot Boots` | 1 | 1 | `trusted_rule_without_oracle_hash` | `equipment_static_attachment` |
| `medium` | `battle_support` | 4051 | `Victory Chimes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `support_or_passive` | 4051 | `Giver of Runes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Hexing Squelcher` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Improvisation Capstone` | 1 | 1 | `trusted_rule_without_oracle_hash` | `exile_value` |
| `medium` | `support_or_passive` | 4051 | `Library of Leng` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Monument to Endurance` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Mother of Runes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
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
