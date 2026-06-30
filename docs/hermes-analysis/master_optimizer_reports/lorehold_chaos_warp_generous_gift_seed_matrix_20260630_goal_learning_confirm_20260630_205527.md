# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-30T20:58:29.824063+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- seeds: `20260630, 123, 999`
- strong_seeds: `20260630`
- games_per_opponent: `3`
- opponent_limit: `8`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 1}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Critical Matchups | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| chaos_warp_same_lane_benchmark_cut_generous_gift | interaction_removal_benchmark | Chaos Warp | Generous Gift | 27-44 | 30-42 | Winota 4-5 vs 3-6 | +3.64 | +4.17 | `reject_regresses_critical_matchup` |

## Seed Detail


### chaos_warp_same_lane_benchmark_cut_generous_gift

- aggregate: `{"avg_seed_delta_pp": 4.17, "baseline_record": "27-44", "baseline_win_rate": 38.03, "candidate_record": "30-42", "candidate_win_rate": 41.67, "critical_matchup_records": {"Winota": {"baseline": {"games": 9, "losses": 5, "stalls": 0, "wins": 4}, "candidate": {"games": 9, "losses": 6, "stalls": 0, "wins": 3}}}, "critical_matchup_regressions": ["Winota"], "decision": "reject_regresses_critical_matchup", "delta_pp_total": 3.64, "games": 72, "incomplete_seeds": [], "package_key": "chaos_warp_same_lane_benchmark_cut_generous_gift", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 20260630 | 11/12/1 `45.83%` | 14/10/0 `58.33%` | +12.50 | `promote_to_deeper_gate` |
| 123 | 5/19/0 `20.83%` | 6/18/0 `25.00%` | +4.17 | `promote_to_deeper_gate` |
| 999 | 11/13/0 `45.83%` | 10/14/0 `41.67%` | -4.16 | `reject_or_rework` |
