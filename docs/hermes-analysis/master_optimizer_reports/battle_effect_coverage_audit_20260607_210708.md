# Battle Effect Coverage Audit

- generated_at: 2026-06-07T21:07:08.289277+00:00
- deck_id: 6
- opponents_loaded: 12
- total_card_instances: 1288
- unique_cards: 554

## Source Totals

| Source | Count |
| --- | ---: |
| battle_rule_generated | 237 |
| battle_rule_manual | 99 |
| effect_map | 222 |
| tag | 283 |
| type_land | 377 |
| unknown | 70 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 89 |
| copy_effect_mismatch | 1 |
| heuristic_effect | 742 |
| land_utility_ability_not_modeled | 48 |
| oracle_silence_mismatch | 1 |
| oracle_target_removal_mismatch | 9 |
| temporary_effect_not_explicit | 65 |
| trigger_not_explicit | 149 |
| unknown_effect | 70 |

## Deck Coverage

| Deck | Cards | Battle Manual | Battle Generated | Handcrafted | Generated | Tag | Effect Map | Type Land | Type Creature | Unknown | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Akiri, Line-Slinger #112 (real) | 99 | 6 | 15 | 0 | 0 | 24 | 19 | 29 | 0 | 6 | 71 |
| Etali, Primal Conqueror #187 (real) | 99 | 5 | 33 | 0 | 0 | 21 | 8 | 27 | 0 | 5 | 70 |
| Gwen Stacy #147 (real) | 99 | 11 | 27 | 0 | 0 | 15 | 14 | 26 | 0 | 6 | 68 |
| Ishai, Ojutai Dragonspeaker #110 (real) | 99 | 8 | 21 | 0 | 0 | 17 | 18 | 24 | 0 | 11 | 72 |
| Kenrith, the Returned King #195 (real) | 99 | 7 | 15 | 0 | 0 | 32 | 11 | 27 | 0 | 7 | 72 |
| Kinnan, Bonder Prodigy #119 (real) | 99 | 3 | 10 | 0 | 0 | 35 | 22 | 25 | 0 | 4 | 77 |
| Kraum, Ludevic's Opus #132 (real) | 99 | 7 | 20 | 0 | 0 | 21 | 16 | 26 | 0 | 9 | 71 |
| Lorehold target deck | 100 | 27 | 38 | 0 | 0 | 2 | 0 | 33 | 0 | 0 | 53 |
| Lumra, Bellow of the Woods #131 (real) | 99 | 2 | 6 | 0 | 0 | 25 | 17 | 48 | 0 | 1 | 60 |
| Magda, Brazen Outlaw #153 (real) | 99 | 8 | 23 | 0 | 0 | 11 | 26 | 28 | 0 | 3 | 67 |
| Sisay, Weatherlight Captain #113 (real) | 99 | 7 | 17 | 0 | 0 | 32 | 11 | 27 | 0 | 5 | 71 |
| Urza, Lord High Artificer #169 (real) | 99 | 4 | 11 | 0 | 0 | 24 | 26 | 25 | 0 | 9 | 73 |
| Yorion, Sky Nomad #120 (real) | 99 | 4 | 1 | 0 | 0 | 24 | 34 | 32 | 0 | 4 | 63 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Ragavan, Nimble Pilferer | ramp_engine | battle_rule_generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real) |
| Valley Floodcaller | creature | effect_map | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) |
| Flashback | recursion | battle_rule_generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Gwen Stacy #147 (real), Kraum, Ludevic's Opus #132 (real) |
| Flawless Maneuver | indestructible | battle_rule_generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Past in Flames | recursion | battle_rule_generated | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Surge to Victory | remove_permanent | battle_rule_manual | cast_permission_not_explicit, temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Flamescroll Celebrant | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Kraum, Ludevic's Opus #132 (real) |
| Myr Battlesphere | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Yorion, Sky Nomad #120 (real) |
| Six | creature | effect_map | cast_permission_not_explicit, heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Birgi, God of Storytelling | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Lorehold target deck |
| Ignoble Hierarch | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Noble Hierarch | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Legolas's Quick Reflexes | unknown | unknown | temporary_effect_not_explicit, trigger_not_explicit, unknown_effect | Lumra, Bellow of the Woods #131 (real) |
| Aetherflux Reservoir | finisher | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Cursed Mirror | ramp_permanent | battle_rule_generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Dragon's Rage Channeler | topdeck_manipulation | battle_rule_generated | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Electroduplicate | token_maker | battle_rule_generated | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Faithless Looting | draw_cards | battle_rule_generated | cast_permission_not_explicit, heuristic_effect | Lorehold target deck, Magda, Brazen Outlaw #153 (real) |
| Giver of Runes | indestructible | battle_rule_generated | heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Guttersnipe | finisher | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Knuckles the Echidna | finisher | battle_rule_generated | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Longshot, Rebel Bowman | finisher | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Molten Duplication | token_maker | battle_rule_generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Monument to Endurance | ramp_engine | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lorehold target deck |
| Mother of Runes | indestructible | battle_rule_generated | heuristic_effect, temporary_effect_not_explicit | Lorehold target deck |
| Open the Omenpaths | pump_all | battle_rule_generated | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real) |
| Professional Face-Breaker | ramp_engine | battle_rule_generated | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Pyroblast | counter | battle_rule_generated | heuristic_effect, oracle_target_removal_mismatch | Etali, Primal Conqueror #187 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real), Lorehold target deck |
| Red Elemental Blast | counter | battle_rule_generated | heuristic_effect, oracle_target_removal_mismatch | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) |
| Sevinne's Reclamation | remove_permanent | battle_rule_generated | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) |
| Storm-Kiln Artist | ramp_engine | battle_rule_generated | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real), Lorehold target deck |
| Strike It Rich | ramp_engine | battle_rule_generated | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Tataru Taru | ramp_engine | battle_rule_generated | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real) |
| Tezzeret, Cruel Captain | tutor | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real), Magda, Brazen Outlaw #153 (real), Urza, Lord High Artificer #169 (real) |
| Treasonous Ogre | ramp_ritual | battle_rule_generated | heuristic_effect, trigger_not_explicit | Etali, Primal Conqueror #187 (real) |
| Underworld Breach | recursion | battle_rule_generated | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real) |
| Vexing Bauble | draw_cards | battle_rule_generated | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real), Magda, Brazen Outlaw #153 (real) |
| Voice of Victory | silence_opponents | battle_rule_generated | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Kenrith, the Returned King #195 (real), Sisay, Weatherlight Captain #113 (real) |
| Amulet of Vigor | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| April O'Neil, Human Element | creature | effect_map | heuristic_effect, trigger_not_explicit | Urza, Lord High Artificer #169 (real) |
| Axgard Cavalry | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Battered Golem | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real), Urza, Lord High Artificer #169 (real) |
| Blazing Firesinger | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real) |
| Blossoming Tortoise | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Burgeoning | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Chatterfang, Squirrel General | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Kenrith, the Returned King #195 (real) |
| Derevi, Empyrial Tactician | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Sisay, Weatherlight Captain #113 (real) |
| Displacer Kitten | creature | effect_map | heuristic_effect, trigger_not_explicit | Gwen Stacy #147 (real) |
| Emiel the Blessed | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Sisay, Weatherlight Captain #113 (real) |
| Enslaved Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Fierce Guardianship | counter | effect_map | cast_permission_not_explicit, heuristic_effect | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kinnan, Bonder Prodigy #119 (real) |
| Gogo, Mysterious Mime | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| High Fae Trickster | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Hullbreaker Horror | remove_permanent | effect_map | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real), Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Hunting Velociraptor | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Icetill Explorer | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Ingenious Artillerist | creature | effect_map | heuristic_effect, trigger_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Isochron Scepter | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real) |
| Liberated Dwarf | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Liquimetal Coating | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |
| Mirage Mirror | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Kinnan, Bonder Prodigy #119 (real) |
| Permission Denied | counter | effect_map | heuristic_effect, oracle_silence_mismatch | Kraum, Ludevic's Opus #132 (real) |
| Rings of Brighthearth | creature | effect_map | heuristic_effect, trigger_not_explicit | Urza, Lord High Artificer #169 (real) |
| Springheart Nantuko | creature | effect_map | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Lumra, Bellow of the Woods #131 (real) |
| Squee, the Immortal | creature | effect_map | cast_permission_not_explicit, heuristic_effect | Etali, Primal Conqueror #187 (real) |
| Sylvan Safekeeper | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Tiller Engine | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #131 (real) |
| Wandering Archaic | creature | effect_map | heuristic_effect, trigger_not_explicit | Etali, Primal Conqueror #187 (real), Kinnan, Bonder Prodigy #119 (real) |
| Wash Away | counter | effect_map | cast_permission_not_explicit, heuristic_effect | Yorion, Sky Nomad #120 (real) |
| Badgermole Cub | ramp_permanent | tag | heuristic_effect, trigger_not_explicit | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Lumra, Bellow of the Woods #131 (real), Sisay, Weatherlight Captain #113 (real) |
| Beseech the Mirror | tutor | tag | cast_permission_not_explicit, heuristic_effect | Kraum, Ludevic's Opus #132 (real) |
| Borne Upon a Wind | draw_cards | tag | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kinnan, Bonder Prodigy #119 (real) |
| Consecrated Sphinx | draw_cards | tag | heuristic_effect, trigger_not_explicit | Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) |
| Curse of Opulence | ramp_permanent | tag | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real) |
| Dizzy Spell | tutor | tag | heuristic_effect, temporary_effect_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real) |
| Eldrazi Confluence | remove_creature | tag | heuristic_effect, temporary_effect_not_explicit | Etali, Primal Conqueror #187 (real), Lumra, Bellow of the Woods #131 (real) |
| Ephemerate | remove_creature | tag | cast_permission_not_explicit, heuristic_effect | Gwen Stacy #147 (real) |
| Faerie Mastermind | draw_cards | tag | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kinnan, Bonder Prodigy #119 (real), Kraum, Ludevic's Opus #132 (real) |
| Finale of Devastation | tutor | tag | heuristic_effect, temporary_effect_not_explicit | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Lumra, Bellow of the Woods #131 (real) |
| Firdoch Core | ramp_permanent | tag | heuristic_effect, temporary_effect_not_explicit | Magda, Brazen Outlaw #153 (real) |

## Unknown Cards

| Card | Decks | Type |
| --- | --- | --- |
| Legolas's Quick Reflexes | Lumra, Bellow of the Woods #131 (real) | Instant |
| Banishing Knack | Urza, Lord High Artificer #169 (real) | Instant |
| Cyclonic Rift | Akiri, Line-Slinger #112 (real), Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Flash Photography | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) | Sorcery |
| Heroes' Hangout | Gwen Stacy #147 (real) | Sorcery |
| Hidden Strings | Akiri, Line-Slinger #112 (real) | Sorcery |
| Kindle the Inner Flame | Etali, Primal Conqueror #187 (real) | Kindred Sorcery — Elemental |
| Opera Love Song | Gwen Stacy #147 (real) | Instant |
| Retraction Helix | Urza, Lord High Artificer #169 (real) | Instant |
| Submerge | Urza, Lord High Artificer #169 (real) | Instant |
| Brain Freeze | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) | Instant |
| Chain of Vapor | Akiri, Line-Slinger #112 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Commandeer | Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Displace | Yorion, Sky Nomad #120 (real) | Instant |
| Dramatic Reversal | Gwen Stacy #147 (real), Kinnan, Bonder Prodigy #119 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Firestorm | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real) | Instant |
| Force of Vigor | Etali, Primal Conqueror #187 (real) | Instant |
| Ghostly Flicker | Yorion, Sky Nomad #120 (real) | Instant |
| Into the Flood Maw | Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real), Kinnan, Bonder Prodigy #119 (real), Sisay, Weatherlight Captain #113 (real) | Instant |
| Mindbreak Trap | Akiri, Line-Slinger #112 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kenrith, the Returned King #195 (real) | Instant — Trap |
| Mine Collapse | Magda, Brazen Outlaw #153 (real) | Instant |
| Misdirection | Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) | Instant |
| Noxious Revival | Etali, Primal Conqueror #187 (real), Kenrith, the Returned King #195 (real) | Instant |
| Pyrokinesis | Etali, Primal Conqueror #187 (real) | Instant |
| Redirect Lightning | Etali, Primal Conqueror #187 (real), Gwen Stacy #147 (real), Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) | Instant — Lesson |
| Run Away Together | Yorion, Sky Nomad #120 (real) | Instant |
| Sink into Stupor | Ishai, Ojutai Dragonspeaker #110 (real), Urza, Lord High Artificer #169 (real) | Instant |
| Snap | Akiri, Line-Slinger #112 (real) | Instant |
| Snapback | Ishai, Ojutai Dragonspeaker #110 (real), Kraum, Ludevic's Opus #132 (real) | Instant |
| Stoke the Flames | Magda, Brazen Outlaw #153 (real) | Instant |
| Sudden Shock | Magda, Brazen Outlaw #153 (real) | Instant |
| Tainted Pact | Kenrith, the Returned King #195 (real), Kraum, Ludevic's Opus #132 (real), Sisay, Weatherlight Captain #113 (real) | Instant |
| Tragic Arrogance | Yorion, Sky Nomad #120 (real) | Sorcery |
