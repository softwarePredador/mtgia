# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T04:44:54+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=610`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `95`
- critical: `0`
- high: `34`
- medium: `7`
- low: `0`
- pass: `54`

## Finding Counts

- `review_only_or_needs_review_rule`: `23`
- `no_active_battle_rule`: `18`
- `trusted_rule_without_oracle_hash`: `9`
- `generic_effect_without_model_scope`: `6`
- `no_trusted_executable_rule`: `6`

## Top 41 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `All Is Dust` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Apex of Power` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7051 | `Beacon of Immortality` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Invincible Hymn` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Lens of Clarity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Mystic Forge` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Oswald Fiddlebender` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7051 | `Tezzeret, Cruel Captain` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `tutor` |
| `high` | `battle_critical` | 7051 | `Vanquish the Horde` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_support` | 7051 | `Helm of Awakening` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Manifold Key` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Perpetual Timepiece` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Primal Amulet // Primal Wellspring` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Sculpting Steel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Unwinding Clock` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Voltaic Key` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `support_or_passive` | 7051 | `Assemble the Players` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Codex Shredder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Ghoulcaller's Bell` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn's Sylex` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn, the Great Creator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kayla's Music Box` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Lantern of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Leyline Dowser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Millikin` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Open the Vaults` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Orcish Spy` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Prototype Portal` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Pyxis of Pandemonium` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Roar of Reclamation` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Warring Triad` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Triumphant Reckoning` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Unstable Glyphbridge // Sandswirl Wanderglyph` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Wand of Vertebrae` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `land_or_mana_base` | 4051 | `Adagia, Windswept Bastion` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Boros Garrison` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Buried Ruin` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Darksteel Citadel` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Fomori Vault` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Rustvale Bridge` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Spire of Industry` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
