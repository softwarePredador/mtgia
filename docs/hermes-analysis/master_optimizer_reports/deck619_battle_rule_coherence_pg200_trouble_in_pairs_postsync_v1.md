# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T02:57:36+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=619`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `89`
- critical: `0`
- high: `30`
- medium: `4`
- low: `0`
- pass: `55`

## Finding Counts

- `review_only_or_needs_review_rule`: `20`
- `no_active_battle_rule`: `12`
- `no_trusted_executable_rule`: `11`
- `trusted_rule_without_oracle_hash`: `9`
- `generic_effect_without_model_scope`: `5`

## Top 34 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Forge Anew` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Grim Tutor` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Lightning, Army of One` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Maskwood Nexus` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Oswald Fiddlebender` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7051 | `Puresteel Paladin` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Razaketh, the Foulblooded` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `tutor` |
| `high` | `battle_critical` | 7051 | `Rune-Scarred Demon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `tutor` |
| `high` | `battle_critical` | 7051 | `Sigarda's Aid` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Sram, Senior Edificer` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Stoneforge Mystic` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7051 | `Voice of Victory` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `silence_opponents` |
| `high` | `battle_critical` | 7051 | `Wishclaw Talisman` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_support` | 7051 | `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Genji Glove` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Hammer of Nazahn` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Ornithopter of Paradise` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Smuggler's Share` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `support_or_passive` | 7051 | `Alicia Masters, Skilled Sculptor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Ardenn, Intrepid Archaeologist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Biotransference` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blightsteel Colossus // Blightsteel Colossus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bloodthirster` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Delney, Streetwise Lookout` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kaalia of the Vast` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karlach, Fury of Avernus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Master of Cruelties` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mjölnir, Hammer of Thor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Seriema` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Vorpal Sword` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_support` | 4051 | `Burnt Offering` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `support_or_passive` | 4051 | `Necrodominance` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `land_or_mana_base` | 4051 | `City of Traitors` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Fabled Passage` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
