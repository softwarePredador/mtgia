# XMage Authoritative Exact Scope Split

- Generated at: `2026-07-01T05:41:40+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Summary

`{"adapter_work_unit_counts": {"direct_damage::targeted_damage_variant_v1": 106, "draw_cards::xmage_draw_card_variant_review_v1": 58, "removal_destroy::targeted_destroy_variant_v1": 148}, "blocked_reason_counts": {"additional_cost_detected": 71, "damage_amount_not_fixed": 44, "damage_effect_class_not_pure": 124, "damage_target_not_supported": 24, "destroy_effect_class_not_pure": 140, "destroy_target_not_supported": 75, "draw_effect_class_not_pure": 558, "not_instant_or_sorcery_spell": 1174, "not_one_shot_spell_ability": 136}, "considered_supported_work_unit_rows": 2658, "family_counts": {"xmage_destroy_target_spell": 148, "xmage_fixed_damage_spell": 106, "xmage_fixed_draw_spell": 58}, "proposal_count": 312, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 312}, "safe_for_batch_pg_package_count": 312, "scope_counts": {"xmage_destroy_target_spell_v1": 148, "xmage_fixed_damage_target_spell_v1": 106, "xmage_fixed_source_controller_draw_spell_v1": 58}}`

## Selected Proposals

| Card | Family | Scope | Effect | Logical rule key |
| --- | --- | --- | --- | --- |
| `Abolish` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Accumulated Knowledge` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Airborne Aid` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Airship Crash` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Alchemist's Greeting` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Allay` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Ancient Grudge` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Annihilating Fire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Atraxa's Fall` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Avenging Arrow` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Barbed Lightning` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3897f8bab939480ae9ff8b778b5f9d70` |
| `Bash to Bits` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Bathe in Dragonfire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Bee Sting` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Befoul` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Bituminous Blast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Bloodchief's Thirst` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:88fa7149781c04cad967b8087888e0e0` |
| `Body Count` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Bombard` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Boulder Salvo` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Brainspoil` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Branching Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:cf9e9715bb8136fe37e29b8b124cbde3` |
| `Break Asunder` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:6bf2229a7737711752b93823c20018a4` |
| `Break the Ice` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Breath of Fire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:455b65e5bead32b4b5fdcb2f5d3615cf` |
| `Brilliant Plan` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Bring Down` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Broken Wings` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Burn Trail` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Burning Fields` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c53012353efbf26120a657b3d0db3226` |
| `Casualties of War` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Channeled Dragonfire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Chemister's Insight` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:6391ead7eef36b3bba201942eb647ba7` |
| `Cinder Storm` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:a7e8c2b510e65e4de7b885d3cd39ead4` |
| `Cleansing Ray` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:2afd0c4dc498a4fc054cfec7c27b2dc5` |
| `Cleansing Screech` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:89027c9dcc7951d77a66097d6396f880` |
| `Clear` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Clear a Path` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Coastal Discovery` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Collar the Culprit` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Collective Unconscious` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Command the Storm` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:50f1613ee859541a3645043d2fe34215` |
| `Concentrate` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Cosmic Epiphany` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Counsel of the Soratami` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Crash` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Craterize` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Creeping Mold` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Crushing Canopy` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Crushing Pain` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:b8d32dff50eb3143aa375eac465f2ae4` |
| `Crushing Vines` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Cut Down` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Damn` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Daring Demolition` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Decimate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Deface` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Defeat` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Defenestrate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Demolish` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Demon Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f17c3a0d837930a609172beaf0d232ec` |
| `Demystify` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Desecration Plague` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:2afd0c4dc498a4fc054cfec7c27b2dc5` |
| `Desert Twister` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:9b7e997dd751cbd96446201f24fb2ae2` |
| `Destroy Evil` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Direct Current` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Disembowel` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Disenchant` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Dissenter's Deliverance` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Divination` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Donatello's Technique` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Dreadbore` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:88fa7149781c04cad967b8087888e0e0` |
| `Dwarven Landslide` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Eagle Vision` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Earth Rift` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Easy Prey` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Electrickery` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:94a798b0cab44d9ddb7589006e034201` |
| `Electrify` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Electro's Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Eliminate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:233369e4b0fa1fc23cff1f00216d0b34` |
| `Engulfing Eruption` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3c27aba62bd3c07635eee2ed0231e769` |
| `Everdream` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Eviscerate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Explosive Impact` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c9cb061ab89f0070b8d09896c8a32c43` |
| `Explosive Shot` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Fatal Blow` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Fell` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Fiery Fall` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:50f1613ee859541a3645043d2fe34215` |
| `Fiery Finish` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c41b662042ab632b3ad0885dd1166848` |
| `Fiery Temper` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Finishing Blow` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:233369e4b0fa1fc23cff1f00216d0b34` |
| `Fire Ambush` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Fireblast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Firebolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Fires of Undeath` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Fissure` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Fissure Vent` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Flame Jab` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:e1e2f2f2c340bd000faf9ec8501492fe` |
| `Flame Javelin` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Flame Jet` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:162c9f96a7c41f0c70a7035a61f955fb` |
| `Flame Lash` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Flame Slash` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Flesh to Dust` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Flow of Ideas` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Fowl Strike` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Fracture` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Fragmentize` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:6bf2229a7737711752b93823c20018a4` |
| `Frantic Inventory` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Frantic Purification` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Fry` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:dbaec042896051bca0cd57988077ca14` |
| `Gallant Strike` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Gang Up` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Geistflame` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Glacial Ray` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Gleeful Sabotage` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:6bf2229a7737711752b93823c20018a4` |
| `Glimpse of Freedom` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Goblin Barrage` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:6e4b9eb3a9a29caff18b2292aca231c9` |
| `Golden Ratio` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Grim Flowering` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Gush` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:6391ead7eef36b3bba201942eb647ba7` |
| `Hero's Downfall` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:233369e4b0fa1fc23cff1f00216d0b34` |
| `Hieroglyphic Illumination` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:6391ead7eef36b3bba201942eb647ba7` |
| `Highway Robbery` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Hornet Sting` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Hull Breach` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Ice Storm` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Icefall` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Impale` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Incendiary Flow` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Inescapable Blaze` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:495ec436fa860e8053e59b67cd2d4d2b` |
| `Inferno Jet` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c608e92e59de895767a48d122ee2e1f9` |
| `Inferno Trap` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Jace's Ingenuity` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:84a6ac5fbb81098a09c0bc8219cc816f` |
| `Keep Watch` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Killing Glare` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Krosan Grip` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Krovikan Rot` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Lava Axe` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:88f0e11e2132483b7dd719057fa15e81` |
| `Lava Dart` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Lava Flow` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Lava Spike` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:162c9f96a7c41f0c70a7035a61f955fb` |
| `Lay Waste` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Leaf Arrow` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:cf9e9715bb8136fe37e29b8b124cbde3` |
| `Legion's Judgment` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Light 'Em Up` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:53c67efee85cd12be45905af29ba9630` |
| `Lightning Blast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Lightning Strike` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Lock and Load` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Long Goodbye` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:233369e4b0fa1fc23cff1f00216d0b34` |
| `Lucid Dreams` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Lunar Insight` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Lórien Revealed` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Magma Burst` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Magmatic Sinkhole` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:dbaec042896051bca0cd57988077ca14` |
| `Make Your Move` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Mass Appeal` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Meeting of Minds` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:6391ead7eef36b3bba201942eb647ba7` |
| `Mental Journey` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:84a6ac5fbb81098a09c0bc8219cc816f` |
| `Mind Spring` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Mine Collapse` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:dbaec042896051bca0cd57988077ca14` |
| `Mizzium Mortars` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f679f436d97fee9e3c5008da40f24bea` |
| `Mob` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Mogg Salvage` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Molten Collapse` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:88fa7149781c04cad967b8087888e0e0` |
| `Molten Frame` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Mortify` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Murder` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Murderous Cut` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Natural Reclamation` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Natural State` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Naturalize` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Nature's Chant` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Obsessive Search` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `One with the Machine` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Open Fire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Oxidize` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Parch` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Pierce the Sky` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:536935530a483391c20fd182dbe2ed56` |
| `Pillage` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Pillar of Flame` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Pinpoint Avalanche` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Plummet` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Plunder` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Precision Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Puncture Blast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Purge` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Putrefy` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Pyromatics` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Pyrrhic Strike` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Quick Study` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:6391ead7eef36b3bba201942eb647ba7` |
| `Quiet Purity` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Radiant's Judgment` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Radical Idea` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Ragefire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:41e9cb04cba305299ae23bfd6e48e739` |
| `Rain of Rust` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Rain of Tears` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Rain of Thorns` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Ray of Distortion` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Ray of Revelation` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:407c00ea22d8d464227c70de26296d76` |
| `Reach of Shadows` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Reach Through Mists` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Reality Hemorrhage` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Reave Soul` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Reclaiming Vines` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Reiterating Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3443ab0caf1f6bdf89ee3bb8ea1fbba1` |
| `Relic Crush` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Repel Calamity` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Reprisal` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Return to the Earth` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Reverse Engineer` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Ribbons of the Reikai` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Rift Bolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Roast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3c27aba62bd3c07635eee2ed0231e769` |
| `Ruinous Path` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:88fa7149781c04cad967b8087888e0e0` |
| `Rush of Knowledge` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Sarkhan's Catharsis` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c82a87930ce3e98fa9de892c49d73b83` |
| `Scattershot` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:94a798b0cab44d9ddb7589006e034201` |
| `Scorching Missile` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:6e4b9eb3a9a29caff18b2292aca231c9` |
| `Scorching Shot` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3c27aba62bd3c07635eee2ed0231e769` |
| `Scorching Spear` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:e1e2f2f2c340bd000faf9ec8501492fe` |
| `Scrap` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Sear` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:f17c3a0d837930a609172beaf0d232ec` |
| `Searing Flesh` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:4172e6ebdd36600f929fcd6fad5fdda8` |
| `Searing Spear` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0179c6cc3d20112655e43b1269bf2290` |
| `Searing Touch` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Searing Wind` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:7ea2b119f7066d0f5299f96fde47d663` |
| `Shatter` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Shattering Pulse` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Shattering Spree` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Shenanigans` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Shivan Meteor` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:0059397667ebf71efdbe07369de2bd19` |
| `Shock` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Shredding Winds` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:536935530a483391c20fd182dbe2ed56` |
| `Silver Scrutiny` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Sinkhole` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Sizzling Barrage` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Skewer the Critics` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Skycrash` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Smelt` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Smite the Monstrous` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Smother` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Spark Spray` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:febd37997bb3683614d20454522b342f` |
| `Spin Out` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Spiteful Blow` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Staggershock` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Stand Up for Yourself` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Stoke the Flames` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Stomp and Howl` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Stone Rain` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Strangle` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3443ab0caf1f6bdf89ee3bb8ea1fbba1` |
| `Strangling Soot` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Stream of Acid` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Sudden Insight` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Sudden Shock` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Sunder from Within` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Sundering Vitae` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Sungold Barrage` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Surge of Brilliance` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Surging Flame` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Swat` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Take Inventory` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Tarfire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3993c1ad477db947e50c1070410cd487` |
| `Tears of Valakut` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:50f1613ee859541a3645043d2fe34215` |
| `Terminal Agony` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Terminate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Think Twice` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Thornado` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Thoughtcast` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Thunder Magic` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:455b65e5bead32b4b5fdcb2f5d3615cf` |
| `Thunderbolt` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:3897f8bab939480ae9ff8b778b5f9d70` |
| `Thunderclap` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:cf9e9715bb8136fe37e29b8b124cbde3` |
| `Thundering Rebuke` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:087b57aa91069ddd54b5bb209093d796` |
| `Thunderous Wrath` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:c9cb061ab89f0070b8d09896c8a32c43` |
| `Tidings` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:c32b93fc5d1a91cbef3b77ef6bf68c5f` |
| `Tome Blast` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Torrent of Stone` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:2eb093a58537802466ff92c4713d5896` |
| `Touch of Brilliance` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:01bef09139cdcf340bcd15bb6d3cf6c8` |
| `Touch of the Void` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Train of Thought` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Transcendent Message` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:37e6267e75385fb0731d4c0d47d837cd` |
| `Travel the Overworld` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:c32b93fc5d1a91cbef3b77ef6bf68c5f` |
| `Traverse Eternity` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Treasure Cruise` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:88ff56cb3f42b4703d6d284b2761b4bd` |
| `Trip Wire` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Unending Whisper` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Unfriendly Fire` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:43077b0f72827de2bbda048a3ff999ad` |
| `Universal Surveillance` | `xmage_fixed_draw_spell` | `xmage_fixed_source_controller_draw_spell_v1` | `draw_cards` | `battle_rule_v1:1dc787546713b8ba46fd75acf55c2668` |
| `Unyaro Bee Sting` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:fcb8373fbec877c86339375e5d6be479` |
| `Vandalize` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Vanquish the Weak` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:f4cebed22cdccdda520867221610197a` |
| `Verdigris` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:8827478db4c81a315abdcbecd194a052` |
| `Vindicate` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:9b7e997dd751cbd96446201f24fb2ae2` |
| `Violent Impact` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Void Rend` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:c52e6fe3b54d906bc6f85e1f7277a3f1` |
| `Volcanic Awakening` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:0b543efc21cb5ee532062e24929c6ae1` |
| `Volcanic Hammer` | `xmage_fixed_damage_spell` | `xmage_fixed_damage_target_spell_v1` | `direct_damage` | `battle_rule_v1:305c6defa16afe96c20667ebabde4177` |
| `Volcanic Submersion` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:96c08a0582c9ddf638096214e8d1b198` |
| `Volcanic Upheaval` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:40c4816f9f6e71cf71552488a7affc4f` |
| `Vote Out` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_creature` | `battle_rule_v1:8844850db13384812775c4a7d8e1dceb` |
| `Wear Away` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:ef2466b649b2dfd10755b79cf1c4df15` |
| `Wear Down` | `xmage_destroy_target_spell` | `xmage_destroy_target_spell_v1` | `remove_permanent` | `battle_rule_v1:6bf2229a7737711752b93823c20018a4` |
| ... | ... | ... | ... | `12 more` |

## Blocked Samples

- `additional_cost_detected`: `["Acceptable Losses", "Altar's Reap", "Annihilating Glare", "Artillerize", "Bankrupt in Blood", "Betrayer's Bargain", "Bitter Triumph", "Blood Divination", "Bone Shards", "Bone Splinters", "Close Encounter", "Collateral Damage"]`
- `damage_amount_not_fixed`: `["Armed Response", "Artillery Blast", "Blaze", "Clan Defiance", "Devil's Play", "Divine Retribution", "Dogpile", "Earth Tremor", "Electrostatic Bolt", "Fall of the Titans", "Fanning the Flames", "Feedback Bolt"]`
- `damage_effect_class_not_pure`: `["Aggressive Sabotage", "Arc Blade", "Arrow Storm", "Barrel Down Sokenzan", "Beacon of Destruction", "Bedeck // Bedazzle", "Blastfire Bolt", "Blightning", "Blooming Blast", "Bolt of Keranos", "Bot Bashing Time", "Brimstone Volley"]`
- `damage_target_not_supported`: `["Arrows of Justice", "Burning Oil", "Consuming Bonfire", "Cosmium Blast", "Divine Arrow", "Dragon's Presence", "Dual Shot", "Furious Reprisal", "Gideon's Reproach", "Hamato Ninp\u014d", "Impeccable Timing", "Iron Verdict"]`
- `destroy_effect_class_not_pure`: `["Active Volcano", "Afterlife", "Aftershock", "Agonizing Demise", "Airbender's Reversal", "Artisan's Sorrow", "Assassin's Strike", "Atomize", "Bant Charm", "Beast Within", "Blight Grenade", "Blood Curdle"]`
- `destroy_target_not_supported`: `["Asphyxiate", "Assassin's Blade", "Assassinate", "Avalanche", "Bramblecrush", "By Force", "Cast Down", "Chill to the Bone", "Consign to Dust", "Cradle to Grave", "Crush", "Curtains' Call"]`
- `draw_effect_class_not_pure`: `["Aang's Defense", "Abeyance", "Abzan Charm", "Accelerate", "Adventure Awaits", "Afflict", "Afterlife Insurance", "Aggressive Urge", "Airbending Lesson", "Allied Strategies", "Amass the Components", "Ambition's Cost"]`
- `not_instant_or_sorcery_spell`: `["Aberrant", "Abomination", "Absolver Thrull", "Abyssal Hunter", "Acid Web Spider", "Acidic Dagger", "Acidic Slime", "Acidic Sliver", "Acolyte of the Inferno", "Acorn Catapult", "Adrenaline Jockey", "Aeolipile"]`
- `not_one_shot_spell_ability`: `["Ajani's Response", "Aleatory", "Arwen's Gift", "Balduvian Rage", "Benefactor's Draught", "Bind", "Bind // Liberate", "Bone Harvest", "Bouncer's Beatdown", "Burnout", "Calibrated Blast", "Chill of the Grave"]`
