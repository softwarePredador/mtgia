# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T12:13:00+00:00`

Scope: distinct cards referenced by Hermes `deck_cards`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `541`
- critical: `1`
- high: `125`
- medium: `31`
- low: `0`
- pass: `384`

## Finding Counts

- `trusted_rule_without_oracle_hash`: `73`
- `no_active_battle_rule`: `67`
- `review_only_or_needs_review_rule`: `61`
- `generic_effect_without_model_scope`: `40`
- `no_trusted_executable_rule`: `3`
- `missing_oracle_identity`: `1`
- `missing_oracle_text`: `1`

## Top 120 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `critical` | `support_or_passive` | 10051 | `Lim-Dul's Vault` | 1 | 1 | `missing_oracle_identity`, `no_active_battle_rule` | - |
| `high` | `battle_critical` | 7153 | `Tymna the Weaver` | 3 | 3 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Aven Interrupter` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent`, `silence_opponents` |
| `high` | `battle_critical` | 7102 | `Beseech the Mirror` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Carpet of Flowers` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7102 | `Culling Ritual` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_ritual` |
| `high` | `battle_critical` | 7102 | `Deafening Silence` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_engine`, `passive` |
| `high` | `battle_critical` | 7102 | `Intuition` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invasion of Ikoria` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Praetor's Grasp` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7102 | `Sylvan Safekeeper` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `high` | `battle_critical` | 7102 | `Tezzeret the Seeker` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Amphibian Downpour` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `finisher`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Bolas's Citadel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Breena, the Demagogue` | 1 | 1 | `review_only_or_needs_review_rule` | `creature`, `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bridgeworks Battle` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Cloud of Faeries` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Commandeer` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Decaying Time Loop` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Demonic Counsel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Dismember` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Drown in Dreams` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7051 | `Entomb` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7051 | `Food Chain` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Freed from the Real` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Gifts Ungiven` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Growing Rites of Itlimoc` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Jin-Gitaxias, Progress Tyrant` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Misdirection` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `redirect_removal` |
| `high` | `battle_critical` | 7051 | `Neoform` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `One with the Multiverse` | 1 | 1 | `review_only_or_needs_review_rule` | `passive`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Peer into the Abyss` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Pyrokinesis` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Scour for Scrap` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Selvala, Heart of the Wilds` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Shark Typhoon` | 1 | 1 | `review_only_or_needs_review_rule` | `passive`, `token_maker` |
| `high` | `battle_critical` | 7051 | `Squee, the Immortal` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `recursion` |
| `high` | `battle_critical` | 7051 | `Summoner's Pact` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Sylvan Library` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_engine`, `passive` |
| `high` | `battle_critical` | 7051 | `Transmute Artifact` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Volatile Stormdrake` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `indestructible` |
| `high` | `battle_support` | 7561 | `Chrome Mox` | 11 | 11 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7510 | `Mox Diamond` | 10 | 10 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7408 | `Lion's Eye Diamond` | 8 | 8 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7204 | `Devoted Druid` | 4 | 4 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Faeburrow Elder` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7102 | `Thousand-Year Elixir` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Altar of Dementia` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `ramp_permanent`, `unknown` |
| `high` | `battle_support` | 7051 | `Ashnod's Altar` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Cursed Mirror` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Defense Grid` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Geosurge` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Grinding Station` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Incubation Druid` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Mirage Mirror` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Open the Omenpaths` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `pump_all`, `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Prismatic Lens` | 1 | 1 | `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Treasonous Ogre` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_ritual` |
| `high` | `support_or_passive` | 7306 | `Valley Floodcaller` | 6 | 6 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7255 | `Delighted Halfling` | 5 | 5 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature` |
| `high` | `support_or_passive` | 7204 | `Endurance` | 4 | 4 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Gilded Drake` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Seedborn Muse` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Spellskite` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Tyvar, Jubilant Brawler` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Wandering Archaic` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Archon of Emeria` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Aven Mindcensor` | 2 | 2 | `review_only_or_needs_review_rule` | `creature`, `passive` |
| `high` | `support_or_passive` | 7102 | `Delney, Streetwise Lookout` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Eidolon of Rhetoric` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Ethersworn Canonist` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Marvin, Murderous Mimic` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Moonshadow` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Nyxbloom Ancient` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Opposition Agent` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Patrolling Peacemaker` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Tayam, Luminous Enigma` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `White Plume Adventurer` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Young Wolf` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Aminatou's Augury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Autumn's Veil` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blazing Firesinger` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bond of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Clout of the Dominus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Collector Ouphe` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Colonel Autumn` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dauntless Dismantler` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Derevi, Empyrial Tactician` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dimensional Infiltrator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Displacer Kitten` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Disruptor Flute` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Emiel the Blessed` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Epic Experiment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Etali, Primal Conqueror` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Experimental Overload` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Fury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Gandalf's Sanction` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hazel's Brewmaster` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hellkite Courser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hope of Ghirapur` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hunting Velociraptor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hydroelectric Specimen` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mardu Devotee` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Memnite` | 1 | 1 | `missing_oracle_text`, `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Metallurgic Summonings` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mystic Reflection` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Nature's Chosen` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Orcish Lumberjack` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Phyrexian Censor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Protective Bubble` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Pulsemage Advocate` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Reckless Barbarian` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Roaming Throne` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rograkh, Son of Rohgahh` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sacrifice` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Steal Enchantment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Stitcher's Supplier` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Strangleroot Geist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subjugate the Hobbits` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subtlety` | 1 | 1 | `no_active_battle_rule` | - |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
