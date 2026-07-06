# Global Commander Ramp Cut Forced Recovery Router

- generated_at: `2026-07-06T06:02:35.904821+00:00`
- status: `ramp_cut_forced_recovery_routes_alternative_cut_trace`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- blocked_ramp_cut_count: `9`
- replacement_candidate_count: `2`
- replacement_exact_ready_count: `0`
- replacement_blocked_count: `18`
- alternative_ramp_card_count: `24`
- alternative_trace_required_count: `2`
- alternative_manual_review_count: `2`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `trace_alternative_ramp_cut_candidates_before_candidate_copy`

## Blocked Cuts

| Card | Status | Usage | Reason |
| --- | --- | ---: | --- |
| `Arcane Signet` | `blocked_prior_usage_requires_replacement` | 0 | `prior_usage_scout_requires_same_lane_replacement` |
| `Basalt Monolith` | `blocked_natural_usage_observed` | 3 | `natural_current_scope_usage_observed` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `blocked_prior_usage_requires_replacement` | 0 | `prior_usage_scout_requires_same_lane_replacement` |
| `Burnt Offering` | `blocked_natural_usage_observed` | 1 | `natural_current_scope_usage_observed` |
| `Cabal Ritual` | `blocked_natural_usage_observed` | 3 | `natural_current_scope_usage_observed` |
| `Culling the Weak` | `blocked_forced_usage_observed` | 9 | `forced_access_usage_observed` |
| `Dark Ritual` | `blocked_prior_usage_requires_replacement` | 0 | `prior_usage_scout_requires_same_lane_replacement` |
| `Desperate Ritual` | `blocked_forced_usage_observed` | 6 | `forced_access_usage_observed` |
| `Grim Monolith` | `blocked_structured_review_required` | 0 | `structured_trace_review_required` |

## Replacement Exactness

| Cut | Replacement | Status | Overlap | Reason |
| --- | --- | --- | --- | --- |
| `Arcane Signet` | `Fellwar Stone` | `replacement_blocked_lower_staple_rank_than_used_cut` | `permanent_mana_rock` | `candidate_is_lower_rank_than_used_cut` |
| `Arcane Signet` | `Commander's Sphere` | `replacement_blocked_lower_staple_rank_than_used_cut` | `commander_color_mana_rock,permanent_mana_rock` | `candidate_is_lower_rank_than_used_cut` |
| `Basalt Monolith` | `Fellwar Stone` | `replacement_blocked_not_big_mana_rock` | `permanent_mana_rock` | `candidate_does_not_cover_colorless_big_mana_role` |
| `Basalt Monolith` | `Commander's Sphere` | `replacement_blocked_not_big_mana_rock` | `permanent_mana_rock` | `candidate_does_not_cover_colorless_big_mana_role` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Burnt Offering` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Burnt Offering` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Cabal Ritual` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Cabal Ritual` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Culling the Weak` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Culling the Weak` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Dark Ritual` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Dark Ritual` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Desperate Ritual` | `Fellwar Stone` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Desperate Ritual` | `Commander's Sphere` | `replacement_blocked_not_exact_same_lane` | `` | `replacement_signature_does_not_cover_cut_signature` |
| `Grim Monolith` | `Fellwar Stone` | `replacement_blocked_not_big_mana_rock` | `permanent_mana_rock` | `candidate_does_not_cover_colorless_big_mana_role` |
| `Grim Monolith` | `Commander's Sphere` | `replacement_blocked_not_big_mana_rock` | `permanent_mana_rock` | `candidate_does_not_cover_colorless_big_mana_role` |

## Alternative Ramp Cuts

| Card | Status | Signatures | Usage | Exposure | Decisions | Next Gate |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `Alicia Masters, Skilled Sculptor` | `alternative_cut_blocked_legendary_plan_engine` | `treasure_ramp` | 0 | 0 | 0 | `find_different_ramp_cut` |
| `Arcane Signet` | `alternative_cut_blocked_already_current_ramp_blocker` | `commander_color_mana_rock,permanent_mana_rock` | 6 | 11 | 7 | `find_different_ramp_cut` |
| `Archaeomancer's Map` | `alternative_cut_blocked_land_access_engine_needs_profile_review` | `land_access_ramp` | 0 | 0 | 1 | `run_mana_base_or_engine_profile_review_before_cut` |
| `Basalt Monolith` | `alternative_cut_blocked_already_current_ramp_blocker` | `colorless_big_mana_rock,permanent_mana_rock` | 3 | 8 | 2 | `find_different_ramp_cut` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `alternative_cut_blocked_already_current_ramp_blocker` | `spell_trigger_mana_engine` | 9 | 15 | 14 | `find_different_ramp_cut` |
| `Cabal Ritual` | `alternative_cut_blocked_already_current_ramp_blocker` | `burst_ritual` | 3 | 3 | 5 | `find_different_ramp_cut` |
| `Culling the Weak` | `alternative_cut_blocked_already_current_ramp_blocker` | `burst_ritual,sacrifice_ritual` | 0 | 0 | 0 | `find_different_ramp_cut` |
| `Dark Ritual` | `alternative_cut_blocked_already_current_ramp_blocker` | `burst_ritual` | 0 | 0 | 1 | `find_different_ramp_cut` |
| `Desperate Ritual` | `alternative_cut_blocked_already_current_ramp_blocker` | `burst_ritual` | 0 | 0 | 0 | `find_different_ramp_cut` |
| `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | `alternative_cut_blocked_card_advantage_engine` | `treasure_card_advantage_engine,treasure_ramp` | 4 | 1 | 2 | `find_different_ramp_cut` |
| `Fabled Passage` | `alternative_cut_blocked_land_mana_base_gate_required` | `land_access_ramp` | 0 | 16 | 0 | `run_mana_base_profile_before_land_cut` |
| `Grim Monolith` | `alternative_cut_blocked_already_current_ramp_blocker` | `colorless_big_mana_rock,permanent_mana_rock` | 0 | 0 | 1 | `find_different_ramp_cut` |
| `Infernal Plunge` | `alternative_cut_current_trace_usage_observed_blocks_cut` | `burst_ritual,sacrifice_ritual` | 3 | 20 | 23 | `find_different_ramp_cut` |
| `Jeska's Will` | `alternative_cut_blocked_premium_ramp_staple` | `burst_ritual` | 4 | 17 | 19 | `find_different_ramp_cut` |
| `Mana Vault` | `alternative_cut_blocked_premium_ramp_staple` | `colorless_big_mana_rock,permanent_mana_rock` | 3 | 7 | 1 | `find_different_ramp_cut` |
| `Monologue Tax` | `alternative_cut_seen_without_usage_needs_manual_negative_review` | `treasure_ramp` | 0 | 0 | 1 | `manual_negative_trace_review_for_alternative_ramp_cut` |
| `Ornithopter of Paradise` | `alternative_cut_needs_current_scope_trace` | `permanent_mana_rock` | 0 | 0 | 0 | `trace_alternative_ramp_cut_candidates_before_candidate_copy` |
| `Professional Face-Breaker` | `alternative_cut_blocked_card_advantage_engine` | `treasure_card_advantage_engine,treasure_ramp` | 0 | 0 | 0 | `find_different_ramp_cut` |
| `Pyretic Ritual` | `alternative_cut_needs_current_scope_trace` | `burst_ritual` | 0 | 0 | 0 | `trace_alternative_ramp_cut_candidates_before_candidate_copy` |
| `Ragavan, Nimble Pilferer` | `alternative_cut_blocked_legendary_plan_engine` | `treasure_card_advantage_engine,treasure_ramp` | 0 | 0 | 0 | `find_different_ramp_cut` |
| `Smothering Tithe` | `alternative_cut_blocked_premium_ramp_staple` | `treasure_card_advantage_engine,treasure_ramp` | 61 | 22 | 16 | `find_different_ramp_cut` |
| `Smuggler's Share` | `alternative_cut_blocked_card_advantage_engine` | `treasure_card_advantage_engine,treasure_ramp` | 0 | 0 | 1 | `find_different_ramp_cut` |
| `Sol Ring` | `alternative_cut_blocked_premium_ramp_staple` | `colorless_big_mana_rock,permanent_mana_rock` | 3 | 13 | 3 | `find_different_ramp_cut` |
| `Strike It Rich` | `alternative_cut_seen_without_usage_needs_manual_negative_review` | `treasure_ramp` | 0 | 1 | 2 | `manual_negative_trace_review_for_alternative_ramp_cut` |

## Blockers

- `no_exact_same_lane_ramp_replacement_ready`
- `current_ramp_cut_blocked_count:9`
- `alternative_ramp_cut_requires_trace:Ornithopter of Paradise,Pyretic Ritual`
- `candidate_copy_closed_after_ramp_forced_recovery_router`

## Policy

- forced_access_boundary: Forced access usage blocks a ramp cut; it does not authorize a swap.
- exact_replacement_boundary: A replacement must cover the cut's exact ramp signature and cannot downgrade a premium used staple without further source proof.
- alternative_cut_boundary: Alternative ramp cuts are trace targets only until card-level usage and negative-review evidence exists.
- mutation_boundary: This router reads reports and SQLite only; it does not mutate deck or database state.
