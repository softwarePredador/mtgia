# Lorehold Hand Filter Cut Model - 2026-06-28

- Generated at: `2026-06-30T07:16:32Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck id: `607`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_candidate_exposure_profile_20260627_v1.json`
- Prior package reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `5`
- Evaluated pairs: `25`
- Preflight benchmark-ready pairs: `0`
- Prior rejected exact pairs: `2`
- Prior rejected cut counts: `{"big score": 2}`
- Status counts: `{"blocked_cut_core_or_high_exposure": 15, "blocked_cut_repeated_benchmark_reject": 3, "blocked_prior_reject": 2, "protected_benchmark_required": 3, "runtime_smoke_required_before_gate": 2}`
- Recommended next action: `do_not_gate_hand_filter_without_new_cut_or_runtime_evidence`

## Preflight Benchmark Candidates

- None.

## Top Pair Evaluations

| Rank | Candidate | Cut | Status | Score | Candidate Role | Cut Role | Cut Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Valakut Awakening // Valakut Stoneforge | Big Score | `blocked_prior_reject` | 118 | `draw_filter_value` | `ramp` | 34 | cut_removes_ramp_or_treasure_role; prior_exact_package_reject |
| 2 | Wheel of Fortune | Big Score | `blocked_prior_reject` | 118 | `draw_filter_value` | `ramp` | 34 | cut_removes_ramp_or_treasure_role; prior_exact_package_reject |
| 3 | Apex of Power | Big Score | `blocked_cut_repeated_benchmark_reject` | 115 | `draw_filter_value` | `ramp` | 34 | candidate_zero_natural_exposure; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 4 | Valakut Awakening // Valakut Stoneforge | Rise of the Eldrazi | `blocked_cut_core_or_high_exposure` | 106 | `draw_filter_value` | `wincon` | 206 | cut_high_exposure:206; cut_is_wincon |
| 5 | Wheel of Fortune | Rise of the Eldrazi | `blocked_cut_core_or_high_exposure` | 106 | `draw_filter_value` | `wincon` | 206 | cut_high_exposure:206; cut_is_wincon |
| 6 | Apex of Power | Rise of the Eldrazi | `blocked_cut_core_or_high_exposure` | 103 | `draw_filter_value` | `wincon` | 206 | candidate_zero_natural_exposure; cut_high_exposure:206; cut_is_wincon |
| 7 | Valakut Awakening // Valakut Stoneforge | Monument to Endurance | `blocked_cut_core_or_high_exposure` | 98 | `draw_filter_value` | `ramp` | 262 | cut_high_exposure:262; cut_removes_ramp_or_treasure_role |
| 8 | Wheel of Fortune | Monument to Endurance | `blocked_cut_core_or_high_exposure` | 98 | `draw_filter_value` | `ramp` | 262 | cut_high_exposure:262; cut_removes_ramp_or_treasure_role |
| 9 | Olórin's Searing Light | Big Score | `blocked_cut_repeated_benchmark_reject` | 97 | `draw_filter_value` | `ramp` | 34 | candidate_low_natural_exposure; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 10 | Valakut Awakening // Valakut Stoneforge | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 96 | `draw_filter_value` | `draw` | 612 | cut_high_exposure:612 |
| 11 | Wheel of Fortune | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 96 | `draw_filter_value` | `draw` | 612 | cut_high_exposure:612 |
| 12 | Apex of Power | Monument to Endurance | `blocked_cut_core_or_high_exposure` | 95 | `draw_filter_value` | `ramp` | 262 | candidate_zero_natural_exposure; cut_high_exposure:262; cut_removes_ramp_or_treasure_role |
| 13 | Apex of Power | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 93 | `draw_filter_value` | `draw` | 612 | candidate_zero_natural_exposure; cut_high_exposure:612 |
| 14 | Olórin's Searing Light | Rise of the Eldrazi | `blocked_cut_core_or_high_exposure` | 85 | `draw_filter_value` | `wincon` | 206 | candidate_low_natural_exposure; cut_high_exposure:206; cut_is_wincon |
| 15 | Olórin's Searing Light | Monument to Endurance | `blocked_cut_core_or_high_exposure` | 77 | `draw_filter_value` | `ramp` | 262 | candidate_low_natural_exposure; cut_high_exposure:262; cut_removes_ramp_or_treasure_role |
| 16 | Valakut Awakening // Valakut Stoneforge | Artist's Talent | `protected_benchmark_required` | 76 | `draw_filter_value` | `draw` | 94 | cut_protected_exposure:94 |
| 17 | Wheel of Fortune | Artist's Talent | `protected_benchmark_required` | 76 | `draw_filter_value` | `draw` | 94 | cut_protected_exposure:94 |
| 18 | Olórin's Searing Light | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 75 | `draw_filter_value` | `draw` | 612 | candidate_low_natural_exposure; cut_high_exposure:612 |
| 19 | Dance with Calamity | Big Score | `blocked_cut_repeated_benchmark_reject` | 73 | `draw_filter_value` | `ramp` | 34 | candidate_zero_natural_exposure; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 20 | Apex of Power | Artist's Talent | `runtime_smoke_required_before_gate` | 73 | `draw_filter_value` | `draw` | 94 | candidate_zero_natural_exposure; cut_protected_exposure:94 |
| 21 | Dance with Calamity | Rise of the Eldrazi | `blocked_cut_core_or_high_exposure` | 61 | `draw_filter_value` | `wincon` | 206 | candidate_zero_natural_exposure; cut_high_exposure:206; cut_is_wincon |
| 22 | Olórin's Searing Light | Artist's Talent | `protected_benchmark_required` | 55 | `draw_filter_value` | `draw` | 94 | candidate_low_natural_exposure; cut_protected_exposure:94 |
| 23 | Dance with Calamity | Monument to Endurance | `blocked_cut_core_or_high_exposure` | 53 | `draw_filter_value` | `ramp` | 262 | candidate_zero_natural_exposure; cut_high_exposure:262; cut_removes_ramp_or_treasure_role |
| 24 | Dance with Calamity | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 51 | `draw_filter_value` | `draw` | 612 | candidate_zero_natural_exposure; cut_high_exposure:612 |
| 25 | Dance with Calamity | Artist's Talent | `runtime_smoke_required_before_gate` | 31 | `draw_filter_value` | `draw` | 94 | candidate_zero_natural_exposure; cut_protected_exposure:94 |

## Guardrails

- `do_not_cut_high_exposure_draw_or_wincon`: Esper Sentinel, Monument to Endurance, and Rise of the Eldrazi have high measured exposure or core wincon roles.
- `big_score_is_benchmark_only`: Big Score is the least-exposed visible cut, but it still provides discard, draw, treasures, and miracle density.
