# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T09:15:44.489635+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `7, 20260625, 42`
- strong_seeds: `42`
- games_per_opponent: `3`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 1}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon | interaction_removal_benchmark | Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | 7-20 | 6-21 | -3.70 | -3.71 | `reject_regresses_strong_seed` |

## Seed Detail


### witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon

- aggregate: `{"avg_seed_delta_pp": -3.71, "baseline_record": "7-20", "baseline_win_rate": 25.93, "candidate_record": "6-21", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -3.7, "games": 27, "incomplete_seeds": [], "package_key": "witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 2/7/0 `22.22%` | 0/9/0 `0.00%` | -22.22 | `reject_or_rework` |
| 20260625 | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | `promote_to_deeper_gate` |
| 42 | 5/4/0 `55.56%` | 4/5/0 `44.44%` | -11.12 | `reject_or_rework` |
