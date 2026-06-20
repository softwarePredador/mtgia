# Battle Effect Coverage Audit

- generated_at: 2026-06-19T16:39:26.583443+00:00
- deck_id: 6
- opponents_loaded: 12
- total_card_instances: 1288
- unique_cards: 556
- runtime_safe_rule_names: 1702
- active_or_review_rule_names: 3159
- non_runtime_safe_rule_names: 1457
- needs_review_rule_names: 1457
- review_only_rule_names: 0
- annotation_only_rule_names: 0
- non_runtime_other_rule_names: 0
- review_status_counts: {"active": 27, "needs_review": 1457, "verified": 1675}
- execution_status_counts: {"auto": 3159}

## Source Totals

| Source | Count |
| --- | ---: |
| battle_rule_curated | 724 |
| battle_rule_needs_review_generated | 34 |
| effect_map | 100 |
| tag | 20 |
| type_land | 377 |
| unknown | 33 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 89 |
| copy_effect_mismatch | 1 |
| heuristic_effect | 120 |
| land_utility_ability_not_modeled | 48 |
| needs_review_rule | 34 |
| oracle_silence_mismatch | 15 |
| oracle_target_removal_mismatch | 20 |
| temporary_effect_not_explicit | 65 |
| trigger_not_explicit | 147 |
| unknown_effect | 33 |

## Deck Coverage

| Deck | Cards | Battle Manual | Battle Generated | Handcrafted | Generated | Tag | Effect Map | Type Land | Type Creature | Unknown | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Akiri, Line-Slinger #30 (real) | 99 | 0 | 0 | 0 | 0 | 0 | 8 | 29 | 0 | 2 | 36 |
| Etali, Primal Conqueror #105 (real) | 99 | 0 | 0 | 0 | 0 | 3 | 6 | 27 | 0 | 1 | 28 |
| Gwen Stacy #65 (real) | 99 | 0 | 0 | 0 | 0 | 1 | 5 | 26 | 0 | 2 | 33 |
| Ishai, Ojutai Dragonspeaker #28 (real) | 99 | 0 | 0 | 0 | 0 | 3 | 7 | 24 | 0 | 2 | 37 |
| Kenrith, the Returned King #113 (real) | 99 | 0 | 0 | 0 | 0 | 1 | 3 | 27 | 0 | 2 | 33 |
| Kinnan, Bonder Prodigy #37 (real) | 99 | 0 | 0 | 0 | 0 | 1 | 12 | 25 | 0 | 0 | 38 |
| Kraum, Ludevic's Opus #50 (real) | 99 | 0 | 0 | 0 | 0 | 0 | 5 | 26 | 0 | 2 | 33 |
| Lorehold target deck | 100 | 0 | 0 | 0 | 0 | 0 | 0 | 33 | 0 | 0 | 28 |
| Lumra, Bellow of the Woods #49 (real) | 99 | 0 | 0 | 0 | 0 | 0 | 9 | 48 | 0 | 0 | 40 |
| Magda, Brazen Outlaw #71 (real) | 99 | 0 | 0 | 0 | 0 | 5 | 19 | 28 | 0 | 8 | 48 |
| Sisay, Weatherlight Captain #31 (real) | 99 | 0 | 0 | 0 | 0 | 0 | 4 | 27 | 0 | 1 | 36 |
| Urza, Lord High Artificer #87 (real) | 99 | 0 | 0 | 0 | 0 | 4 | 8 | 25 | 0 | 5 | 36 |
| Yorion, Sky Nomad #38 (real) | 99 | 0 | 0 | 0 | 0 | 2 | 14 | 32 | 0 | 8 | 40 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Valley Floodcaller | creature | effect_map | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) |
| Ragavan, Nimble Pilferer | creature | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #30 (real), Etali, Primal Conqueror #105 (real), Gwen Stacy #65 (real), Ishai, Ojutai Dragonspeaker #28 (real) |
| Six | creature | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
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
| Amulet of Vigor | unknown | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Chatterfang, Squirrel General | creature | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Kenrith, the Returned King #113 (real) |
| Curse of Opulence | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #28 (real) |
| Ephemerate | remove_creature | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule | Gwen Stacy #65 (real) |
| Horizon Explorer | tutor | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Lotus Cobra | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Nissa, Resurgent Animist | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Tireless Provisioner | ramp_permanent | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
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
| Banishing Knack | remove_permanent | unknown | temporary_effect_not_explicit, unknown_effect | Urza, Lord High Artificer #87 (real) |
| Flash Photography | unknown | unknown | cast_permission_not_explicit, unknown_effect | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) |
| Heroes' Hangout | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Gwen Stacy #65 (real) |
| Hidden Strings | unknown | unknown | trigger_not_explicit, unknown_effect | Akiri, Line-Slinger #30 (real) |
| Kindle the Inner Flame | unknown | unknown | cast_permission_not_explicit, unknown_effect | Etali, Primal Conqueror #105 (real) |
| Liquimetal Coating | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Magda, Brazen Outlaw #71 (real) |
| Opera Love Song | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Gwen Stacy #65 (real) |
| Submerge | unknown | unknown | cast_permission_not_explicit, unknown_effect | Urza, Lord High Artificer #87 (real) |
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

## Unknown Cards

| Card | Decks | Type |
| --- | --- | --- |
| Banishing Knack | Urza, Lord High Artificer #87 (real) | Instant |
| Flash Photography | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real) | Sorcery |
| Heroes' Hangout | Gwen Stacy #65 (real) | Sorcery |
| Hidden Strings | Akiri, Line-Slinger #30 (real) | Sorcery |
| Kindle the Inner Flame | Etali, Primal Conqueror #105 (real) | Kindred Sorcery — Elemental |
| Liquimetal Coating | Magda, Brazen Outlaw #71 (real) | Artifact |
| Opera Love Song | Gwen Stacy #65 (real) | Instant |
| Submerge | Urza, Lord High Artificer #87 (real) | Instant |
| Ashnod's Transmogrant | Magda, Brazen Outlaw #71 (real) | Artifact |
| Candelabra of Tawnos | Akiri, Line-Slinger #30 (real) | Artifact |
| Clown Car | Magda, Brazen Outlaw #71 (real) | Artifact — Vehicle |
| Codex Shredder | Urza, Lord High Artificer #87 (real) | Artifact |
| Copy Artifact | Kraum, Ludevic's Opus #50 (real), Urza, Lord High Artificer #87 (real) | Enchantment |
| Cryptic Coat | Yorion, Sky Nomad #38 (real) | Artifact — Equipment |
| Cursed Windbreaker | Yorion, Sky Nomad #38 (real) | Artifact — Equipment |
| Dissection Tools | Yorion, Sky Nomad #38 (real) | Artifact — Equipment |
| Firestorm | Ishai, Ojutai Dragonspeaker #28 (real), Kenrith, the Returned King #113 (real), Kraum, Ludevic's Opus #50 (real) | Instant |
| God-Pharaoh's Statue | Magda, Brazen Outlaw #71 (real) | Legendary Artifact |
| Mine Collapse | Magda, Brazen Outlaw #71 (real) | Instant |
| Nevermore | Yorion, Sky Nomad #38 (real) | Enchantment |
| Out of Time | Yorion, Sky Nomad #38 (real) | Enchantment |
| Power Artifact | Urza, Lord High Artificer #87 (real) | Enchantment — Aura |
| Reality Acid | Yorion, Sky Nomad #38 (real) | Enchantment — Aura |
| Scroll of Fate | Yorion, Sky Nomad #38 (real) | Artifact |
| Stoke the Flames | Magda, Brazen Outlaw #71 (real) | Instant |
| Sudden Shock | Magda, Brazen Outlaw #71 (real) | Instant |
| Thorn of Amethyst | Magda, Brazen Outlaw #71 (real) | Artifact |
| Tragic Arrogance | Yorion, Sky Nomad #38 (real) | Sorcery |
| Tyvar, Jubilant Brawler | Sisay, Weatherlight Captain #31 (real) | Legendary Planeswalker — Tyvar |
