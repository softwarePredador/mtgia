# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-23T19:28:20+00:00`

Scope: distinct cards referenced by Hermes `deck_cards`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `205`
- critical: `0`
- high: `23`
- medium: `15`
- low: `0`
- pass: `167`

## Finding Counts

- `review_only_or_needs_review_rule`: `32`
- `no_trusted_executable_rule`: `13`
- `no_active_battle_rule`: `5`
- `trusted_rule_without_oracle_hash`: `2`
- `generic_effect_without_model_scope`: `1`

## Top 38 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Angel's Grace` | 1 | 1 | `generic_effect_without_model_scope` | `cannot_lose_turn` |
| `high` | `battle_critical` | 7051 | `Cool but Rude` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Magmakin Artillerist` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Pyromancer Ascension` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Razorgrass Ambush // Razorgrass Field` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Surge to Victory` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `pump_all`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Tempt with Bunnies` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `token_maker` |
| `high` | `battle_critical` | 7051 | `Twinflame Tyrant` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Velomachus Lorehold` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_support` | 7102 | `Monument to Endurance` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_engine` |
| `high` | `battle_support` | 7051 | `Ancient Copper Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Big Score` | 1 | 1 | `review_only_or_needs_review_rule` | `ramp_engine`, `treasure_maker` |
| `high` | `battle_support` | 7051 | `Goldspan Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Locket of Yesterdays` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Pyromancer's Goggles` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Surly Badgersaur` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Tablet of Discovery` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Emeria's Call // Emeria, Shattered Skyclave` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Molecule Man` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Naktamun Lorespinner // Wheel of Fortune` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Terror of the Peaks` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `The Mind Stone` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Thor, God of Thunder` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `land_or_mana_base` | 4153 | `Eiganjo, Seat of the Empire` | 3 | 3 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Command Beacon` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Radiant Summit` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Reliquary Tower` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Turbulent Steppe` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Boros Garrison` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Boseiju, Who Shelters All` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Cori Mountain Monastery` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Exotic Orchard` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Furycalm Snarl` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Glittering Massif` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Plaza of Heroes` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Scavenger Grounds` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Sokenzan, Crucible of Defiance` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Valakut, the Molten Pinnacle` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
