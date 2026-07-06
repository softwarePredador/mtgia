# Global Commander Engine Cut Trace Replacement Gate

- generated_at: `2026-07-06T04:22:23.939082+00:00`
- status: `engine_cut_trace_replacement_gate_needs_trace_review`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- trace_card_count: `1`
- seed_count: `3`
- generated_replay_count: `3`
- trace_no_exposure_count: `0`
- trace_usage_observed_count: `0`
- trace_manual_review_count: `1`
- replacement_candidate_count: `12`
- strong_replacement_candidate_count: `2`
- adjacent_replacement_candidate_count: `10`
- candidate_copy_allowed_now: `false`
- battle_replay_performed: `true`
- battle_gate_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `review_engine_cut_trace_results_before_candidate_copy`

## Trace Review

| Card | Status | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | --- |
| `Archaeomancer's Map` | `engine_cut_natural_trace_seen_without_usage_needs_manual_negative_review` | 0 | 0 | 1 | `manual_negative_trace_review_for_engine_cut_before_candidate_copy` |

## Replacement Reviews

| Cut | Status | Strong | Adjacent | Next Gate |
| --- | --- | ---: | ---: | --- |
| `Biotransference` | `engine_replacement_candidates_found_needs_source_trace_review` | 2 | 10 | `review_engine_replacement_candidates_before_candidate_copy` |

## Replacement Candidate Sample

| Card | Status | Signals | Rank | Type |
| --- | --- | --- | ---: | --- |
| `Mind Stone` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap` | 31 | `Artifact` |
| `Solemn Simulacrum` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap,engine_access_tutor` | 34 | `Artifact Creature — Golem` |
| `Commander's Sphere` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap` | 39 | `Artifact` |
| `Phyrexian Arena` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `slow_draw_engine` | 96 | `Enchantment` |
| `Wayfarer's Bauble` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `engine_access_tutor` | 108 | `Artifact` |
| `Urza's Saga` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap,engine_access_tutor` | 119 | `Enchantment Land — Urza's Saga` |
| `Deadly Dispute` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap` | 131 | `Instant` |
| `Big Score` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `artifact_engine_overlap` | 172 | `Instant` |
| `Boros Charm` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `combat_engine` | 173 | `Instant` |
| `Akroma's Will` | `adjacent_engine_candidate_needs_explicit_same_lane_proof` | `combat_engine` | 205 | `Instant` |
| `Storm-Kiln Artist` | `same_lane_engine_candidate_needs_source_trace_review` | `artifact_engine_overlap,treasure_engine` | 233 | `Creature — Dwarf Shaman` |
| `Pitiless Plunderer` | `same_lane_engine_candidate_needs_source_trace_review` | `artifact_engine_overlap,treasure_engine` | 237 | `Creature — Human Pirate` |

## Seed Reports

- seed `80`: `engine_cut_natural_replay_generated`, events `789`, decisions `130`
- seed `81`: `engine_cut_natural_replay_generated`, events `636`, decisions `103`
- seed `82`: `engine_cut_natural_replay_generated`, events `945`, decisions `133`

## Blockers

- `natural_trace_manual_negative_review_required:Archaeomancer's Map`
- `replacement_candidates_require_source_trace_review`
- `candidate_copy_closed_after_trace_replacement_gate`

## Policy

- natural_trace_boundary: Natural replay trace is evidence collection only, not a promotion battle gate.
- replacement_boundary: Local staple/oracle engine candidates are review seeds, not explicit same-lane proof by themselves.
- same_lane_boundary: A replacement for a used engine cut still needs source and trace review before candidate copy.
- mutation_boundary: This gate reads SQLite and writes report artifacts only.
