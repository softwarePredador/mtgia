# PG486 next subpattern mining - 2026-07-05

- Source queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg485_activated_damage_discard_cost_new_server_commander_legal.json`
- Adapter-required rows scanned: `25941`
- Existing exact splitter proposals: `0`
- Distinct blocked reasons: `188`

## Top blocked reasons

- `unsupported_adapter_work_unit`: `18469`
- `not_instant_or_sorcery_spell`: `3834`
- `draw_effect_class_not_pure`: `445`
- `recursion_effect_class_not_pure`: `374`
- `mana_source_auxiliary_ability_not_supported`: `271`
- `not_one_shot_spell_ability`: `249`
- `tutor_effect_class_not_supported`: `145`
- `mana_source_unsafe_ability_class`: `133`
- `mana_source_safe_ability_missing`: `132`
- `destroy_effect_class_not_pure`: `129`
- `damage_effect_class_not_pure`: `103`
- `additional_cost_detected`: `96`
- `life_gain_effect_class_not_pure`: `87`
- `board_wipe_effect_class_not_supported`: `81`
- `board_wipe_ability_class_not_simple`: `67`
- `add_counters_effect_class_not_pure`: `63`
- `destroy_target_not_supported`: `47`
- `tutor_ability_class_not_simple`: `45`
- `activated_damage_oracle_not_simple`: `42`
- `bounce_effect_class_not_pure`: `41`
- `exile_effect_class_not_pure`: `40`
- `board_wipe_oracle_not_simple`: `37`
- `static_graveyard_count_pt_oracle_not_exact`: `35`
- `counter_effect_class_not_pure`: `35`
- `token_source_create_token_not_fixed`: `29`
- `token_literal_description_missing`: `29`
- `bounce_ability_class_not_simple`: `28`
- `activated_destroy_oracle_not_simple`: `25`
- `mana_source_effect_class_not_simple`: `24`
- `counter_target_not_supported`: `23`

## Top signatures by blocked reason

### unsupported_adapter_work_unit (18469)
- Work unit `draw_engine::xmage_draw_card_variant_review_v1`: `1567`
- Work unit `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`: `1064`
- Work unit `add_counters::source_add_counters_variant_v1`: `764`
- Work unit `untap_target::xmage_targeted_untap_variant_review_v1`: `260`
- Work unit `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1`: `247`
- Signature count `35`; effects `['AttachEffect', 'BoostEnchantedEffect']`; abilities `['EnchantAbility', 'SimpleStaticAbility']`; targets `[]`; signals `['targeting', 'static_ability']`; samples `['Alpha Status', 'Ancestral Mask', 'Aspect of Wolf', 'Blanchwood Armor', 'Blessing of the Nephilim', 'Boon of Emrakul', 'Chant of the Skifsang', 'Clinging Darkness']`
- Signature count `34`; effects `['CreateTokenEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['token', 'activated_ability']`; samples `['Ant Queen', 'Birthing Boughs', 'Boris Devilboon', 'Centaur Glade', "Centaur's Herald", 'Dragon Roost', 'Envoy of Okinec Ahau', 'Eternal Student']`
- Signature count `33`; effects `['BoostSourceEffect']`; abilities `['FlyingAbility', 'SimpleActivatedAbility']`; targets `[]`; signals `['activated_ability']`; samples `['Aven Flock', 'Aven Trooper', 'Balshan Collaborator', 'Blistering Dieflyn', 'Canyon Drake', 'Chilling Shade', 'Darklit Gargoyle', 'Dragon Hatchling']`
- Signature count `31`; effects `['BoostAllEffect']`; abilities `[]`; targets `[]`; signals `[]`; samples `['Army of Allah', 'Cloudkill', 'Cower in Fear', 'Dead of Winter', 'Drag to the Bottom', 'Eyeblight Massacre', 'Festergloom', 'Final Revels']`
- Signature count `29`; effects `['RegenerateSourceEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['activated_ability']`; samples `['Ancient Silverback', 'Asphodel Wanderer', 'Clay Statue', 'Cudgel Troll', 'Deepwood Ghoul', 'Diabolic Machine', 'Drowned', 'Drudge Skeletons']`

### not_instant_or_sorcery_spell (3834)
- Work unit `recursion::xmage_graveyard_return_variant_review_v1`: `1292`
- Work unit `direct_damage::targeted_damage_variant_v1`: `564`
- Work unit `life_gain::xmage_life_gain_variant_review_v1`: `499`
- Work unit `tutor::xmage_library_search_variant_review_v1`: `359`
- Work unit `add_counters::targeted_add_counters_variant_v1`: `350`
- Signature count `16`; effects `['ReturnToHandTargetEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['targeting', 'activated_ability']`; samples `['Aegis Automaton', 'Alexi, Zephyr Mage', 'Barrin, Master Wizard', 'Dispersing Orb', 'Escape Routes', 'Flooded Shoreline', 'Galecaster Colossus', 'Hallowed Ground']`
- Signature count `16`; effects `['ReturnToHandTargetEffect']`; abilities `['EntersBattlefieldTriggeredAbility']`; targets `[]`; signals `['targeting', 'triggered_ability']`; samples `['Aether Adept', 'Bigfin Bouncer', 'Dispersal Technician', 'Exclusion Mage', 'Glowing Anemone', 'Guardians of Koilos', 'Iceridge Serpent', "Man-o'-War"]`
- Signature count `15`; effects `['AddCountersTargetEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['targeting', 'counter', 'activated_ability']`; samples `['Amok', 'Armor Thrull', 'Coretapper', 'Daring Mechanic', 'Deranged Outcast', 'Dragon Blood', 'Fevered Convulsions', 'Fume Spitter']`
- Signature count `15`; effects `['SearchLibraryPutInHandEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['targeting', 'activated_ability']`; samples `['Armillary Sphere', "Artificer's Intuition", 'Braidwood Sextant', 'Captain Sisay', 'Corpse Harvester', 'Dragonstorm Forecaster', 'Fauna Shaman', 'Greenseeker']`
- Signature count `14`; effects `['CounterTargetEffect']`; abilities `['SimpleActivatedAbility']`; targets `[]`; signals `['targeting', 'counter', 'activated_ability']`; samples `['Daring Apprentice', 'Deathgrip', 'Diplomatic Escort', 'Douse', 'Ertai, the Corrupted', 'Ertai, Wizard Adept', 'Hydromorph Guardian', 'Lifeforce']`

### draw_effect_class_not_pure (445)
- Work unit `draw_cards::xmage_draw_card_variant_review_v1`: `445`
- Signature count `5`; effects `['BoostAllEffect', 'DrawCardSourceControllerEffect']`; abilities `[]`; targets `[]`; signals `['draw']`; samples `['Bewildering Blizzard', 'Blinding Spray', 'Hydrolash', 'Pack Attack', "Roilmage's Trick"]`
- Signature count `5`; effects `['DrawCardSourceControllerEffect', 'PutCardFromHandOntoBattlefieldEffect']`; abilities `[]`; targets `[]`; signals `['draw']`; samples `['Embrace the Paradox', 'Eureka Moment', 'Growth Spiral', 'Lessons from Life', 'Mind into Matter']`
- Signature count `4`; effects `['BoostTargetEffect', 'ConditionalOneShotEffect', 'DrawCardSourceControllerEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'draw', 'condition']`; samples `['Chilling Trap', 'Might of the Old Ways', 'Thoughtweft Charge', "Unagi's Spray"]`
- Signature count `4`; effects `['DrawCardSourceControllerEffect', 'ProliferateEffect']`; abilities `[]`; targets `[]`; signals `['draw']`; samples `['Contentious Plan', 'Steady Progress', "Tezzeret's Gambit", "Vivisurgeon's Insight"]`
- Signature count `4`; effects `['DrawCardSourceControllerEffect', 'PutOnLibraryTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'draw']`; samples `['Footbottom Feast', 'Forever Young', 'Frantic Salvage', 'Gravepurge']`

### recursion_effect_class_not_pure (374)
- Work unit `recursion::xmage_graveyard_return_variant_review_v1`: `374`
- Signature count `4`; effects `['ConditionalOneShotEffect', 'DamageTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'condition']`; samples `['Fiery Impulse', 'Shower of Coals', 'Thermal Blast', 'Unholy Heat']`
- Signature count `3`; effects `['DestroyTargetEffect', 'ReturnFromGraveyardToBattlefieldTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Deadly Plot', 'Live or Die', 'Moment of Reckoning']`
- Signature count `3`; effects `['LookLibraryAndPickControllerEffect']`; abilities `['FlashbackAbility']`; targets `[]`; signals `[]`; samples `['Forbidden Alchemy', 'Resentful Revelation', 'Tapping at the Window']`
- Signature count `2`; effects `['ConditionalOneShotEffect', 'LookLibraryAndPickControllerEffect']`; abilities `[]`; targets `[]`; signals `['condition']`; samples `['Accumulate Wisdom', 'Flow State']`
- Signature count `2`; effects `['ReturnToHandTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Aether Burst', 'Reap']`

### mana_source_auxiliary_ability_not_supported (271)
- Work unit `ramp_permanent::xmage_artifact_mana_source_variant_review_v1`: `164`
- Work unit `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: `107`
- Signature count `3`; effects `['GainAbilityControlledEffect']`; abilities `['AnyColorManaAbility', 'SimpleStaticAbility']`; targets `[]`; signals `['mana', 'static_ability']`; samples `['Great Divide Guide', 'Joiner Adept', 'Manaweft Sliver']`
- Signature count `2`; effects `['BecomesCreatureSourceEffect']`; abilities `['BlueManaAbility', 'FlyingAbility', 'SimpleActivatedAbility', 'WhiteManaAbility']`; targets `[]`; signals `['mana', 'activated_ability']`; samples `['Azorius Keyrune', 'Ojutai Monument']`
- Signature count `2`; effects `['ScryEffect']`; abilities `['AnyColorManaAbility', 'EntersBattlefieldTriggeredAbility']`; targets `[]`; signals `['mana', 'triggered_ability']`; samples `['Bronze Walrus', 'Mana Geode']`
- Signature count `2`; effects `['GainLifeEffect']`; abilities `['AnyColorManaAbility', 'EntersBattlefieldTriggeredAbility']`; targets `[]`; signals `['mana', 'triggered_ability']`; samples `['Centaur Nurturer', 'Dawnhart Rejuvenator']`
- Signature count `2`; effects `['GainAbilitySourceEffect']`; abilities `['AnyColorManaAbility', 'DeathtouchAbility', 'ReachAbility', 'SimpleActivatedAbility']`; targets `[]`; signals `['mana', 'activated_ability']`; samples `['Frog Butler', 'Poison Dart Frog']`

### not_one_shot_spell_ability (249)
- Work unit `draw_cards::xmage_draw_card_variant_review_v1`: `81`
- Work unit `recursion::xmage_graveyard_return_variant_review_v1`: `45`
- Work unit `direct_damage::targeted_damage_variant_v1`: `27`
- Work unit `removal_destroy::targeted_destroy_variant_v1`: `19`
- Work unit `life_gain::xmage_life_gain_variant_review_v1`: `19`
- Signature count `6`; effects `['DestroyTargetEffect', 'SpellCostReductionSourceEffect']`; abilities `['SimpleStaticAbility']`; targets `[]`; signals `['targeting', 'cost_reduction', 'condition', 'static_ability']`; samples `["Ajani's Response", 'Fate of the Sun-Cryst', 'Grounded for Life', 'Luminous Rebuke', 'Mortality Spear', 'Seized from Slumber']`
- Signature count `5`; effects `['CounterTargetEffect', 'SpellCostReductionSourceEffect']`; abilities `['SimpleStaticAbility']`; targets `[]`; signals `['targeting', 'cost_reduction', 'counter', 'condition', 'static_ability']`; samples `['Brush Off', "Ertai's Scorn", 'Not of This World', 'Out of Air', 'Stoic Rebuttal']`
- Signature count `3`; effects `['BoostTargetEffect', 'CreateDelayedTriggeredAbilityEffect', 'DrawCardSourceControllerEffect']`; abilities `['AtTheBeginOfNextUpkeepDelayedTriggeredAbility']`; targets `[]`; signals `['targeting', 'draw', 'triggered_ability']`; samples `['Balduvian Rage', 'Feral Instinct', 'Fevered Strength']`
- Signature count `3`; effects `['ExileTargetEffect', 'SpellCostReductionSourceEffect']`; abilities `['SimpleStaticAbility']`; targets `[]`; signals `['targeting', 'cost_reduction', 'condition', 'static_ability']`; samples `['Banish from Edoras', 'Quicksand Whirlpool', "Ride's End"]`
- Signature count `3`; effects `['CounterTargetEffect', 'DrawCardSourceControllerEffect']`; abilities `['TargetActivatedAbility']`; targets `[]`; signals `['targeting', 'draw', 'counter', 'activated_ability']`; samples `['Bind', 'Bind // Liberate', 'Squelch']`

### tutor_effect_class_not_supported (145)
- Work unit `tutor::xmage_library_search_variant_review_v1`: `145`
- Signature count `4`; effects `['ExileTargetAndSearchGraveyardHandLibraryEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Eradicate', 'Scour', 'Sowing Salt', 'Splinter']`
- Signature count `4`; effects `['ReturnToHandTargetEffect', 'SearchLibraryGraveyardPutInHandEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Grasping Current', "Jace's Ruse", "Ral's Dispersal", 'Rhythmic Water Vortex']`
- Signature count `3`; effects `['DestroyTargetEffect', 'DrawCardSourceControllerEffect', 'SearchLibraryPutInPlayTargetControllerEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'draw']`; samples `['Cleansing Wildfire', "Geomancer's Gambit", 'Price of Freedom']`
- Signature count `3`; effects `['CounterTargetAndSearchGraveyardHandLibraryEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Counterbore', 'Quash', 'Test of Talents']`
- Signature count `3`; effects `['DestroyTargetEffect', 'SearchLibraryPutInPlayEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Deathsprout', 'Frenzied Tilling', 'Mwonvuli Acid-Moss']`

### mana_source_unsafe_ability_class (133)
- Work unit `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: `89`
- Work unit `ramp_permanent::xmage_artifact_mana_source_variant_review_v1`: `44`
- Signature count `10`; effects `[]`; abilities `['DynamicManaAbility']`; targets `[]`; signals `['mana']`; samples `['Deathbloom Ritualist', 'Harabaz Druid', "Karametra's Acolyte", 'Magus of the Coffers', 'Priest of Titania', 'Priest of Yawgmoth', 'Sanctum Weaver', 'Soldevi Adnate']`
- Signature count `5`; effects `['AddCountersSourceEffect']`; abilities `['DynamicManaAbility', 'SimpleActivatedAbility']`; targets `[]`; signals `['mana', 'counter', 'activated_ability']`; samples `['Black Mana Battery', 'Blue Mana Battery', 'Green Mana Battery', 'Red Mana Battery', 'White Mana Battery']`
- Signature count `3`; effects `[]`; abilities `['ConditionalAnyColorManaAbility']`; targets `[]`; signals `['mana', 'condition']`; samples `['Flamebraider', "Ixalli's Lorekeeper", 'Smokebraider']`
- Signature count `2`; effects `[]`; abilities `['AnyColorManaAbility', 'DynamicManaAbility']`; targets `[]`; signals `['mana']`; samples `['Accomplished Alchemist', 'Arbor Adherent']`
- Signature count `2`; effects `[]`; abilities `['DefenderAbility', 'DynamicManaAbility']`; targets `[]`; signals `['mana']`; samples `['Axebane Guardian', 'Overgrown Battlement']`

### mana_source_safe_ability_missing (132)
- Work unit `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: `105`
- Work unit `ramp_permanent::xmage_artifact_mana_source_variant_review_v1`: `27`
- Signature count `4`; effects `['BasicManaEffect']`; abilities `['EntersBattlefieldTriggeredAbility']`; targets `[]`; signals `['triggered_ability']`; samples `['Akki Rockspeaker', 'Burning-Tree Emissary', 'Priest of Gix', 'Priest of Urabrask']`
- Signature count `4`; effects `[]`; abilities `['AnyColorLandsProduceManaAbility']`; targets `[]`; signals `['targeting', 'mana']`; samples `['Harvester Druid', 'Naga Vitalist', 'Quirion Explorer', 'Sylvok Explorer']`
- Signature count `3`; effects `['BasicManaEffect']`; abilities `['DiesSourceTriggeredAbility']`; targets `[]`; signals `['triggered_ability']`; samples `['Cathodion', 'Myr Moonvessel', 'Su-Chi']`
- Signature count `3`; effects `['BasicManaEffect']`; abilities `['EntersBattlefieldTriggeredAbility']`; targets `[]`; signals `['condition', 'triggered_ability']`; samples `['Coal Stoker', 'Hidden Herbalists', 'Iridescent Tiger']`
- Signature count `2`; effects `['BasicManaEffect', 'DrawCardSourceControllerEffect']`; abilities `['EntersBattlefieldTriggeredAbility', 'SimpleActivatedAbility']`; targets `[]`; signals `['draw', 'condition', 'triggered_ability', 'activated_ability']`; samples `['Famished Foragers', 'Flamecache Gecko']`

### destroy_effect_class_not_pure (129)
- Work unit `removal_destroy::targeted_destroy_variant_v1`: `129`
- Signature count `15`; effects `['DamageTargetEffect', 'DestroyTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Bumi Bash', 'Collision Course', 'Coordinated Maneuver', 'Crash and Burn', 'Fiery Intervention', 'Keep Out', 'Kill! Maim! Burn!', 'Molten Blast']`
- Signature count `6`; effects `['DamageTargetControllerEffect', 'DestroyTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Cryoclasm', 'Detonate', 'Melt Terrain', 'Peak Eruption', 'Poison the Well', 'Word of Blasting']`
- Signature count `6`; effects `['DestroyTargetEffect', 'LoseLifeTargetControllerEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Despoil', "Glissa's Scorn", 'Hideous End', 'Sip of Hemlock', 'Spreading Rot', 'Victorious Destruction']`
- Signature count `5`; effects `['CreateTokenControllerTargetEffect', 'DestroyTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Afterlife', 'Beast Within', 'Bovine Intervention', 'Emergency Eject', 'Harsh Annotation']`
- Signature count `4`; effects `['DestroyTargetEffect', 'ReturnToHandTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Active Volcano', "Crosis's Charm", 'Flash Flood', "Tyrant's Scorn"]`

### damage_effect_class_not_pure (103)
- Work unit `direct_damage::targeted_damage_variant_v1`: `103`
- Signature count `11`; effects `['ConditionalOneShotEffect', 'DamageTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'condition']`; samples `['Arrow Storm', 'Brimstone Volley', 'Cackling Flames', "Crater's Claws", 'Firecannon Blast', 'Frost Bite', 'Galvanic Blast', 'Galvanize']`
- Signature count `4`; effects `['ConditionalOneShotEffect', 'DamageTargetEffect']`; abilities `['KickerAbility']`; targets `[]`; signals `['targeting', 'condition']`; samples `['Burst Lightning', 'Firebending Lesson', 'Roil Eruption', 'Shivan Fire']`
- Signature count `3`; effects `['CantBlockTargetEffect', 'DamageTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Mugging', "Sparkmage's Gambit", 'Wrap in Flames']`
- Signature count `3`; effects `['DamageTargetEffect', 'LookLibraryAndPickControllerEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Prophetic Bolt', "Sarkhan's Dragonfire", 'Stress Dream']`
- Signature count `2`; effects `['DamageTargetEffect', 'ShuffleSpellEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Beacon of Destruction', "Red Sun's Zenith"]`

### additional_cost_detected (96)
- Work unit `recursion::xmage_graveyard_return_variant_review_v1`: `14`
- Work unit `tutor::xmage_library_search_variant_review_v1`: `11`
- Work unit `removal_exile::targeted_exile_variant_v1`: `11`
- Work unit `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1`: `10`
- Work unit `counter_spell::counter_target_stack_object_variant_v1`: `9`
- Signature count `8`; effects `['ExileTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Angelic Purge', "Bogslither's Embrace", 'Eaten Alive', 'Final Vengeance', 'March of Otherworldly Light', 'Necrotic Fumes', 'Vengeful Dreams', 'Worthy Cost']`
- Signature count `7`; effects `['CounterTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Abjure', 'Deprive', 'Disappearing Act', 'Disruption Protocol', "Familiar's Ruse", 'Wild Unraveling', 'Withering Boon']`
- Signature count `5`; effects `['BoostTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Caustic Exhale', 'Hatred', 'Ruthless Disposal', 'Vicious Betrayal', 'Waste Away']`
- Signature count `3`; effects `['ReturnToHandTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Aether Tide', 'Scapegoat', 'Turbulent Dreams']`
- Signature count `2`; effects `['BoostTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Chill Haunting', 'Weigh Down']`

### life_gain_effect_class_not_pure (87)
- Work unit `life_gain::xmage_life_gain_variant_review_v1`: `87`
- Signature count `8`; effects `['BoostTargetEffect', 'GainLifeEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Fortifying Draught', 'Moment of Craving', 'Moment of Triumph', "Nightmare's Thirst", 'Syphon Fuel', 'Take Heart', 'Tandem Tactics', "Umezawa's Charm"]`
- Signature count `3`; effects `['GainLifeEffect', 'LookLibraryAndPickControllerEffect']`; abilities `[]`; targets `[]`; signals `[]`; samples `['Basic Conjuration', 'Bond of Flourishing', 'Commune with Evil']`
- Signature count `3`; effects `['GainLifeEffect', 'PreventAllDamageByAllPermanentsEffect']`; abilities `[]`; targets `[]`; signals `[]`; samples `['Blunt the Assault', 'Fog of War', 'Respite']`
- Signature count `3`; effects `['GainLifeEffect', 'ReturnToHandTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Dramatic Rescue', 'Narrow Escape', 'Pulse of Murasa']`
- Signature count `2`; effects `['CounterTargetEffect', 'GainLifeEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Absorb', 'Fall of the Gavel']`

### board_wipe_effect_class_not_supported (81)
- Work unit `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1`: `81`
- Signature count `7`; effects `['SacrificeAllEffect']`; abilities `[]`; targets `[]`; signals `['destroy_all']`; samples `['Barter in Blood', 'Crack the Earth', 'Innocent Blood', 'Renounce the Guilds', 'Simplify', 'Tectonic Break', 'Tremble']`
- Signature count `2`; effects `['CantBlockAllEffect', 'DamageAllEffect']`; abilities `[]`; targets `[]`; signals `['destroy_all']`; samples `['Cosmotronic Wave', 'Hazardous Blast']`
- Signature count `2`; effects `['DiscardEachPlayerEffect', 'LoseLifeAllPlayersEffect', 'SacrificeAllEffect']`; abilities `[]`; targets `[]`; signals `['destroy_all']`; samples `['Death Cloud', 'Smallpox']`
- Signature count `2`; effects `['DamageAllEffect', 'SacrificeAllEffect']`; abilities `[]`; targets `[]`; signals `['destroy_all']`; samples `['Destructive Force', 'Wildfire']`
- Signature count `2`; effects `['DestroyAllEffect', 'ReturnFromYourGraveyardToBattlefieldAllEffect']`; abilities `[]`; targets `[]`; signals `['destroy_all']`; samples `['Return of the Nightstalkers', 'Zombie Apocalypse']`

### board_wipe_ability_class_not_simple (67)
- Work unit `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1`: `67`
- Signature count `7`; effects `['DamageAllEffect']`; abilities `['FlyingAbility']`; targets `[]`; signals `['destroy_all']`; samples `['Flame Sweep', 'Hurly-Burly', 'Magmaquake', 'Rough // Tumble', 'Seismic Rupture', 'Seismic Shudder', 'Tremor']`
- Signature count `3`; effects `['DestroyAllEffect']`; abilities `['CyclingAbility']`; targets `[]`; signals `['destroy_all']`; samples `["Akroma's Vengeance", 'Hush', 'Pest Control']`
- Signature count `3`; effects `['DamageAllEffect']`; abilities `['CyclingAbility']`; targets `[]`; signals `['destroy_all']`; samples `['Fuel the Flames', 'Starstorm', 'Sweltering Suns']`
- Signature count `2`; effects `['DestroyAllEffect']`; abilities `['CantBeCounteredSourceAbility']`; targets `[]`; signals `['destroy_all']`; samples `['Obliterate', 'Supreme Verdict']`
- Signature count `2`; effects `['DestroyAllEffect']`; abilities `['AlternativeCostSourceAbility']`; targets `[]`; signals `['destroy_all', 'condition']`; samples `["Patrician's Scorn", 'Reverent Silence']`

### add_counters_effect_class_not_pure (63)
- Work unit `add_counters::targeted_add_counters_variant_v1`: `63`
- Signature count `6`; effects `['AddCountersTargetEffect', 'BoostTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Azula Always Lies', 'Free from Flesh', 'Fully Grown', 'Heightened Reflexes', 'Spontaneous Flight', 'Subtle Strike']`
- Signature count `5`; effects `['AddCountersTargetEffect', 'DamageWithPowerFromOneToAnotherTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `["Domri's Ambush", 'Felling Blow', "Hunter's Edge", 'Knockout Maneuver', 'Venom Blast']`
- Signature count `4`; effects `['AddCountersTargetEffect', 'TapTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Involuntary Cooldown', 'Procrastinate', 'Succumb to the Cold', 'Tranquilize']`
- Signature count `2`; effects `['AddCountersTargetEffect', 'ConditionalOneShotEffect', 'FightTargetsEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter', 'condition']`; samples `['Ancient Animus', 'Duel for Dominance']`
- Signature count `2`; effects `['AddCountersTargetEffect', 'ProliferateEffect']`; abilities `[]`; targets `[]`; signals `['targeting', 'counter']`; samples `['Courage in Crisis', 'Grim Affliction']`

### destroy_target_not_supported (47)
- Work unit `removal_destroy::targeted_destroy_variant_v1`: `47`
- Signature count `29`; effects `['DestroyTargetEffect']`; abilities `[]`; targets `[]`; signals `['targeting']`; samples `['Avalanche', 'By Force', 'Cast Down', 'Chill to the Bone', 'Cradle to Grave', "Eyeblight's Ending", 'Feast of Dreams', 'Hex']`
- Signature count `3`; effects `['DestroyTargetEffect']`; abilities `['CastOnlyDuringPhaseStepSourceAbility']`; targets `[]`; signals `['targeting', 'condition']`; samples `["Assassin's Blade", 'Eightfold Maze', 'Just Fate']`
- Signature count `2`; effects `['DestroyTargetEffect']`; abilities `['ConvokeAbility']`; targets `[]`; signals `['targeting']`; samples `['Cut Short', 'Protective Response']`
- Signature count `2`; effects `['DestroyTargetEffect']`; abilities `['MadnessAbility']`; targets `[]`; signals `['targeting']`; samples `['Dark Withering', 'Murderous Compulsion']`
- Signature count `2`; effects `['DestroyTargetEffect']`; abilities `['AlternativeCostSourceAbility', 'FlyingAbility']`; targets `[]`; signals `['targeting', 'condition']`; samples `['Pitfall Trap', 'Slingbow Trap']`

### tutor_ability_class_not_simple (45)
- Work unit `tutor::xmage_library_search_variant_review_v1`: `45`
- Signature count `2`; effects `['ConditionalOneShotEffect', 'SearchLibraryPutInPlayEffect']`; abilities `['KickerAbility']`; targets `[]`; signals `['targeting', 'condition']`; samples `['Grow from the Ashes', 'Primal Growth']`
- Signature count `1`; effects `['SearchLibraryPutInPlayEffect']`; abilities `['CyclingAbility']`; targets `[]`; signals `['targeting']`; samples `['Beneath the Sands']`
- Signature count `1`; effects `['SearchLibraryAndExileTargetEffect']`; abilities `['GravestormAbility']`; targets `[]`; signals `['targeting']`; samples `['Bitter Ordeal']`
- Signature count `1`; effects `['BecomesCreatureTargetEffect', 'ConditionalOneShotEffect', 'SearchLibraryPutInHandEffect']`; abilities `['BargainAbility', 'HasteAbility']`; targets `[]`; signals `['targeting', 'condition']`; samples `['Brave the Wilds']`
- Signature count `1`; effects `['AddCountersTargetEffect', 'BecomesCreatureTargetEffect', 'ContinuousEffect', 'CosmiumConfluenceEffect', 'DestroyTargetEffect', 'OneShotEffect', 'SearchLibraryPutInPlayEffect']`; abilities `['HasteAbility']`; targets `[]`; signals `['targeting', 'counter']`; samples `['Cosmium Confluence']`

## Selection note

This report is diagnostic only. It does not promote rules. The next PG wave must pick a narrow exact signature, add matching runtime/parser tests, generate package SQL, apply PostgreSQL, sync Hermes/SQLite, and rerun E2E/audits.
