# Global Commander Ramp Cut Trace Replacement Gate

- generated_at: `2026-07-06T05:46:44.391086+00:00`
- status: `ramp_cut_trace_replacement_gate_needs_forced_access`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- trace_card_count: `5`
- structured_review_card_count: `1`
- seed_count: `3`
- generated_replay_count: `3`
- trace_no_exposure_count: `2`
- trace_usage_observed_count: `3`
- trace_manual_review_count: `0`
- structured_manual_review_count: `1`
- replacement_candidate_count: `12`
- strong_replacement_candidate_count: `2`
- adjacent_replacement_candidate_count: `10`
- candidate_copy_allowed_now: `false`
- battle_replay_performed: `true`
- battle_gate_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_forced_access_trace_for_unexposed_ramp_cut`

## Trace Review

| Card | Status | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | --- |
| `Basalt Monolith` | `ramp_cut_natural_trace_usage_observed_blocks_cut` | 3 | 8 | 2 | `find_different_ramp_cut_or_same_lane_replacement_before_candidate_copy` |
| `Burnt Offering` | `ramp_cut_natural_trace_usage_observed_blocks_cut` | 1 | 6 | 7 | `find_different_ramp_cut_or_same_lane_replacement_before_candidate_copy` |
| `Cabal Ritual` | `ramp_cut_natural_trace_usage_observed_blocks_cut` | 3 | 3 | 5 | `find_different_ramp_cut_or_same_lane_replacement_before_candidate_copy` |
| `Culling the Weak` | `ramp_cut_natural_trace_no_target_exposure_needs_force_access` | 0 | 0 | 0 | `run_forced_access_trace_for_unexposed_ramp_cut` |
| `Desperate Ritual` | `ramp_cut_natural_trace_no_target_exposure_needs_force_access` | 0 | 0 | 0 | `run_forced_access_trace_for_unexposed_ramp_cut` |

## Structured Trace Review

| Card | Status | Structured Evidence | Text Usage Candidates | Next Gate |
| --- | --- | ---: | ---: | --- |
| `Grim Monolith` | `ramp_cut_text_trace_candidate_requires_manual_structured_review` | 2 | 2 | `manual_structured_trace_review_for_ramp_cut_before_candidate_copy` |

## Replacement Reviews

| Cut | Status | Strong | Adjacent | Next Gate |
| --- | --- | ---: | ---: | --- |
| `Arcane Signet` | `ramp_replacement_candidates_found_needs_source_trace_review` | 2 | 10 | `review_ramp_replacement_candidates_before_candidate_copy` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_replacement_candidates_found_needs_source_trace_review` | 2 | 10 | `review_ramp_replacement_candidates_before_candidate_copy` |
| `Dark Ritual` | `ramp_replacement_candidates_found_needs_source_trace_review` | 2 | 10 | `review_ramp_replacement_candidates_before_candidate_copy` |

## Replacement Candidate Sample

| Card | Status | Signals | Rank | Type |
| --- | --- | --- | ---: | --- |
| `Evolving Wilds` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 16 | `Land` |
| `Fellwar Stone` | `same_lane_ramp_candidate_needs_source_trace_review` | `mana_production,ramp_role_text` | 18 | `Artifact` |
| `Thought Vessel` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `ramp_role_text` | 21 | `Artifact` |
| `Myriad Landscape` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 24 | `Land` |
| `Terramorphic Expanse` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 28 | `Land` |
| `Mind Stone` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `ramp_role_text` | 31 | `Artifact` |
| `Solemn Simulacrum` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 34 | `Artifact Creature — Golem` |
| `Polluted Delta` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 38 | `Land` |
| `Commander's Sphere` | `same_lane_ramp_candidate_needs_source_trace_review` | `mana_production,ramp_role_text` | 39 | `Artifact` |
| `Misty Rainforest` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 41 | `Land` |
| `Flooded Strand` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 42 | `Land` |
| `Windswept Heath` | `adjacent_ramp_candidate_needs_explicit_same_lane_proof` | `land_search_ramp` | 46 | `Land` |

## Seed Reports

- seed `90`: `ramp_cut_natural_replay_generated`, events `876`, decisions `124`
- seed `91`: `ramp_cut_natural_replay_generated`, events `1241`, decisions `184`
- seed `92`: `ramp_cut_natural_replay_generated`, events `827`, decisions `123`

## Blockers

- `natural_trace_no_target_exposure_needs_force_access:Culling the Weak,Desperate Ritual`
- `natural_trace_usage_observed_blocks_cut:Basalt Monolith,Burnt Offering,Cabal Ritual`
- `structured_trace_manual_review_required:Grim Monolith`
- `replacement_candidates_require_source_trace_review`
- `candidate_copy_closed_after_ramp_trace_replacement_gate`

## Policy

- natural_trace_boundary: Natural replay trace is evidence collection only, not a promotion battle gate.
- structured_trace_boundary: Text trace candidates require manual structured review before negative clearance.
- replacement_boundary: Local staple/oracle ramp candidates are review seeds, not explicit same-lane proof by themselves.
- same_lane_boundary: A replacement for a used ramp cut still needs source and trace review before candidate copy.
- mutation_boundary: This gate reads SQLite and writes report artifacts only.
