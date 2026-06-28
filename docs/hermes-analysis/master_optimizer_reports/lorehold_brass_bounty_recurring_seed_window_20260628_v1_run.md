# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T06:04:50.151275+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `63261404, 63261405, 63261406, 63261407, 63261408, 63261409, 63261410, 63261411, 63261412, 63261413, 63261414, 63261415, 63261416, 63261417, 63261418, 63261419`
- strong_seeds: `63261404, 63261405, 63261406, 63261407, 63261408, 63261409, 63261410, 63261411, 63261412, 63261413, 63261414, 63261415, 63261416, 63261417, 63261418, 63261419`
- games_per_opponent: `1`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 1}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | 14-34 | 12-36 | -4.17 | -4.17 | `reject_regresses_strong_seed` |

## Seed Detail


### brass_bounty_cut_boros_signet

- aggregate: `{"avg_seed_delta_pp": -4.17, "baseline_record": "14-34", "baseline_win_rate": 29.17, "candidate_record": "12-36", "candidate_win_rate": 25.0, "decision": "reject_regresses_strong_seed", "delta_pp_total": -4.17, "games": 48, "incomplete_seeds": [], "package_key": "brass_bounty_cut_boros_signet", "strong_seed_regressions": [63261404, 63261409, 63261419]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 63261404 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 63261405 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 63261406 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 63261407 | 2/1/0 `66.67%` | 2/1/0 `66.67%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261408 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261409 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 63261410 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261411 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261412 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261413 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261414 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261415 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261416 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 63261417 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261418 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 63261419 | 2/1/0 `66.67%` | 1/2/0 `33.33%` | -33.34 | `reject_or_rework` |
