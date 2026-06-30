# Lorehold Recursion Cut Model - 2026-06-27

- Generated at: `2026-06-30T14:32:00Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck id: `607`
- Miner report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Exposure profiles: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_cut_candidate_exposure_profile_20260627_v1.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v1.json`
- Prior package reports: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `2`
- Evaluated pairs: `10`
- Preflight benchmark-ready pairs: `0`
- Prior rejected exact pairs: `1`
- Prior rejected cut counts: `{"pinnacle monk mystic peak": 1}`
- Status counts: `{"blocked_core_or_current_engine_cut": 8, "blocked_cut_prior_reject": 1, "blocked_prior_reject": 1}`
- Recommended next action: `do_not_gate_recursion_without_non_squee_cut_or_multi_card_package`

## Preflight Benchmark Candidates

- None.

## Top Pair Evaluations

| Rank | Candidate | Cut | Status | Score | Candidate Role | Cut Role | Cut Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Volcanic Vision | Pinnacle Monk // Mystic Peak | `blocked_prior_reject` | 130 | `recursion_candidate` | `engine` | 14 | candidate_low_natural_exposure; prior_exact_package_reject |
| 2 | Volcanic Vision | Farewell | `blocked_core_or_current_engine_cut` | 126 | `recursion_candidate` | `board_wipe` | 29 | candidate_low_natural_exposure; cut_has_board_wipe_tag; cut_is_board_wipe |
| 3 | Volcanic Vision | Furygale Flocking | `blocked_core_or_current_engine_cut` | 126 | `recursion_candidate` | `wincon` | 22 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_is_wincon |
| 4 | Restoration Seminar | Pinnacle Monk // Mystic Peak | `blocked_cut_prior_reject` | 118 | `recursion_candidate` | `engine` | 14 | candidate_low_natural_exposure; cut_prior_reject_count:1 |
| 5 | Volcanic Vision | Squee, Goblin Nabob | `blocked_core_or_current_engine_cut` | 116 | `recursion_candidate` | `recursion_engine` | 6752 | candidate_low_natural_exposure; cut_high_exposure:6752; cut_is_current_squee_recursion_engine |
| 6 | Restoration Seminar | Farewell | `blocked_core_or_current_engine_cut` | 114 | `recursion_candidate` | `board_wipe` | 29 | candidate_low_natural_exposure; cut_has_board_wipe_tag; cut_is_board_wipe |
| 7 | Restoration Seminar | Furygale Flocking | `blocked_core_or_current_engine_cut` | 114 | `recursion_candidate` | `wincon` | 22 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_is_wincon |
| 8 | Volcanic Vision | Mizzix's Mastery | `blocked_core_or_current_engine_cut` | 108 | `recursion_candidate` | `wincon` | 196 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:196; cut_is_wincon |
| 9 | Restoration Seminar | Squee, Goblin Nabob | `blocked_core_or_current_engine_cut` | 104 | `recursion_candidate` | `recursion_engine` | 6752 | candidate_low_natural_exposure; cut_high_exposure:6752; cut_is_current_squee_recursion_engine |
| 10 | Restoration Seminar | Mizzix's Mastery | `blocked_core_or_current_engine_cut` | 96 | `recursion_candidate` | `wincon` | 196 | candidate_low_natural_exposure; cut_has_wincon_tag; cut_high_exposure:196; cut_is_wincon |

## Guardrails

- `preserve_squee_current_engine`: Squee has measured graveyard-return exposure and should not be cut for Volcanic Vision or Restoration Seminar.
- `protect_wincon_and_wipe_slots`: Farewell, Furygale Flocking, and Mizzix's Mastery carry core wipe/wincon roles and are not blind recursion cuts.
