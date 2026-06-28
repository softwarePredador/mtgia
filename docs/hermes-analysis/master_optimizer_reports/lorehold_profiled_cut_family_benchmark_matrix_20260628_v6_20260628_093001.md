# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T09:31:08.487323+00:00`
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
| tablet_of_discovery_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Tablet of Discovery | Bender's Waterskin | 4-5 | 3-6 | -11.11 | -11.11 | `reject_regresses_strong_seed` |
| lion_s_eye_diamond_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Lion's Eye Diamond | Bender's Waterskin | 4-5 | 3-6 | -11.11 | -11.11 | `reject_regresses_strong_seed` |
| surly_badgersaur_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Surly Badgersaur | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| treasonous_ogre_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Treasonous Ogre | Bender's Waterskin | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |

## Seed Detail


### tablet_of_discovery_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_regresses_strong_seed", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "tablet_of_discovery_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### lion_s_eye_diamond_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_regresses_strong_seed", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "lion_s_eye_diamond_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### surly_badgersaur_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "surly_badgersaur_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### treasonous_ogre_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "treasonous_ogre_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |
