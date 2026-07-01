# Global Card Adaptation Acceleration Model

- Generated at: `2026-07-01T03:14:03+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

## Core Finding

The all-card adaptation cannot be managed as one PostgreSQL row per card.
The correct unit is identity/template/family, ordered by global Commander-legal breadth.
Current registered deck usage is an internal QA seed only, not a demand signal.

## Scope Compression

| Scope | Rows | Unique Names | Unique Oracle IDs |
| --- | ---: | ---: | ---: |
| `all_cards` | 34331 | 34071 | 34077 |
| `commander_legal` | 31334 | 31101 | 31099 |
| `external_popularity_signal` | 738 | 588 | 588 |
| `current_registered_deck_qa_seed` | 2479 | 2400 | 2396 |
| `ready_product_qa_seed` | 818 | 808 | 807 |

## Battle Gap Compression

| Metric | Value |
| --- | ---: |
| `row_count` | 31772 |
| `unique_names` | 31713 |
| `unique_oracle_ids` | 31725 |
| `commander_legal_rows` | 28869 |
| `commander_legal_unique_names` | 28835 |
| `external_popularity_rows` | 345 |
| `external_popularity_unique_names` | 345 |
| `registered_deck_qa_rows` | 1511 |
| `registered_deck_qa_unique_names` | 1511 |
| `ready_product_qa_rows` | 232 |
| `ready_product_qa_unique_names` | 232 |

## Work Unit Comparison

| Model | Units |
| --- | ---: |
| Card row one-by-one | 31772 |
| Normalized name identity | 31713 |
| Commander-legal identity scope | 28835 |
| External popularity identity signal | 345 |
| Current registered-deck QA seed | 1511 |
| Ready-product QA seed | 232 |
| Template + residual family first | 28 |
| Row-to-Commander-legal compression | 1.1x |
| Row-to-template/family compression | 1134.71x |

## Template-First Coverage

- Template count: `13`
- Matched rows: `10285`
- Matched unique names: `10263`
- Matched Commander-legal unique names: `9386`
- Commander-legal gap coverage ratio: `0.3255`
- Matched external-popularity unique names: `218`
- External-popularity gap coverage ratio: `0.6319`
- Matched registered-deck QA unique names: `644`
- Registered-deck QA gap coverage ratio: `0.4262`

| Template | Rows | Names | Commander Legal Rows | External Popularity Rows | Registered Deck QA Rows | Ready Product QA Rows | Confidence | Runtime Unit | Samples |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| `create_fixed_tokens` | 2955 | 2949 | 2640 | 28 | 171 | 11 | `template_candidate` | fixed token creation with parsed token body | `A Killer Among Us`, `Aang, Airbending Master`, `Aatchik, Emerald Radian`, `Abby, Merciless Soldier`, `Abdel Adrian, Gorion's Ward`, `Abhorrent Overlord` |
| `draw_fixed_cards` | 2802 | 2801 | 2570 | 68 | 204 | 34 | `template_candidate` | card draw resolver | `Aang's Defense`, `Aberrant`, `Abeyance`, `Abomination of Gudul`, `Abundance`, `Abzan Beastmaster` |
| `direct_damage_fixed_amount` | 1020 | 1020 | 952 | 4 | 36 | 4 | `template_candidate` | fixed/direct damage resolver with target selector | `Acceptable Losses`, `Acidic Sliver`, `Aeolipile`, `Aethertorch Renegade`, `Agonizing Syphon`, `Ajani Vengeant` |
| `add_mana_static_or_activated` | 846 | 832 | 740 | 19 | 74 | 15 | `template_candidate` | mana-source production from activated/ritual text | `________ Goblin`, `A Realm Reborn`, `Abstract Paintmage`, `Abundant Growth`, `Abzan Banner`, `Abzan Devotee` |
| `destroy_target_permanent` | 604 | 604 | 565 | 33 | 41 | 4 | `template_candidate` | targeted permanent destruction by target type | `Abolish`, `Absolver Thrull`, `Acidic Slime`, `Aerial Predation`, `Aftershock`, `Ainok Survivalist` |
| `return_target_from_graveyard` | 430 | 430 | 400 | 1 | 12 | 2 | `template_candidate` | graveyard target return by destination | `Abiding Grace`, `Abuelo's Awakening`, `Admiral Brass, Unsinkable`, `Adun Oakenshield`, `Aerith, Last Ancient`, `Aether Helix` |
| `scry_or_surveil_fixed` | 378 | 378 | 356 | 3 | 14 | 1 | `template_candidate` | topdeck selection/reorder resolver | `Aang's Iceberg`, `Aether Theorist`, `Aminatou, Veil Piercer`, `Anchor to the Aether`, `Appendage Amalgam`, `April O'Neil, Kunoichi Trainee` |
| `counter_target_spell` | 307 | 307 | 297 | 37 | 38 | 1 | `template_candidate` | single target stack counter resolver | `Abjure`, `Absorb`, `Abstruse Interference`, `Access Denied`, `Admiral's Order`, `Amazing Acrobatics` |
| `exile_target_permanent` | 274 | 274 | 248 | 14 | 16 | 2 | `template_candidate` | targeted exile by target type | `Abstruse Appropriation`, `Act of Authority`, `Admonition Angel`, `Against All Odds`, `Agate Assault`, `Ajani Unyielding` |
| `search_library_basic_land` | 268 | 268 | 244 | 6 | 14 | 0 | `template_candidate` | land tutor/search and zone movement | `A.I.M. Scientists`, `Aang's Journey`, `Absorb Vis`, `Ainok Guide`, `Ancient Excavation`, `Armillary Sphere` |
| `search_library_card_to_hand` | 185 | 185 | 167 | 3 | 12 | 3 | `split_required_candidate` | typed tutor/search to hand/top/battlefield after exact destination split | `Academy Rector`, `Alpine Houndmaster`, `Altar of Bone`, `Angel's Herald`, `Archmage Ascension`, `Artificer's Intuition` |
| `protection_hexproof_indestructible_until_eot` | 142 | 142 | 139 | 2 | 8 | 1 | `template_candidate` | temporary protection shield | `Airtight Alibi`, `Alseid of Life's Bounty`, `And They Shall Know No Fear`, `Aquitect's Defenses`, `Archangel Avacyn // Avacyn, the Purifier`, `Armored Guardian` |
| `life_gain_or_loss_fixed_amount` | 74 | 74 | 73 | 0 | 4 | 1 | `template_candidate` | life total delta resolver | `Abuna's Chant`, `Alabaster Potion`, `Ancestor's Chosen`, `Atalya, Samite Master`, `Ayara, Widow of the Realm // Ayara, Furnace Queen`, `Balm of Restoration` |

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
- Then implement top template resolvers by global Commander-legal breadth.
- Use external popularity/staple signals as secondary ordering when available.
- Use current registered decks only as QA smoke seeds, not as demand priority.
- Then split residual high-volume families with XMage source evidence.
- Only after template/family coverage is green should card-specific exceptions be scheduled.
