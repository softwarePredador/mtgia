# XMage Authoritative Exact Scope Split

- Generated at: `2026-07-01T08:12:57+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Summary

`{"adapter_work_unit_counts": {"counter_spell::counter_target_stack_object_variant_v1": 12}, "blocked_reason_counts": {"additional_cost_detected": 106, "counter_ability_class_not_simple": 19, "counter_effect_class_not_pure": 35, "counter_oracle_not_simple": 2, "counter_target_not_supported": 23, "damage_amount_not_fixed": 45, "damage_effect_class_not_pure": 123, "damage_target_not_supported": 24, "destroy_effect_class_not_pure": 138, "destroy_target_not_supported": 74, "draw_effect_class_not_pure": 562, "exile_effect_class_not_pure": 42, "exile_oracle_not_simple": 9, "exile_target_not_supported": 29, "life_gain_amount_not_fixed": 19, "life_gain_effect_class_not_pure": 166, "life_gain_oracle_not_simple": 11, "mana_source_effect_class_not_simple": 307, "mana_source_oracle_not_simple": 121, "mana_source_safe_ability_missing": 133, "mana_source_spell_not_supported": 1, "mana_source_unsafe_ability_class": 135, "not_instant_or_sorcery_spell": 1891, "not_one_shot_spell_ability": 176}, "considered_supported_work_unit_rows": 4203, "family_counts": {"xmage_counter_target_spell": 12}, "proposal_count": 12, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 12}, "safe_for_batch_pg_package_count": 12, "scope_counts": {"xmage_counter_target_spell_v1": 12}}`

## Selected Proposals

| Card | Family | Scope | Effect | Logical rule key |
| --- | --- | --- | --- | --- |
| `Annul` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:b802630c68c32a86a5ac07d841e984ef` |
| `Artifact Blast` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:5a1d2fb58efab0d5edcd6a1e06a3c66e` |
| `Cancel` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:7e29c853e44945f99da7e36251341d47` |
| `Dispel` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:da19782039253e55b3e3029cb5d2012a` |
| `Envelop` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:4d75d79719bc4abcc79832e5129f5ff2` |
| `Essence Scatter` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:d9e200666f7e3bc7a26190104109b887` |
| `Extinguish` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:4d75d79719bc4abcc79832e5129f5ff2` |
| `False Summoning` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:d9e200666f7e3bc7a26190104109b887` |
| `Flash Counter` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:da19782039253e55b3e3029cb5d2012a` |
| `Gainsay` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:8d03d84edda7e25cde871fb06d09359b` |
| `Preemptive Strike` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:d9e200666f7e3bc7a26190104109b887` |
| `Remove Soul` | `xmage_counter_target_spell` | `xmage_counter_target_spell_v1` | `counter` | `battle_rule_v1:d9e200666f7e3bc7a26190104109b887` |

## Blocked Samples

- `additional_cost_detected`: `["Abjure", "Acceptable Losses", "Altar's Reap", "Angelic Purge", "Annihilating Glare", "Artillerize", "Bankrupt in Blood", "Betrayer's Bargain", "Bitter Triumph", "Blood Divination", "Bogslither's Embrace", "Bone Shards"]`
- `counter_ability_class_not_simple`: `["Admiral's Order", "Broken Concentration", "Consign to Memory", "Controvert", "Fervent Denial", "Forbid", "Forceful Denial", "Last Word", "Long River's Pull", "Muddle the Mixture", "Neutralize", "Out of Bounds"]`
- `counter_effect_class_not_pure`: `["Amazing Acrobatics", "Bar the Gate", "Bring the Ending", "Confirm Suspicions", "Countersquall", "Dawn Charm", "Deny the Witch", "Didn't Say Please", "Discombobulate", "Dissolve", "Ertai's Trickery", "Essence Capture"]`
- `counter_oracle_not_simple`: `["Change the Equation", "Spell Blast"]`
- `counter_target_not_supported`: `["Avoid Fate", "Ceremonious Rejection", "Disallow", "Disdainful Stroke", "Double Negative", "Flashfreeze", "Frazzle", "Guttural Response", "Hisoka's Defiance", "Intervene", "Minor Misstep", "Mystic Denial"]`
- `damage_amount_not_fixed`: `["Armed Response", "Artillery Blast", "Blaze", "Clan Defiance", "Devil's Play", "Divine Retribution", "Dogpile", "Earth Tremor", "Electrostatic Bolt", "Fall of the Titans", "Fanning the Flames", "Feedback Bolt"]`
- `damage_effect_class_not_pure`: `["Aggressive Sabotage", "Arc Blade", "Arrow Storm", "Barrel Down Sokenzan", "Beacon of Destruction", "Bedeck // Bedazzle", "Blastfire Bolt", "Blightning", "Blooming Blast", "Bolt of Keranos", "Bot Bashing Time", "Brimstone Volley"]`
- `damage_target_not_supported`: `["Arrows of Justice", "Burning Oil", "Consuming Bonfire", "Cosmium Blast", "Divine Arrow", "Dragon's Presence", "Dual Shot", "Furious Reprisal", "Gideon's Reproach", "Hamato Ninp\u014d", "Impeccable Timing", "Iron Verdict"]`
- `destroy_effect_class_not_pure`: `["Active Volcano", "Afterlife", "Aftershock", "Agonizing Demise", "Airbender's Reversal", "Artisan's Sorrow", "Assassin's Strike", "Atomize", "Bant Charm", "Beast Within", "Blight Grenade", "Blood Curdle"]`
- `destroy_target_not_supported`: `["Asphyxiate", "Assassin's Blade", "Assassinate", "Avalanche", "Bramblecrush", "By Force", "Cast Down", "Chill to the Bone", "Consign to Dust", "Cradle to Grave", "Crush", "Curtains' Call"]`
- `draw_effect_class_not_pure`: `["Aang's Defense", "Abeyance", "Abzan Charm", "Accelerate", "Adventure Awaits", "Afflict", "Afterlife Insurance", "Aggressive Urge", "Airbending Lesson", "Allied Strategies", "Amass the Components", "Ambition's Cost"]`
- `exile_effect_class_not_pure`: `["Agate Assault", "Aim for the Head", "Angelic Ascension", "Anguished Unmaking", "Ashes to Ashes", "Break Down the Door", "Buy Your Silence", "Cast into the Fire", "Consuming Sinkhole", "Crib Swap", "Devout Decree", "Dispatch"]`
- `exile_oracle_not_simple`: `["Barrier Breach", "Crush Contraband", "Devouring Light", "Forsake the Worldly", "Repel the Vile", "Sylvan Reclamation", "Tear Asunder", "Topple", "Wipe Clean"]`
- `exile_target_not_supported`: `["Blade Banish", "Blazing Hope", "Bring to Trial", "Celestial Purge", "Complete Disregard", "Death in the Family", "Despark", "Dust to Dust", "Epic Downfall", "Excoriate", "Exorcise", "Expel"]`
- `life_gain_amount_not_fixed`: `["Blessed Reversal", "Bountiful Harvest", "Festival of Trokin", "Fruition", "Gerrard's Wisdom", "Invigorating Falls", "Joyous Respite", "Landbind Ritual", "Nourishing Shoal", "Peach Garden Oath", "Predator's Rapport", "Presence of the Wise"]`
- `life_gain_effect_class_not_pure`: `["Aang's Journey", "Absorb", "Abuna's Chant", "Aerial Assault", "Aerial Predation", "Agonizing Syphon", "Appetite for the Unnatural", "Archangel's Light", "Bargain", "Basic Conjuration", "Battle at the Bridge", "Battlefield Promotion"]`
- `life_gain_oracle_not_simple`: `["Ancestral Tribute", "Benediction of Moons", "Captured Sunlight", "Folk Medicine", "Gnaw to the Bone", "Meditation Puzzle", "Reaping the Rewards", "Rejuvenate", "Sun's Bounty", "Vital Surge", "Weather the Storm"]`
- `mana_source_effect_class_not_simple`: `["Abzan Banner", "Aetheric Amplifier", "Agility Bobblehead", "All-Fates Scroll", "Altar of the Pantheon", "Ancient Cornucopia", "Animal Attendant", "Arcum's Astrolabe", "Arixmethes, Slumbering Isle", "Armored Scrapgorger", "Ashaya, Soul of the Wild", "Astral Cornucopia"]`
- `mana_source_oracle_not_simple`: `["Agent of Stromgald", "Apprentice Wizard", "Arc Reactor", "Basal Thrull", "Black Lotus", "Blightsoil Druid", "Blood Celebrant", "Blood Pet", "Blood Vassal", "Bog Initiate", "Bog Witch", "Catalyst Elemental"]`
- `mana_source_safe_ability_missing`: `["Abstract Paintmage", "Aetherflux Conduit", "Akki Rockspeaker", "Alluring Suitor // Deadly Dancer", "Ardent Electromancer", "Arvinox, the Mind Flail", "Azula, Cunning Usurper", "Barbflare Gremlin", "Benthic Explorers", "Berta, Wise Extrapolator", "Blazing Firesinger // Seething Song", "Boommobile"]`
- `mana_source_spell_not_supported`: `["Esper Origins // Summon: Esper Maduin"]`
- `mana_source_unsafe_ability_class`: `["Abzan Devotee", "Accomplished Alchemist", "Adarkar Unicorn", "Alena, Kessig Trapper", "Altar of the Lost", "Arbor Adherent", "Automated Artificer", "Axebane Guardian", "Barrels of Blasting Jelly", "Battery Bearer", "Beastcaller Savant", "Bighorner Rancher"]`
- `not_instant_or_sorcery_spell`: `["Aberrant", "Abiding Grace", "Abomination", "Absolver Thrull", "Absolving Lammasu", "Abyssal Hunter", "Acid Web Spider", "Acidic Dagger", "Acidic Slime", "Acidic Sliver", "Acolyte of the Inferno", "Acorn Catapult"]`
- `not_one_shot_spell_ability`: `["Ajani's Response", "Aleatory", "Arwen's Gift", "Astral Confrontation", "Balduvian Rage", "Banish from Edoras", "Benefactor's Draught", "Bind", "Bind // Liberate", "Blessed Wine", "Bone Harvest", "Bouncer's Beatdown"]`
