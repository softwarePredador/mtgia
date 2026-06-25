# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T01:56:46+00:00`

Scope: distinct cards referenced by Hermes `deck_cards`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `963`
- critical: `1`
- high: `400`
- medium: `63`
- low: `0`
- pass: `499`

## Finding Counts

- `review_only_or_needs_review_rule`: `263`
- `no_active_battle_rule`: `170`
- `trusted_rule_without_oracle_hash`: `128`
- `no_trusted_executable_rule`: `118`
- `generic_effect_without_model_scope`: `77`
- `missing_oracle_identity`: `1`
- `missing_oracle_text`: `1`

## Top 120 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `critical` | `support_or_passive` | 10051 | `Lim-Dul's Vault` | 1 | 1 | `missing_oracle_identity`, `no_active_battle_rule` | - |
| `high` | `battle_critical` | 7357 | `Apex of Power` | 7 | 7 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7357 | `Flusterstorm` | 7 | 7 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7306 | `Formidable Speaker` | 6 | 6 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7255 | `Force of Negation` | 5 | 5 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7255 | `Kinnan, Bonder Prodigy` | 5 | 5 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7255 | `Tainted Pact` | 5 | 5 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7255 | `Voice of Victory` | 5 | 5 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `silence_opponents` |
| `high` | `battle_critical` | 7255 | `Volcanic Vision` | 5 | 5 | `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7255 | `Wishclaw Talisman` | 5 | 5 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7204 | `Chain of Vapor` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7204 | `Dance with Calamity` | 4 | 4 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `exile_value` |
| `high` | `battle_critical` | 7204 | `Demonic Consultation` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7204 | `Eternal Witness` | 4 | 4 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `recursion` |
| `high` | `battle_critical` | 7204 | `Finale of Devastation` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `pump_all`, `tutor` |
| `high` | `battle_critical` | 7204 | `Galvanoth` | 4 | 4 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7204 | `Longshot, Rebel Bowman` | 4 | 4 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `high` | `battle_critical` | 7204 | `Noxious Revival` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `recursion` |
| `high` | `battle_critical` | 7204 | `Penance` | 4 | 4 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7204 | `Thassa's Oracle` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `finisher` |
| `high` | `battle_critical` | 7204 | `Vandalblast` | 4 | 4 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7153 | `Ad Nauseam` | 3 | 3 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7153 | `Deflecting Palm` | 3 | 3 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7153 | `Dragon's Rage Channeler` | 3 | 3 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `topdeck_manipulation` |
| `high` | `battle_critical` | 7153 | `Eldritch Evolution` | 3 | 3 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7153 | `Mnemonic Betrayal` | 3 | 3 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7153 | `Reprieve` | 3 | 3 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7153 | `Touch the Spirit Realm` | 3 | 3 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7153 | `Twinflame Tyrant` | 3 | 3 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7153 | `Tymna the Weaver` | 3 | 3 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7153 | `Velomachus Lorehold` | 3 | 3 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7153 | `Verge Rangers` | 3 | 3 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7102 | `Authority of the Consuls` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Aven Interrupter` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent`, `silence_opponents` |
| `high` | `battle_critical` | 7102 | `Beacon of Immortality` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7102 | `Beseech the Mirror` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Bloodchief Ascension` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Bolt Bend` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Carpet of Flowers` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7102 | `Culling Ritual` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `ramp_ritual` |
| `high` | `battle_critical` | 7102 | `Deafening Silence` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_engine`, `passive` |
| `high` | `battle_critical` | 7102 | `Guttersnipe` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `high` | `battle_critical` | 7102 | `Heroes Remembered` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Intuition` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invasion of Ikoria` | 2 | 2 | `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Invincible Hymn` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7102 | `Magmakin Artillerist` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Mana Drain` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7102 | `Oswald Fiddlebender` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `tutor` |
| `high` | `battle_critical` | 7102 | `Planetarium of Wan Shi Tong` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7102 | `Praetor's Grasp` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7102 | `Reckless Handling` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Sheoldred, the Apocalypse` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Sylvan Safekeeper` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `indestructible` |
| `high` | `battle_critical` | 7102 | `Taunt from the Rampart` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7102 | `Tezzeret the Seeker` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7102 | `Tezzeret, Cruel Captain` | 2 | 2 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `passive`, `tutor` |
| `high` | `battle_critical` | 7102 | `Trouble in Pairs` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7102 | `Ultima` | 2 | 2 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7102 | `Wheel of Fate` | 2 | 2 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Abrade` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_artifact_or_3dmg`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Agate Instigator` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Akroma's Will` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `indestructible`, `pump_all` |
| `high` | `battle_critical` | 7051 | `Alhammarret's Archive` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `All Is Dust` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Amphibian Downpour` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `finisher`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Ancient Gold Dragon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Angel's Grace` | 1 | 1 | `generic_effect_without_model_scope` | `cannot_lose_turn` |
| `high` | `battle_critical` | 7051 | `Arcane Bombardment` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Arcane Denial` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Archfiend of Ifnir` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Archivist of Oghma` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Armageddon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Ashling, Flame Dancer` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `finisher` |
| `high` | `battle_critical` | 7051 | `Blood Moon` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bolas's Citadel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Boltwave` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Bone Miser` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Breena, the Demagogue` | 1 | 1 | `review_only_or_needs_review_rule` | `creature`, `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bridgeworks Battle` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Brilliant Restoration` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Chandra's Ignition` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Clever Concealment` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `phase_out` |
| `high` | `battle_critical` | 7051 | `Cloud of Faeries` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Commandeer` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter`, `draw_cards` |
| `high` | `battle_critical` | 7051 | `Coruscation Mage` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Dark Deal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Decaying Time Loop` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Decree of Pain` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `board_wipe` |
| `high` | `battle_critical` | 7051 | `Demonic Counsel` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Dismember` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `draw_cards`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Drown in Dreams` | 1 | 1 | `review_only_or_needs_review_rule` | `draw_cards`, `passive` |
| `high` | `battle_critical` | 7051 | `Electro, Assaulting Battery` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `creature`, `remove_creature` |
| `high` | `battle_critical` | 7051 | `Entomb` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_cards`, `tutor` |
| `high` | `battle_critical` | 7051 | `Ephemerate` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Erode` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Explosive Singularity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Exquisite Blood` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Feed the Swarm` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_creature`, `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Fiery Inscription` | 1 | 1 | `review_only_or_needs_review_rule`, `trusted_rule_without_oracle_hash` | `finisher`, `passive` |
| `high` | `battle_critical` | 7051 | `Firesong and Sunspeaker` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Flashback` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `recursion` |
| `high` | `battle_critical` | 7051 | `Food Chain` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Forge Anew` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Freed from the Real` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `draw_engine`, `ramp_engine` |
| `high` | `battle_critical` | 7051 | `Gifts Ungiven` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Gisela, Blade of Goldnight` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Gods Willing` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `indestructible` |
| `high` | `battle_critical` | 7051 | `Grim Tutor` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `tutor` |
| `high` | `battle_critical` | 7051 | `Growing Rites of Itlimoc` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Impact Tremors` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Infernal Grasp` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Jin-Gitaxias, Progress Tyrant` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `copy_spell` |
| `high` | `battle_critical` | 7051 | `Kaya's Ghostform` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Kederekt Parasite` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Lens of Clarity` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `topdeck_manipulation` |
| `high` | `battle_critical` | 7051 | `Light Up the Stage` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Lightning, Army of One` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `Magus of the Wheel` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Malakir Rebirth // Malakir Mire` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
