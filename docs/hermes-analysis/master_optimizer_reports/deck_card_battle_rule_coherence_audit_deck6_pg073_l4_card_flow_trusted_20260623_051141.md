# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T05:24:54+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=6`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `100`
- critical: `0`
- high: `1`
- medium: `17`
- low: `0`
- pass: `82`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `18`
- `generic_effect_without_model_scope`: `3`

## Top 18 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Chaos Warp` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `medium` | `battle_critical` | 4051 | `Scroll Rack` | 1 | 1 | `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `medium` | `battle_critical` | 4051 | `Silence` | 1 | 1 | `trusted_rule_without_oracle_hash` | `silence_spell` |
| `medium` | `battle_support` | 4051 | `Fellwar Stone` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Jeska's Will` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Mana Vault` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Mizzix's Mastery` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `overload_recursion` |
| `medium` | `battle_support` | 4051 | `Mox Amber` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Seething Song` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Talisman of Conviction` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Unexpected Windfall` | 1 | 1 | `trusted_rule_without_oracle_hash` | `treasure_maker` |
| `medium` | `support_or_passive` | 4051 | `Drannith Magistrate` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Giver of Runes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Mother of Runes` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Professional Face-Breaker` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Ranger-Captain of Eos` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Storm-Kiln Artist` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Valakut Awakening // Valakut Stoneforge` | 1 | 1 | `trusted_rule_without_oracle_hash` | `hand_filter` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
