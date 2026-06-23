# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T05:04:19+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=606`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `81`
- critical: `0`
- high: `7`
- medium: `30`
- low: `0`
- pass: `44`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `37`
- `generic_effect_without_model_scope`: `11`

## Top 37 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Flare of Duplication` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Powerbalance` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Reforge the Soul` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Rise of the Eldrazi` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `extra_turn` |
| `high` | `battle_critical` | 7051 | `Rite of the Dragoncaller` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Storm Herd` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Witch Enchanter // Witch-Blessed Meadow` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `medium` | `battle_critical` | 4051 | `Borrowed Knowledge` | 1 | 1 | `trusted_rule_without_oracle_hash` | `draw_cards` |
| `medium` | `battle_critical` | 4051 | `Chandra, Hope's Beacon` | 1 | 1 | `trusted_rule_without_oracle_hash` | `copy_spell` |
| `medium` | `battle_critical` | 4051 | `Farewell` | 1 | 1 | `trusted_rule_without_oracle_hash` | `board_wipe` |
| `medium` | `battle_critical` | 4051 | `Hit the Mother Lode` | 1 | 1 | `trusted_rule_without_oracle_hash` | `draw_cards`, `treasure_maker` |
| `medium` | `battle_critical` | 4051 | `Increasing Vengeance` | 1 | 1 | `trusted_rule_without_oracle_hash` | `copy_spell` |
| `medium` | `battle_critical` | 4051 | `Olórin's Searing Light` | 1 | 1 | `trusted_rule_without_oracle_hash` | `remove_creature` |
| `medium` | `battle_critical` | 4051 | `Ondu Inversion // Ondu Skyruins` | 1 | 1 | `trusted_rule_without_oracle_hash` | `board_wipe` |
| `medium` | `battle_critical` | 4051 | `Reckless Endeavor` | 1 | 1 | `trusted_rule_without_oracle_hash` | `damage_wipe_treasure` |
| `medium` | `battle_critical` | 4051 | `Restoration Seminar` | 1 | 1 | `trusted_rule_without_oracle_hash` | `recursion` |
| `medium` | `battle_critical` | 4051 | `Tibalt's Trickery` | 1 | 1 | `trusted_rule_without_oracle_hash` | `counter` |
| `medium` | `battle_critical` | 4051 | `Wear // Tear` | 1 | 1 | `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `medium` | `battle_support` | 4051 | `Commander's Plate` | 1 | 1 | `trusted_rule_without_oracle_hash` | `equipment_static_attachment` |
| `medium` | `battle_support` | 4051 | `Jeska's Will` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Mithril Coat` | 1 | 1 | `trusted_rule_without_oracle_hash` | `equipment_static_attachment` |
| `medium` | `battle_support` | 4051 | `Monologue Tax` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine` |
| `medium` | `battle_support` | 4051 | `Mox Opal` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Reverse the Sands` | 1 | 1 | `trusted_rule_without_oracle_hash` | `redistribute_life_totals` |
| `medium` | `battle_support` | 4051 | `Simian Spirit Guide` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Sunforger` | 1 | 1 | `trusted_rule_without_oracle_hash` | `equipment_static_attachment` |
| `medium` | `battle_support` | 4051 | `Swiftfoot Boots` | 1 | 1 | `trusted_rule_without_oracle_hash` | `equipment_static_attachment` |
| `medium` | `battle_support` | 4051 | `Thought Vessel` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Wayfarer's Bauble` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `support_or_passive` | 4051 | `Combustible Gearhulk` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Hexing Squelcher` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Improvisation Capstone` | 1 | 1 | `trusted_rule_without_oracle_hash` | `exile_value` |
| `medium` | `support_or_passive` | 4051 | `Library of Leng` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Ragavan, Nimble Pilferer` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Skyclave Apparition` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Soulfire Eruption` | 1 | 1 | `trusted_rule_without_oracle_hash` | `deal_damage` |
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
