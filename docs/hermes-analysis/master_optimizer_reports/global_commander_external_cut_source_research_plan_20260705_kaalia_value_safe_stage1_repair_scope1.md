# Global Commander External Cut-Source Research Plan

- generated_at: `2026-07-05T22:45:34.642189+00:00`
- status: `external_cut_source_research_plan_ready_no_deck_action`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `8`
- usage_blocked_hypothesis_count: `6`
- seen_without_usage_count: `2`
- explicit_same_lane_route_count: `0`
- external_source_count: `6`
- package_explicit_add_axes: `angels_demons_dragons_payoffs`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_external_commander_reference_corpus_for_cut_candidates`

## External Sources

| Source | Type | Use | Limitation |
| --- | --- | --- | --- |
| [wizards_commander_brackets_2026_02_09](https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026) | `official_commander_policy` | classify power/bracket risk before cutting high-power staples or Game Changers | policy context only; it does not prove a card belongs in a specific commander deck |
| [wizards_commander_brackets_2025_10_21](https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025) | `official_commander_policy` | avoid flattening optimized staples into generic over-target cut pressure | bracket intent is not a same-lane replacement proof |
| [edhrec_kaalia_current](https://edhrec.com/commanders/kaalia-of-the-vast) | `commander_public_usage` | build a commander-specific public corpus and separate payoff adds from unrelated cut lanes | EDHREC popularity is an evidence lane, not final deck truth or battle proof |
| [edhrec_kaalia_expensive_midrange_2026_06_24](https://edhrec.com/commanders/kaalia-of-the-vast/midrange/expensive) | `commander_public_usage_filtered` | treat small filtered samples as source-lane hints requiring local corroboration | sample-size constrained and not enough to authorize cuts by itself |
| [edhrec_kaalia_hidden_gems_2026_03_26](https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast) | `commander_strategy_article` | protect attack-window, recast, and payoff-density lanes from generic cuts | article recommendations are qualitative and must be validated against the target deck and battle traces |
| [edhrec_commander_deckbuilding_guide](https://edhrec.com/articles/how-to-build-a-commander-deck) | `general_deckbuilding_method` | keep ramp/draw/removal/protection categories as floors, not automatic cut permissions | generic categories must bend to commander intent and same-lane evidence |

## Hypothesis Research Rows

| Cut | Trace Group | Lane | Research Status | External Cut Permission |
| --- | --- | --- | --- | --- |
| `Biotransference` | `usage_blocked` | `off_profile_or_unclassified_cut_lane` | `external_research_cannot_override_target_usage` | `false` |
| `Maskwood Nexus` | `usage_blocked` | `off_profile_or_unclassified_cut_lane` | `external_research_cannot_override_target_usage` | `false` |
| `Necromancy` | `usage_blocked` | `reanimation_plan_b` | `external_research_cannot_override_target_usage` | `false` |
| `Necropotence` | `usage_blocked` | `card_draw_selection,reanimation_plan_b` | `external_research_cannot_override_target_usage` | `false` |
| `Puresteel Paladin` | `seen_without_usage` | `card_draw_selection` | `external_research_requires_negative_trace_review_first` | `false` |
| `Sigarda's Aid` | `usage_blocked` | `off_profile_or_unclassified_cut_lane` | `external_research_cannot_override_target_usage` | `false` |
| `Sram, Senior Edificer` | `usage_blocked` | `card_draw_selection` | `external_research_cannot_override_target_usage` | `false` |
| `Trouble in Pairs` | `seen_without_usage` | `card_draw_selection,dedicated_win_conditions` | `external_research_requires_negative_trace_review_first` | `false` |

## Research Actions

- `P0` `collect_external_commander_reference_corpus_for_cut_candidates`: Internal mined hypotheses either were used or lacked explicit same-lane replacement proof.
- `P1` `separate_payoff_add_axis_from_cut_lane_research`: The package add axes are explicit payoff repairs and do not automatically replace draw, reanimation, equipment, or off-profile cuts.
- `P2` `annotate_high_power_staples_with_bracket_and_game_changer_context`: Official bracket policy makes tutors, fast mana, value engines, and efficient disruption bracket-context signals, not generic cut fodder.
- `P3` `rerun_internal_hypothesis_miner_after_external_annotations`: No new deck action should occur until external corpus evidence is mapped back to named current-deck cards.

## Blockers

- `external_research_is_not_cut_permission`
- `target_usage_or_seen_without_usage_still_blocks_value_safe_reclassification`
- `candidate_copy_closed_until_external_corpus_maps_to_negative_or_same_lane_evidence`
