# Battle Effect Coverage Audit

- generated_at: 2026-06-20T12:09:52.630949+00:00
- deck_id: 6
- opponents_loaded: 12
- total_card_instances: 1288
- unique_cards: 556
- runtime_safe_rule_names: 1702
- active_or_review_rule_names: 3159
- non_runtime_safe_rule_names: 1457
- needs_review_rule_names: 1457
- review_only_rule_names: 1457
- annotation_only_rule_names: 0
- non_runtime_other_rule_names: 0
- review_status_counts: {"active": 27, "needs_review": 1457, "verified": 1675}
- execution_status_counts: {"auto": 1702, "review_only": 1457}

## Source Totals

| Source | Count |
| --- | ---: |
| battle_rule_curated | 724 |
| battle_rule_needs_review_generated | 34 |
| effect_map | 100 |
| focused_template_ready | 33 |
| handcrafted | 6 |
| tag | 14 |
| type_land | 377 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 89 |
| copy_effect_mismatch | 1 |
| heuristic_effect | 114 |
| land_utility_ability_not_modeled | 48 |
| needs_review_rule | 34 |
| oracle_silence_mismatch | 15 |
| oracle_target_removal_mismatch | 23 |
| temporary_effect_not_explicit | 65 |
| trigger_not_explicit | 147 |

## Deck Coverage

| Deck | Cards | Battle Rule Curated | Battle Rule Needs Review Generated | Focused Template Ready | Handcrafted | Effect Map | Tag | Type Land | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Akiri, Line-Slinger #30 (real) | 99 | 59 | 1 | 2 | 0 | 8 | 0 | 29 | 35 |
| Etali, Primal Conqueror #105 (real) | 99 | 60 | 2 | 1 | 2 | 6 | 1 | 27 | 26 |
| Gwen Stacy #65 (real) | 99 | 63 | 2 | 2 | 0 | 5 | 1 | 26 | 33 |
| Ishai, Ojutai Dragonspeaker #28 (real) | 99 | 60 | 3 | 2 | 1 | 7 | 2 | 24 | 35 |
| Kenrith, the Returned King #113 (real) | 99 | 63 | 3 | 2 | 0 | 3 | 1 | 27 | 32 |
| Kinnan, Bonder Prodigy #37 (real) | 99 | 60 | 1 | 0 | 1 | 12 | 0 | 25 | 37 |
| Kraum, Ludevic's Opus #50 (real) | 99 | 64 | 2 | 2 | 0 | 5 | 0 | 26 | 31 |
| Lorehold target deck | 100 | 67 | 0 | 0 | 0 | 0 | 0 | 33 | 29 |
| Lumra, Bellow of the Woods #49 (real) | 99 | 33 | 9 | 0 | 0 | 9 | 0 | 48 | 40 |
| Magda, Brazen Outlaw #71 (real) | 99 | 37 | 2 | 8 | 0 | 19 | 5 | 28 | 41 |
| Sisay, Weatherlight Captain #31 (real) | 99 | 67 | 0 | 1 | 0 | 4 | 0 | 27 | 35 |
| Urza, Lord High Artificer #87 (real) | 99 | 56 | 1 | 5 | 2 | 8 | 2 | 25 | 31 |
| Yorion, Sky Nomad #38 (real) | 99 | 35 | 8 | 8 | 0 | 14 | 2 | 32 | 32 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Valley Floodcaller | creature | effect_map | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) |
| Ragavan, Nimble Pilferer | creature | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Etali, Primal Conqueror #105 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real) |
| Ephemerate | protect_creature | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule, oracle_target_removal_mismatch | Gwen Stacy #65 (real) |
| Six | recursion | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Flamescroll Celebrant | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Kraum, Ludevic's Opus #50 (real) |
| Birgi, God of Storytelling | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Etali, Primal Conqueror #105 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real) |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | ramp_engine | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Flashback | recursion | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Gwen Stacy #65 (real), Kraum, Ludevic's Opus #50 (real) |
| Flawless Maneuver | indestructible | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Ignoble Hierarch | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Kenrith, the Returned King #113 (real), Sisay, Weatherlight Captain #31 (real) |
| Legolas's Quick Reflexes | protect_creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Mizzix's Mastery | overload_recursion | battle_rule_curated | cast_permission_not_explicit, oracle_target_removal_mismatch | Lorehold target deck |
| Myr Battlesphere | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Yorion, Sky Nomad #38 (real) |
| Noble Hierarch | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Kenrith, the Returned King #113 (real), Sisay, Weatherlight Captain #31 (real) |
| Past in Flames | recursion | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Amulet of Vigor | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Chatterfang, Squirrel General | token_maker | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Kenrith, the Returned King #113 (real) |
| Curse of Opulence | token_maker | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real) |
| Horizon Explorer | token_maker | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Lotus Cobra | ramp_ritual | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Nissa, Resurgent Animist | ramp_ritual | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Tireless Provisioner | ramp_engine | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Tormod's Crypt | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, oracle_target_removal_mismatch | Urza, Lord High Artificer #87 (real) |
| Veil of Summer | draw_cards | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Akiri, Line-Slinger #30 (real), Etali, Primal Conqueror #105 (real), Kenrith, the Returned King #113 (real), Kinnan, Bonder Prodigy #37 (real) |
| April O'Neil, Human Element | creature | effect_map | heuristic_effect, trigger_not_explicit | Urza, Lord High Artificer #87 (real) |
| Axgard Cavalry | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Battered Golem | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #71 (real), Urza, Lord High Artificer #87 (real) |
| Blazing Firesinger | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #105 (real), Gwen Stacy #65 (real) |
| Blossoming Tortoise | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Derevi, Empyrial Tactician | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Sisay, Weatherlight Captain #31 (real) |
| Displacer Kitten | creature | effect_map | heuristic_effect, trigger_not_explicit | Gwen Stacy #65 (real) |
| Emiel the Blessed | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Sisay, Weatherlight Captain #31 (real) |
| Enslaved Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Gogo, Mysterious Mime | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| High Fae Trickster | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |
| Hunting Velociraptor | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #105 (real) |
| Icetill Explorer | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Ingenious Artillerist | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Liberated Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Permission Denied | counter | effect_map | heuristic_effect, oracle_silence_mismatch | Kraum, Ludevic's Opus #50 (real) |
| Tiller Engine | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Wandering Archaic | creature | effect_map | heuristic_effect, trigger_not_explicit | Etali, Primal Conqueror #105 (real), Kinnan, Bonder Prodigy #37 (real) |
| Dizzy Spell | tutor | tag | heuristic_effect, temporary_effect_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real) |
| Firdoch Core | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Heartwood Storyteller | draw_cards | tag | heuristic_effect, trigger_not_explicit | Kenrith, the Returned King #113 (real) |
| Omen of the Sea | draw_cards | tag | cast_permission_not_explicit, heuristic_effect | Yorion, Sky Nomad #38 (real) |
| Siege Smash | remove_permanent | tag | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Mirrorpool | land | type_land | copy_effect_mismatch, land_utility_ability_not_modeled | Lumra, Bellow of the Woods #49 (real) |
| Aetherflux Reservoir | finisher | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Agatha's Soul Cauldron | passive | battle_rule_curated | oracle_target_removal_mismatch | Kinnan, Bonder Prodigy #37 (real), Sisay, Weatherlight Captain #31 (real) |
| Badgermole Cub | creature | battle_rule_curated | trigger_not_explicit | Akiri, Line-Slinger #30 (real), Kinnan, Bonder Prodigy #37 (real), Lumra, Bellow of the Woods #49 (real), Sisay, Weatherlight Captain #31 (real) |
| Beseech the Mirror | tutor | battle_rule_curated | cast_permission_not_explicit | Kraum, Ludevic's Opus #50 (real) |
| Borne Upon a Wind | draw_cards | battle_rule_curated | cast_permission_not_explicit | Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kinnan, Bonder Prodigy #37 (real) |
| Boros Charm | modal_boros_charm | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Burgeoning | ramp_engine | battle_rule_curated | trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Consecrated Sphinx | draw_engine | battle_rule_curated | trigger_not_explicit | Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |
| Cursed Mirror | ramp_permanent | battle_rule_curated | temporary_effect_not_explicit | Etali, Primal Conqueror #105 (real) |
| Cyclonic Rift | remove_permanent | battle_rule_curated | cast_permission_not_explicit | Akiri, Line-Slinger #30 (real), Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |
| Dawnbringer Cleric | creature | battle_rule_curated | oracle_target_removal_mismatch | Yorion, Sky Nomad #38 (real) |
| Deathrite Shaman | creature | battle_rule_curated | oracle_target_removal_mismatch | Kenrith, the Returned King #113 (real), Sisay, Weatherlight Captain #31 (real) |
| Deflecting Swat | redirect_removal | battle_rule_curated | cast_permission_not_explicit | Akiri, Line-Slinger #30 (real), Etali, Primal Conqueror #105 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real) |
| Dragon's Rage Channeler | creature | battle_rule_curated | trigger_not_explicit | Gwen Stacy #65 (real) |
| Drannith Magistrate | passive | battle_rule_curated | oracle_silence_mismatch | Lorehold target deck |
| Duplicant | creature | battle_rule_curated | oracle_target_removal_mismatch | Yorion, Sky Nomad #38 (real) |
| Eldrazi Confluence | remove_permanent | battle_rule_curated | temporary_effect_not_explicit | Etali, Primal Conqueror #105 (real), Lumra, Bellow of the Woods #49 (real) |
| Electroduplicate | copy_creature_token | battle_rule_curated | cast_permission_not_explicit | Etali, Primal Conqueror #105 (real), Lorehold target deck |
| Esper Sentinel | draw_engine | battle_rule_curated | trigger_not_explicit | Akiri, Line-Slinger #30 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) |
| Faerie Mastermind | creature | battle_rule_curated | trigger_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kinnan, Bonder Prodigy #37 (real), Kraum, Ludevic's Opus #50 (real) |
| Faithless Looting | draw_cards | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck, Magda, Brazen Outlaw #71 (real) |
| Fierce Guardianship | counter | battle_rule_curated | cast_permission_not_explicit | Akiri, Line-Slinger #30 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real), Kinnan, Bonder Prodigy #37 (real) |
| Finale of Devastation | tutor | battle_rule_curated | temporary_effect_not_explicit | Akiri, Line-Slinger #30 (real), Kinnan, Bonder Prodigy #37 (real), Lumra, Bellow of the Woods #49 (real) |
| Forensic Gadgeteer | creature | battle_rule_curated | trigger_not_explicit | Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |
| Giver of Runes | creature | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Guild Artisan | passive | battle_rule_curated | trigger_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Guttersnipe | creature | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Hullbreaker Horror | counter | battle_rule_curated | trigger_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real), Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |
| Isochron Scepter | copy_spell | battle_rule_curated | cast_permission_not_explicit | Gwen Stacy #65 (real) |
| Kinnan, Bonder Prodigy | creature | battle_rule_curated | trigger_not_explicit | Akiri, Line-Slinger #30 (real), Kenrith, the Returned King #113 (real), Sisay, Weatherlight Captain #31 (real) |
| Knuckles the Echidna | creature | battle_rule_curated | trigger_not_explicit | Magda, Brazen Outlaw #71 (real) |
| Liquimetal Torque | ramp_permanent | battle_rule_curated | temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real), Urza, Lord High Artificer #87 (real) |

## Unknown Effect Denominator

- Unknown effect cards: `29`
- Unknown effect source counts: `{"battle_rule_curated": 1, "focused_template_ready": 28}`
- Unknown effect status counts: `{"focused_template_ready": 28, "waived_curated_unknown_effect": 1}`

| Card | Source | Status | Owner | Flags | Decks | Effect scopes |
| --- | --- | --- | --- | --- | --- | --- |
| Flash Photography | focused_template_ready | focused_template_ready | battle-focused-template-contract | cast_permission_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) | copy_permanent_flash_or_flashback |
| Heroes' Hangout | focused_template_ready | focused_template_ready | battle-focused-template-contract | temporary_effect_not_explicit | Gwen Stacy #65 (real) | impulse_topdeck_or_library_zone |
| Hidden Strings | focused_template_ready | focused_template_ready | battle-focused-template-contract | trigger_not_explicit | Akiri, Line-Slinger #30 (real) | tap_untap_cipher_trigger |
| Kindle the Inner Flame | focused_template_ready | focused_template_ready | battle-focused-template-contract | cast_permission_not_explicit | Etali, Primal Conqueror #105 (real) | copy_token_delayed_sacrifice |
| Liquimetal Coating | focused_template_ready | focused_template_ready | battle-focused-template-contract | temporary_effect_not_explicit | Magda, Brazen Outlaw #71 (real) | type_change_continuous_effect |
| Opera Love Song | focused_template_ready | focused_template_ready | battle-focused-template-contract | temporary_effect_not_explicit | Gwen Stacy #65 (real) | impulse_topdeck_or_library_zone |
| Submerge | focused_template_ready | focused_template_ready | battle-focused-template-contract | cast_permission_not_explicit | Urza, Lord High Artificer #87 (real) | alternative_cost_library_bounce |
| Mirrormade | battle_rule_curated | waived_curated_unknown_effect | battle-effect-contract |  | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kinnan, Bonder Prodigy #37 (real), Urza, Lord High Artificer #87 (real) |  |
| Ashnod's Transmogrant | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | counter_type_change |
| Candelabra of Tawnos | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Akiri, Line-Slinger #30 (real) | utility_artifact_untap_x_lands |
| Clown Car | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | x_vehicle_counters_token |
| Codex Shredder | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Urza, Lord High Artificer #87 (real) | mill_graveyard_return |
| Copy Artifact | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Kraum, Ludevic's Opus #50 (real), Urza, Lord High Artificer #87 (real) | copy_artifact_as_enters |
| Cryptic Coat | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | manifest_cloak_equipment |
| Cursed Windbreaker | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | manifest_cloak_equipment |
| Dissection Tools | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | manifest_cloak_equipment |
| Firestorm | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kraum, Ludevic's Opus #50 (real) | additional_cost_discard_multi_target_damage |
| God-Pharaoh's Statue | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | static_tax_opponent_life_loss |
| Mine Collapse | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | alternative_cost_sacrifice_mountain_damage |
| Nevermore | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | named_card_cast_restriction |
| Out of Time | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | phase_out_mass_removal_counters, vanishing_sacrifice_trigger_removal |
| Power Artifact | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Urza, Lord High Artificer #87 (real) | cost_reduction_static_aura |
| Reality Acid | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | vanishing_sacrifice_trigger_removal |
| Scroll of Fate | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | manifest_from_hand_activated_ability |
| Stoke the Flames | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | convoke_damage |
| Sudden Shock | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | split_second_damage |
| Thorn of Amethyst | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Magda, Brazen Outlaw #71 (real) | static_noncreature_tax |
| Tragic Arrogance | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Yorion, Sky Nomad #38 (real) | modal_mass_sacrifice_selection |
| Tyvar, Jubilant Brawler | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Sisay, Weatherlight Captain #31 (real) | planeswalker_static_activated_graveyard |

## Focused Template Ready Cards

| Card | Effect | Decks | Templates | Effect Scopes |
| --- | --- | --- | --- | --- |
| Banishing Knack | remove_permanent | Urza, Lord High Artificer #87 (real) | supports_granted_bounce_ability_template | granted_bounce_ability |
| Flash Photography | unknown | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) | supports_copy_permanent_flash_or_flashback_template | copy_permanent_flash_or_flashback |
| Heroes' Hangout | unknown | Gwen Stacy #65 (real) | supports_impulse_topdeck_or_library_zone_template | impulse_topdeck_or_library_zone |
| Hidden Strings | unknown | Akiri, Line-Slinger #30 (real) | supports_tap_untap_cipher_trigger_template | tap_untap_cipher_trigger |
| Kindle the Inner Flame | unknown | Etali, Primal Conqueror #105 (real) | supports_copy_token_delayed_sacrifice_template | copy_token_delayed_sacrifice |
| Liquimetal Coating | unknown | Magda, Brazen Outlaw #71 (real) | supports_type_change_continuous_effect_template | type_change_continuous_effect |
| Opera Love Song | unknown | Gwen Stacy #65 (real) | supports_impulse_topdeck_or_library_zone_template | impulse_topdeck_or_library_zone |
| Submerge | unknown | Urza, Lord High Artificer #87 (real) | supports_alternative_cost_library_bounce_template | alternative_cost_library_bounce |
| Ashnod's Transmogrant | unknown | Magda, Brazen Outlaw #71 (real) | supports_counter_type_change_template | counter_type_change |
| Candelabra of Tawnos | unknown | Akiri, Line-Slinger #30 (real) | supports_utility_artifact_untap_x_lands_template | utility_artifact_untap_x_lands |
| Clown Car | unknown | Magda, Brazen Outlaw #71 (real) | supports_x_vehicle_counters_token_template | x_vehicle_counters_token |
| Codex Shredder | unknown | Urza, Lord High Artificer #87 (real) | supports_mill_graveyard_return_template | mill_graveyard_return |
| Copy Artifact | unknown | Kraum, Ludevic's Opus #50 (real), Urza, Lord High Artificer #87 (real) | supports_copy_artifact_as_enters_template | copy_artifact_as_enters |
| Cryptic Coat | unknown | Yorion, Sky Nomad #38 (real) | supports_manifest_cloak_equipment_template | manifest_cloak_equipment |
| Cursed Windbreaker | unknown | Yorion, Sky Nomad #38 (real) | supports_manifest_cloak_equipment_template | manifest_cloak_equipment |
| Dissection Tools | unknown | Yorion, Sky Nomad #38 (real) | supports_manifest_cloak_equipment_template | manifest_cloak_equipment |
| Firestorm | unknown | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kraum, Ludevic's Opus #50 (real) | supports_additional_cost_discard_multi_target_damage_template | additional_cost_discard_multi_target_damage |
| God-Pharaoh's Statue | unknown | Magda, Brazen Outlaw #71 (real) | supports_static_tax_opponent_life_loss_template | static_tax_opponent_life_loss |
| Mine Collapse | unknown | Magda, Brazen Outlaw #71 (real) | supports_alternative_cost_sacrifice_mountain_damage_template | alternative_cost_sacrifice_mountain_damage |
| Nevermore | unknown | Yorion, Sky Nomad #38 (real) | supports_named_card_cast_restriction_template | named_card_cast_restriction |
| Out of Time | unknown | Yorion, Sky Nomad #38 (real) | supports_phase_out_mass_removal_counters_template, supports_vanishing_sacrifice_trigger_removal_template | phase_out_mass_removal_counters, vanishing_sacrifice_trigger_removal |
| Power Artifact | unknown | Urza, Lord High Artificer #87 (real) | supports_cost_reduction_static_aura_template | cost_reduction_static_aura |
| Reality Acid | unknown | Yorion, Sky Nomad #38 (real) | supports_vanishing_sacrifice_trigger_removal_template | vanishing_sacrifice_trigger_removal |
| Scroll of Fate | unknown | Yorion, Sky Nomad #38 (real) | supports_manifest_from_hand_activated_ability_template | manifest_from_hand_activated_ability |
| Stoke the Flames | unknown | Magda, Brazen Outlaw #71 (real) | supports_convoke_damage_template | convoke_damage |
| Sudden Shock | unknown | Magda, Brazen Outlaw #71 (real) | supports_split_second_damage_template | split_second_damage |
| Thorn of Amethyst | unknown | Magda, Brazen Outlaw #71 (real) | supports_static_noncreature_tax_template | static_noncreature_tax |
| Tragic Arrogance | unknown | Yorion, Sky Nomad #38 (real) | supports_modal_mass_sacrifice_selection_template | modal_mass_sacrifice_selection |
| Tyvar, Jubilant Brawler | unknown | Sisay, Weatherlight Captain #31 (real) | supports_planeswalker_static_activated_graveyard_template | planeswalker_static_activated_graveyard |
