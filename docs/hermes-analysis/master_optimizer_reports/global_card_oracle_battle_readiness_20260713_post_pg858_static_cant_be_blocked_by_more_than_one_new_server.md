# Global All-Card Oracle Battle Readiness

- Generated at: `2026-07-13T02:43:17.990823+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- All known cards: `34331`
- Current registered-deck QA unique cards: `2203`
- Ready-product QA unique cards: `364`

## All Card Inventory

| Source | Metric | Value |
| --- | --- | ---: |
| `cards` | `total_cards` | 34331 |
| `cards` | `missing_oracle_id` | 3 |
| `cards` | `missing_oracle_text` | 359 |
| `cards` | `missing_type_line` | 0 |
| `cards` | `missing_name` | 0 |
| `cards` | `missing_all_legalities` | 0 |
| `cards` | `missing_commander_legality` | 0 |
| `cards` | `not_commander_legal` | 2997 |
| `card_intelligence_snapshot` | `total_snapshot_cards` | 34331 |
| `card_intelligence_snapshot` | `snapshot_missing_commander_legality` | 0 |
| `card_intelligence_snapshot` | `snapshot_has_any_rule` | 8081 |
| `card_intelligence_snapshot` | `snapshot_has_verified_rule` | 6932 |

## Routing Adjustments

| Metric | Value |
| --- | ---: |
| `empty_oracle_text_generic_candidates` | 359 |
| `oracle_text_empty_but_not_oracle_data_sync` | 359 |

## Lane Counts

| Lane | All Known Cards | Ready Product QA Cards |
| --- | ---: | ---: |
| `battle_and_oracle_ready` | 6825 | 265 |
| `battle_family_mapper_required` | 26969 | 86 |
| `battle_rule_verification_required` | 70 | 13 |
| `commander_illegal_block` | 2997 | 0 |
| `digital_non_commander_rule_exception` | 3 | 0 |
| `generic_runtime_or_no_card_rule` | 359 | 0 |
| `official_oracle_identity_unavailable` | 3 | 0 |

## Battle Gap Families

| Family | Cards |
| --- | ---: |
| `manual_model_review` | 6135 |
| `triggered_or_static_ability` | 3804 |
| `damage_or_life_total_change` | 3635 |
| `token_creation` | 3437 |
| `draw_selection_topdeck` | 3186 |
| `graveyard_recursion` | 1875 |
| `targeted_removal` | 876 |
| `tutor_search_library` | 742 |
| `modal_or_choice_effect` | 697 |
| `mana_generation_or_ritual` | 584 |
| `alternate_or_free_cast` | 493 |
| `protection_prevention` | 477 |
| `recursion_or_bounce` | 447 |
| `counterspell_or_stack_interaction` | 312 |
| `copy_spell_or_permanent` | 269 |

## Recommended Batches

| Batch | Cards | Method | Top Cards |
| --- | ---: | --- | --- |
| `battle_rule_verification_required` | 70 | active executable rule exists, but snapshot has no verified rule; run focused runtime/E2E proof, then promote review_status to verified via PG package | `Aetherflux Reservoir`, `Apex of Power`, `Approach of the Second Sun`, `Arcane Endeavor`, `Archaeomancer's Map`, `Austere Command`, `Basking Broodscale`, `Blind Obedience`, `Boros Charm`, `Breena, the Demagogue` |
| `battle_family::manual_model_review` | 6135 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `+2 Mace`, `_____ _____ _____ Trespasser`, `_____ Bird Gets the Worm`, `_____-o-saurus`, `A Little Chat`, `A Tale for the Ages`, `Aang, Air Nomad`, `Aang, Swift Savior // Aang and La, Ocean's Fury`, `Aarakocra Sneak`, `Abaddon the Despoiler` |
| `battle_family::triggered_or_static_ability` | 3804 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `_____ _____ Rocketship`, `Aang, at the Crossroads // Aang, Destined Savior`, `Aang, the Last Airbender`, `Abbot of Keral Keep`, `Aberrant Manawurm`, `Abigale, Poet Laureate // Heroic Stanza`, `Aboleth Spawn`, `Abomination`, `Aboroth`, `Absorbing Man` |
| `battle_family::damage_or_life_total_change` | 3635 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `_____ Balls of Fire`, `Abandon Reason`, `Abattoir Ghoul`, `Absolute Virtue`, `Abuna Acolyte`, `Abuna's Chant`, `Abyssal Hunter`, `Abyssal Specter`, `Abzan Guide`, `Achilles Davenport` |
| `battle_family::token_creation` | 3437 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `A Killer Among Us`, `Aang and Katara`, `Aang, Airbending Master`, `Aatchik, Emerald Radian`, `Abby, Merciless Soldier`, `Abdel Adrian, Gorion's Ward`, `Abhorrent Overlord`, `Abyssal Harvester`, `Abzan Ascendancy`, `Academy Manufactor` |
| `battle_family::draw_selection_topdeck` | 3186 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Aang's Iceberg`, `Aberrant`, `Abeyance`, `Abomination of Gudul`, `Abundance`, `Abzan Beastmaster`, `Abzan Charm`, `Academic Dispute`, `Academy Elite`, `Academy Loremaster` |
| `battle_family::graveyard_recursion` | 1875 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `"Lifetime" Pass Holder`, `A Good Day to Pie`, `Aang, A Lot to Learn`, `Abandon the Post`, `Abandoned Sarcophagus`, `Aberrant Mind Sorcerer`, `Aberrant Researcher // Perfected Form`, `Abhorrent Oculus`, `Aboshan's Desire`, `Abstract Performance` |
| `battle_family::targeted_removal` | 876 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Absolver Thrull`, `Abstruse Appropriation`, `Act of Authority`, `Active Volcano`, `Admonition Angel`, `Against All Odds`, `Agate Assault`, `Agent of Erebos`, `Agonizing Demise`, `Aim for the Head` |
| `battle_family::tutor_search_library` | 742 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `A.I.M. Scientists`, `Aang's Journey`, `Absorb Vis`, `Abzan Monument`, `Academy Rector`, `Aerial Surveyor`, `Agency Outfitter`, `Ainok Guide`, `Ajani's Aid`, `Alabaster Host Intercessor` |
| `battle_family::modal_or_choice_effect` | 697 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abandon Hope`, `Abundant Harvest`, `Abzan Advantage`, `Abzan Skycaptain`, `Academic Probation`, `Acquisitions Expert`, `Adaptive Automaton`, `Adaptive Sporesinger`, `Addle`, `Aether Gust` |
| `battle_family::mana_generation_or_ritual` | 584 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `________ Goblin`, `A Realm Reborn`, `Abstract Paintmage`, `Abundant Growth`, `Adarkar Unicorn`, `Advanced Reconstruction`, `Alena, Kessig Trapper`, `Alpine Moon`, `Altar of Shadows`, `Altar of the Lost` |
| `battle_family::alternate_or_free_cast` | 493 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abundant Maw`, `Acid-Spewer Dragon`, `Adventurous Eater // Have a Bite`, `Aerie Bowmasters`, `Aether Meltdown`, `Aether Searcher`, `Aether Web`, `Affa Guard Hound`, `Ainok Tracker`, `Alley Assailant` |
| `battle_family::protection_prevention` | 477 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Absolute Grace`, `Absolute Law`, `Adept Watershaper`, `Aegis of the Gods`, `Agent Frank Horrigan`, `Agent of the Shadow Thieves`, `Airtight Alibi`, `Akroma's Memorial`, `Akroma, Angel of Fury`, `Akroma, Vision of Ixidor` |
| `battle_family::recursion_or_bounce` | 447 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abiding Grace`, `Absorb Identity`, `Abuelo's Awakening`, `Academy Journeymage`, `Admiral Brass, Unsinkable`, `Aerith, Last Ancient`, `Aether Helix`, `Aethersnipe`, `Alchemist's Retrieval`, `Alesha, Who Laughs at Fate` |
| `battle_family::counterspell_or_stack_interaction` | 312 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abstruse Interference`, `Access Denied`, `Admiral's Order`, `Adric, Mathematical Genius`, `Amazing Acrobatics`, `Anticognition`, `Archmage's Charm`, `Arenson's Aura`, `Artistic Refusal`, `Assimilate Essence` |
| `battle_family::copy_spell_or_permanent` | 269 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abstruse Archaic`, `Adaptive Training Post`, `Aethertow`, `Aeve, Progenitor Ooze`, `Agrus Kos, Eternal Soldier`, `Alania, Divergent Storm`, `All of History, All at Once`, `Archmage of Echoes`, `Ashad, the Lone Cyberman`, `Astral Steel` |

## Top Actionable Cards

| Card | Priority | Lanes | Family | Ready Product QA Decks | Registered QA Decks | XMage |
| --- | ---: | --- | --- | ---: | ---: | --- |
| `Aetherflux Reservoir` | 400 | `battle_rule_verification_required` | `damage_or_life_total_change` | 0 | 11 | `unchecked` |
| `Apex of Power` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 13 | `unchecked` |
| `Approach of the Second Sun` | 400 | `battle_rule_verification_required` | `manual_model_review` | 1 | 23 | `unchecked` |
| `Arcane Endeavor` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Archaeomancer's Map` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 0 | `unchecked` |
| `Austere Command` | 400 | `battle_rule_verification_required` | `modal_or_choice_effect` | 0 | 23 | `unchecked` |
| `Basking Broodscale` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 0 | `unchecked` |
| `Blind Obedience` | 400 | `battle_rule_verification_required` | `triggered_or_static_ability` | 0 | 20 | `unchecked` |
| `Boros Charm` | 400 | `battle_rule_verification_required` | `damage_or_life_total_change` | 1 | 75 | `unchecked` |
| `Breena, the Demagogue` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 9 | `unchecked` |
| `Chandra, Hope's Beacon` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 0 | 13 | `unchecked` |
| `Channeled Force` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Chromatic Star` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 0 | `unchecked` |
| `Combustible Gearhulk` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Commander's Plate` | 400 | `battle_rule_verification_required` | `protection_prevention` | 0 | 8 | `unchecked` |
| `Curator's Ward` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Decaying Time Loop` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Drown in Dreams` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Dualcaster Mage` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 2 | 3 | `unchecked` |
| `Electric Revelation` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Empowered Autogenerator` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 0 | `unchecked` |
| `Enlightened Tutor` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 20 | `unchecked` |
| `Ether` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 0 | 0 | `unchecked` |
| `Fateful Showdown` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Fellwar Stone` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 3 | 495 | `unchecked` |
| `Formidable Speaker` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 15 | `unchecked` |
| `Goblin Engineer` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 1 | `unchecked` |
| `Heat Shimmer` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 1 | `unchecked` |
| `Idyllic Tutor` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 9 | `unchecked` |
| `Imperial Recruiter` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 1 | 8 | `unchecked` |
| `Increasing Vengeance` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 0 | 0 | `unchecked` |
| `Kraum, Ludevic's Opus` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Leyline of Abundance` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 0 | `unchecked` |
| `Library of Leng` | 400 | `battle_rule_verification_required` | `graveyard_recursion` | 1 | 22 | `unchecked` |
| `Lightning Greaves` | 400 | `battle_rule_verification_required` | `manual_model_review` | 5 | 461 | `unchecked` |
| `Machine God's Effigy` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 0 | `unchecked` |
| `Magma Opus` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 0 | `unchecked` |
| `Mana Vault` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 1 | 152 | `unchecked` |
| `Mithril Coat` | 400 | `battle_rule_verification_required` | `protection_prevention` | 0 | 8 | `unchecked` |
| `Molten Duplication` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 1 | `unchecked` |
| `Olórin's Searing Light` | 400 | `battle_rule_verification_required` | `damage_or_life_total_change` | 0 | 0 | `unchecked` |
| `Ondu Inversion // Ondu Skyruins` | 400 | `battle_rule_verification_required` | `manual_model_review` | 0 | 0 | `unchecked` |
| `One with the Multiverse` | 400 | `battle_rule_verification_required` | `alternate_or_free_cast` | 0 | 0 | `unchecked` |
| `Past in Flames` | 400 | `battle_rule_verification_required` | `graveyard_recursion` | 0 | 1 | `unchecked` |
| `Path to Exile` | 400 | `battle_rule_verification_required` | `targeted_removal` | 1 | 171 | `unchecked` |
| `Radiant Scrollwielder` | 400 | `battle_rule_verification_required` | `graveyard_recursion` | 0 | 0 | `unchecked` |
| `Rakdos, the Muscle` | 400 | `battle_rule_verification_required` | `protection_prevention` | 0 | 0 | `unchecked` |
| `Reckless Endeavor` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 5 | `unchecked` |
| `Recruiter of the Guard` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 3 | `unchecked` |
| `Reiterate` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 0 | 1 | `unchecked` |
| `Reverberate` | 400 | `battle_rule_verification_required` | `copy_spell_or_permanent` | 0 | 1 | `unchecked` |
| `Reverse the Sands` | 400 | `battle_rule_verification_required` | `manual_model_review` | 0 | 0 | `unchecked` |
| `Ring of the Lucii` | 400 | `battle_rule_verification_required` | `mana_generation_or_ritual` | 0 | 2 | `unchecked` |
| `Sazacap's Brew` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 0 | `unchecked` |
| `Scavenging Ooze` | 400 | `battle_rule_verification_required` | `targeted_removal` | 0 | 1 | `unchecked` |
| `Scroll Rack` | 400 | `battle_rule_verification_required` | `manual_model_review` | 1 | 23 | `unchecked` |
| `Sensei's Divining Top` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 4 | 157 | `unchecked` |
| `Shantotto, Tactician Magician` | 400 | `battle_rule_verification_required` | `draw_selection_topdeck` | 0 | 0 | `unchecked` |
| `Shark Typhoon` | 400 | `battle_rule_verification_required` | `token_creation` | 0 | 37 | `unchecked` |
| `Sisay, Weatherlight Captain` | 400 | `battle_rule_verification_required` | `tutor_search_library` | 0 | 5 | `unchecked` |

## Method Notes

- Scope is every PostgreSQL `cards` row, not only Lorehold or saved decks.
- Current registered deck usage is an internal QA seed only; it is not a user-demand or launch-priority signal.
- Oracle and legalities gaps should be handled in bulk before battle-family work.
- Battle work should be pulled by `battle_family::*` batches, not card-by-card.
- Broad XMage availability is routing evidence only; it is not executable PostgreSQL truth.
- Cards classified as generic runtime/no card rule are not automatically blockers.
