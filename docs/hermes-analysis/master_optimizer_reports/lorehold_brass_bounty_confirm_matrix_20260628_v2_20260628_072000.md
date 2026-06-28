# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T07:13:15.568598+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `7, 20260625, 42`
- strong_seeds: `42`
- games_per_opponent: `3`
- opponent_limit: `5`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 1}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | 17-28 | 16-29 | -2.22 | -2.22 | `reject_or_rework` |

## Seed Detail


### brass_bounty_cut_boros_signet

- aggregate: `{"avg_seed_delta_pp": -2.22, "baseline_record": "17-28", "baseline_win_rate": 37.78, "candidate_record": "16-29", "candidate_win_rate": 35.56, "decision": "reject_or_rework", "delta_pp_total": -2.22, "games": 45, "incomplete_seeds": [], "package_key": "brass_bounty_cut_boros_signet", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 9/6/0 `60.00%` | 5/10/0 `33.33%` | -26.67 | `reject_or_rework` |
| 20260625 | 6/9/0 `40.00%` | 6/9/0 `40.00%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 2/13/0 `13.33%` | 5/10/0 `33.33%` | +20.00 | `promote_to_deeper_gate` |
