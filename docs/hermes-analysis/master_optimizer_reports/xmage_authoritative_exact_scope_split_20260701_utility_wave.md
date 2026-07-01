# XMage Authoritative Exact Scope Split

- Generated at: `2026-07-01T07:51:37+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Summary

`{"adapter_work_unit_counts": {"life_gain::xmage_life_gain_variant_review_v1": 6, "ramp_permanent::xmage_artifact_mana_source_variant_review_v1": 12, "ramp_permanent::xmage_creature_mana_source_variant_review_v1": 17, "removal_exile::targeted_exile_variant_v1": 18}, "blocked_reason_counts": {"additional_cost_detected": 97, "damage_amount_not_fixed": 44, "damage_effect_class_not_pure": 123, "damage_target_not_supported": 24, "destroy_effect_class_not_pure": 138, "destroy_target_not_supported": 74, "draw_effect_class_not_pure": 556, "exile_effect_class_not_pure": 42, "exile_oracle_not_simple": 9, "exile_target_not_supported": 29, "life_gain_amount_not_fixed": 19, "life_gain_effect_class_not_pure": 166, "life_gain_oracle_not_simple": 11, "mana_source_effect_class_not_simple": 303, "mana_source_oracle_not_simple": 119, "mana_source_safe_ability_missing": 132, "mana_source_spell_not_supported": 1, "mana_source_unsafe_ability_class": 133, "not_instant_or_sorcery_spell": 1824, "not_one_shot_spell_ability": 163}, "considered_supported_work_unit_rows": 4060, "family_counts": {"xmage_exile_target_spell": 18, "xmage_fixed_life_gain_spell": 6, "xmage_simple_mana_source_permanent": 29}, "proposal_count": 53, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 53}, "safe_for_batch_pg_package_count": 53, "scope_counts": {"xmage_exile_target_spell_v1": 18, "xmage_fixed_controller_gain_life_spell_v1": 6, "xmage_simple_tap_mana_source_permanent_v1": 29}}`

## Selected Proposals

| Card | Family | Scope | Effect | Logical rule key |
| --- | --- | --- | --- | --- |
| `Alloy Myr` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Altar's Light` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:344ee4ceca0b5f8f7d5fdabb88b47884` |
| `Angel's Mercy` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:0f25d24d3c5a3407ed57856db5992117` |
| `Angelic Edict` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:be537a381b606ab55acffdaf22bdddef` |
| `Blessed Light` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:e35e9434e3ba0e376ce4d59aeeca7c53` |
| `Bloodstone Cameo` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:157975c852f269cdf3bc89dcae7dd03f` |
| `Boreal Druid` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ae4457bc12786f7e5b4488c282f7004e` |
| `Caustic Rain` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:42742846342dec802c47c11ade2516ad` |
| `Chaplain's Blessing` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:0efac9a4b073d02f8b4dccce6d09d0f4` |
| `Copper Myr` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Drake-Skull Cameo` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d0e08457f1641a563199afe86ac7e0a4` |
| `Druid of the Cowl` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Erase` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ea17b91f68e124b22b0af2770e713b60` |
| `Fade into Antiquity` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:1fd9f658e128ca955f7acc4e117b9132` |
| `Fate Forgotten` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:344ee4ceca0b5f8f7d5fdabb88b47884` |
| `Feed the Serpent` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:a320309e986688f78d171c92e09fdf3d` |
| `Final Death` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_creature` | `battle_rule_v1:cb6917973f2f9a0cd7955b9a6682866c` |
| `Final Reward` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_creature` | `battle_rule_v1:cb6917973f2f9a0cd7955b9a6682866c` |
| `Gold Myr` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:1f43cb19e0418cc56efdb5595373b2e5` |
| `Golden Hind` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Goobbue Gardener` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Great Forest Druid` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Iona's Judgment` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:be537a381b606ab55acffdaf22bdddef` |
| `Iron Myr` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:be0fafded425748b1945af1f8374ab11` |
| `Ironwright's Cleansing` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:1fd9f658e128ca955f7acc4e117b9132` |
| `Leaden Myr` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ada92998d97db6cefbc450fbf01d646e` |
| `Leaf Gilder` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Lifespring Druid` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Llanowar Dead` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ada92998d97db6cefbc450fbf01d646e` |
| `Manakin` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ae4457bc12786f7e5b4488c282f7004e` |
| `Nourish` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:a13cb6d631fa4df94fefbee9c04b6dea` |
| `Opaline Unicorn` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Orochi Sustainer` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Princess Lucrezia` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:fc5d21fc34fa1e198cf8938b934a9b38` |
| `Revoke Existence` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:1fd9f658e128ca955f7acc4e117b9132` |
| `Riven Turnbull` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ada92998d97db6cefbc450fbf01d646e` |
| `Rosethorn Acolyte // Seasonal Ritual` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:27b46ea42ba71c2416b979903bdf5a0b` |
| `Sacred Nectar` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:89294a30a7c038f531fd4a66bc98ef68` |
| `Scour from Existence` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:65a0a297fa7e8450d12dfb9250ad210f` |
| `Seashell Cameo` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:56fde69c1feefbe667383740024fb9a7` |
| `Shattering Blow` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:518eccc35731deb7d285e0864f258fed` |
| `Sisters of the Flame` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:be0fafded425748b1945af1f8374ab11` |
| `Skyshroud Troopers` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |
| `Spring of Eternal Peace` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:127239c6cb437de88829822693da2244` |
| `Three Tree Rootweaver` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Tigereye Cameo` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9bf13b73a48fa06ad07dcca49c12df44` |
| `Troll-Horn Cameo` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:fdc6bc7ee5024eaa2431d23343c8b97d` |
| `Unmake` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_creature` | `battle_rule_v1:cb6917973f2f9a0cd7955b9a6682866c` |
| `Utopia Tree` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7082e6e49591d7b9efe2cc3aea718c08` |
| `Utter End` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_permanent` | `battle_rule_v1:138f212350697c8175f0f4f93e54bb6d` |
| `Wander Off` | `xmage_exile_target_spell` | `xmage_exile_target_spell_v1` | `remove_creature` | `battle_rule_v1:cb6917973f2f9a0cd7955b9a6682866c` |
| `Whitesun's Passage` | `xmage_fixed_life_gain_spell` | `xmage_fixed_controller_gain_life_spell_v1` | `life_total_change` | `battle_rule_v1:3deac22371fed5334c1541219c6c639d` |
| `Wirewood Elf` | `xmage_simple_mana_source_permanent` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e93a9c512a324d005ef1abc0b5da6934` |

## Blocked Samples

- `additional_cost_detected`: `["Acceptable Losses", "Altar's Reap", "Angelic Purge", "Annihilating Glare", "Artillerize", "Bankrupt in Blood", "Betrayer's Bargain", "Bitter Triumph", "Blood Divination", "Bogslither's Embrace", "Bone Shards", "Bone Splinters"]`
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
- `mana_source_oracle_not_simple`: `["Agent of Stromgald", "Apprentice Wizard", "Arc Reactor", "Basal Thrull", "Blightsoil Druid", "Blood Celebrant", "Blood Pet", "Blood Vassal", "Bog Initiate", "Bog Witch", "Catalyst Elemental", "Charcoal Diamond"]`
- `mana_source_safe_ability_missing`: `["Abstract Paintmage", "Aetherflux Conduit", "Akki Rockspeaker", "Alluring Suitor // Deadly Dancer", "Ardent Electromancer", "Arvinox, the Mind Flail", "Azula, Cunning Usurper", "Barbflare Gremlin", "Benthic Explorers", "Berta, Wise Extrapolator", "Blazing Firesinger // Seething Song", "Boommobile"]`
- `mana_source_spell_not_supported`: `["Esper Origins // Summon: Esper Maduin"]`
- `mana_source_unsafe_ability_class`: `["Abzan Devotee", "Accomplished Alchemist", "Adarkar Unicorn", "Alena, Kessig Trapper", "Altar of the Lost", "Arbor Adherent", "Automated Artificer", "Axebane Guardian", "Barrels of Blasting Jelly", "Battery Bearer", "Beastcaller Savant", "Bighorner Rancher"]`
- `not_instant_or_sorcery_spell`: `["Aberrant", "Abiding Grace", "Abomination", "Absolver Thrull", "Absolving Lammasu", "Abyssal Hunter", "Acid Web Spider", "Acidic Dagger", "Acidic Slime", "Acidic Sliver", "Acolyte of the Inferno", "Acorn Catapult"]`
- `not_one_shot_spell_ability`: `["Ajani's Response", "Aleatory", "Arwen's Gift", "Astral Confrontation", "Balduvian Rage", "Banish from Edoras", "Benefactor's Draught", "Bind", "Bind // Liberate", "Blessed Wine", "Bone Harvest", "Bouncer's Beatdown"]`
