# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T09:28:37.419561+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `7, 20260625, 42`
- strong_seeds: `42`
- games_per_opponent: `1`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 5}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| lotus_petal_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Lotus Petal | Bender's Waterskin | 4-5 | 3-6 | -11.11 | -11.11 | `reject_regresses_strong_seed` |
| millikin_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Millikin | Bender's Waterskin | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| monologue_tax_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Monologue Tax | Bender's Waterskin | 4-5 | 3-6 | -11.11 | -11.11 | `reject_regresses_strong_seed` |
| erode_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Erode | Winds of Abandon | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| electro_assaulting_battery_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Electro, Assaulting Battery | Winds of Abandon | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |

## Seed Detail


### lotus_petal_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_regresses_strong_seed", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "lotus_petal_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### millikin_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "millikin_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### monologue_tax_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_regresses_strong_seed", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "monologue_tax_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 3/0/0 `100.00%` | +66.67 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### erode_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "erode_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### electro_assaulting_battery_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "electro_assaulting_battery_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |
