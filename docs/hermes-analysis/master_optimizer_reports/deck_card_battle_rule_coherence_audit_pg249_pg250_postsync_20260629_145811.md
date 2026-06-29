# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-29T14:58:11+00:00`

Scope: distinct cards referenced by Hermes `deck_cards`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `1034`
- critical: `1`
- high: `359`
- medium: `54`
- low: `0`
- pass: `620`

## Finding Counts

- `review_only_or_needs_review_rule`: `213`
- `no_active_battle_rule`: `170`
- `trusted_rule_without_oracle_hash`: `117`
- `no_trusted_executable_rule`: `91`
- `generic_effect_without_model_scope`: `71`
- `missing_oracle_identity`: `1`
- `missing_oracle_text`: `1`

## Top 414 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `critical` | `support_or_passive` | 10051 | `Lim-Dul's Vault` | 1 | 1 | `missing_oracle_identity`, `no_active_battle_rule` | - |
| `high` | `battle_critical` | 7153 | `Tymna the Weaver` | 3 | 3 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Archfiend of Ifnir` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Aven Interrupter` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent`, `silence_opponents` |
| `high` | `battle_critical` | 7102 | `Beacon of Immortality` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7102 | `Beseech the Mirror` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Bloodchief Ascension` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Carpet of Flowers` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7102 | `Culling Ritual` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_ritual` |
| `high` | `battle_critical` | 7102 | `Deafening Silence` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_engine`, `passive` |
| `high` | `battle_critical` | 7102 | `Dismember` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `remove_creature` |
| `high` | `battle_critical` | 7102 | `Entomb` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7102 | `Exquisite Blood` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Grim Tutor` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Heroes Remembered` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Intuition` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invasion of Ikoria` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invincible Hymn` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7102 | `Malakir Rebirth // Malakir Mire` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Oswald Fiddlebender` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7102 | `Planetarium of Wan Shi Tong` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7102 | `Praetor's Grasp` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7102 | `Razaketh, the Foulblooded` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `tutor` |
| `high` | `battle_critical` | 7102 | `Reckless Handling` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Sylvan Safekeeper` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `high` | `battle_critical` | 7102 | `Taunt from the Rampart` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Tezzeret the Seeker` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Tezzeret, Cruel Captain` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `tutor` |
| `high` | `battle_critical` | 7102 | `The Meathook Massacre` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `The Soul Stone` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent`, `recursion` |
| `high` | `battle_critical` | 7102 | `Toxic Deluge` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Wheel of Fate` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Withering Torment` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Abrade` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_artifact_or_3dmg`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Akroma's Will` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `indestructible`, `pump_all` |
| `high` | `battle_critical` | 7051 | `Alhammarret's Archive` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `All Is Dust` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Amphibian Downpour` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `finisher`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Ancient Gold Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Animate Dead` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Arcane Bombardment` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Arcane Denial` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Archivist of Oghma` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Ashling, Flame Dancer` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `high` | `battle_critical` | 7051 | `Blood Moon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bolas's Citadel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Brainstorm` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Brainsurge` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Breena, the Demagogue` | 1 | 1 | `review_only_or_needs_review_rule` | `creature`, `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bridgeworks Battle` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Call of the Ring` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Chandra's Ignition` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Cloud of Faeries` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Commandeer` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Commander's Sphere` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_permanent` |
| `high` | `battle_critical` | 7051 | `Curiosity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Damnation` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Dark Deal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Decaying Time Loop` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Decree of Pain` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Demonic Counsel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Drown in Dreams` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7051 | `Electro, Assaulting Battery` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Ephemerate` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Exsanguinate` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Feed the Swarm` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_creature`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Flare of Denial` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Flashback` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `recursion` |
| `high` | `battle_critical` | 7051 | `Food Chain` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Forge Anew` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Freed from the Real` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Gifts Ungiven` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Gisela, Blade of Goldnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Growing Rites of Itlimoc` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Infernal Grasp` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Jin-Gitaxias, Progress Tyrant` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Kaya's Ghostform` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Kederekt Parasite` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Lens of Clarity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Light Up the Stage` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Lightning, Army of One` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Likeness Looter` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Living Death` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Maskwood Nexus` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Mayhem Devil` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Misdirection` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `redirect_removal` |
| `high` | `battle_critical` | 7051 | `Morbid Opportunist` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Mystic Forge` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Necromancy` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `recursion` |
| `high` | `battle_critical` | 7051 | `Neoform` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `One with the Multiverse` | 1 | 1 | `review_only_or_needs_review_rule` | `passive`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Ophidian Eye` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Painful Quandary` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Peer into the Abyss` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Phyrexian Arena` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Ponder` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Propaganda // Propaganda` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Psychic Frog` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Psychosis Crawler` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Puresteel Paladin` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Pyrokinesis` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Rakdos Charm` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Reanimate` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `recursion` |
| `high` | `battle_critical` | 7051 | `Relic of Sauron` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_permanent` |
| `high` | `battle_critical` | 7051 | `Rune-Scarred Demon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `tutor` |
| `high` | `battle_critical` | 7051 | `Sanguine Bond` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Scour for Scrap` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Scrawling Crawler` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Selvala, Heart of the Wilds` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Shadowspear` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Shark Typhoon` | 1 | 1 | `review_only_or_needs_review_rule` | `passive`, `token_maker` |
| `high` | `battle_critical` | 7051 | `Sigarda's Aid` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Single Combat` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Solemn Simulacrum` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Solphim, Mayhem Dominus` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Spiked Corridor // Torture Pit` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Spiteful Banditry` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Spiteful Visions` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Squee, the Immortal` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `recursion` |
| `high` | `battle_critical` | 7051 | `Sram, Senior Edificer` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Stoneforge Mystic` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7051 | `Strix Serenade` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `counter` |
| `high` | `battle_critical` | 7051 | `Sudden Spoiling` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `silence_opponents` |
| `high` | `battle_critical` | 7051 | `Summoner's Pact` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Sylvan Library` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_engine`, `passive` |
| `high` | `battle_critical` | 7051 | `Think Twice` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Transmute Artifact` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Valgavoth, Harrower of Souls` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Victimize` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Volatile Stormdrake` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Whip of Erebos` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Whispersilk Cloak` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Windfall` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Worldfire` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe`, `worldfire_reset` |
| `high` | `battle_critical` | 7051 | `Wound Reflection` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_support` | 7663 | `Chrome Mox` | 13 | 13 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7510 | `Mox Diamond` | 10 | 10 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7459 | `Lion's Eye Diamond` | 9 | 9 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7204 | `Devoted Druid` | 4 | 4 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7153 | `Helm of Awakening` | 3 | 3 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Ancient Copper Dragon` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7102 | `Cursed Mirror` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Faeburrow Elder` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7102 | `Grinding Station` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Mana Geyser` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `high` | `battle_support` | 7102 | `Semblance Anvil` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Talisman of Dominance` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Thousand-Year Elixir` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `battle_support` | 7102 | `Treasonous Ogre` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_ritual` |
| `high` | `battle_support` | 7102 | `Unwinding Clock` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Altar of Dementia` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `ramp_permanent`, `unknown` |
| `high` | `battle_support` | 7051 | `Ashnod's Altar` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Basilisk Collar` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Cavern-Hoard Dragon` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_engine` |
| `high` | `battle_support` | 7051 | `Cloud Key` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Currency Converter` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Defense Grid` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Dimir Signet` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Genji Glove` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Geosurge` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Hammer of Nazahn` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Incubation Druid` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Manifold Key` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Mirage Mirror` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_engine`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Neheb, the Eternal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Open the Omenpaths` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `pump_all`, `ramp_ritual` |
| `high` | `battle_support` | 7051 | `Ornithopter of Paradise` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Orzhov Signet` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Perpetual Timepiece` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Prismatic Lens` | 1 | 1 | `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Radiant Scrollwielder` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `overload_recursion` |
| `high` | `battle_support` | 7051 | `Rakdos Signet` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Sculpting Steel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Talisman of Creativity` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Talisman of Hierarchy` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Talisman of Progress` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `The Darkness Crystal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `The Ozolith` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `The Reaver Cleaver` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `The Wind Crystal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Vedalken Orrery` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Voltaic Key` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `ramp_permanent` |
| `high` | `battle_support` | 7051 | `Warren Soultrader` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `support_or_passive` | 7306 | `Valley Floodcaller` | 6 | 6 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7255 | `Delighted Halfling` | 5 | 5 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature` |
| `high` | `support_or_passive` | 7204 | `Delney, Streetwise Lookout` | 4 | 4 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7204 | `Endurance` | 4 | 4 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Gilded Drake` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Seedborn Muse` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Spellskite` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Tyvar, Jubilant Brawler` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7153 | `Wandering Archaic` | 3 | 3 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Archon of Emeria` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Aven Mindcensor` | 2 | 2 | `review_only_or_needs_review_rule` | `creature`, `passive` |
| `high` | `support_or_passive` | 7102 | `Bloodthirsty Conqueror` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Displacer Kitten` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Eidolon of Rhetoric` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Ethersworn Canonist` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Marvin, Murderous Mimic` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Moonshadow` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Nyxbloom Ancient` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Opposition Agent` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Patrolling Peacemaker` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Syr Konrad, the Grim` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Tayam, Luminous Enigma` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Vial Smasher the Fierce` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `White Plume Adventurer` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7102 | `Young Wolf` | 2 | 2 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7059 | `Nazgûl` | 1 | 9 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Afterlife from the Loam` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Alicia Masters, Skilled Sculptor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Aminatou's Augury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Anger` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Ardenn, Intrepid Archaeologist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Assemble the Players` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Autumn's Veil` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bilbo, Retired Burglar` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blazing Firesinger` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blightsteel Colossus // Blightsteel Colossus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blood Artist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blood for the Blood God!` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blood Pact` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Blood Seeker` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bloodletter of Aclazotz` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bloodthirster` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bond of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Brallin, Skyshark Rider` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Brash Taunter` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Cemetery Gatekeeper` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Chaos Wand` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Charmbreaker Devils` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Clout of the Dominus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Codex Shredder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Collector Ouphe` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Colonel Autumn` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Containment Construct` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Court of Ambition` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dauntless Dismantler` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Deathbellow War Cry` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Derevi, Empyrial Tactician` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Devastating Onslaught` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Dimensional Infiltrator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Disruptor Flute` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Eight-and-a-Half-Tails` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Emiel the Blessed` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Enduring Tenacity` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Entropic Battlecruiser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Epic Experiment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Etali, Primal Conqueror` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Experimental Overload` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Falkenrath Noble` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Fell Specter` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Fury` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Gandalf's Sanction` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Ghoulcaller's Bell` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Gleeful Arsonist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Gray Merchant of Asphodel` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Harmonic Prodigy` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Harsh Mentor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hazel's Brewmaster` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hellkite Courser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `High Fae Trickster` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hope of Ghirapur` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hunting Velociraptor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Hydroelectric Specimen` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kaalia of the Vast` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kaervek the Merciless` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kambal, Consul of Allocation` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kardur, Doomscourge // Kardur, Doomscourge` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karlach, Fury of Avernus` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn's Sylex` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Karn, the Great Creator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kayla's Music Box` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kefka, Court Mage // Kefka, Ruler of Ruin` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kira, Great Glass-Spinner` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Lantern of Insight` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Leyline Dowser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Liliana's Caress` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mai, Scornful Striker` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Marauding Blight-Priest` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mardu Devotee` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Massacre Girl` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Massacre Wurm` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Master of Cruelties` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Memnite` | 1 | 1 | `missing_oracle_text`, `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Metallurgic Summonings` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Misleading Signpost` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mjölnir, Hammer of Thor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mogis, God of Slaughter` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Mystic Reflection` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Naktamun Lorespinner // Wheel of Fortune` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Nature's Chosen` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Necrogoyf` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Nightshade Harvester` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Niv-Mizzet, Parun` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Oppression` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Orcish Lumberjack` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Orcish Spy` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Persistent Constrictor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Phyrexian Censor` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Possibility Storm` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Protective Bubble` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Prototype Portal` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Pulsemage Advocate` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Purphoros, God of the Forge` | 1 | 1 | `review_only_or_needs_review_rule` | `passive`, `pump_all` |
| `high` | `support_or_passive` | 7051 | `Pyxis of Pandemonium` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Radiant Performer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Raiders' Wake` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rampaging Ferocidon` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Reckless Barbarian` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rem Karolus, Stalwart Slayer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rise of the Dark Realms` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Roaming Throne` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rograkh, Son of Rohgahh` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sacrifice` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sadistic Shell Game` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sangromancer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sauron, the Dark Lord` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sawhorn Nemesis` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Screaming Nemesis` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Serra Ascendant` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Sheoldred // The True Scriptures` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sigil of Sleep` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Slickshot Show-Off` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Soothing of Sméagol` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Spirit Link` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Star Athlete` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Starwinder` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Steal Enchantment` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Stitcher's Supplier` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Strangleroot Geist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Stuffy Doll` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subjugate the Hobbits` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Subtlety` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Summons of Saruman` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Suspended Sentence` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Swift Reconfiguration` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Séance Board` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Teferi's Time Twist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Haunt of Hightower` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Lord of Pain` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Seriema` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Walls of Ba Sing Se` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `The Warring Triad` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tidal Barracuda` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tinybones, Bauble Burglar` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tinybones, Trinket Thief` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Toralf, God of Fury // Toralf's Hammer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Uncivil Unrest` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Unstable Glyphbridge // Sandswirl Wanderglyph` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Vito, Thorn of the Dusk Rose` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Void Winnower` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Vorpal Sword` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Wand of Vertebrae` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Wild Ricochet` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Words of Waste` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Y'shtola, Night's Blessed` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Zephid's Embrace` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Zirda, the Dawnwaker` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `battle_critical` | 4204 | `Mystical Tutor` | 4 | 4 | `trusted_rule_without_oracle_hash` | `tutor` |
| `medium` | `battle_support` | 4408 | `Crop Rotation` | 8 | 8 | `trusted_rule_without_oracle_hash` | `land_ramp` |
| `medium` | `battle_support` | 4102 | `Birgi, God of Storytelling` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `creature`, `ramp_engine` |
| `medium` | `battle_support` | 4102 | `Burnt Offering` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `"Name Sticker" Goblin` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Everflowing Chalice` | 1 | 1 | `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Fractured Powerstone` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_permanent` |
| `medium` | `battle_support` | 4051 | `Metamorphosis` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `battle_support` | 4051 | `Rain of Filth` | 1 | 1 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `ramp_ritual` |
| `medium` | `support_or_passive` | 4255 | `Thrasios, Triton Hero` | 5 | 5 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4204 | `Badgermole Cub` | 4 | 4 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4204 | `The Cabbage Merchant` | 4 | 4 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4153 | `Vexing Bauble` | 3 | 3 | `trusted_rule_without_oracle_hash` | `hate_artifact` |
| `medium` | `support_or_passive` | 4102 | `Deadpool, Trading Card` | 2 | 2 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4102 | `Soul-Guide Lantern` | 2 | 2 | `trusted_rule_without_oracle_hash` | `hate_artifact` |
| `medium` | `support_or_passive` | 4102 | `Survival of the Fittest` | 2 | 2 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4102 | `Wall of Roots` | 2 | 2 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Altar of the Wretched` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Electroduplicate` | 1 | 1 | `trusted_rule_without_oracle_hash` | `copy_creature_token` |
| `medium` | `support_or_passive` | 4051 | `Fiend Artisan` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Goblin Welder` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Greedy Freebooter` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Knight of the Reliquary` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `Necrodominance` | 1 | 1 | `trusted_rule_without_oracle_hash` | `passive` |
| `medium` | `support_or_passive` | 4051 | `Shambling Ghast` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `support_or_passive` | 4051 | `The Balrog of Moria` | 1 | 1 | `trusted_rule_without_oracle_hash` | `creature` |
| `medium` | `land_or_mana_base` | 4459 | `Cavern of Souls` | 9 | 9 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4408 | `Starting Town` | 8 | 8 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4306 | `City of Traitors` | 6 | 6 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4255 | `Emergence Zone` | 5 | 5 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4153 | `Scavenger Grounds` | 3 | 3 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Ash Barrens` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Crystal Vein` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Fabled Passage` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Forbidden Orchard` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Myriad Landscape` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Reflecting Pool` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Sokenzan, Crucible of Defiance` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Temple of Triumph` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4102 | `Urborg, Tomb of Yawgmoth` | 2 | 2 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Adagia, Windswept Bastion` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Buried Ruin` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Conduit Pylons` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Cori Mountain Monastery` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Darksteel Citadel` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Fire Nation Palace` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Fomori Vault` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Guildless Commons` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Lotus Vale` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Rustvale Bridge` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Shinka, the Bloodsoaked Keep` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Spinerock Knoll` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Spire of Industry` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Zhalfirin Void` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
