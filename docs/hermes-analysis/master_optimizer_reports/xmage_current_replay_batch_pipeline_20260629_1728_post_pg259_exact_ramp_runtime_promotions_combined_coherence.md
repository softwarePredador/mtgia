# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T17:15:29+00:00`

Scope: distinct cards referenced by Hermes `deck_cards`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `791`
- critical: `1`
- high: `109`
- medium: `49`
- low: `0`
- pass: `632`

## Finding Counts

- `shadow_rule_preserved_for_history`: `84`
- `trusted_rule_without_oracle_hash`: `76`
- `no_active_battle_rule`: `73`
- `generic_effect_without_model_scope`: `44`
- `no_trusted_executable_rule`: `10`
- `review_only_or_needs_review_rule`: `10`
- `missing_oracle_identity`: `1`
- `missing_oracle_text`: `1`

## Top 120 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `critical` | `support_or_passive` | 10051 | `Lim-Dul's Vault` | 1 | 1 | `missing_oracle_identity`, `no_active_battle_rule` | - |
| `high` | `battle_critical` | 7153 | `Tymna the Weaver` | 3 | 3 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Aven Interrupter` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent`, `silence_opponents` |
| `high` | `battle_critical` | 7102 | `Beseech the Mirror` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Intuition` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invasion of Ikoria` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Praetor's Grasp` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7102 | `Tezzeret the Seeker` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Wheel of Fate` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Abrade` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_artifact_or_3dmg`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Alhammarret's Archive` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `All Is Dust` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Amphibian Downpour` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `finisher`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Ancient Gold Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Arcane Bombardment` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Archivist of Oghma` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Blood Moon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bolas's Citadel` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Chandra's Ignition` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Commandeer` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Entomb` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7051 | `Flashback` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `recursion` |
| `high` | `battle_critical` | 7051 | `Gifts Ungiven` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Gisela, Blade of Goldnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Growing Rites of Itlimoc` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Jin-Gitaxias, Progress Tyrant` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Lens of Clarity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Misdirection` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `redirect_removal` |
| `high` | `battle_critical` | 7051 | `Mystic Forge` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Peer into the Abyss` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Pyrokinesis` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Transmute Artifact` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Volatile Stormdrake` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Worldfire` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe`, `worldfire_reset` |
| `high` | `battle_support` | 7051 | `Cloud Key` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Currency Converter` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Neheb, the Eternal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Perpetual Timepiece` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `support_or_passive` | 7306 | `Valley Floodcaller` | 6 | 6 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7204 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | 4 | 4 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7204 | `Endurance` | 4 | 4 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Gilded Drake` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Seedborn Muse` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Spellskite` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Tyvar, Jubilant Brawler` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Wandering Archaic` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Delney, Streetwise Lookout` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Marvin, Murderous Mimic` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Moonshadow` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Nyxbloom Ancient` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Opposition Agent` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Patrolling Peacemaker` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Tayam, Luminous Enigma` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `White Plume Adventurer` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Young Wolf` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Aminatou's Augury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Assemble the Players` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Autumn's Veil` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blazing Firesinger` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bond of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Chaos Wand` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Charmbreaker Devils` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Clout of the Dominus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Codex Shredder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Collector Ouphe` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Colonel Autumn` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dauntless Dismantler` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Deathbellow War Cry` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Derevi, Empyrial Tactician` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dimensional Infiltrator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Disruptor Flute` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Eight-and-a-Half-Tails` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Epic Experiment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Etali, Primal Conqueror` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Experimental Overload` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Fury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Gandalf's Sanction` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Ghoulcaller's Bell` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hellkite Courser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hope of Ghirapur` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hunting Velociraptor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn's Sylex` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn, the Great Creator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kayla's Music Box` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Lantern of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Leyline Dowser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Memnite` | 1 | 1 | `missing_oracle_text`, `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Metallurgic Summonings` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mystic Reflection` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Naktamun Lorespinner // Wheel of Fortune` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Nature's Chosen` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Orcish Spy` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Possibility Storm` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Protective Bubble` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Prototype Portal` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Pulsemage Advocate` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Pyxis of Pandemonium` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Roaming Throne` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rograkh, Son of Rohgahh` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Steal Enchantment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Stitcher's Supplier` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Strangleroot Geist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subjugate the Hobbits` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subtlety` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Summons of Saruman` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Swift Reconfiguration` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tidal Barracuda` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Vial Smasher the Fierce` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Void Winnower` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Zephid's Embrace` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_critical` | 4153 | `Mystical Tutor` | 3 | 3 | `trusted_rule_without_oracle_hash` | `tutor` |
| `medium` | `battle_critical` | 4102 | `Carpet of Flowers` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `medium` | `battle_critical` | 4102 | `Culling Ritual` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_ritual` |
| `medium` | `battle_critical` | 4102 | `Sylvan Safekeeper` | 2 | 2 | `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `medium` | `battle_critical` | 4102 | `Tezzeret, Cruel Captain` | 2 | 2 | `trusted_rule_without_oracle_hash` | `passive`, `tutor` |
| `medium` | `battle_critical` | 4051 | `Akroma's Will` | 1 | 1 | `trusted_rule_without_oracle_hash` | `indestructible`, `pump_all` |
| `medium` | `battle_critical` | 4051 | `Ashling, Flame Dancer` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `medium` | `battle_critical` | 4051 | `Dismember` | 1 | 1 | `trusted_rule_without_oracle_hash` | `draw_cards`, `remove_creature` |
| `medium` | `battle_critical` | 4051 | `Electro, Assaulting Battery` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature`, `remove_creature` |
| `medium` | `battle_critical` | 4051 | `Food Chain` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
