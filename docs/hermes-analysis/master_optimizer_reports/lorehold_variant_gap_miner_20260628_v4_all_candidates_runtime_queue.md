# Lorehold Variant Gap Miner - 2026-06-27

- Generated at: `2026-06-28T01:17:32Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- Base deck: `6`
- Variant decks: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`

## Summary

- variant_only_card_count: `270`
- candidate_status_counts: `{'blocked_runtime_rule_gap': 61, 'high_frequency_runtime_ready_unexplored': 20, 'runtime_ready_unexplored': 172, 'tested_negative_add_requires_new_cut': 17}`
- cut_status_counts: `{'blocked_core_cut': 28, 'blocked_locked_cut': 9, 'manual_review_needed': 4, 'requires_same_lane_gate': 38, 'risky_same_lane_only': 2, 'tested_negative_cut': 12, 'untested_flex_candidate': 1}`
- runtime_ready_unexplored_count: `192`
- blocked_runtime_rule_gap_count: `61`
- tested_negative_add_count: `17`
- tested_negative_cut_count: `12`
- pairing_count: `12`
- pairing_status_counts: `{'blocked_no_safe_cut_in_lane': 8, 'manual_cut_review_required': 2, 'needs_lane_model_before_gate': 2}`
- gate_ready_pairing_count: `0`
- manual_review_pairing_count: `2`
- blocked_pairing_count: `8`

## Top Variant Candidates

| Rank | Card | Status | Score | Decks | Lane | Active Rules | Reviewed Overrides | Effects | Rule Quality Flags | Prior Negative Adds |
| ---: | --- | --- | ---: | --- | --- | ---: | ---: | --- | --- | ---: |
| 1 | `Plateau` | `high_frequency_runtime_ready_unexplored` | 94 | 610, 611, 612, 613, 614, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 2 | `Apex of Power` | `high_frequency_runtime_ready_unexplored` | 92 | 609, 610, 611, 613, 615, 616 | `hand_filter` | 3 | 1 | draw_cards, passive | none | 0 |
| 3 | `Clifftop Retreat` | `high_frequency_runtime_ready_unexplored` | 84 | 609, 610, 611, 614, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 4 | `Enlightened Tutor` | `high_frequency_runtime_ready_unexplored` | 84 | 608, 611, 612, 613, 614, 615 | `contextual` | 1 | 0 | tutor | none | 0 |
| 5 | `Gamble` | `high_frequency_runtime_ready_unexplored` | 74 | 609, 612, 613, 614, 615 | `contextual` | 1 | 0 | tutor | none | 0 |
| 6 | `Volcanic Vision` | `high_frequency_runtime_ready_unexplored` | 72 | 609, 611, 613, 614 | `graveyard_recursion` | 3 | 1 | recursion | none | 0 |
| 7 | `Olórin's Searing Light` | `high_frequency_runtime_ready_unexplored` | 68 | 609, 613, 614, 615 | `hand_filter` | 2 | 1 | draw_cards, remove_creature | none | 0 |
| 8 | `Restoration Seminar` | `high_frequency_runtime_ready_unexplored` | 68 | 609, 610, 611, 612 | `graveyard_recursion` | 2 | 1 | recursion | none | 0 |
| 9 | `Valakut Awakening // Valakut Stoneforge` | `high_frequency_runtime_ready_unexplored` | 68 | 608, 609, 610, 611 | `hand_filter` | 2 | 1 | draw_cards, hand_filter | none | 0 |
| 10 | `Wheel of Fortune` | `high_frequency_runtime_ready_unexplored` | 68 | 608, 609, 612, 616 | `hand_filter` | 2 | 1 | draw_cards | none | 0 |
| 11 | `Boseiju, Who Shelters All` | `high_frequency_runtime_ready_unexplored` | 64 | 612, 613, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 12 | `Dance with Calamity` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 614 | `hand_filter` | 1 | 0 | draw_cards, exile_value | none | 0 |
| 13 | `Galvanoth` | `high_frequency_runtime_ready_unexplored` | 64 | 611, 613, 614, 615 | `hand_filter` | 1 | 0 | creature | none | 0 |
| 14 | `Goldspan Dragon` | `high_frequency_runtime_ready_unexplored` | 64 | 608, 611, 614, 615 | `early_mana` | 1 | 0 | creature | none | 0 |
| 15 | `Insurrection` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 614, 615 | `finisher_or_big_spell` | 1 | 0 | steal_all_creatures | none | 0 |
| 16 | `Invoke Calamity` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 614, 615, 616 | `graveyard_recursion` | 1 | 0 | free_cast, recursion | none | 0 |
| 17 | `Longshot, Rebel Bowman` | `high_frequency_runtime_ready_unexplored` | 64 | 611, 612, 613, 615 | `finisher_or_big_spell` | 1 | 0 | creature | none | 0 |
| 18 | `Penance` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 614 | `hand_filter` | 1 | 0 | damage_prevention_shield | none | 0 |
| 19 | `Rugged Prairie` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 610, 611, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 20 | `Sundown Pass` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 615 | `mana_base` | 1 | 0 | land | none | 0 |
| 21 | `Brass's Bounty` | `tested_negative_add_requires_new_cut` | 58 | 609, 611, 612, 613, 614, 615 | `early_mana` | 2 | 1 | ramp_engine, treasure_maker | none | 1 |
| 22 | `Perch Protection` | `tested_negative_add_requires_new_cut` | 54 | 609, 610, 611, 613, 614, 615 | `finisher_or_big_spell` | 1 | 0 | composite_resolution, extra_turn | none | 1 |
| 23 | `Silence` | `tested_negative_add_requires_new_cut` | 48 | 612, 613, 614, 615, 616 | `protection_window` | 2 | 1 | silence_opponents, silence_spell | none | 1 |
| 24 | `Boros Charm` | `tested_negative_add_requires_new_cut` | 44 | 609, 612, 613, 614, 615 | `protection_window` | 1 | 0 | indestructible, modal_boros_charm | none | 1 |
| 25 | `Storm-Kiln Artist` | `tested_negative_add_requires_new_cut` | 44 | 608, 611, 612, 613, 614 | `early_mana` | 1 | 0 | creature, ramp_engine | none | 1 |
| 26 | `Mana Vault` | `runtime_ready_unexplored` | 38 | 612, 613, 615 | `early_mana` | 2 | 1 | ramp_permanent | none | 0 |
| 27 | `Soulfire Eruption` | `runtime_ready_unexplored` | 38 | 613, 614, 616 | `hand_filter` | 2 | 1 | deal_damage, draw_cards | none | 0 |
| 28 | `Austere Command` | `tested_negative_add_requires_new_cut` | 34 | 609, 610, 611, 612 | `pressure_absorber_or_protection` | 1 | 0 | board_wipe | none | 1 |
| 29 | `Boros Garrison` | `runtime_ready_unexplored` | 34 | 609, 610, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 30 | `Cavern of Souls` | `runtime_ready_unexplored` | 34 | 612, 614, 615 | `mana_base` | 1 | 0 | land | none | 0 |

## Runtime Rule Gap Queue

| Rank | Card | Score | Decks | Lane | Review-only Rules | Disabled Rules |
| ---: | --- | ---: | --- | --- | ---: | ---: |
| 1 | `Goliath Daydreamer` | 10 | 613, 614, 615 | `contextual` | 1 | 0 |
| 2 | `Twinflame Tyrant` | 10 | 608, 611, 615 | `finisher_or_big_spell` | 2 | 0 |
| 3 | `Verge Rangers` | 10 | 609, 611, 613 | `hand_filter` | 2 | 0 |
| 4 | `Ancient Copper Dragon` | 0 | 608, 616 | `early_mana` | 2 | 0 |
| 5 | `Beacon of Immortality` | 0 | 610, 615 | `finisher_or_big_spell` | 2 | 0 |
| 6 | `Boros Reckoner` | 0 | 612, 616 | `contextual` | 0 | 0 |
| 7 | `Heroes Remembered` | 0 | 614, 615 | `hand_filter` | 2 | 0 |
| 8 | `Invincible Hymn` | 0 | 610, 614 | `finisher_or_big_spell` | 2 | 0 |
| 9 | `Planetarium of Wan Shi Tong` | 0 | 611, 613 | `hand_filter` | 2 | 0 |
| 10 | `Semblance Anvil` | 0 | 612, 616 | `early_mana` | 2 | 0 |
| 11 | `Taunt from the Rampart` | 0 | 611, 615 | `hand_filter` | 2 | 0 |
| 12 | `Terror of the Peaks` | 0 | 608, 612 | `contextual` | 1 | 0 |
| 13 | `Alhammarret's Archive` | -10 | 611 | `hand_filter` | 2 | 0 |
| 14 | `Ancient Gold Dragon` | -10 | 612 | `finisher_or_big_spell` | 2 | 0 |
| 15 | `Assemble the Players` | -10 | 610 | `contextual` | 0 | 0 |
| 16 | `Balefire Liege` | -10 | 616 | `contextual` | 0 | 0 |
| 17 | `Blood Moon` | -10 | 616 | `hand_filter` | 2 | 0 |
| 18 | `Chandra's Ignition` | -10 | 613 | `hand_filter` | 2 | 0 |
| 19 | `Chaos Wand` | -10 | 616 | `contextual` | 0 | 0 |
| 20 | `Charmbreaker Devils` | -10 | 612 | `contextual` | 0 | 0 |
| 21 | `Cloud Key` | -10 | 612 | `early_mana` | 2 | 0 |
| 22 | `Codex Shredder` | -10 | 610 | `contextual` | 0 | 0 |
| 23 | `Currency Converter` | -10 | 614 | `early_mana` | 2 | 0 |
| 24 | `Deathbellow War Cry` | -10 | 616 | `contextual` | 0 | 0 |
| 25 | `Eight-and-a-Half-Tails` | -10 | 616 | `contextual` | 0 | 0 |
| 26 | `Ephemerate` | -10 | 612 | `pressure_absorber_or_protection` | 2 | 0 |
| 27 | `Firesong and Sunspeaker` | -10 | 616 | `finisher_or_big_spell` | 2 | 0 |
| 28 | `Ghoulcaller's Bell` | -10 | 610 | `contextual` | 0 | 0 |
| 29 | `Gisela, Blade of Goldnight` | -10 | 612 | `finisher_or_big_spell` | 2 | 0 |
| 30 | `Karn's Sylex` | -10 | 610 | `contextual` | 0 | 0 |
| 31 | `Karn, the Great Creator` | -10 | 610 | `contextual` | 0 | 0 |
| 32 | `Kayla's Music Box` | -10 | 610 | `contextual` | 0 | 0 |
| 33 | `Lantern of Insight` | -10 | 610 | `contextual` | 0 | 0 |
| 34 | `Lens of Clarity` | -10 | 610 | `hand_filter` | 2 | 0 |
| 35 | `Leyline Dowser` | -10 | 610 | `contextual` | 0 | 0 |
| 36 | `Naktamun Lorespinner // Wheel of Fortune` | -10 | 608 | `contextual` | 0 | 0 |
| 37 | `Neheb, the Eternal` | -10 | 616 | `early_mana` | 2 | 0 |
| 38 | `Orcish Spy` | -10 | 610 | `contextual` | 0 | 0 |
| 39 | `Perpetual Timepiece` | -10 | 610 | `early_mana` | 2 | 0 |
| 40 | `Possibility Storm` | -10 | 616 | `contextual` | 0 | 0 |

## Cut Risk Inventory

| Card | Status | Lane | Negative Cut Count | Negative Packages |
| --- | --- | --- | ---: | --- |
| `Hexing Squelcher` | `blocked_locked_cut` | `contextual` | 0 | none |
| `Pearl Medallion` | `blocked_locked_cut` | `early_mana` | 0 | none |
| `Ruby Medallion` | `blocked_locked_cut` | `early_mana` | 0 | none |
| `Victory Chimes` | `blocked_locked_cut` | `early_mana` | 0 | none |
| `Storm Herd` | `blocked_locked_cut` | `finisher_or_big_spell` | 0 | none |
| `Thor, God of Thunder` | `blocked_locked_cut` | `graveyard_recursion` | 0 | none |
| `Dawn's Truce` | `blocked_locked_cut` | `hand_filter` | 0 | none |
| `Reliquary Tower` | `blocked_locked_cut` | `mana_base` | 0 | none |
| `Fated Clash` | `blocked_locked_cut` | `pressure_absorber_or_protection` | 0 | none |
| `Bender's Waterskin` | `risky_same_lane_only` | `early_mana` | 0 | none |
| `Creative Technique` | `risky_same_lane_only` | `finisher_or_big_spell` | 0 | none |
| `Arcane Signet` | `tested_negative_cut` | `early_mana` | 1 | storm_kiln_artist_cut_arcane_signet |
| `Boros Signet` | `tested_negative_cut` | `early_mana` | 1 | brass_bounty_cut_boros_signet |
| `Fellwar Stone` | `tested_negative_cut` | `early_mana` | 1 | seething_song_cut_fellwar_stone |
| `Jeska's Will` | `tested_negative_cut` | `early_mana` | 1 | birgi_spellchain_cut_jeskas_will |
| `Talisman of Conviction` | `tested_negative_cut` | `early_mana` | 1 | runaway_steamkin_cut_talisman |
| `The Scarlet Witch` | `tested_negative_cut` | `early_mana` | 2 | dragon_rage_channeler_cut_scarlet_witch, radiant_scrollwielder_cut_scarlet_witch |
| `Prismari Pianist` | `tested_negative_cut` | `finisher_or_big_spell` | 3 | guttersnipe_spell_payoff_cut_prismari, monastery_mentor_spell_tokens_cut_prismari, young_pyromancer_spell_tokens_cut_prismari |
| `Avatar's Wrath` | `tested_negative_cut` | `pressure_absorber_or_protection` | 5 | boros_charm_pressure_cut_avatar_wrath, perch_protection_cut_avatar_wrath, akromas_will_cut_avatar_wrath, silence_cut_avatar_wrath, reprieve_cut_avatar_wrath |
| `Emeria's Call // Emeria, Shattered Skyclave` | `tested_negative_cut` | `pressure_absorber_or_protection` | 1 | austere_command_wipe_over_emeria_tradeoff |
| `Mother of Runes` | `tested_negative_cut` | `pressure_absorber_or_protection` | 1 | grand_abolisher_cut_mother_of_runes |
| `Promise of Loyalty` | `tested_negative_cut` | `pressure_absorber_or_protection` | 1 | ghostly_prison_pressure_cut_promise |
| `Tibalt's Trickery` | `tested_negative_cut` | `pressure_absorber_or_protection` | 2 | overmaster_protect_draw_cut_tibalts_trickery, lapse_approach_topdeck_cut_tibalts_trickery |
| `Sol Ring` | `untested_flex_candidate` | `early_mana` | 0 | none |

## Pairing Hypotheses

- `Plateau` -> `blocked_no_safe_cut_in_lane` in lane `mana_base`; action: find a safer same-lane cut or build a multi-card package; cut options: Ancient Tomb (blocked_cut_contract, blocked_core_cut, mana_base); Arid Mesa (blocked_cut_contract, blocked_core_cut, mana_base); Battlefield Forge (blocked_cut_contract, blocked_core_cut, mana_base); Bloodstained Mire (blocked_cut_contract, blocked_core_cut, mana_base); Command Beacon (blocked_cut_contract, blocked_core_cut, mana_base)
- `Apex of Power` -> `blocked_no_safe_cut_in_lane` in lane `hand_filter`; action: find a safer same-lane cut or build a multi-card package; cut options: Artist's Talent (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Big Score (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Esper Sentinel (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Monument to Endurance (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Rise of the Eldrazi (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter)
- `Clifftop Retreat` -> `blocked_no_safe_cut_in_lane` in lane `mana_base`; action: find a safer same-lane cut or build a multi-card package; cut options: Ancient Tomb (blocked_cut_contract, blocked_core_cut, mana_base); Arid Mesa (blocked_cut_contract, blocked_core_cut, mana_base); Battlefield Forge (blocked_cut_contract, blocked_core_cut, mana_base); Bloodstained Mire (blocked_cut_contract, blocked_core_cut, mana_base); Command Beacon (blocked_cut_contract, blocked_core_cut, mana_base)
- `Enlightened Tutor` -> `needs_lane_model_before_gate` in lane `contextual`; action: define contextual lane and candidate-specific cut model before gate; cut options: none
- `Gamble` -> `needs_lane_model_before_gate` in lane `contextual`; action: define contextual lane and candidate-specific cut model before gate; cut options: none
- `Volcanic Vision` -> `manual_cut_review_required` in lane `graveyard_recursion`; action: review the cut role/runtime model before gate; cut options: Squee, Goblin Nabob (manual_cut_review_required, manual_review_needed, graveyard_recursion); Farewell (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Furygale Flocking (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Mizzix's Mastery (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Pinnacle Monk // Mystic Peak (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion)
- `Olórin's Searing Light` -> `blocked_no_safe_cut_in_lane` in lane `hand_filter`; action: find a safer same-lane cut or build a multi-card package; cut options: Artist's Talent (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Big Score (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Esper Sentinel (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Monument to Endurance (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Rise of the Eldrazi (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter)
- `Restoration Seminar` -> `manual_cut_review_required` in lane `graveyard_recursion`; action: review the cut role/runtime model before gate; cut options: Squee, Goblin Nabob (manual_cut_review_required, manual_review_needed, graveyard_recursion); Farewell (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Furygale Flocking (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Mizzix's Mastery (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion); Pinnacle Monk // Mystic Peak (protected_same_lane_benchmark_required, requires_same_lane_gate, graveyard_recursion)
- `Valakut Awakening // Valakut Stoneforge` -> `blocked_no_safe_cut_in_lane` in lane `hand_filter`; action: find a safer same-lane cut or build a multi-card package; cut options: Artist's Talent (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Big Score (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Esper Sentinel (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Monument to Endurance (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Rise of the Eldrazi (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter)
- `Wheel of Fortune` -> `blocked_no_safe_cut_in_lane` in lane `hand_filter`; action: find a safer same-lane cut or build a multi-card package; cut options: Artist's Talent (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Big Score (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Esper Sentinel (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Monument to Endurance (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Rise of the Eldrazi (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter)
- `Boseiju, Who Shelters All` -> `blocked_no_safe_cut_in_lane` in lane `mana_base`; action: find a safer same-lane cut or build a multi-card package; cut options: Ancient Tomb (blocked_cut_contract, blocked_core_cut, mana_base); Arid Mesa (blocked_cut_contract, blocked_core_cut, mana_base); Battlefield Forge (blocked_cut_contract, blocked_core_cut, mana_base); Bloodstained Mire (blocked_cut_contract, blocked_core_cut, mana_base); Command Beacon (blocked_cut_contract, blocked_core_cut, mana_base)
- `Dance with Calamity` -> `blocked_no_safe_cut_in_lane` in lane `hand_filter`; action: find a safer same-lane cut or build a multi-card package; cut options: Artist's Talent (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Big Score (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Esper Sentinel (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Monument to Endurance (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter); Rise of the Eldrazi (protected_same_lane_benchmark_required, requires_same_lane_gate, hand_filter)

## Method Notes

- SQLite/Hermes was read as an audit cache only; no PostgreSQL write was performed.
- Battle rules were aggregated by card name before deck comparison to avoid multi-rule fanout.
- A candidate with a prior negative add is not rejected forever, but it requires a different cut model before retest.
- A cut with prior negative evidence is protected until a same-lane package gives stronger proof.
