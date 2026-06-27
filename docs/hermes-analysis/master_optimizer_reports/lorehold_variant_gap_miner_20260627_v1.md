# Lorehold Variant Gap Miner - 2026-06-27

- Generated at: `2026-06-27T21:17:08Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- Base deck: `6`
- Variant decks: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`

## Summary

- variant_only_card_count: `270`
- candidate_status_counts: `{'blocked_runtime_rule_gap': 61, 'high_frequency_runtime_ready_unexplored': 22, 'runtime_ready_unexplored': 172, 'tested_negative_add_requires_new_cut': 15}`
- cut_status_counts: `{'blocked_core_cut': 28, 'blocked_locked_cut': 9, 'manual_review_needed': 5, 'requires_same_lane_gate': 38, 'risky_same_lane_only': 2, 'tested_negative_cut': 10, 'untested_flex_candidate': 2}`
- runtime_ready_unexplored_count: `194`
- blocked_runtime_rule_gap_count: `61`
- tested_negative_add_count: `15`
- tested_negative_cut_count: `10`
- pairing_count: `12`

## Top Variant Candidates

| Rank | Card | Status | Score | Decks | Lane | Active Rules | Reviewed Overrides | Effects | Rule Quality Flags | Prior Negative Adds |
| ---: | --- | --- | ---: | --- | --- | ---: | ---: | --- | --- | ---: |
| 1 | `Plateau` | `high_frequency_runtime_ready_unexplored` | 94 | 610, 611, 612, 613, 614, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 2 | `Apex of Power` | `high_frequency_runtime_ready_unexplored` | 92 | 609, 610, 611, 613, 615, 616 | `hand_filter` | 3 | 1 | draw_cards, passive | none | 0 |
| 3 | `Brass's Bounty` | `high_frequency_runtime_ready_unexplored` | 88 | 609, 611, 612, 613, 614, 615 | `early_mana` | 2 | 1 | ramp_engine, treasure_maker | none | 0 |
| 4 | `Clifftop Retreat` | `high_frequency_runtime_ready_unexplored` | 84 | 609, 610, 611, 614, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 5 | `Enlightened Tutor` | `high_frequency_runtime_ready_unexplored` | 84 | 608, 611, 612, 613, 614, 615 | `contextual` | 1 | 0 | tutor | none | 0 |
| 6 | `Gamble` | `high_frequency_runtime_ready_unexplored` | 74 | 609, 612, 613, 614, 615 | `contextual` | 1 | 0 | tutor | none | 0 |
| 7 | `Volcanic Vision` | `high_frequency_runtime_ready_unexplored` | 72 | 609, 611, 613, 614 | `graveyard_recursion` | 3 | 1 | recursion | none | 0 |
| 8 | `Olórin's Searing Light` | `high_frequency_runtime_ready_unexplored` | 68 | 609, 613, 614, 615 | `hand_filter` | 2 | 1 | draw_cards, remove_creature | none | 0 |
| 9 | `Restoration Seminar` | `high_frequency_runtime_ready_unexplored` | 68 | 609, 610, 611, 612 | `graveyard_recursion` | 2 | 1 | recursion | none | 0 |
| 10 | `Valakut Awakening // Valakut Stoneforge` | `high_frequency_runtime_ready_unexplored` | 68 | 608, 609, 610, 611 | `hand_filter` | 2 | 1 | draw_cards, hand_filter | none | 0 |
| 11 | `Wheel of Fortune` | `high_frequency_runtime_ready_unexplored` | 68 | 608, 609, 612, 616 | `hand_filter` | 2 | 1 | draw_cards | none | 0 |
| 12 | `Austere Command` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 610, 611, 612 | `pressure_absorber_or_protection` | 1 | 0 | board_wipe | none | 0 |
| 13 | `Boseiju, Who Shelters All` | `high_frequency_runtime_ready_unexplored` | 64 | 612, 613, 615, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 14 | `Dance with Calamity` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 614 | `hand_filter` | 1 | 0 | draw_cards, exile_value | none | 0 |
| 15 | `Galvanoth` | `high_frequency_runtime_ready_unexplored` | 64 | 611, 613, 614, 615 | `hand_filter` | 1 | 0 | creature | none | 0 |
| 16 | `Goldspan Dragon` | `high_frequency_runtime_ready_unexplored` | 64 | 608, 611, 614, 615 | `early_mana` | 1 | 0 | creature | none | 0 |
| 17 | `Insurrection` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 614, 615 | `finisher_or_big_spell` | 1 | 0 | steal_all_creatures | none | 0 |
| 18 | `Invoke Calamity` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 614, 615, 616 | `graveyard_recursion` | 1 | 0 | free_cast, recursion | none | 0 |
| 19 | `Longshot, Rebel Bowman` | `high_frequency_runtime_ready_unexplored` | 64 | 611, 612, 613, 615 | `finisher_or_big_spell` | 1 | 0 | creature | none | 0 |
| 20 | `Penance` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 614 | `hand_filter` | 1 | 0 | damage_prevention_shield | none | 0 |
| 21 | `Rugged Prairie` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 610, 611, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 22 | `Sundown Pass` | `high_frequency_runtime_ready_unexplored` | 64 | 609, 611, 613, 615 | `mana_base` | 1 | 0 | land | none | 0 |
| 23 | `Perch Protection` | `tested_negative_add_requires_new_cut` | 54 | 609, 610, 611, 613, 614, 615 | `finisher_or_big_spell` | 1 | 0 | composite_resolution, extra_turn | none | 1 |
| 24 | `Silence` | `tested_negative_add_requires_new_cut` | 48 | 612, 613, 614, 615, 616 | `protection_window` | 2 | 1 | silence_opponents, silence_spell | none | 1 |
| 25 | `Boros Charm` | `tested_negative_add_requires_new_cut` | 44 | 609, 612, 613, 614, 615 | `protection_window` | 1 | 0 | indestructible, modal_boros_charm | none | 1 |
| 26 | `Storm-Kiln Artist` | `tested_negative_add_requires_new_cut` | 44 | 608, 611, 612, 613, 614 | `early_mana` | 1 | 0 | creature, ramp_engine | none | 1 |
| 27 | `Mana Vault` | `runtime_ready_unexplored` | 38 | 612, 613, 615 | `early_mana` | 2 | 1 | ramp_permanent | none | 0 |
| 28 | `Soulfire Eruption` | `runtime_ready_unexplored` | 38 | 613, 614, 616 | `hand_filter` | 2 | 1 | deal_damage, draw_cards | none | 0 |
| 29 | `Boros Garrison` | `runtime_ready_unexplored` | 34 | 609, 610, 616 | `mana_base` | 1 | 0 | land | none | 0 |
| 30 | `Cavern of Souls` | `runtime_ready_unexplored` | 34 | 612, 614, 615 | `mana_base` | 1 | 0 | land | none | 0 |

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
| `Fellwar Stone` | `tested_negative_cut` | `early_mana` | 1 | seething_song_cut_fellwar_stone |
| `Jeska's Will` | `tested_negative_cut` | `early_mana` | 1 | birgi_spellchain_cut_jeskas_will |
| `Talisman of Conviction` | `tested_negative_cut` | `early_mana` | 1 | runaway_steamkin_cut_talisman |
| `The Scarlet Witch` | `tested_negative_cut` | `early_mana` | 2 | dragon_rage_channeler_cut_scarlet_witch, radiant_scrollwielder_cut_scarlet_witch |
| `Prismari Pianist` | `tested_negative_cut` | `finisher_or_big_spell` | 3 | guttersnipe_spell_payoff_cut_prismari, monastery_mentor_spell_tokens_cut_prismari, young_pyromancer_spell_tokens_cut_prismari |
| `Avatar's Wrath` | `tested_negative_cut` | `pressure_absorber_or_protection` | 5 | boros_charm_pressure_cut_avatar_wrath, perch_protection_cut_avatar_wrath, akromas_will_cut_avatar_wrath, silence_cut_avatar_wrath, reprieve_cut_avatar_wrath |
| `Mother of Runes` | `tested_negative_cut` | `pressure_absorber_or_protection` | 1 | grand_abolisher_cut_mother_of_runes |
| `Promise of Loyalty` | `tested_negative_cut` | `pressure_absorber_or_protection` | 1 | ghostly_prison_pressure_cut_promise |
| `Tibalt's Trickery` | `tested_negative_cut` | `pressure_absorber_or_protection` | 2 | overmaster_protect_draw_cut_tibalts_trickery, lapse_approach_topdeck_cut_tibalts_trickery |
| `Boros Signet` | `untested_flex_candidate` | `early_mana` | 0 | none |
| `Sol Ring` | `untested_flex_candidate` | `early_mana` | 0 | none |

## Pairing Hypotheses

- `Plateau` -> `needs_cut_model_before_gate` in lane `mana_base`; cut options: none
- `Apex of Power` -> `needs_cut_model_before_gate` in lane `hand_filter`; cut options: none
- `Brass's Bounty` -> `gate_candidate_requires_manual_review` in lane `early_mana`; cut options: The Mind Stone (manual_review_needed, early_mana); Bender's Waterskin (risky_same_lane_only, early_mana); Boros Signet (untested_flex_candidate, early_mana); Sol Ring (untested_flex_candidate, early_mana)
- `Clifftop Retreat` -> `needs_cut_model_before_gate` in lane `mana_base`; cut options: none
- `Enlightened Tutor` -> `needs_lane_model_before_gate` in lane `contextual`; cut options: none
- `Gamble` -> `needs_lane_model_before_gate` in lane `contextual`; cut options: none
- `Volcanic Vision` -> `gate_candidate_requires_manual_review` in lane `graveyard_recursion`; cut options: Squee, Goblin Nabob (manual_review_needed, graveyard_recursion)
- `Olórin's Searing Light` -> `needs_cut_model_before_gate` in lane `hand_filter`; cut options: none
- `Restoration Seminar` -> `gate_candidate_requires_manual_review` in lane `graveyard_recursion`; cut options: Squee, Goblin Nabob (manual_review_needed, graveyard_recursion)
- `Valakut Awakening // Valakut Stoneforge` -> `needs_cut_model_before_gate` in lane `hand_filter`; cut options: none
- `Wheel of Fortune` -> `needs_cut_model_before_gate` in lane `hand_filter`; cut options: none
- `Austere Command` -> `gate_candidate_requires_manual_review` in lane `pressure_absorber_or_protection`; cut options: Emeria's Call // Emeria, Shattered Skyclave (manual_review_needed, pressure_absorber_or_protection)

## Method Notes

- SQLite/Hermes was read as an audit cache only; no PostgreSQL write was performed.
- Battle rules were aggregated by card name before deck comparison to avoid multi-rule fanout.
- A candidate with a prior negative add is not rejected forever, but it requires a different cut model before retest.
- A cut with prior negative evidence is protected until a same-lane package gives stronger proof.
