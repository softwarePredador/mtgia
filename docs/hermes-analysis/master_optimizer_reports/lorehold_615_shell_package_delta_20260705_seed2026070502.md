# Lorehold 615 Shell Package Delta

Generated at: `2026-07-05T15:23:15.091763+00:00`
Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
Battle report: `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8_seed2026070502.json`

## Decision

- Status: `keep_607_protected_baseline`.
- Promotion ready from this report: `False`.
- Baseline 607 modified: `False`.
- PostgreSQL writes performed: `False`.
- Deck materialization performed: `False`.

## Battle Signal

| deck | wins | losses | win_rate | avg_win_turn | strategy_score | primary_risks |
| --- | --- | --- | --- | --- | --- | --- |
| 607 | 12 | 20 | 37.5 | 15.75 | 139.038 | draw_role, recursion_role, tutor_role |
| 615 | 8 | 24 | 25.0 | 11.0 | 134.67 | removal_role, recursion_role, tutor_role |

Win delta 615 minus 607: `-4`.
Average win-turn delta 615 minus 607: `-4.75`.
Opponent seed: `2026070502`. Simulation seed: `2026070502`.

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
| mana base power shift | 16 | Boseiju, Who Shelters All, Cavern of Souls, Clifftop Retreat, Mountain // Mountain x6, Myriad Landscape, Plains // Plains x4, Plateau, Sundown Pass | 158 | Boseiju, Who Shelters All, Cavern of Souls, Clifftop Retreat, Mountain // Mountain, Myriad Landscape, Plains // Plains, Plateau, Sundown Pass |
| resource engine / card advantage | 11 | Apex of Power, Enlightened Tutor, Faithless Looting, Galvanoth, Gamble, Heroes Remembered, Olórin's Searing Light, Single Combat, +3 more | 166 | Apex of Power, Enlightened Tutor, Faithless Looting, Galvanoth, Gamble, Heroes Remembered, Olórin's Searing Light, Single Combat, +2 more |
| pressure and deterministic finishers | 7 | Beacon of Immortality, Goliath Daydreamer, Guttersnipe, Longshot, Rebel Bowman, Perch Protection, Rite of the Dragoncaller, Twinflame Tyrant | 57 | Beacon of Immortality, Goliath Daydreamer, Guttersnipe, Longshot, Rebel Bowman, Perch Protection, Rite of the Dragoncaller |
| protection window | 7 | Boros Charm, Deflecting Palm, Grand Abolisher, Mithril Coat, Red Elemental Blast, Reprieve, Silence | 66 | Boros Charm, Deflecting Palm, Grand Abolisher, Mithril Coat, Silence |
| spell chain conversion | 7 | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Double Vision, Flare of Duplication, Flashback, Invoke Calamity, Reiterate, Underworld Breach | 133 | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Double Vision, Flare of Duplication, Flashback, Invoke Calamity, Reiterate, Underworld Breach |
| fast mana / burst ramp | 5 | Brass's Bounty, Goldspan Dragon, Mana Vault, Primal Amulet // Primal Wellspring, Seething Song | 42 | Brass's Bounty, Goldspan Dragon, Mana Vault, Primal Amulet // Primal Wellspring, Seething Song |
| interaction / meta answers | 4 | Chaos Warp, Erode, Lightning Bolt, Vandalblast | 94 | Chaos Warp, Erode, Lightning Bolt, Vandalblast |

## 607 Removed Package Groups

| package | quantity | cards | 607_observed_event_total | 607_observed_cards |
| --- | --- | --- | --- | --- |
| mana base removed from 607 | 16 | Battlefield Forge, Bloodstained Mire, Eiganjo, Seat of the Empire, Elegant Parlor, Exotic Orchard, Flooded Strand, Glittering Massif, Marsh Flats, +8 more | 128 | Battlefield Forge, Bloodstained Mire, Eiganjo, Seat of the Empire, Elegant Parlor, Exotic Orchard, Flooded Strand, Glittering Massif, Marsh Flats, +8 more |
| protection window removed from 607 | 9 | Avatar's Wrath, Dawn's Truce, Emeria's Call // Emeria, Shattered Skyclave, Flawless Maneuver, Giver of Runes, Mother of Runes, Redirect Lightning, Swiftfoot Boots, +1 more | 79 | Avatar's Wrath, Dawn's Truce, Emeria's Call // Emeria, Shattered Skyclave, Flawless Maneuver, Giver of Runes, Mother of Runes, Swiftfoot Boots |
| cost reduction/ramp removed from 607 | 7 | Boros Signet, Fellwar Stone, Pearl Medallion, Ruby Medallion, Talisman of Conviction, The Scarlet Witch, Victory Chimes | 143 | Boros Signet, Fellwar Stone, Pearl Medallion, Ruby Medallion, Talisman of Conviction, The Scarlet Witch, Victory Chimes |
| interaction removed from 607 | 6 | Generous Gift, High Noon, Path to Exile, Stroke of Midnight, Thor, God of Thunder, Winds of Abandon | 154 | Generous Gift, High Noon, Path to Exile, Stroke of Midnight, Thor, God of Thunder, Winds of Abandon |
| spell value removed from 607 | 6 | Artist's Talent, Creative Technique, Hit the Mother Lode, Improvisation Capstone, Molecule Man, Pinnacle Monk // Mystic Peak | 95 | Artist's Talent, Creative Technique, Hit the Mother Lode, Improvisation Capstone, Molecule Man, Pinnacle Monk // Mystic Peak |
| board control shift | 5 | Blasphemous Act, Everything Comes to Dust, Fated Clash, Promise of Loyalty, Tragic Arrogance | 53 | Blasphemous Act, Everything Comes to Dust, Promise of Loyalty, Tragic Arrogance |
| finisher pressure removed from 607 | 5 | Furygale Flocking, Prismari Pianist, Storm Herd, Surge to Victory, Tempt with Bunnies | 73 | Furygale Flocking, Prismari Pianist, Storm Herd, Surge to Victory, Tempt with Bunnies |
| topdeck access removed from 607 | 3 | Bender's Waterskin, Scroll Rack, The Mind Stone | 91 | Bender's Waterskin, Scroll Rack, The Mind Stone |

## Top Observed 615 Added Cards

| card | event_total | events |
| --- | --- | --- |
| Mountain // Mountain | 74 | land_played:74 |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 47 | cost_paid:5, spell_cast:5, trigger_resolved:37 |
| Plains // Plains | 47 | land_played:47 |
| The One Ring | 46 | cost_paid:11, spell_cast:11, spell_resolved:10, utility_artifact_activated:14 |
| Flashback | 35 | cost_paid:7, miracle_cast:1, recursion_resolved:10, spell_cast:7, spell_resolved:10 |
| Guttersnipe | 33 | cost_paid:10, trigger_resolved:23 |
| Chaos Warp | 32 | cost_paid:6, miracle_cast:2, removal_resolved:9, spell_cast:6, spell_resolved:9 |
| Enlightened Tutor | 30 | cost_paid:8, miracle_cast:3, spell_cast:8, spell_resolved:11 |
| Erode | 28 | cost_paid:7, removal_resolved:7, spell_cast:7, spell_resolved:7 |
| Underworld Breach | 21 | cost_paid:7, spell_cast:7, spell_resolved:7 |
| Faithless Looting | 20 | cost_paid:5, miracle_cast:2, spell_cast:5, spell_resolved:8 |
| Gamble | 20 | cost_paid:6, miracle_cast:1, spell_cast:6, spell_resolved:7 |

## Strategic Event Deltas

| event | 607 | 615 | delta |
| --- | --- | --- | --- |
| static_cost_reduction_total | 90 | 2 | -88 |
| lorehold_spell_cast | 301 | 239 | -62 |
| lorehold_cost_paid | 348 | 289 | -59 |
| lorehold_rummage_discard_to_top | 7 | 54 | 47 |
| static_cost_reduction_casts | 47 | 2 | -45 |
| lorehold_upkeep_rummage | 112 | 156 | 44 |
| birgi_spell_cast_mana | 0 | 37 | 37 |
| spell_cast_mana_trigger | 0 | 37 | 37 |
| lorehold_spell_rummage | 36 | 0 | -36 |
| discard_to_top_replacement | 28 | 54 | 26 |
| lorehold_spell_rummage_discard_to_top | 21 | 0 | -21 |
| miracle_cast | 69 | 49 | -20 |
| thor_noncreature_damage_amount | 20 | 0 | -20 |
| topdeck_manipulation_activated | 38 | 22 | -16 |
| scarlet_static_cost_reduction_total | 13 | 0 | -13 |
| scarlet_static_cost_reduction_casts | 7 | 0 | -7 |
| thor_noncreature_damage | 4 | 0 | -4 |
| thor_cost_paid | 3 | 0 | -3 |

## Guardrail

This report treats 615 as a whole-shell learning signal, not as an automatic replacement for protected deck 607. A promotion still needs repeat/opponent-rotated battle evidence plus explicit review of the official power-watch cards introduced by the 615 shell.
