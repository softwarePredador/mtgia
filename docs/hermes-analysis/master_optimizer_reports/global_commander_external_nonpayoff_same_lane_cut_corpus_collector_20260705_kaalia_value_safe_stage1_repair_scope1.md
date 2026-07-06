# Global Commander External Nonpayoff Same-Lane Cut Corpus Collector

- generated_at: `2026-07-06T00:27:39.567040+00:00`
- status: `external_nonpayoff_same_lane_corpus_collected_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- target_role_count: `3`
- external_source_count: `6`
- role_corpus_count: `3`
- exhausted_role_count: `3`
- fresh_same_lane_cut_source_count: `0`
- blocked_recycled_cut_source_count: `47`
- ready_pair_count: `0`
- unpaired_add_count: `8`
- external_cut_permission_now: `false`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery`

## Role Corpus Rows

| Role | Adds | Sources | Fresh | Recycled | Status | Next Evidence |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `haste_protection_silence` | 2 | 6 | 0 | 16 | `external_nonpayoff_corpus_collected_for_exhausted_same_lane_role` | `map_external_nonpayoff_same_lane_corpus_to_cut_policy` |
| `mana_acceleration` | 1 | 6 | 0 | 15 | `external_nonpayoff_corpus_collected_for_exhausted_same_lane_role` | `map_external_nonpayoff_same_lane_corpus_to_cut_policy` |
| `tutors_access` | 5 | 5 | 0 | 16 | `external_nonpayoff_corpus_collected_for_exhausted_same_lane_role` | `map_external_nonpayoff_same_lane_corpus_to_cut_policy` |

## Source Corpus Snapshot

- `edhrec_kaalia_current_2026_07_05` (commander_public_usage): 37,936 Kaalia commander decks; public page exposes Top Cards, Game Changers, Utility Artifacts, Mana Artifacts, Instants, and Lands sections. (https://edhrec.com/commanders/kaalia-of-the-vast)
- `edhrec_kaalia_combos_2026_07_05` (commander_combo_corpus): 1,141 Kaalia combo rows, including attack/combat, tutor, mana, and payoff dependency contexts. (https://edhrec.com/combos/kaalia-of-the-vast)
- `commander_spellbook_combo_search_2026_07_05` (commander_combo_search_engine): Commander Spellbook is a Commander combo search engine with advanced search and most-popular combo surfaces. (https://commanderspellbook.com/)
- `wizards_commander_brackets_2026_02_09` (official_commander_policy): Wizards confirms Commander Brackets and Game Changers remain active policy surfaces in 2026. (https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026)
- `scryfall_game_changer_surface_via_playgroup_2026_07_05` (scryfall_synced_game_changer_index): 53 Game Changer cards synced from Scryfall is:gamechanger on 2026-07-05. (https://playgroup.gg/commander/game-changers)
- `draftsim_kaalia_deck_guide_2025` (commander_strategy_article): Kaalia is described as targeted because her mana advantage depends on surviving and attacking. (https://draftsim.com/kaalia-of-the-vast-edh-deck/)

## Blockers

- `external_corpus_is_not_cut_permission`
- `target_deck_usage_and_stage_evidence_still_override_external_absence`
- `candidate_copy_closed_until_policy_maps_external_corpus_to_new_source_candidates`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`

## Policy

- external_boundary: External corpus can create source-policy lanes, but cannot authorize cutting used or stage-only cards.
- nonpayoff_boundary: This pass is constrained to nonpayoff same-lane support; lands, commander, and payoff bodies remain excluded.
- trace_boundary: Target-deck trace and card-level usage evidence remain stronger than external absence or popularity.
- battle_boundary: No battle gate opens until candidate copy exists and the relevant added/cut cards are exercised.
