# Lorehold Topdeck Mana Trace Gap Scout

- Generated at: `2026-07-05T07:57:59Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_mana_trace_gap_scout_found_unprobed_floor_sensitive_gaps_keep_607`
- Trace gap rows: `10`
- Unprobed topdeck gaps: `6`
- Floor-sensitive gaps: `6`
- Already probed topdeck rows: `4`
- Mana eligible pairs: `0`
- Mana exact rejected pairs: `2`
- Structure matrix allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `collect_targeted_floor_traces_for_unprobed_gap_rows_before_structure_matrix`

## Trace Gap Rows

| Card | Status | Exposure | Role | Value | Blockers |
| --- | --- | ---: | --- | ---: | --- |
| Call Forth the Tempest | `unprobed_low_exposure_floor_sensitive_trace_gap` | 8 | `miracle_conversion_finisher` | 38 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, miracle_conversion_finisher_floor_unknown |
| Hit the Mother Lode | `unprobed_low_exposure_floor_sensitive_trace_gap` | 11 | `miracle_conversion_finisher` | 38 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, miracle_conversion_finisher_floor_unknown |
| Everything Comes to Dust | `unprobed_low_exposure_floor_sensitive_trace_gap` | 34 | `miracle_conversion_finisher` | 38 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, miracle_conversion_finisher_floor_unknown |
| Rise of the Eldrazi | `unprobed_low_exposure_floor_sensitive_trace_gap` | 60 | `miracle_conversion_finisher` | 41 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, miracle_conversion_finisher_floor_unknown |
| Pinnacle Monk // Mystic Peak | `already_probed_blocked` | 8 | `recursion_engine` | 10 | miracle_topdeck_floor_equivalence_required, probe_cut_has_material_exposure, probe_cut_role_not_low_impact:recursion_engine, requires_exposure_trace_before_safe_cut |
| Reforge the Soul | `already_probed_blocked` | 23 | `draw_filter_value` | 13 | miracle_topdeck_floor_equivalence_required, probe_cut_has_material_exposure, probe_cut_role_not_low_impact:draw_filter_value, requires_exposure_trace_before_safe_cut |
| Improvisation Capstone | `already_probed_blocked` | 59 | `draw_filter_value` | 10 | miracle_topdeck_floor_equivalence_required, probe_cut_has_material_exposure, probe_cut_role_not_low_impact:draw_filter_value, requires_exposure_trace_before_safe_cut |
| Surge to Victory | `unprobed_floor_sensitive_trace_gap` | 275 | `miracle_conversion_finisher` | 38 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, miracle_conversion_finisher_floor_unknown |
| Esper Sentinel | `unprobed_floor_sensitive_trace_gap` | 527 | `draw_filter_value` | 19 | not_in_current_named_probe_frontier, cut_card_has_material_exposure, floor_sensitive_lane_unknown, draw_filter_floor_unknown |
| Artist's Talent | `already_probed_blocked` | 535 | `draw_filter_value` | 10 | miracle_topdeck_floor_equivalence_required, probe_cut_has_material_exposure, probe_cut_role_not_low_impact:draw_filter_value, requires_exposure_trace_before_safe_cut |

## Mana Trace Gap

- frontier_status: `mana_route_closed_by_exact_decisions`
- safe_model_ready_pair_count: `2`
- remaining_ready_pair_count_after_exact_reject_filter: `0`
- eligible_pair_count: `0`
- exact_rejected_pair_count: `2`
- exact_rejected_pairs:
  - `Plateau` over `Radiant Summit`: `reject_promotion_keep_607_current_baseline`; blockers: forced_opening_hand_diagnostic_lost_to_607, natural_smoke_did_not_access_plateau, natural_smoke_lost_to_607
  - `Plateau` over `Turbulent Steppe`: `reject_promotion_keep_607_current_baseline`; blockers: forced_opening_hand_diagnostic_lost_to_607

## External Research Context

- `Wizards Commander format`: Official format and color identity are entry gates, not proof of card quality. (https://magic.wizards.com/en/formats/commander)
- `Scryfall Lorehold Oracle`: Lorehold grants miracle to instants and sorceries and rummages on each opponent upkeep. (https://scryfall.com/card/sos/201/lorehold-the-historian)
- `EDHREC Optimized Topdeck Lorehold`: Current commander-context signal is Topdeck plus Spellslinger; Scroll Rack and Sensei's Top are high-synergy cards. (https://edhrec.com/commanders/lorehold-the-historian/optimized/topdeck)
- `EDHREC Miracles Every Turn`: Library of Leng plus upkeep rummage is a core miracle setup pattern. (https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander)
- `EDHREC Ramp in Commander`: Ramp is about outpacing the curve; in Lorehold it must also preserve commander timing and miracle cadence. (https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander)
- `Card Kingdom ramp/draw article`: Ramp and draw are structural pillars, but pillar counts do not replace commander-specific package proof. (https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/)

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Unprobed floor-sensitive cut slots exist, so the next work is trace collection rather than a new deck, structure matrix, or battle gate.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_candidate_deck_from_trace_gap_rows
  - collect candidate-loss-vs-607 floor traces for unprobed rows
  - do_not_retest exact Plateau pairs without new mana evidence
