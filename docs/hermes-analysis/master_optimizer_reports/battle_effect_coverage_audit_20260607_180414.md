# Battle Effect Coverage Audit

- generated_at: 2026-06-07T18:04:14.907233+00:00
- deck_id: 6
- opponents_loaded: 12
- total_card_instances: 1288
- unique_cards: 554

## Source Totals

| Source | Count |
| --- | ---: |
| effect_map | 123 |
| generated | 599 |
| handcrafted | 98 |
| tag | 71 |
| type_land | 377 |
| unknown | 20 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 77 |
| copy_effect_mismatch | 1 |
| heuristic_effect | 793 |
| land_utility_ability_not_modeled | 48 |
| oracle_silence_mismatch | 1 |
| oracle_target_removal_mismatch | 9 |
| temporary_effect_not_explicit | 63 |
| trigger_not_explicit | 133 |
| unknown_effect | 20 |

## Deck Coverage

| Deck | Cards | Handcrafted | Generated | Tag | Effect Map | Type Land | Type Creature | Unknown | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Akiri, Line-Slinger #112 (real) | 99 | 6 | 50 | 4 | 9 | 29 | 0 | 1 | 68 |
| Etali, Primal Conqueror #187 (real) | 99 | 5 | 49 | 11 | 6 | 27 | 0 | 1 | 69 |
| Gwen Stacy #147 (real) | 99 | 11 | 52 | 3 | 5 | 26 | 0 | 2 | 65 |
| Ishai, Ojutai Dragonspeaker #110 (real) | 99 | 8 | 52 | 4 | 7 | 24 | 0 | 4 | 69 |
| Kenrith, the Returned King #195 (real) | 99 | 7 | 57 | 3 | 3 | 27 | 0 | 2 | 70 |
| Kinnan, Bonder Prodigy #119 (real) | 99 | 3 | 52 | 7 | 12 | 25 | 0 | 0 | 77 |
| Kraum, Ludevic's Opus #132 (real) | 99 | 7 | 57 | 1 | 6 | 26 | 0 | 2 | 68 |
| Lorehold target deck | 100 | 26 | 39 | 2 | 0 | 33 | 0 | 0 | 45 |
| Lumra, Bellow of the Woods #131 (real) | 99 | 2 | 35 | 5 | 9 | 48 | 0 | 0 | 60 |
| Magda, Brazen Outlaw #153 (real) | 99 | 8 | 28 | 7 | 25 | 28 | 0 | 3 | 66 |
| Sisay, Weatherlight Captain #113 (real) | 99 | 7 | 55 | 5 | 5 | 27 | 0 | 0 | 68 |
| Urza, Lord High Artificer #169 (real) | 99 | 4 | 46 | 9 | 11 | 25 | 0 | 4 | 73 |
| Yorion, Sky Nomad #120 (real) | 99 | 4 | 27 | 10 | 25 | 32 | 0 | 1 | 63 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Valley Floodcaller | creature | effect_map | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) |
| Ragavan, Nimble Pilferer | ramp_engine | generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real) |
| Flamescroll Celebrant | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Kraum, Ludevic's Opus #132 (real) |
| Flashback | recursion | generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Gwen Stacy #147 (real), Kraum, Ludevic's Opus #132 (real) |
| Flawless Maneuver | indestructible | generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Ignoble Hierarch | ramp_permanent | generated | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Legolas's Quick Reflexes | silence_opponents | generated | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Myr Battlesphere | token_maker | generated | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Yorion, Sky Nomad #120 (real) |
| Noble Hierarch | ramp_permanent | generated | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Past in Flames | recursion | generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Six | recursion | generated | cast_permission_not_explicit, heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Birgi, God of Storytelling | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Lorehold target deck |
| April O'Neil, Human Element | creature | effect_map | heuristic_effect, trigger_not_explicit | Urza, Lord High Artificer #169 (real) |
| Axgard Cavalry | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Battered Golem | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real), Urza, Lord High Artificer #169 (real) |
| Blazing Firesinger | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real) |
| Blossoming Tortoise | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Derevi, Empyrial Tactician | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Sisay, Weatherlight Captain #113 (real) |
| Displacer Kitten | creature | effect_map | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Emiel the Blessed | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Sisay, Weatherlight Captain #113 (real) |
| Enslaved Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Gogo, Mysterious Mime | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| High Fae Trickster | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Hunting Velociraptor | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Icetill Explorer | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Ingenious Artillerist | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Liberated Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Liquimetal Coating | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Permission Denied | counter | effect_map | heuristic_effect, oracle_silence_mismatch | Kraum, Ludevic's Opus #132 (real) |
| Tiller Engine | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Wandering Archaic | creature | effect_map | heuristic_effect, trigger_not_explicit | Etali, Primal Conqueror #187 (real), Kinnan, Bonder Prodigy #119 (real) |
| Wash Away | counter | effect_map | cast_permission_not_explicit, heuristic_effect | Yorion, Sky Nomad #120 (real) |
| Aetherflux Reservoir | finisher | generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Amulet of Vigor | ramp_permanent | generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Beseech the Mirror | tutor | generated | cast_permission_not_explicit, heuristic_effect | Kraum, Ludevic's Opus #132 (real) |
| Borne Upon a Wind | draw_cards | generated | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kinnan, Bonder Prodigy #119 (real) |
| Burgeoning | draw_engine | generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Chatterfang, Squirrel General | token_maker | generated | heuristic_effect, temporary_effect_not_explicit | Kenrith, the Returned King #195 (real) |
| Consecrated Sphinx | draw_engine | generated | heuristic_effect, trigger_not_explicit | Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Curse of Opulence | token_maker | generated | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real) |
| Cursed Mirror | ramp_permanent | generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Cyclonic Rift | remove_permanent | generated | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Dragon's Rage Channeler | topdeck_manipulation | generated | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Electroduplicate | token_maker | generated | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Ephemerate | remove_creature | generated | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real) |
| Faerie Mastermind | draw_engine | generated | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kinnan, Bonder Prodigy #119 (real), Kraum, Ludevic's Opus #132 (real) |
| Faithless Looting | draw_cards | generated | cast_permission_not_explicit, heuristic_effect | Lorehold target deck, Magda, Brazen Outlaw #153 (real) |
| Fierce Guardianship | counter | generated | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kinnan, Bonder Prodigy #119 (real) |
| Finale of Devastation | pump_all | generated | heuristic_effect, temporary_effect_not_explicit | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Lumra, Bellow of the Woods #131 (real) |
| Forensic Gadgeteer | token_maker | generated | heuristic_effect, trigger_not_explicit | Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Giver of Runes | indestructible | generated | heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Guttersnipe | finisher | generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Horizon Explorer | token_maker | generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Hullbreaker Horror | remove_permanent | generated | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real), Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Isochron Scepter | ramp_permanent | generated | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real) |
| Kinnan, Bonder Prodigy | topdeck_manipulation | generated | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Knuckles the Echidna | finisher | generated | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Liquimetal Torque | ramp_permanent | generated | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real), Urza, Lord High Artificer #169 (real) |
| Longshot, Rebel Bowman | finisher | generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Lotho, Corrupt Shirriff | ramp_engine | generated | heuristic_effect, trigger_not_explicit | Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real), Sisay, Weatherlight Captain #113 (real) |
| Lotus Cobra | ramp_ritual | generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Magda, the Hoardmaster | ramp_engine | generated | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Mirage Mirror | ramp_permanent | generated | heuristic_effect, temporary_effect_not_explicit | Kinnan, Bonder Prodigy #119 (real) |
| Mnemonic Betrayal | draw_cards | generated | cast_permission_not_explicit, heuristic_effect | Kraum, Ludevic's Opus #132 (real), Sisay, Weatherlight Captain #113 (real) |
| Molten Duplication | token_maker | generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Monument to Endurance | ramp_engine | generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Mother of Runes | indestructible | generated | heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Mulldrifter | draw_cards | generated | cast_permission_not_explicit, heuristic_effect | Yorion, Sky Nomad #120 (real) |
| Mystic Remora | draw_engine | generated | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) |
| Nature's Rhythm | recursion | generated | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Lumra, Bellow of the Woods #131 (real), Sisay, Weatherlight Captain #113 (real) |
| Nezahal, Primal Tide | creature | generated | heuristic_effect, trigger_not_explicit | Kinnan, Bonder Prodigy #119 (real) |
| Nissa, Resurgent Animist | ramp_ritual | generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Open the Omenpaths | pump_all | generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Orcish Bowmasters | remove_creature | generated | heuristic_effect, trigger_not_explicit | Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real), Sisay, Weatherlight Captain #113 (real) |
| Professional Face-Breaker | ramp_engine | generated | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Pyroblast | counter | generated | heuristic_effect, oracle_target_removal_mismatch | Etali, Primal Conqueror #187 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real), Lorehold target deck |
| Red Elemental Blast | counter | generated | heuristic_effect, oracle_target_removal_mismatch | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) |
| Rhystic Study | draw_engine | generated | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) |
| Rings of Brighthearth | ramp_permanent | generated | heuristic_effect, trigger_not_explicit | Urza, Lord High Artificer #169 (real) |
| Selvala, Heart of the Wilds | draw_cards | generated | heuristic_effect, trigger_not_explicit | Sisay, Weatherlight Captain #113 (real) |

## Unknown Cards

| Card | Decks | Type |
| --- | --- | --- |
| Banishing Knack | Urza, Lord High Artificer #169 (real) | Instant |
| Flash Photography | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) | Sorcery |
| Heroes' Hangout | Gwen Stacy #147 (real) | Sorcery |
| Hidden Strings | Akiri, Line-Slinger #112 (real) | Sorcery |
| Kindle the Inner Flame | Etali, Primal Conqueror #187 (real) | Kindred Sorcery — Elemental |
| Opera Love Song | Gwen Stacy #147 (real) | Instant |
| Retraction Helix | Urza, Lord High Artificer #169 (real) | Instant |
| Submerge | Urza, Lord High Artificer #169 (real) | Instant |
| Firestorm | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real) | Instant |
| Mine Collapse | Magda, Brazen Outlaw #153 (real) | Instant |
| Sink into Stupor | Ishai, Ojutai Dragonspeaker #110 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Snapback | Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) | Instant |
| Stoke the Flames | Magda, Brazen Outlaw #153 (real) | Instant |
| Sudden Shock | Magda, Brazen Outlaw #153 (real) | Instant |
| Tragic Arrogance | Yorion, Sky Nomad #120 (real) | Sorcery |
