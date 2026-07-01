# Global Card Adaptation Acceleration Model

- Generated at: `2026-07-01T02:59:53+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

## Core Finding

The all-card adaptation cannot be managed as one PostgreSQL row per card.
The correct unit is identity/template/family, with deck usage used only as priority.

## Scope Compression

| Scope | Rows | Unique Names | Unique Oracle IDs |
| --- | ---: | ---: | ---: |
| `all_cards` | 34331 | 34071 | 34077 |
| `commander_legal` | 31334 | 31101 | 31099 |
| `used_in_any_deck` | 2479 | 2400 | 2396 |
| `ready_product` | 818 | 808 | 807 |

## Battle Gap Compression

| Metric | Value |
| --- | ---: |
| `row_count` | 31772 |
| `unique_names` | 31713 |
| `unique_oracle_ids` | 31725 |
| `commander_legal_rows` | 28869 |
| `commander_legal_unique_names` | 28835 |
| `used_deck_rows` | 1511 |
| `used_deck_unique_names` | 1511 |
| `ready_product_rows` | 232 |
| `ready_product_unique_names` | 232 |

## Work Unit Comparison

| Model | Units |
| --- | ---: |
| Card row one-by-one | 31772 |
| Normalized name identity | 31713 |
| Current used-deck identity first | 1511 |
| Ready-product identity first | 232 |
| Template + residual family first | 28 |
| Row-to-used compression | 21.03x |
| Row-to-template/family compression | 1134.71x |

## Template-First Coverage

- Template count: `13`
- Matched rows: `10285`
- Matched unique names: `10263`
- Matched used-deck unique names: `644`
- Used-gap coverage ratio: `0.4262`

| Template | Rows | Names | Used Deck Rows | Ready Product Rows | Confidence | Runtime Unit | Samples |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| `draw_fixed_cards` | 2802 | 2801 | 204 | 34 | `template_candidate` | card draw resolver | `Auntie Ool, Cursewretch`, `Jin-Gitaxias // The Great Synthesis`, `Ponder`, `Sythis, Harvest's Hand`, `Korvold, Fae-Cursed King`, `Phyrexian Arena` |
| `create_fixed_tokens` | 2955 | 2949 | 171 | 11 | `template_candidate` | fixed token creation with parsed token body | `Talrand, Sky Summoner`, `Edgar Markov`, `Prosper, Tome-Bound`, `Miirym, Sentinel Wyrm`, `Wilhelt, the Rotcleaver`, `Seize the Spoils` |
| `add_mana_static_or_activated` | 846 | 832 | 74 | 15 | `template_candidate` | mana-source production from activated/ritual text | `Talisman of Hierarchy`, `Rakdos Signet`, `Orzhov Signet`, `Misleading Signpost`, `Gyre Sage`, `The Great Henge` |
| `destroy_target_permanent` | 604 | 604 | 41 | 4 | `template_candidate` | targeted permanent destruction by target type | `Withering Torment`, `Infernal Grasp`, `Terminate`, `Rakdos Charm`, `Suspended Sentence`, `Goblin Trashmaster` |
| `counter_target_spell` | 307 | 307 | 38 | 1 | `template_candidate` | single target stack counter resolver | `Kozilek, the Great Distortion`, `Rewind`, `Cryptic Command`, `Cancel`, `Dispel`, `Spell Snare` |
| `direct_damage_fixed_amount` | 1020 | 1020 | 36 | 4 | `template_candidate` | fixed/direct damage resolver with target selector | `Syr Konrad, the Grim`, `Dragon Tempest`, `Mayhem Devil`, `Brallin, Skyshark Rider`, `Boggart Shenanigans`, `Outpost Siege` |
| `exile_target_permanent` | 274 | 274 | 16 | 2 | `template_candidate` | targeted exile by target type | `Anguished Unmaking`, `Reality Shift`, `Teferi's Time Twist`, `Abstruse Appropriation`, `Cloudshift`, `Despark` |
| `scry_or_surveil_fixed` | 378 | 378 | 14 | 1 | `template_candidate` | topdeck selection/reorder resolver | `Burning Prophet`, `Viscera Seer`, `Jace's Sanctum`, `Dawnhand Dissident`, `Aang's Iceberg`, `A-Dragon's Rage Channeler` |
| `search_library_basic_land` | 268 | 268 | 14 | 0 | `template_candidate` | land tutor/search and zone movement | `Kodama's Reach`, `Aang's Journey`, `Absorb Vis`, `Sword of the Animist`, `Wight of the Reliquary`, `Thirsting Roots` |
| `return_target_from_graveyard` | 430 | 430 | 12 | 2 | `template_candidate` | graveyard target return by destination | `Forge Anew`, `Whip of Erebos`, `Unnatural Restoration`, `Abiding Grace`, `Abuelo's Awakening`, `Artisan of Kozilek` |
| `search_library_card_to_hand` | 185 | 185 | 12 | 3 | `split_required_candidate` | typed tutor/search to hand/top/battlefield after exact destination split | `Razaketh, the Foulblooded`, `Rune-Scarred Demon`, `Birthing Pod`, `Muddle the Mixture`, `Buried Alive`, `Sterling Grove` |
| `protection_hexproof_indestructible_until_eot` | 142 | 142 | 8 | 1 | `template_candidate` | temporary protection shield | `Temur Sabertooth`, `Yahenni, Undying Partisan`, `Alseid of Life's Bounty`, `Hajar, Loyal Bodyguard`, `A-Winota, Joiner of Forces`, `Fascist Art Director` |
| `life_gain_or_loss_fixed_amount` | 74 | 74 | 4 | 1 | `template_candidate` | life total delta resolver | `Bloodchief Ascension`, `Obelisk Spider`, `Abuna's Chant`, `Crovax`, `Tamiyo's Safekeeping`, `Alabaster Potion` |

## Residual Families After Templates

| Family | Rows |
| --- | ---: |
| `manual_model_review` | 7988 |
| `triggered_or_static_ability` | 3907 |
| `damage_or_life_total_change` | 3128 |
| `graveyard_recursion` | 2023 |
| `token_creation` | 740 |
| `modal_or_choice_effect` | 699 |
| `alternate_or_free_cast` | 525 |
| `draw_selection_topdeck` | 520 |
| `protection_prevention` | 450 |
| `targeted_removal` | 421 |
| `tutor_search_library` | 390 |
| `copy_spell_or_permanent` | 277 |
| `recursion_or_bounce` | 170 |
| `mana_generation_or_ritual` | 144 |
| `counterspell_or_stack_interaction` | 105 |

## Required Execution Order

- Do not adapt 34331 card rows one by one.
- First close hash/data-only and true oracle alias gaps.
- Then implement top template resolvers that hit used deck cards.
- Then split residual high-volume families with XMage source evidence.
- Only after product/used queues are green should unused Commander-legal residuals be scheduled.
