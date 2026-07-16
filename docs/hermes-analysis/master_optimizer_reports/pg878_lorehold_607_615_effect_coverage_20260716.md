# Battle Effect Coverage Audit

- generated_at: 2026-07-16T09:04:23.946433+00:00
- deck_id: 615
- opponents_loaded: 12
- total_card_instances: 1288
- unique_cards: 595
- runtime_safe_rule_names: 7009
- active_or_review_rule_names: 8073
- non_runtime_safe_rule_names: 1064
- needs_review_rule_names: 1064
- review_only_rule_names: 29
- annotation_only_rule_names: 0
- non_runtime_other_rule_names: 0
- review_status_counts: {"active": 68, "needs_review": 1064, "verified": 6941}
- execution_status_counts: {"auto": 8044, "review_only": 29}

## Source Totals

| Source | Count |
| --- | ---: |
| battle_rule_curated | 761 |
| battle_rule_needs_review_generated | 27 |
| effect_map | 81 |
| focused_template_ready | 5 |
| known_cards_canonical_snapshot | 1 |
| tag | 20 |
| type_land | 376 |
| unknown | 17 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 79 |
| copy_effect_mismatch | 1 |
| heuristic_effect | 101 |
| land_utility_ability_not_modeled | 54 |
| needs_review_rule | 27 |
| oracle_silence_mismatch | 14 |
| oracle_target_removal_mismatch | 20 |
| temporary_effect_not_explicit | 70 |
| trigger_not_explicit | 163 |
| unknown_effect | 17 |

## Deck Coverage

| Deck | Cards | Battle Rule Curated | Battle Rule Needs Review Generated | Focused Template Ready | Effect Map | Tag | Type Land | Unknown | Known Cards Canonical Snapshot | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Arcum Dagsson #97 (real) | 99 | 56 | 1 | 1 | 9 | 0 | 26 | 6 | 0 | 32 |
| Grist, the Hunger Tide #66 (real) | 99 | 50 | 7 | 0 | 6 | 3 | 26 | 7 | 0 | 38 |
| Ishai, Ojutai Dragonspeaker #80 (real) | 99 | 66 | 5 | 1 | 4 | 1 | 22 | 0 | 0 | 39 |
| K-9, Mark I #34 (real) | 99 | 64 | 0 | 1 | 4 | 3 | 26 | 1 | 0 | 34 |
| Kinnan, Bonder Prodigy #104 (real) | 99 | 65 | 0 | 0 | 8 | 0 | 26 | 0 | 0 | 25 |
| Kinnan, Bonder Prodigy #27 (real) | 99 | 69 | 0 | 1 | 4 | 1 | 24 | 0 | 0 | 26 |
| Kinnan, Bonder Prodigy #37 (real) | 99 | 69 | 0 | 0 | 5 | 0 | 25 | 0 | 0 | 31 |
| Kraum, Ludevic's Opus #86 (real) | 99 | 67 | 1 | 0 | 2 | 1 | 28 | 0 | 0 | 29 |
| Lorehold target deck | 100 | 65 | 0 | 0 | 0 | 0 | 34 | 0 | 1 | 31 |
| Lumra, Bellow of the Woods #49 (real) | 99 | 36 | 7 | 0 | 8 | 0 | 48 | 0 | 0 | 38 |
| Najeela, the Blade-Blossom #111 (real) | 99 | 70 | 0 | 0 | 2 | 0 | 27 | 0 | 0 | 25 |
| Sisay, Weatherlight Captain #61 (real) | 99 | 59 | 1 | 1 | 7 | 2 | 29 | 0 | 0 | 41 |
| Winota, Joiner of Forces #39 (real) | 99 | 25 | 5 | 0 | 22 | 9 | 35 | 3 | 0 | 44 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Valley Floodcaller | creature | effect_map | cast_permission_not_explicit, heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real), K-9, Mark I #34 (real), Kinnan, Bonder Prodigy #104 (real), Kinnan, Bonder Prodigy #27 (real) |
| Ragavan, Nimble Pilferer | creature | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit, trigger_not_explicit | K-9, Mark I #34 (real), Kraum, Ludevic's Opus #86 (real), Najeela, the Blade-Blossom #111 (real), Sisay, Weatherlight Captain #61 (real) |
| Kutzil, Malamet Exemplar | passive | battle_rule_needs_review_generated | needs_review_rule, oracle_silence_mismatch, trigger_not_explicit | Sisay, Weatherlight Captain #61 (real) |
| Legion Warboss | passive | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Six | passive | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Veyran, Voice of Duality | passive | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Erkenbrand, Lord of Westfold | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Goldnight Commander | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Harmonic Prodigy | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Lavinia, Azorius Renegade | creature | effect_map | heuristic_effect, oracle_silence_mismatch, trigger_not_explicit | Sisay, Weatherlight Captain #61 (real) |
| Liberator, Urza's Battlethopter | creature | effect_map | cast_permission_not_explicit, heuristic_effect, trigger_not_explicit | Arcum Dagsson #97 (real) |
| Signal Pest | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Théoden, King of Rohan | creature | effect_map | heuristic_effect, temporary_effect_not_explicit, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Apex of Power | passive | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Birgi, God of Storytelling | ramp_engine | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real), Kraum, Ludevic's Opus #86 (real) |
| Flashback | recursion | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Goliath Daydreamer | free_cast | battle_rule_curated | cast_permission_not_explicit, trigger_not_explicit | Lorehold target deck |
| Ignoble Hierarch | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Najeela, the Blade-Blossom #111 (real), Sisay, Weatherlight Captain #61 (real) |
| Legolas's Quick Reflexes | protect_creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real), Sisay, Weatherlight Captain #61 (real) |
| Mizzix's Mastery | overload_recursion | battle_rule_curated | cast_permission_not_explicit, oracle_target_removal_mismatch | Lorehold target deck |
| Noble Hierarch | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | K-9, Mark I #34 (real), Najeela, the Blade-Blossom #111 (real), Sisay, Weatherlight Captain #61 (real) |
| Ruby, Daring Tracker | ramp_permanent | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Sisay, Weatherlight Captain #61 (real) |
| Velomachus Lorehold | creature | battle_rule_curated | cast_permission_not_explicit, trigger_not_explicit | Lorehold target deck |
| Archmage Emeritus | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Baral, Chief of Compliance | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Chatterfang, Squirrel General | passive | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Grist, the Hunger Tide #66 (real) |
| Horizon Explorer | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Light Up the Stage | passive | battle_rule_needs_review_generated | cast_permission_not_explicit, needs_review_rule | Ishai, Ojutai Dragonspeaker #80 (real) |
| Lotus Cobra | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Loyal Apprentice | passive | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Mentor of the Meek | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Nissa, Resurgent Animist | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Selfless Spirit | passive | battle_rule_needs_review_generated | needs_review_rule, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Tireless Provisioner | passive | battle_rule_needs_review_generated | needs_review_rule, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Alexios, Deimos of Kosmos | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Arabella, Abandoned Doll | creature | effect_map | heuristic_effect, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Blood Artist | creature | effect_map | heuristic_effect, trigger_not_explicit | Grist, the Hunger Tide #66 (real) |
| Blossoming Tortoise | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Crashing Drawbridge | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Arcum Dagsson #97 (real) |
| Derevi, Empyrial Tactician | creature | effect_map | heuristic_effect, trigger_not_explicit | Najeela, the Blade-Blossom #111 (real), Sisay, Weatherlight Captain #61 (real) |
| Forsaken Miner | creature | effect_map | heuristic_effect, trigger_not_explicit | Grist, the Hunger Tide #66 (real) |
| Icetill Explorer | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Krark, the Thumbless | creature | effect_map | heuristic_effect, trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Phoenix Chick | creature | effect_map | heuristic_effect, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Shield Sphere | creature | effect_map | heuristic_effect, trigger_not_explicit | Arcum Dagsson #97 (real) |
| Silverwing Squadron | creature | effect_map | heuristic_effect, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Spider-Sense | counter | effect_map | cast_permission_not_explicit, heuristic_effect | Kraum, Ludevic's Opus #86 (real) |
| Tam, Mindful First-Year | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | Sisay, Weatherlight Captain #61 (real) |
| The Fourteenth Doctor | creature | effect_map | heuristic_effect, temporary_effect_not_explicit | K-9, Mark I #34 (real) |
| Tiller Engine | creature | effect_map | heuristic_effect, trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Vengeful Bloodwitch | creature | effect_map | heuristic_effect, trigger_not_explicit | Grist, the Hunger Tide #66 (real) |
| Void Winnower | creature | effect_map | heuristic_effect, oracle_silence_mismatch | Kinnan, Bonder Prodigy #104 (real) |
| Wandering Archaic | creature | effect_map | heuristic_effect, trigger_not_explicit | Kinnan, Bonder Prodigy #104 (real), Kinnan, Bonder Prodigy #37 (real) |
| Witherbloom Apprentice | creature | effect_map | heuristic_effect, trigger_not_explicit | Grist, the Hunger Tide #66 (real) |
| Witty Roastmaster | creature | effect_map | heuristic_effect, trigger_not_explicit | Winota, Joiner of Forces #39 (real) |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | ramp_engine | known_cards_canonical_snapshot | temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Abeyance | draw_cards | tag | heuristic_effect, temporary_effect_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Alseid of Life's Bounty | indestructible | tag | heuristic_effect, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Cliffside Rescuer | indestructible | tag | heuristic_effect, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Dizzy Spell | tutor | tag | heuristic_effect, temporary_effect_not_explicit | Kinnan, Bonder Prodigy #27 (real) |
| Eowyn, Fearless Knight | remove_creature | tag | heuristic_effect, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Heartwood Storyteller | draw_cards | tag | heuristic_effect, trigger_not_explicit | K-9, Mark I #34 (real) |
| Katara, Waterbending Master | draw_cards | tag | heuristic_effect, trigger_not_explicit | Kraum, Ludevic's Opus #86 (real) |
| Lena, Selfless Champion | indestructible | tag | heuristic_effect, temporary_effect_not_explicit | Winota, Joiner of Forces #39 (real) |
| Spider-UK | draw_cards | tag | cast_permission_not_explicit, heuristic_effect | Winota, Joiner of Forces #39 (real) |
| Mirrorpool | land | type_land | copy_effect_mismatch, land_utility_ability_not_modeled | Lumra, Bellow of the Woods #49 (real) |
| Cabal Therapy | unknown | unknown | cast_permission_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |
| Frontline Rush | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Winota, Joiner of Forces #39 (real) |
| Professor Onyx | unknown | unknown | trigger_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |
| Shallow Grave | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |
| Yawgmoth's Will | unknown | unknown | temporary_effect_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |
| Agatha's Soul Cauldron | passive | battle_rule_curated | oracle_target_removal_mismatch | Arcum Dagsson #97 (real), Kinnan, Bonder Prodigy #104 (real), Kinnan, Bonder Prodigy #37 (real), Sisay, Weatherlight Captain #61 (real) |
| Amulet of Vigor | untap_tapped_permanent_etb_engine | battle_rule_curated | trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |
| Angel's Grace | cannot_lose_turn | battle_rule_curated | temporary_effect_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Ashling, Flame Dancer | creature | battle_rule_curated | trigger_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) |
| Badgermole Cub | creature | battle_rule_curated | trigger_not_explicit | Kinnan, Bonder Prodigy #37 (real), Lumra, Bellow of the Woods #49 (real), Sisay, Weatherlight Captain #61 (real) |
| Beseech the Mirror | tutor | battle_rule_curated | cast_permission_not_explicit | Grist, the Hunger Tide #66 (real) |
| Borne Upon a Wind | draw_cards | battle_rule_curated | cast_permission_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real), K-9, Mark I #34 (real), Kinnan, Bonder Prodigy #27 (real), Kinnan, Bonder Prodigy #37 (real) |
| Boros Charm | modal_boros_charm | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Burgeoning | ramp_engine | battle_rule_curated | trigger_not_explicit | Lumra, Bellow of the Woods #49 (real) |

## Source Unknown Cards

| Card | Decks | Type |
| --- | --- | --- |
| Cabal Therapy | Grist, the Hunger Tide #66 (real) | Sorcery |
| Frontline Rush | Winota, Joiner of Forces #39 (real) | Instant |
| Professor Onyx | Grist, the Hunger Tide #66 (real) | Legendary Planeswalker — Liliana |
| Shallow Grave | Grist, the Hunger Tide #66 (real) | Instant |
| Yawgmoth's Will | Grist, the Hunger Tide #66 (real) | Sorcery |
| Chain of Smog | Grist, the Hunger Tide #66 (real) | Sorcery |
| Charge of the Mites | Winota, Joiner of Forces #39 (real) | Instant |
| Clowning Around | Winota, Joiner of Forces #39 (real) | Sorcery |
| Damping Sphere | Arcum Dagsson #97 (real) | Artifact |
| Encroaching Mycosynth | Arcum Dagsson #97 (real) | Artifact |
| Footsteps of the Goryo | Grist, the Hunger Tide #66 (real) | Sorcery — Arcane |
| Mind Over Matter | Arcum Dagsson #97 (real) | Enchantment |
| Mythos of Illuna | K-9, Mark I #34 (real) | Sorcery |
| Pattern of Rebirth | Grist, the Hunger Tide #66 (real) | Enchantment — Aura |
| Portal to Phyrexia | Arcum Dagsson #97 (real) | Artifact |
| Skateboard | Arcum Dagsson #97 (real) | Artifact — Equipment |
| Twiddle | Arcum Dagsson #97 (real) | Instant |

## Unknown Effect Denominator

- Unknown effect cards: `21`
- Unknown effect source counts: `{"focused_template_ready": 5, "unknown": 16}`
- Unknown effect status counts: `{"focused_template_ready": 5, "source_unknown": 16}`

| Card | Source | Status | Owner | Flags | Decks | Effect scopes |
| --- | --- | --- | --- | --- | --- | --- |
| Cabal Therapy | unknown | source_unknown | battle-unknown-template-backlog | cast_permission_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Frontline Rush | unknown | source_unknown | battle-unknown-template-backlog | temporary_effect_not_explicit, unknown_effect | Winota, Joiner of Forces #39 (real) |  |
| Professor Onyx | unknown | source_unknown | battle-unknown-template-backlog | trigger_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Shallow Grave | unknown | source_unknown | battle-unknown-template-backlog | temporary_effect_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Yawgmoth's Will | unknown | source_unknown | battle-unknown-template-backlog | temporary_effect_not_explicit, unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Hidden Strings | focused_template_ready | focused_template_ready | battle-focused-template-contract | trigger_not_explicit | Kinnan, Bonder Prodigy #27 (real) | tap_untap_cipher_trigger |
| Submerge | focused_template_ready | focused_template_ready | battle-focused-template-contract | cast_permission_not_explicit | Ishai, Ojutai Dragonspeaker #80 (real) | alternative_cost_library_bounce |
| Chain of Smog | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Charge of the Mites | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Winota, Joiner of Forces #39 (real) |  |
| Clowning Around | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Winota, Joiner of Forces #39 (real) |  |
| Damping Sphere | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Encroaching Mycosynth | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Mind Over Matter | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Mythos of Illuna | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | K-9, Mark I #34 (real) |  |
| Pattern of Rebirth | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Grist, the Hunger Tide #66 (real) |  |
| Portal to Phyrexia | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Skateboard | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Twiddle | unknown | source_unknown | battle-unknown-template-backlog | unknown_effect | Arcum Dagsson #97 (real) |  |
| Firestorm | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | K-9, Mark I #34 (real) | additional_cost_discard_multi_target_damage |
| God-Pharaoh's Statue | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Arcum Dagsson #97 (real) | static_tax_opponent_life_loss |
| Tyvar, Jubilant Brawler | focused_template_ready | focused_template_ready | battle-focused-template-contract |  | Sisay, Weatherlight Captain #61 (real) | planeswalker_static_activated_graveyard |

## Focused Template Ready Cards

| Card | Effect | Decks | Templates | Effect Scopes |
| --- | --- | --- | --- | --- |
| Hidden Strings | unknown | Kinnan, Bonder Prodigy #27 (real) | supports_tap_untap_cipher_trigger_template | tap_untap_cipher_trigger |
| Submerge | unknown | Ishai, Ojutai Dragonspeaker #80 (real) | supports_alternative_cost_library_bounce_template | alternative_cost_library_bounce |
| Firestorm | unknown | K-9, Mark I #34 (real) | supports_additional_cost_discard_multi_target_damage_template | additional_cost_discard_multi_target_damage |
| God-Pharaoh's Statue | unknown | Arcum Dagsson #97 (real) | supports_static_tax_opponent_life_loss_template | static_tax_opponent_life_loss |
| Tyvar, Jubilant Brawler | unknown | Sisay, Weatherlight Captain #61 (real) | supports_planeswalker_static_activated_graveyard_template | planeswalker_static_activated_graveyard |
