# Global Commander Reviewed External Seeded Cut Trace Collector

- generated_at: `2026-07-06T01:21:33.069680+00:00`
- status: `reviewed_external_seeded_cut_trace_needs_force_access`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `10`
- usage_blocked_hypothesis_count: `0`
- seen_without_usage_count: `0`
- not_seen_count: `10`
- seed_report_count: `8`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `force_access_or_expand_replay_window_for_seeded_hypotheses`

## Review Rows

| Cut | Role | Status | Usage | Exposure | Decisions | Next Evidence |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `Basalt Monolith` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Monologue Tax` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Burnt Offering` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Culling the Weak` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Desperate Ritual` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Grim Monolith` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Infernal Plunge` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Pyretic Ritual` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Cabal Ritual` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Strike It Rich` | `mana_acceleration` | `reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |

## Blockers

- `unseen_seeded_hypotheses_need_force_access:Basalt Monolith,Monologue Tax,Burnt Offering,Culling the Weak,Desperate Ritual,Grim Monolith,Infernal Plunge,Pyretic Ritual,Cabal Ritual,Strike It Rich`
- `candidate_copy_closed_until_seeded_hypothesis_has_negative_or_same_lane_proof`

## Policy

- trace_boundary: This collector reuses existing replay artifacts and does not run a new battle.
- usage_boundary: A seeded cut hypothesis used by the target deck is not value-safe from this trace.
- unseen_boundary: Unseen hypotheses are not negative proof; force-access or broader replay is required.
- candidate_copy_boundary: This collector never opens candidate copy, battle, promotion, or value-safe reclassification.
