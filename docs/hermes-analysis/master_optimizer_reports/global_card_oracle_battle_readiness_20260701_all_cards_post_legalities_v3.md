# Global All-Card Oracle Battle Readiness

- Generated at: `2026-07-01T02:50:58.948261+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- All known cards: `34331`
- Used in any deck unique cards: `2479`
- Ready-product unique cards: `818`

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
| `card_intelligence_snapshot` | `snapshot_has_any_rule` | 3303 |
| `card_intelligence_snapshot` | `snapshot_has_verified_rule` | 1923 |

## Routing Adjustments

| Metric | Value |
| --- | ---: |
| `empty_oracle_text_generic_candidates` | 360 |
| `oracle_text_empty_but_not_oracle_data_sync` | 359 |

## Lane Counts

| Lane | All Known Cards | Ready Product Cards |
| --- | ---: | ---: |
| `battle_and_oracle_ready` | 788 | 387 |
| `battle_family_mapper_required` | 31772 | 232 |
| `commander_illegal_block` | 2994 | 0 |
| `commander_legality_sync` | 3 | 0 |
| `generic_runtime_or_no_card_rule` | 360 | 0 |
| `oracle_data_sync` | 4 | 0 |
| `oracle_identity_rule_link_or_copy` | 2 | 1 |
| `trusted_rule_oracle_hash_backfill` | 1406 | 198 |

## Battle Gap Families

| Family | Cards |
| --- | ---: |
| `manual_model_review` | 7988 |
| `damage_or_life_total_change` | 4222 |
| `triggered_or_static_ability` | 3907 |
| `draw_selection_topdeck` | 3700 |
| `token_creation` | 3695 |
| `graveyard_recursion` | 2023 |
| `targeted_removal` | 1299 |
| `mana_generation_or_ritual` | 990 |
| `tutor_search_library` | 843 |
| `modal_or_choice_effect` | 699 |
| `recursion_or_bounce` | 600 |
| `protection_prevention` | 592 |
| `alternate_or_free_cast` | 525 |
| `counterspell_or_stack_interaction` | 412 |
| `copy_spell_or_permanent` | 277 |

## Recommended Batches

| Batch | Cards | Method | Top Cards |
| --- | ---: | --- | --- |
| `oracle_bulk_backfill` | 4 | Scryfall bulk/default-cards or targeted exact lookup; update cards only after exact identity match | `A-Omnath, Locus of Creation`, `A-Alrund's Epiphany`, `A-Unholy Heat`, `Birds of Paradise // Birds of Paradise` |
| `commander_legality_gap_sync` | 3 | Scryfall legalities by oracle_id/set_code; fill missing commander status without changing decklists | `A-Omnath, Locus of Creation`, `A-Alrund's Epiphany`, `A-Unholy Heat` |
| `oracle_identity_rule_link_or_copy` | 2 | candidate copy/link from trusted rule on same oracle_id; requires oracle_hash check and focused runtime smoke before PG package | `Sol Ring // Sol Ring`, `Birds of Paradise // Birds of Paradise` |
| `battle_family::manual_model_review` | 7988 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Isshin, Two Heavens as One`, `Ulamog, the Defiler`, `Propaganda // Propaganda`, `Sapphire Medallion`, `Toxic Deluge`, `Delney, Streetwise Lookout`, `Back to Basics`, `Void Winnower`, `Displacement Wave`, `Engulf the Shore` |
| `battle_family::damage_or_life_total_change` | 4222 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Syr Konrad, the Grim`, `Master of Cruelties`, `Bloodthirsty Conqueror`, `Bloodthirster`, `Bloodchief Ascension`, `Basilisk Collar`, `Dragon Tempest`, `Mayhem Devil`, `Bloodletter of Aclazotz`, `Balefire Dragon` |
| `battle_family::triggered_or_static_ability` | 3907 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Atraxa, Praetors' Voice`, `Kaalia of the Vast`, `Sword Coast Sailor`, `Wilson, Refined Grizzly`, `Jodah, the Unifier`, `Exquisite Blood`, `Karlach, Fury of Avernus`, `The Meathook Massacre`, `The Ozolith`, `High Tide` |
| `battle_family::draw_selection_topdeck` | 3700 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Auntie Ool, Cursewretch`, `Jin-Gitaxias // The Great Synthesis`, `Ponder`, `Sythis, Harvest's Hand`, `Korvold, Fae-Cursed King`, `Phyrexian Arena`, `Archfiend of Ifnir`, `Burning Prophet`, `Will of the Jeskai`, `Sea Gate Restoration // Sea Gate, Reborn` |
| `battle_family::token_creation` | 3695 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Talrand, Sky Summoner`, `Krenko, Mob Boss`, `Edgar Markov`, `Prosper, Tome-Bound`, `Miirym, Sentinel Wyrm`, `Wilhelt, the Rotcleaver`, `Beast Within`, `Seize the Spoils`, `Inspired Tinkering`, `Lorehold Command` |
| `battle_family::graveyard_recursion` | 2023 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Muldrotha, the Gravetide`, `Meren of Clan Nel Toth`, `Containment Construct`, `Blightsteel Colossus // Blightsteel Colossus`, `Animate Dead`, `Victimize`, `Angel of Serenity`, `Valgavoth, Terror Eater`, `Seize the Day`, `Afterlife from the Loam` |
| `battle_family::targeted_removal` | 1299 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Tormod's Crypt`, `Withering Torment`, `Anguished Unmaking`, `Infernal Grasp`, `Terminate`, `Reality Shift`, `Rakdos Charm`, `Suspended Sentence`, `Teferi's Time Twist`, `Thor, God of Thunder` |
| `battle_family::mana_generation_or_ritual` | 990 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Talisman of Hierarchy`, `Rakdos Signet`, `Orzhov Signet`, `Misleading Signpost`, `Gyre Sage`, `The Great Henge`, `Kami of Whispered Hopes`, `Automated Artificer`, `Colossal Plow`, `Fabrication Foundry` |
| `battle_family::tutor_search_library` | 843 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Razaketh, the Foulblooded`, `Farseek`, `Merchant Scroll`, `Rune-Scarred Demon`, `Nature's Lore`, `Three Visits`, `Birthing Pod`, `The Seriema`, `Goblin Recruiter`, `Goblin Matron` |
| `battle_family::modal_or_choice_effect` | 699 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Malakir Rebirth // Malakir Mire`, `Sadistic Shell Game`, `Thoughtseize`, `Experimental Augury`, `A-Baleful Beholder`, `Contagion Clasp`, `Abandon Hope`, `Urza's Incubator`, `Drown in Ichor`, `Contagion Engine` |
| `battle_family::recursion_or_bounce` | 600 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Ugin's Binding`, `Wipe Away`, `Forge Anew`, `Soothing of Sméagol`, `Whip of Erebos`, `Unnatural Restoration`, `Absorb Identity`, `Abiding Grace`, `Abuelo's Awakening`, `Seal of Removal` |
| `battle_family::protection_prevention` | 592 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Shadowspear`, `Heroic Intervention`, `Animar, Soul of Elements`, `Avacyn, Angel of Hope`, `Hammer of Nazahn`, `Akroma's Memorial`, `Temur Sabertooth`, `Ulamog, the Ceaseless Hunger // Ulamog, the Ceaseless Hunger`, `Tekuthal, Inquiry Dominus`, `Yahenni, Undying Partisan` |
| `battle_family::alternate_or_free_cast` | 525 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Light Up the Stage`, `Apex Devastator`, `High Fae Trickster`, `Maelstrom Wanderer`, `Conspicuous Snoop`, `Reckless Bushwhacker`, `Korlessa, Scale Singer`, `Gonti, Lord of Luxury`, `Zhulodok, Void Gorger`, `Shimmer Myr` |
| `battle_family::counterspell_or_stack_interaction` | 412 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Kozilek, the Great Distortion`, `Strix Serenade`, `Rewind`, `Cryptic Command`, `Cancel`, `Unwind`, `Dispel`, `Spell Snare`, `Disallow`, `Archmage's Charm` |
| `battle_family::copy_spell_or_permanent` | 277 | XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync | `Mists of Lórien`, `Strionic Resonator`, `Narset's Reversal`, `Abstruse Archaic`, `Thunderclap Drake`, `Weaver of Harmony`, `A-Demilich`, `A-Leyline of Resonance`, `A-Mentor's Guidance`, `A-Rowan, Scholar of Sparks // A-Will, Scholar of Frost` |

## Top Actionable Cards

| Card | Priority | Lanes | Family | Ready Product Decks | Decks | XMage |
| --- | ---: | --- | --- | ---: | ---: | --- |
| `Talrand, Sky Summoner` | 149186 | `battle_family_mapper_required` | `token_creation` | 0 | 466 | `available` |
| `Auntie Ool, Cursewretch` | 35189 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 109 | `available` |
| `Jin-Gitaxias // The Great Synthesis` | 30769 | `battle_family_mapper_required` | `draw_selection_topdeck` | 1 | 89 | `available` |
| `Island // Island` | 24248 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 5 | 339 | `unchecked` |
| `Atraxa, Praetors' Voice` | 20765 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 65 | `available` |
| `Swamp // Swamp` | 20551 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 6 | 313 | `unchecked` |
| `Cavern of Souls` | 19565 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 7 | 265 | `unchecked` |
| `Mana Vault` | 14982 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 6 | 142 | `unchecked` |
| `Wastes` | 14373 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 0 | 130 | `unchecked` |
| `Dragonskull Summit` | 12667 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 5 | 127 | `unchecked` |
| `Silence` | 12147 | `trusted_rule_oracle_hash_backfill` | `manual_model_review` | 6 | 7 | `unchecked` |
| `Krenko, Mob Boss` | 11258 | `battle_family_mapper_required` | `token_creation` | 0 | 98 | `available` |
| `Blood Crypt // Blood Crypt` | 10961 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 4 | 141 | `unchecked` |
| `Kaalia of the Vast` | 10941 | `battle_family_mapper_required` | `triggered_or_static_ability` | 2 | 21 | `available` |
| `Kozilek, the Great Distortion` | 10732 | `battle_family_mapper_required` | `counterspell_or_stack_interaction` | 1 | 92 | `available` |
| `Starting Town` | 10562 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 4 | 122 | `unchecked` |
| `Forest // Forest` | 9780 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 1 | 280 | `unchecked` |
| `Ponder` | 9219 | `battle_family_mapper_required` | `draw_selection_topdeck` | 2 | 239 | `available` |
| `Everflowing Chalice` | 8914 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 234 | `unchecked` |
| `Edgar Markov` | 8867 | `battle_family_mapper_required` | `token_creation` | 0 | 27 | `available` |
| `Isshin, Two Heavens as One` | 8635 | `battle_family_mapper_required` | `manual_model_review` | 1 | 35 | `available` |
| `Path of Ancestry` | 8494 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 214 | `unchecked` |
| `Muldrotha, the Gravetide` | 8225 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 25 | `available` |
| `Boseiju, Who Shelters All` | 8084 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 4 | 4 | `unchecked` |
| `Pinnacle Monk // Mystic Peak` | 8084 | `trusted_rule_oracle_hash_backfill` | `recursion_or_bounce` | 4 | 4 | `unchecked` |
| `Command Tower // Command Tower` | 7917 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 0 | 377 | `unchecked` |
| `Arcane Denial` | 7906 | `trusted_rule_oracle_hash_backfill` | `counterspell_or_stack_interaction` | 2 | 186 | `unchecked` |
| `Prosper, Tome-Bound` | 7904 | `battle_family_mapper_required` | `token_creation` | 0 | 24 | `available` |
| `Godless Shrine` | 7134 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 54 | `unchecked` |
| `Watery Grave` | 6987 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 47 | `unchecked` |
| `Miirym, Sentinel Wyrm` | 6941 | `battle_family_mapper_required` | `token_creation` | 0 | 21 | `available` |
| `Urza, Lord High Artificer` | 6741 | `trusted_rule_oracle_hash_backfill` | `token_creation` | 0 | 21 | `unchecked` |
| `Abstergo Entertainment` | 6688 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 128 | `unchecked` |
| `Sulfurous Springs` | 6672 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 32 | `unchecked` |
| `Brainstorm` | 6620 | `trusted_rule_oracle_hash_backfill` | `draw_selection_topdeck` | 1 | 220 | `unchecked` |
| `Razaketh, the Foulblooded` | 6578 | `battle_family_mapper_required` | `tutor_search_library` | 3 | 18 | `available` |
| `Lazotep Quarry` | 6478 | `trusted_rule_oracle_hash_backfill` | `token_creation` | 2 | 118 | `unchecked` |
| `Talon Gates of Madara` | 6436 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 116 | `unchecked` |
| `Sol Ring // Sol Ring` | 6377 | `oracle_identity_rule_link_or_copy` | `mana_generation_or_ritual` | 1 | 187 | `unchecked` |
| `Meren of Clan Nel Toth` | 6362 | `battle_family_mapper_required` | `graveyard_recursion` | 0 | 22 | `available` |
| `Steam Vents // Steam Vents` | 6357 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 17 | `unchecked` |
| `Farseek` | 6316 | `battle_family_mapper_required` | `tutor_search_library` | 1 | 196 | `available` |
| `Otawara, Soaring City` | 6310 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 110 | `unchecked` |
| `Sword Coast Sailor` | 6299 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 19 | `available` |
| `Sythis, Harvest's Hand` | 6299 | `battle_family_mapper_required` | `draw_selection_topdeck` | 0 | 19 | `available` |
| `Wilson, Refined Grizzly` | 6299 | `battle_family_mapper_required` | `triggered_or_static_ability` | 0 | 19 | `available` |
| `Pongify` | 6284 | `trusted_rule_oracle_hash_backfill` | `token_creation` | 1 | 204 | `unchecked` |
| `Containment Construct` | 6263 | `battle_family_mapper_required` | `graveyard_recursion` | 3 | 3 | `available` |
| `Rogue's Passage` | 6226 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 2 | 106 | `unchecked` |
| `Boros Garrison` | 6126 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 6 | `unchecked` |
| `Gemstone Caverns` | 6126 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 6 | `unchecked` |
| `Valakut Awakening // Valakut Stoneforge` | 6126 | `trusted_rule_oracle_hash_backfill` | `draw_selection_topdeck` | 3 | 6 | `unchecked` |
| `Shattered Sanctum` | 6084 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 4 | `unchecked` |
| `Helm of Awakening` | 6063 | `trusted_rule_oracle_hash_backfill` | `manual_model_review` | 3 | 3 | `unchecked` |
| `Ornithopter of Paradise` | 6063 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 3 | `unchecked` |
| `Raucous Theater` | 6063 | `trusted_rule_oracle_hash_backfill` | `mana_generation_or_ritual` | 3 | 3 | `unchecked` |
| `Manifold Key` | 6016 | `trusted_rule_oracle_hash_backfill` | `manual_model_review` | 2 | 96 | `unchecked` |
| `Mystic Forge` | 5932 | `trusted_rule_oracle_hash_backfill` | `alternate_or_free_cast` | 2 | 92 | `unchecked` |
| `Inventors' Fair` | 5848 | `trusted_rule_oracle_hash_backfill` | `tutor_search_library` | 2 | 88 | `unchecked` |
| `Ulamog, the Defiler` | 5838 | `battle_family_mapper_required` | `manual_model_review` | 2 | 78 | `available` |

## Method Notes

- Scope is every PostgreSQL `cards` row, not only Lorehold or saved decks.
- Oracle and legalities gaps should be handled in bulk before battle-family work.
- Battle work should be pulled by `battle_family::*` batches, not card-by-card.
- Broad XMage availability is routing evidence only; it is not executable PostgreSQL truth.
- Cards classified as generic runtime/no card rule are not automatically blockers.
