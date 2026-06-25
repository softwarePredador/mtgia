# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T00:17:05+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=612`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `100`
- critical: `0`
- high: `27`
- medium: `7`
- low: `0`
- pass: `66`

## Finding Counts

- `review_only_or_needs_review_rule`: `26`
- `no_trusted_executable_rule`: `13`
- `no_active_battle_rule`: `8`
- `trusted_rule_without_oracle_hash`: `6`
- `generic_effect_without_model_scope`: `5`

## Top 34 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Agate Instigator` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Ancient Gold Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Ephemerate` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Gisela, Blade of Goldnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Impact Tremors` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Longshot, Rebel Bowman` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `high` | `battle_critical` | 7051 | `Molten Gatekeeper` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Reprieve` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Ultima` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_support` | 7051 | `Cloud Key` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Grinding Station` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Helm of Awakening` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Lion's Eye Diamond` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Mana Geyser` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Pyromancer's Goggles` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Semblance Anvil` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Boros Reckoner` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Charmbreaker Devils` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Purphoros, God of the Forge` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `pump_all` |
| `high` | `support_or_passive` | 7051 | `Rem Karolus, Stalwart Slayer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Repercussion` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Taii Wakeen, Perfect Shot` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Terror of the Peaks` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Toralf, God of Fury // Toralf's Hammer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Warleader's Call` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `pump_all` |
| `high` | `support_or_passive` | 7051 | `Wild Ricochet` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Zirda, the Dawnwaker` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `land_or_mana_base` | 4051 | `Boseiju, Who Shelters All` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Cavern of Souls` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `City of Traitors` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Crystal Vein` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Eiganjo, Seat of the Empire` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Forbidden Orchard` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Sokenzan, Crucible of Defiance` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
