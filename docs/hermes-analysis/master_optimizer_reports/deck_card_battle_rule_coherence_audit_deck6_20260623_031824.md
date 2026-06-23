# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T03:18:39+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=6`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `100`
- critical: `0`
- high: `25`
- medium: `7`
- low: `0`
- pass: `68`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `31`
- `review_only_or_needs_review_rule`: `24`
- `generic_effect_without_model_scope`: `17`

## Top 32 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Chaos Warp` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Drannith Magistrate` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `silence_opponents` |
| `high` | `battle_critical` | 7051 | `Dualcaster Mage` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Esper Sentinel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Faithless Looting` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Gamble` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Get Lost` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Giver of Runes` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `high` | `battle_critical` | 7051 | `Heat Shimmer` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Molten Duplication` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Mother of Runes` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `high` | `battle_critical` | 7051 | `Pyroblast` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Ranger-Captain of Eos` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `silence_opponents` |
| `high` | `battle_critical` | 7051 | `Reiterate` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `The One Ring` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_engine`, `indestructible` |
| `high` | `battle_critical` | 7051 | `Twinflame` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Wheel of Misfortune` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_support` | 7051 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Jeska's Will` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Lotus Petal` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Mizzix's Mastery` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `overload_recursion` |
| `high` | `battle_support` | 7051 | `Professional Face-Breaker` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_engine` |
| `high` | `battle_support` | 7051 | `Ruby Medallion` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Storm-Kiln Artist` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_engine` |
| `high` | `battle_support` | 7051 | `Unexpected Windfall` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `treasure_maker` |
| `medium` | `battle_critical` | 4051 | `Silence` | 1 | 1 | `trusted_rule_without_oracle_hash` | `silence_spell` |
| `medium` | `battle_support` | 4051 | `Fellwar Stone` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Mana Vault` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Mox Amber` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Seething Song` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Talisman of Conviction` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
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
