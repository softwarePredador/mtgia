# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T09:07:46.890440+00:00`
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
| basalt_monolith_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Basalt Monolith | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| desperate_ritual_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Desperate Ritual | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| crackle_with_power_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Crackle with Power | Winds of Abandon | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| lightning_helix_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Lightning Helix | Winds of Abandon | 4-5 | 4-5 | +0.00 | +0.00 | `reject_regresses_strong_seed` |

## Seed Detail


### basalt_monolith_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "basalt_monolith_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### desperate_ritual_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "desperate_ritual_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 2/1/0 `66.67%` | -33.33 | `reject_or_rework` |

### crackle_with_power_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "crackle_with_power_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### lightning_helix_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": 0.0, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "4-5", "candidate_win_rate": 44.44, "decision": "reject_regresses_strong_seed", "delta_pp_total": 0.0, "games": 9, "incomplete_seeds": [], "package_key": "lightning_helix_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 3/0/0 `100.00%` | +100.00 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |
