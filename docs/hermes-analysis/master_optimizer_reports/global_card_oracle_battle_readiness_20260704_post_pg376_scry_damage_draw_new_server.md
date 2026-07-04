# Global All-Card Oracle Battle Readiness

- Generated at: `2026-07-04T01:20:19.546566+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- All known cards: `34331`
- Current registered-deck QA unique cards: `2203`
- Ready-product QA unique cards: `364`

## All Card Inventory

| Source | Metric | Value |
| --- | --- | ---: |
| `cards` | `total_cards` | 34331 |
| `cards` | `missing_oracle_id` | 4 |
| `cards` | `missing_oracle_text` | 360 |
| `cards` | `missing_type_line` | 1 |
| `cards` | `missing_name` | 0 |
| `cards` | `missing_all_legalities` | 0 |
| `cards` | `missing_commander_legality` | 3 |
| `cards` | `not_commander_legal` | 2994 |
| `card_intelligence_snapshot` | `total_snapshot_cards` | 34331 |
| `card_intelligence_snapshot` | `snapshot_missing_commander_legality` | 3 |
| `card_intelligence_snapshot` | `snapshot_has_any_rule` | 5034 |
| `card_intelligence_snapshot` | `snapshot_has_verified_rule` | 3745 |

## Routing Adjustments

| Metric | Value |
| --- | ---: |
| `empty_oracle_text_generic_candidates` | 360 |
| `oracle_text_empty_but_not_oracle_data_sync` | 359 |

## Lane Counts

| Lane | All Known Cards | Ready Product QA Cards |
| --- | ---: | ---: |
| `battle_and_oracle_ready` | 3880 | 250 |
| `battle_family_mapper_required` | 29950 | 100 |
| `commander_illegal_block` | 2994 | 0 |
| `commander_legality_sync` | 3 | 0 |
| `generic_runtime_or_no_card_rule` | 360 | 0 |
| `oracle_data_sync` | 4 | 0 |
| `oracle_identity_rule_link_or_copy` | 2 | 1 |
| `trusted_rule_oracle_hash_backfill` | 43 | 13 |

## Battle Gap Families

| Family | Cards |
| --- | ---: |
| `manual_model_review` | 7289 |
| `damage_or_life_total_change` | 3957 |
| `triggered_or_static_ability` | 3907 |
| `token_creation` | 3633 |
| `draw_selection_topdeck` | 3488 |
| `graveyard_recursion` | 1902 |
| `targeted_removal` | 1061 |
| `mana_generation_or_ritual` | 937 |
| `tutor_search_library` | 826 |
| `modal_or_choice_effect` | 699 |
| `protection_prevention` | 569 |
| `alternate_or_free_cast` | 524 |
| `recursion_or_bounce` | 495 |
| `counterspell_or_stack_interaction` | 394 |
| `copy_spell_or_permanent` | 269 |

## Recommended Batches

| Batch | Cards | Method | Top Cards |
| --- | ---: | --- | --- |
| `oracle_bulk_backfill` | 4 | Scryfall bulk/default-cards or targeted exact lookup; update cards only after exact identity match | `A-Alrund's Epiphany`, `A-Omnath, Locus of Creation`, `A-Unholy Heat`, `Birds of Paradise // Birds of Paradise` |
| `commander_legality_gap_sync` | 3 | Scryfall legalities by oracle_id/set_code; fill missing commander status without changing decklists | `A-Alrund's Epiphany`, `A-Omnath, Locus of Creation`, `A-Unholy Heat` |
| `oracle_identity_rule_link_or_copy` | 2 | candidate copy/link from trusted rule on same oracle_id; requires oracle_hash check and focused runtime smoke before PG package | `Birds of Paradise // Birds of Paradise`, `Sol Ring // Sol Ring` |
| `battle_family::manual_model_review` | 7289 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `+2 Mace`, `_____ _____ _____ Trespasser`, `_____ Bird Gets the Worm`, `_____-o-saurus`, `A Little Chat`, `A Tale for the Ages`, `Aang, Air Nomad`, `Aang, Swift Savior // Aang and La, Ocean's Fury`, `Aarakocra Sneak`, `Abaddon the Despoiler` |
| `battle_family::damage_or_life_total_change` | 3957 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `_____ Balls of Fire`, `Abandon Reason`, `Abattoir Ghoul`, `Absolute Virtue`, `Abuna Acolyte`, `Abuna's Chant`, `Abyssal Hunter`, `Abyssal Specter`, `Abzan Guide`, `Acceptable Losses` |
| `battle_family::triggered_or_static_ability` | 3907 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `_____ _____ Rocketship`, `Aang, at the Crossroads // Aang, Destined Savior`, `Aang, the Last Airbender`, `Abbot of Keral Keep`, `Aberrant Manawurm`, `Abigale, Poet Laureate // Heroic Stanza`, `Aboleth Spawn`, `Abomination`, `Aboroth`, `Absorbing Man` |
| `battle_family::token_creation` | 3633 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `A Killer Among Us`, `Aang and Katara`, `Aang, Airbending Master`, `Aatchik, Emerald Radian`, `Abby, Merciless Soldier`, `Abdel Adrian, Gorion's Ward`, `Abhorrent Overlord`, `Abyssal Harvester`, `Abzan Ascendancy`, `Academy Manufactor` |
| `battle_family::draw_selection_topdeck` | 3488 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Aang's Defense`, `Aang's Iceberg`, `Aberrant`, `Abeyance`, `Abomination of Gudul`, `Abundance`, `Abzan Beastmaster`, `Abzan Charm`, `Academic Dispute`, `Academy Elite` |
| `battle_family::graveyard_recursion` | 1902 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `"Lifetime" Pass Holder`, `A Good Day to Pie`, `Aang, A Lot to Learn`, `Abandon the Post`, `Abandoned Sarcophagus`, `Aberrant Mind Sorcerer`, `Aberrant Researcher // Perfected Form`, `Abhorrent Oculus`, `Abomination of Llanowar`, `Aboshan's Desire` |
| `battle_family::targeted_removal` | 1061 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Absolver Thrull`, `Abstruse Appropriation`, `Acid Web Spider`, `Acidic Slime`, `Act of Authority`, `Active Volcano`, `Admonition Angel`, `Aerial Assault`, `Aerial Predation`, `Aftershock` |
| `battle_family::mana_generation_or_ritual` | 937 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `________ Goblin`, `A Realm Reborn`, `Abstract Paintmage`, `Abundant Growth`, `Abzan Banner`, `Abzan Devotee`, `Accomplished Alchemist`, `Adarkar Unicorn`, `Advanced Reconstruction`, `Aetheric Amplifier` |
| `battle_family::tutor_search_library` | 826 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `A.I.M. Scientists`, `Aang's Journey`, `Absorb Vis`, `Abzan Monument`, `Academy Rector`, `Aerial Surveyor`, `Agency Outfitter`, `Ainok Guide`, `Ajani's Aid`, `Alabaster Host Intercessor` |
| `battle_family::modal_or_choice_effect` | 699 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abandon Hope`, `Abundant Harvest`, `Abzan Advantage`, `Abzan Skycaptain`, `Academic Probation`, `Acquisitions Expert`, `Adaptive Automaton`, `Adaptive Sporesinger`, `Addle`, `Aether Gust` |
| `battle_family::protection_prevention` | 569 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abbey Gargoyles`, `Absolute Grace`, `Absolute Law`, `Adept Watershaper`, `Aegis of the Gods`, `Agent Frank Horrigan`, `Agent of the Shadow Thieves`, `Airtight Alibi`, `Akroma's Memorial`, `Akroma, Angel of Fury` |
| `battle_family::alternate_or_free_cast` | 524 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abundant Maw`, `Acid-Spewer Dragon`, `Adventurous Eater // Have a Bite`, `Aerie Bowmasters`, `Aether Meltdown`, `Aether Searcher`, `Aether Web`, `Affa Guard Hound`, `Ainok Tracker`, `Alley Assailant` |
| `battle_family::recursion_or_bounce` | 495 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abiding Grace`, `Absorb Identity`, `Abuelo's Awakening`, `Academy Journeymage`, `Admiral Brass, Unsinkable`, `Aerith, Last Ancient`, `Aether Adept`, `Aether Helix`, `Aethersnipe`, `Alchemist's Retrieval` |
| `battle_family::counterspell_or_stack_interaction` | 394 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abjure`, `Absorb`, `Abstruse Interference`, `Access Denied`, `Admiral's Order`, `Adric, Mathematical Genius`, `Amazing Acrobatics`, `Anticognition`, `Archmage's Charm`, `Arenson's Aura` |
| `battle_family::copy_spell_or_permanent` | 269 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Abstruse Archaic`, `Adaptive Training Post`, `Aethertow`, `Aeve, Progenitor Ooze`, `Agrus Kos, Eternal Soldier`, `Alania, Divergent Storm`, `All of History, All at Once`, `Archmage of Echoes`, `Ashad, the Lone Cyberman`, `Astral Steel` |

## Top Actionable Cards

| Card | Priority | Lanes | Family | Ready Product QA Decks | Registered QA Decks | XMage |
| --- | ---: | --- | --- | ---: | ---: | --- |
| `A-Alrund's Epiphany` | 1500 | `oracle_data_sync, commander_legality_sync` | `token_creation` | 0 | 16 | `unchecked` |
| `A-Omnath, Locus of Creation` | 1500 | `oracle_data_sync, commander_legality_sync` | `mana_generation_or_ritual` | 0 | 6 | `unchecked` |
| `A-Unholy Heat` | 1500 | `oracle_data_sync, commander_legality_sync` | `damage_or_life_total_change` | 0 | 0 | `unchecked` |
| `Birds of Paradise // Birds of Paradise` | 1250 | `oracle_data_sync, generic_runtime_or_no_card_rule` | `oracle_gap` | 0 | 0 | `unchecked` |
| `Birds of Paradise // Birds of Paradise` | 500 | `oracle_identity_rule_link_or_copy` | `mana_generation_or_ritual` | 0 | 0 | `unchecked` |
| `Sol Ring // Sol Ring` | 500 | `oracle_identity_rule_link_or_copy` | `mana_generation_or_ritual` | 1 | 187 | `unchecked` |
| `"Lifetime" Pass Holder` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 0 | `missing` |
| `+2 Mace` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 18 | `missing` |
| `_____ _____ _____ Trespasser` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `missing` |
| `_____ _____ Rocketship` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 0 | `missing` |
| `_____ Balls of Fire` | 250 | `battle_family_mapper_required` | `damage_or_life_total_change` | 0 | 0 | `missing` |
| `_____ Bird Gets the Worm` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `missing` |
| `_____-o-saurus` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `missing` |
| `________ Goblin` | 250 | `battle_family_mapper_required` | `mana_generation_or_ritual` | 0 | 0 | `missing` |
| `A Good Day to Pie` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 0 | `missing` |
| `A Killer Among Us` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 0 | `available` |
| `A Little Chat` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `available` |
| `A Realm Reborn` | 250 | `battle_family_mapper_required` | `mana_generation_or_ritual` | 0 | 0 | `available` |
| `A Tale for the Ages` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `available` |
| `A.I.M. Scientists` | 250 | `battle_family_mapper_required` | `tutor_search_library` | 0 | 0 | `available` |
| `Aang and Katara` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 6 | `available` |
| `Aang's Defense` | 250 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 16 | `available` |
| `Aang's Iceberg` | 250 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 18 | `available` |
| `Aang's Journey` | 250 | `battle_family_mapper_required` | `tutor_search_library` | 0 | 32 | `available` |
| `Aang, A Lot to Learn` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 11 | `available` |
| `Aang, Air Nomad` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 17 | `available` |
| `Aang, Airbending Master` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 16 | `available` |
| `Aang, at the Crossroads // Aang, Destined Savior` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 12 | `available` |
| `Aang, Swift Savior // Aang and La, Ocean's Fury` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 7 | `available` |
| `Aang, the Last Airbender` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 18 | `available` |
| `Aarakocra Sneak` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 18 | `available` |
| `Aatchik, Emerald Radian` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 8 | `available` |
| `Abaddon the Despoiler` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 4 | `available` |
| `Abandon Hope` | 250 | `battle_family_mapper_required` | `modal_or_choice_effect` | 0 | 20 | `available` |
| `Abandon Reason` | 250 | `battle_family_mapper_required` | `damage_or_life_total_change` | 0 | 20 | `available` |
| `Abandon the Post` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 20 | `available` |
| `Abandoned Sarcophagus` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 28 | `available` |
| `Abattoir Ghoul` | 250 | `battle_family_mapper_required` | `damage_or_life_total_change` | 0 | 18 | `available` |
| `Abbey Gargoyles` | 250 | `battle_family_mapper_required` | `protection_prevention` | 0 | 13 | `available` |
| `Abbot of Keral Keep` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 19 | `available` |
| `Abby, Merciless Soldier` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 9 | `available` |
| `Abdel Adrian, Gorion's Ward` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 18 | `available` |
| `Abduction` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 15 | `available` |
| `Aberrant` | 250 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 14 | `available` |
| `Aberrant Manawurm` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 0 | `available` |
| `Aberrant Mind Sorcerer` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 17 | `available` |
| `Aberrant Researcher // Perfected Form` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 15 | `available` |
| `Abeyance` | 250 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 17 | `available` |
| `Abhorrent Oculus` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 13 | `available` |
| `Abhorrent Overlord` | 250 | `battle_family_mapper_required` | `token_creation` | 0 | 19 | `available` |
| `Abiding Grace` | 250 | `battle_family_mapper_required` | `recursion_or_bounce` | 0 | 16 | `available` |
| `Abigale, Poet Laureate // Heroic Stanza` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 0 | `available` |
| `Abjure` | 250 | `battle_family_mapper_required` | `counterspell_or_stack_interaction` | 0 | 17 | `available` |
| `Abnormal Endurance` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 19 | `available` |
| `Aboleth Spawn` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 15 | `available` |
| `Abominable Treefolk` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 12 | `available` |
| `Abomination` | 250 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 15 | `available` |
| `Abomination of Gudul` | 250 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 7 | `available` |
| `Abomination of Llanowar` | 250 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 10 | `available` |
| `Abomination, Terrifying Titan` | 250 | `battle_family_mapper_required` | `manual_model_review` | 0 | 0 | `available` |

## Method Notes

- Scope is every PostgreSQL `cards` row, not only Lorehold or saved decks.
- Current registered deck usage is an internal QA seed only; it is not a user-demand or launch-priority signal.
- Oracle and legalities gaps should be handled in bulk before battle-family work.
- Battle work should be pulled by `battle_family::*` batches, not card-by-card.
- Broad XMage availability is routing evidence only; it is not executable PostgreSQL truth.
- Cards classified as generic runtime/no card rule are not automatically blockers.
