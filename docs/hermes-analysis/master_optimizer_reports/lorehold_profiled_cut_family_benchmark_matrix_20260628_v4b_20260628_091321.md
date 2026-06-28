# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T09:14:27.740848+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `7, 20260625, 42`
- strong_seeds: `42`
- games_per_opponent: `1`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 4}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Pyretic Ritual | Bender's Waterskin | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Locket of Yesterdays | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Razorgrass Ambush // Razorgrass Field | Winds of Abandon | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | 4-5 | 4-5 | +0.00 | +0.00 | `tie_hold_for_more_games` |

## Seed Detail


### pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": 0.0, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "4-5", "candidate_win_rate": 44.44, "decision": "tie_hold_for_more_games", "delta_pp_total": 0.0, "games": 9, "incomplete_seeds": [], "package_key": "witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | `tie_promote_to_deeper_gate` |
