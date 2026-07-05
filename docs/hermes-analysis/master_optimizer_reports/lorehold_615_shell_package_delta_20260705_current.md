# Lorehold 615 Shell Package Delta

Generated at: `2026-07-05T15:21:09.378474+00:00`
Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
Battle report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8.json`

## Decision

- Status: `615_positive_battle_signal_requires_power_bracket_review_and_repeat_gate`.
- Promotion ready from this report: `False`.
- Baseline 607 modified: `False`.
- PostgreSQL writes performed: `False`.
- Deck materialization performed: `False`.

## Battle Signal

| deck | wins | losses | win_rate | avg_win_turn | strategy_score | primary_risks |
| --- | --- | --- | --- | --- | --- | --- |
| 607 | 11 | 21 | 34.38 | 18.73 | 139.038 | draw_role, recursion_role, tutor_role |
| 615 | 14 | 18 | 43.75 | 15.29 | 134.67 | removal_role, recursion_role, tutor_role |

Win delta 615 minus 607: `3`.
Average win-turn delta 615 minus 607: `-3.44`.
Opponent seed: `20260705`. Simulation seed: `20260705`.

## Deck Delta

- 607 unique rows/quantity: `94` / `100`.
- 615 unique rows/quantity: `84` / `100`.
- Added quantity into 615: `57` across `49` cards or quantity shifts.
- Removed quantity from 607: `57` across `57` cards or quantity shifts.

## Official Power Watch

| card | quantity | package | reason |
| --- | --- | --- | --- |
| Mana Vault | 1 | fast_mana_burst | Wizards Commander Brackets Beta lists it as an extremely powerful fast-mana Game Changer. |
| The One Ring | 1 | resource_engine_card_advantage | Wizards Commander Brackets Beta lists it as overwhelming resource advantage. |
| Underworld Breach | 1 | spell_chain_conversion | Wizards Commander Brackets Beta lists it as a combo/storm Game Changer. |

Shared power-watch cards already present in both shells:
| card | quantity | reason |
| --- | --- | --- |
| Farewell | 1 | Wizards Commander Brackets Beta update on 2026-02-09 added it to Game Changers. |

Research sources:

- https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta
- https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026
- https://mtgcommander.net/index.php/banned-list/

## 615 Added Package Groups

| package | quantity | cards | observed_event_total | observed_cards |
| --- | --- | --- | --- | --- |
| mana base power shift | 16 | Boseiju, Who Shelters All, Cavern of Souls, Clifftop Retreat, Mountain // Mountain x6, Myriad Landscape, Plains // Plains x4, Plateau, Sundown Pass | 169 | Boseiju, Who Shelters All, Cavern of Souls, Clifftop Retreat, Mountain // Mountain, Myriad Landscape, Plains // Plains, Plateau, Sundown Pass |
| resource engine / card advantage | 11 | Apex of Power, Enlightened Tutor, Faithless Looting, Galvanoth, Gamble, Heroes Remembered, Olórin's Searing Light, Single Combat, +3 more | 208 | Apex of Power, Enlightened Tutor, Faithless Looting, Galvanoth, Gamble, Heroes Remembered, Olórin's Searing Light, Single Combat, +3 more |
| pressure and deterministic finishers | 7 | Beacon of Immortality, Goliath Daydreamer, Guttersnipe, Longshot, Rebel Bowman, Perch Protection, Rite of the Dragoncaller, Twinflame Tyrant | 99 | Beacon of Immortality, Goliath Daydreamer, Guttersnipe, Longshot, Rebel Bowman, Perch Protection, Rite of the Dragoncaller, Twinflame Tyrant |
| protection window | 7 | Boros Charm, Deflecting Palm, Grand Abolisher, Mithril Coat, Red Elemental Blast, Reprieve, Silence | 83 | Boros Charm, Deflecting Palm, Grand Abolisher, Mithril Coat, Silence |
| spell chain conversion | 7 | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Double Vision, Flare of Duplication, Flashback, Invoke Calamity, Reiterate, Underworld Breach | 155 | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Double Vision, Flare of Duplication, Flashback, Invoke Calamity, Reiterate, Underworld Breach |
| fast mana / burst ramp | 5 | Brass's Bounty, Goldspan Dragon, Mana Vault, Primal Amulet // Primal Wellspring, Seething Song | 59 | Brass's Bounty, Goldspan Dragon, Mana Vault, Primal Amulet // Primal Wellspring, Seething Song |
| interaction / meta answers | 4 | Chaos Warp, Erode, Lightning Bolt, Vandalblast | 121 | Chaos Warp, Erode, Lightning Bolt, Vandalblast |

## 607 Removed Package Groups

| package | quantity | cards | 607_observed_event_total | 607_observed_cards |
| --- | --- | --- | --- | --- |
| mana base removed from 607 | 16 | Battlefield Forge, Bloodstained Mire, Eiganjo, Seat of the Empire, Elegant Parlor, Exotic Orchard, Flooded Strand, Glittering Massif, Marsh Flats, +8 more | 135 | Battlefield Forge, Bloodstained Mire, Eiganjo, Seat of the Empire, Elegant Parlor, Exotic Orchard, Flooded Strand, Marsh Flats, Plaza of Heroes, +7 more |
| protection window removed from 607 | 9 | Avatar's Wrath, Dawn's Truce, Emeria's Call // Emeria, Shattered Skyclave, Flawless Maneuver, Giver of Runes, Mother of Runes, Redirect Lightning, Swiftfoot Boots, +1 more | 88 | Avatar's Wrath, Dawn's Truce, Emeria's Call // Emeria, Shattered Skyclave, Flawless Maneuver, Giver of Runes, Mother of Runes, Redirect Lightning, Swiftfoot Boots |
| cost reduction/ramp removed from 607 | 7 | Boros Signet, Fellwar Stone, Pearl Medallion, Ruby Medallion, Talisman of Conviction, The Scarlet Witch, Victory Chimes | 151 | Boros Signet, Fellwar Stone, Pearl Medallion, Ruby Medallion, Talisman of Conviction, The Scarlet Witch, Victory Chimes |
| interaction removed from 607 | 6 | Generous Gift, High Noon, Path to Exile, Stroke of Midnight, Thor, God of Thunder, Winds of Abandon | 96 | Generous Gift, High Noon, Path to Exile, Stroke of Midnight, Thor, God of Thunder, Winds of Abandon |
| spell value removed from 607 | 6 | Artist's Talent, Creative Technique, Hit the Mother Lode, Improvisation Capstone, Molecule Man, Pinnacle Monk // Mystic Peak | 91 | Artist's Talent, Creative Technique, Hit the Mother Lode, Improvisation Capstone, Molecule Man, Pinnacle Monk // Mystic Peak |
| board control shift | 5 | Blasphemous Act, Everything Comes to Dust, Fated Clash, Promise of Loyalty, Tragic Arrogance | 81 | Blasphemous Act, Everything Comes to Dust, Fated Clash, Promise of Loyalty, Tragic Arrogance |
| finisher pressure removed from 607 | 5 | Furygale Flocking, Prismari Pianist, Storm Herd, Surge to Victory, Tempt with Bunnies | 106 | Furygale Flocking, Prismari Pianist, Storm Herd, Surge to Victory, Tempt with Bunnies |
| topdeck access removed from 607 | 3 | Bender's Waterskin, Scroll Rack, The Mind Stone | 128 | Bender's Waterskin, Scroll Rack, The Mind Stone |

## Top Observed 615 Added Cards

| card | event_total | events |
| --- | --- | --- |
| Mountain // Mountain | 66 | land_played:66 |
| Plains // Plains | 58 | land_played:58 |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 42 | cost_paid:7, spell_cast:7, trigger_resolved:28 |
| The One Ring | 42 | cost_paid:10, spell_cast:10, spell_resolved:6, utility_artifact_activated:16 |
| Lightning Bolt | 35 | cost_paid:8, miracle_cast:5, spell_cast:8, spell_resolved:14 |
| Guttersnipe | 33 | cost_paid:6, trigger_resolved:27 |
| Deflecting Palm | 32 | cost_paid:7, miracle_cast:4, spell_cast:7, spell_resolved:14 |
| Flashback | 32 | cost_paid:3, miracle_cast:6, recursion_resolved:10, spell_cast:3, spell_resolved:10 |
| Erode | 30 | cost_paid:6, miracle_cast:2, removal_resolved:8, spell_cast:6, spell_resolved:8 |
| Vandalblast | 30 | cost_paid:6, miracle_cast:2, removal_resolved:8, spell_cast:6, spell_resolved:8 |
| Gamble | 29 | cost_paid:9, spell_cast:9, spell_resolved:11 |
| Enlightened Tutor | 27 | cost_paid:8, miracle_cast:1, spell_cast:8, spell_resolved:10 |

## Strategic Event Deltas

| event | 607 | 615 | delta |
| --- | --- | --- | --- |
| static_cost_reduction_total | 99 | 1 | -98 |
| static_cost_reduction_casts | 49 | 1 | -48 |
| lorehold_cost_paid | 377 | 338 | -39 |
| lorehold_spell_cast | 324 | 292 | -32 |
| birgi_spell_cast_mana | 0 | 28 | 28 |
| spell_cast_mana_trigger | 0 | 28 | 28 |
| lorehold_upkeep_rummage | 111 | 138 | 27 |
| miracle_cast | 62 | 86 | 24 |
| scarlet_static_cost_reduction_total | 24 | 0 | -24 |
| discard_to_top_replacement | 17 | 39 | 22 |
| lorehold_rummage_discard_to_top | 17 | 39 | 22 |
| lorehold_spell_rummage | 16 | 0 | -16 |
| thor_noncreature_damage_amount | 14 | 0 | -14 |
| scarlet_static_cost_reduction_casts | 12 | 0 | -12 |
| topdeck_manipulation_activated | 76 | 70 | -6 |
| thor_cost_paid | 3 | 0 | -3 |
| thor_noncreature_damage | 3 | 0 | -3 |

## Guardrail

This report treats 615 as a whole-shell learning signal, not as an automatic replacement for protected deck 607. A promotion still needs repeat/opponent-rotated battle evidence plus explicit review of the official power-watch cards introduced by the 615 shell.
