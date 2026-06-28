# Lorehold Recursion Cut Model - 2026-06-27

- Generated at: `2026-06-28T00:34:52Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Exposure profiles: `docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_cut_candidate_exposure_profile_20260627_v1.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `2`
- Evaluated pairs: `10`
- Preflight benchmark-ready pairs: `2`
- Status counts: `{"blocked_core_or_current_engine_cut": 8, "preflight_benchmark_ready": 2}`
- Recommended next action: `preflight_Volcanic Vision_over_Pinnacle Monk // Mystic Peak`

## Preflight Benchmark Candidates

| Rank | Candidate | Cut | Score | Candidate Exposure | Cut Exposure | Blockers |
| ---: | --- | --- | ---: | ---: | ---: | --- |
| 1 | Volcanic Vision | Pinnacle Monk // Mystic Peak | 130 | 2 | 14 | candidate_low_natural_exposure |
| 2 | Restoration Seminar | Pinnacle Monk // Mystic Peak | 118 | 2 | 14 | candidate_low_natural_exposure |

## Top Pair Evaluations

| Rank | Candidate | Cut | Status | Score | Candidate Role | Cut Role | Cut Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Volcanic Vision | Pinnacle Monk // Mystic Peak | `preflight_benchmark_ready` | 130 | `recursion_candidate` | `engine` | 14 | candidate_low_natural_exposure |
| 2 | Volcanic Vision | Farewell | `blocked_core_or_current_engine_cut` | 126 | `recursion_candidate` | `board_wipe` | 29 | candidate_low_natural_exposure; cut_has_board_wipe_tag; cut_is_board_wipe |
| 3 | Volcanic Vision | Furygale Flocking | `blocked_core_or_current_engine_cut` | 126 | `recursion_candidate` | `wincon` | 22 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_is_wincon |
| 4 | Restoration Seminar | Pinnacle Monk // Mystic Peak | `preflight_benchmark_ready` | 118 | `recursion_candidate` | `engine` | 14 | candidate_low_natural_exposure |
| 5 | Volcanic Vision | Squee, Goblin Nabob | `blocked_core_or_current_engine_cut` | 116 | `recursion_candidate` | `wincon` | 6752 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:6752; cut_is_current_squee_recursion_engine; cut_is_wincon |
| 6 | Restoration Seminar | Farewell | `blocked_core_or_current_engine_cut` | 114 | `recursion_candidate` | `board_wipe` | 29 | candidate_low_natural_exposure; cut_has_board_wipe_tag; cut_is_board_wipe |
| 7 | Restoration Seminar | Furygale Flocking | `blocked_core_or_current_engine_cut` | 114 | `recursion_candidate` | `wincon` | 22 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_is_wincon |
| 8 | Volcanic Vision | Mizzix's Mastery | `blocked_core_or_current_engine_cut` | 108 | `recursion_candidate` | `wincon` | 196 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:196; cut_is_wincon |
| 9 | Restoration Seminar | Squee, Goblin Nabob | `blocked_core_or_current_engine_cut` | 104 | `recursion_candidate` | `wincon` | 6752 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:6752; cut_is_current_squee_recursion_engine; cut_is_wincon |
| 10 | Restoration Seminar | Mizzix's Mastery | `blocked_core_or_current_engine_cut` | 96 | `recursion_candidate` | `wincon` | 196 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:196; cut_is_wincon |

## Guardrails

- `preserve_squee_current_engine`: Squee has measured graveyard-return exposure and should not be cut for Volcanic Vision or Restoration Seminar.
- `protect_wincon_and_wipe_slots`: Farewell, Furygale Flocking, and Mizzix's Mastery carry core wipe/wincon roles and are not blind recursion cuts.
