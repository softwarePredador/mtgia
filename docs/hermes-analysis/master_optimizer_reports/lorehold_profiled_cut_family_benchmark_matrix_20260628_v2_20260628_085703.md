# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T08:58:07.430145+00:00`
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
| seething_song_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Seething Song | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| mana_vault_same_lane_benchmark_cut_bender_s_waterskin | ramp_benchmark | Mana Vault | Bender's Waterskin | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| invoke_calamity_same_lane_benchmark_cut_creative_technique | big_spell_value_benchmark | Invoke Calamity | Creative Technique | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| velomachus_lorehold_same_lane_benchmark_cut_creative_technique | big_spell_value_benchmark | Velomachus Lorehold | Creative Technique | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |

## Seed Detail


### seething_song_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "seething_song_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### mana_vault_same_lane_benchmark_cut_bender_s_waterskin

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "mana_vault_same_lane_benchmark_cut_bender_s_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### invoke_calamity_same_lane_benchmark_cut_creative_technique

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "invoke_calamity_same_lane_benchmark_cut_creative_technique", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### velomachus_lorehold_same_lane_benchmark_cut_creative_technique

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "velomachus_lorehold_same_lane_benchmark_cut_creative_technique", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |
