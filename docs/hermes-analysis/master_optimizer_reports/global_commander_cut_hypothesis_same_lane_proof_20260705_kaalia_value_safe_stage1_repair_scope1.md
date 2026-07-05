# Global Commander Cut-Hypothesis Same-Lane Proof

- generated_at: `2026-07-05T22:39:10.001219+00:00`
- status: `cut_hypothesis_same_lane_proof_routes_to_more_mining`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `8`
- usage_blocked_hypothesis_count: `6`
- seen_without_usage_count: `2`
- not_seen_count: `0`
- explicit_same_lane_route_count: `0`
- incidental_role_overlap_count: `9`
- package_explicit_add_axes: `angels_demons_dragons_payoffs`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `mine_more_hypotheses_or_external_cut_source_research`

## Hypothesis Rows

| Cut | Trace Group | Decision | Roles | Same-Lane Routes | Incidental Overlaps |
| --- | --- | --- | --- | ---: | ---: |
| `Biotransference` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `` | 0 | 0 |
| `Maskwood Nexus` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `` | 0 | 0 |
| `Necromancy` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `reanimation_plan_b` | 0 | 0 |
| `Necropotence` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `card_draw_selection, reanimation_plan_b` | 0 | 2 |
| `Puresteel Paladin` | `seen_without_usage` | `blocked_seen_without_usage_needs_negative_or_force_access_review` | `card_draw_selection` | 0 | 2 |
| `Sigarda's Aid` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `` | 0 | 0 |
| `Sram, Senior Edificer` | `usage_blocked` | `blocked_no_explicit_same_lane_route_for_used_hypothesis` | `card_draw_selection` | 0 | 2 |
| `Trouble in Pairs` | `seen_without_usage` | `blocked_seen_without_usage_needs_negative_or_force_access_review` | `card_draw_selection, dedicated_win_conditions` | 0 | 3 |

## Blockers

- `usage_blocked_hypotheses:Biotransference,Maskwood Nexus,Necromancy,Necropotence,Sigarda's Aid,Sram, Senior Edificer`
- `seen_without_usage_requires_negative_review:Puresteel Paladin,Trouble in Pairs`
- `no_explicit_same_lane_route_for_usage_blocked_hypotheses`
- `candidate_copy_closed_until_hypothesis_has_negative_trace_or_explicit_same_lane_equal_gate`

## Policy

- same_lane_boundary: Only package add covered_axes or selected_for_axis create an explicit same-lane route.
- incidental_overlap_boundary: Shared profile_roles on a payoff card are incidental overlap, not value-safe cut proof.
- trace_boundary: Used hypotheses stay blocked; seen-without-usage hypotheses still need negative review or force-access.
- mutation_boundary: This proof model does not copy decks, mutate DBs, run battles, reclassify cuts, or open promotion.
