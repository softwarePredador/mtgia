# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-30T16:57:34.816063+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- seeds: `20260630, 123, 999`
- strong_seeds: `42`
- games_per_opponent: `3`
- opponent_limit: `8`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 1}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| storm_kiln_artist_cut_arcane_signet | spellchain_mana | Storm-Kiln Artist | Arcane Signet | 27-44 | 29-43 | +2.25 | +2.78 | `promote_to_confirm_gate` |

## Seed Detail


### storm_kiln_artist_cut_arcane_signet

- aggregate: `{"avg_seed_delta_pp": 2.78, "baseline_record": "27-44", "baseline_win_rate": 38.03, "candidate_record": "29-43", "candidate_win_rate": 40.28, "decision": "promote_to_confirm_gate", "delta_pp_total": 2.25, "games": 72, "incomplete_seeds": [], "package_key": "storm_kiln_artist_cut_arcane_signet", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 20260630 | 11/12/1 `45.83%` | 10/14/0 `41.67%` | -4.16 | `reject_or_rework` |
| 123 | 5/19/0 `20.83%` | 11/13/0 `45.83%` | +25.00 | `promote_to_deeper_gate` |
| 999 | 11/13/0 `45.83%` | 8/16/0 `33.33%` | -12.50 | `reject_or_rework` |
