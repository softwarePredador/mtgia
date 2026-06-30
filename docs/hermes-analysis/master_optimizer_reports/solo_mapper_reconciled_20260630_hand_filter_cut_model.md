# Lorehold Hand Filter Cut Model - 2026-06-28

- Generated at: `2026-06-30T14:32:00Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck id: `607`
- Miner report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Exposure profiles: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_candidate_exposure_profile_20260630_active_rule_roles_explicit.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260630_post_pg270_deck607.json`
- Prior package reports: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `5`
- Evaluated pairs: `25`
- Preflight benchmark-ready pairs: `0`
- Expanded non-core evaluated pairs: `445`
- Expanded preflight benchmark-ready pairs: `0`
- Expanded miracle-core override-required pairs: `0`
- Prior rejected exact pairs: `4`
- Prior rejected cut counts: `{"big score": 2, "improvisation capstone": 2}`
- Status counts: `{"blocked_candidate_lane_mismatch": 4, "blocked_cut_core_or_high_exposure": 8, "blocked_cut_cross_lane": 8, "blocked_cut_repeated_benchmark_reject": 3, "blocked_prior_reject": 2}`
- Expanded status counts: `{"blocked_candidate_lane_mismatch": 88, "blocked_cut_core_or_high_exposure": 4, "blocked_cut_repeated_benchmark_reject": 3, "blocked_expanded_cut_cross_lane": 288, "blocked_expanded_cut_protected_anchor": 60, "blocked_prior_reject": 2}`
- Recommended next action: `do_not_gate_hand_filter_without_new_cut_or_runtime_evidence`

## Preflight Benchmark Candidates

- None.

## Expanded Non-Core Cut Search

- No expanded preflight-ready pair found.

### Top Expanded Evaluations

| Rank | Candidate | Cut | Status | Score | Cut Role | Cut Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | ---: | --- |
| 1 | Apex of Power | Ancient Tomb | `blocked_expanded_cut_cross_lane` | 123 | `land` | 39 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_cross_lane_role_signals:ramp_engine,tutor_access; cut_is_land |
| 2 | Apex of Power | Arid Mesa | `blocked_expanded_cut_cross_lane` | 123 | `land` | 13 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 3 | Apex of Power | Battlefield Forge | `blocked_expanded_cut_cross_lane` | 123 | `land` | 15 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_cross_lane_role_signals:ramp_engine; cut_is_land |
| 4 | Apex of Power | Bloodstained Mire | `blocked_expanded_cut_cross_lane` | 123 | `land` | 31 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 5 | Apex of Power | Call Forth the Tempest | `blocked_expanded_cut_cross_lane` | 123 | `board_wipe` | 8 | candidate_zero_natural_exposure; cut_cross_lane:board_wipe; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:board_wipe; cut_miracle_core_spell_payoff_requires_explicit_override |
| 6 | Apex of Power | Command Beacon | `blocked_expanded_cut_cross_lane` | 123 | `land` | 18 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 7 | Apex of Power | Dawn's Truce | `blocked_expanded_cut_cross_lane` | 123 | `protection` | 17 | candidate_zero_natural_exposure; cut_cross_lane:protection; cut_cross_lane_secondary_tags:protection |
| 8 | Apex of Power | Elegant Parlor | `blocked_expanded_cut_cross_lane` | 123 | `land` | 8 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 9 | Apex of Power | Everything Comes to Dust | `blocked_expanded_cut_cross_lane` | 123 | `board_wipe` | 34 | candidate_zero_natural_exposure; cut_cross_lane:board_wipe; cut_cross_lane_role_signals:board_wipe_pressure_reset,pressure_reset_board_wipe; cut_cross_lane_secondary_tags:board_wipe; cut_miracle_core_spell_payoff_requires_explicit_override |
| 10 | Apex of Power | Exotic Orchard | `blocked_expanded_cut_cross_lane` | 123 | `land` | 14 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 11 | Apex of Power | Flawless Maneuver | `blocked_expanded_cut_cross_lane` | 123 | `protection` | 16 | candidate_zero_natural_exposure; cut_cross_lane:protection; cut_cross_lane_secondary_tags:protection |
| 12 | Apex of Power | Flooded Strand | `blocked_expanded_cut_cross_lane` | 123 | `land` | 18 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 13 | Apex of Power | Generous Gift | `blocked_expanded_cut_cross_lane` | 123 | `removal` | 38 | candidate_zero_natural_exposure; cut_cross_lane:removal; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal |
| 14 | Apex of Power | Giver of Runes | `blocked_expanded_cut_cross_lane` | 123 | `protection` | 58 | candidate_zero_natural_exposure; cut_cross_lane:protection; cut_cross_lane_secondary_tags:creature,protection |
| 15 | Apex of Power | Glittering Massif | `blocked_expanded_cut_cross_lane` | 123 | `land` | 75 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_cross_lane_role_signals:ramp_engine; cut_is_land |
| 16 | Apex of Power | Hexing Squelcher | `blocked_expanded_cut_cross_lane` | 123 | `creature` | 78 | candidate_zero_natural_exposure; cut_cross_lane:creature; cut_cross_lane_secondary_tags:creature |
| 17 | Apex of Power | High Noon | `blocked_expanded_cut_cross_lane` | 123 | `removal` | 66 | candidate_zero_natural_exposure; cut_cross_lane:removal; cut_cross_lane_secondary_tags:removal |
| 18 | Apex of Power | Marsh Flats | `blocked_expanded_cut_cross_lane` | 123 | `land` | 29 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 19 | Apex of Power | Mother of Runes | `blocked_expanded_cut_cross_lane` | 123 | `protection` | 70 | candidate_zero_natural_exposure; cut_cross_lane:protection; cut_cross_lane_secondary_tags:creature,protection |
| 20 | Apex of Power | Pinnacle Monk // Mystic Peak | `blocked_expanded_cut_cross_lane` | 123 | `engine` | 8 | candidate_zero_natural_exposure; cut_cross_lane_role_signals:graveyard_recursion,recursion_engine; cut_cross_lane_secondary_tags:removal; cut_miracle_core_spell_payoff_requires_explicit_override |
| 21 | Apex of Power | Plaza of Heroes | `blocked_expanded_cut_cross_lane` | 123 | `land` | 17 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_cross_lane_role_signals:ramp_engine; cut_is_land |
| 22 | Apex of Power | Prismari Pianist | `blocked_expanded_cut_cross_lane` | 123 | `wincon` | 71 | candidate_zero_natural_exposure; cut_cross_lane:wincon; cut_cross_lane_secondary_tags:wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 23 | Apex of Power | Prismatic Vista | `blocked_expanded_cut_cross_lane` | 123 | `land` | 14 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |
| 24 | Apex of Power | Radiant Summit | `blocked_expanded_cut_cross_lane` | 123 | `land` | 7 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_cross_lane_role_signals:ramp_engine; cut_is_land |
| 25 | Apex of Power | Reliquary Tower | `blocked_expanded_cut_cross_lane` | 123 | `land` | 31 | candidate_zero_natural_exposure; cut_cross_lane:land; cut_is_land |

### Miracle-Core Override Candidates

- None.

## Top Pair Evaluations

| Rank | Candidate | Cut | Status | Score | Candidate Role | Cut Role | Cut Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Apex of Power | Rise of the Eldrazi | `blocked_cut_cross_lane` | 123 | `ramp_engine` | `wincon` | 56 | candidate_zero_natural_exposure; cut_cross_lane:wincon; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal,wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 2 | Apex of Power | Monument to Endurance | `blocked_cut_cross_lane` | 115 | `ramp_engine` | `ramp` | 56 | candidate_zero_natural_exposure; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp; cut_removes_ramp_or_treasure_role |
| 3 | Apex of Power | Big Score | `blocked_cut_repeated_benchmark_reject` | 115 | `ramp_engine` | `ramp` | 34 | candidate_zero_natural_exposure; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp,treasure_maker; cut_miracle_core_spell_payoff_requires_explicit_override; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 4 | Valakut Awakening // Valakut Stoneforge | Rise of the Eldrazi | `blocked_cut_cross_lane` | 111 | `draw_filter_value` | `wincon` | 56 | cut_cross_lane:wincon; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal,wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 5 | Wheel of Fortune | Rise of the Eldrazi | `blocked_cut_cross_lane` | 111 | `draw_filter_value` | `wincon` | 56 | cut_cross_lane:wincon; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal,wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 6 | Valakut Awakening // Valakut Stoneforge | Monument to Endurance | `blocked_cut_cross_lane` | 103 | `draw_filter_value` | `ramp` | 56 | cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp; cut_removes_ramp_or_treasure_role |
| 7 | Wheel of Fortune | Monument to Endurance | `blocked_cut_cross_lane` | 103 | `draw_filter_value` | `ramp` | 56 | cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp; cut_removes_ramp_or_treasure_role |
| 8 | Valakut Awakening // Valakut Stoneforge | Big Score | `blocked_prior_reject` | 103 | `draw_filter_value` | `ramp` | 34 | cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp,treasure_maker; cut_miracle_core_spell_payoff_requires_explicit_override; cut_removes_ramp_or_treasure_role; prior_exact_package_reject |
| 9 | Wheel of Fortune | Big Score | `blocked_prior_reject` | 103 | `draw_filter_value` | `ramp` | 34 | cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp,treasure_maker; cut_miracle_core_spell_payoff_requires_explicit_override; cut_removes_ramp_or_treasure_role; prior_exact_package_reject |
| 10 | Dance with Calamity | Rise of the Eldrazi | `blocked_cut_cross_lane` | 95 | `draw_filter_value` | `wincon` | 56 | candidate_zero_natural_exposure; cut_cross_lane:wincon; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal,wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 11 | Apex of Power | Artist's Talent | `blocked_cut_core_or_high_exposure` | 93 | `ramp_engine` | `draw` | 494 | candidate_zero_natural_exposure; cut_expanded_protected_exposure:494; cut_high_exposure:494; cut_miracle_core_spell_payoff_requires_explicit_override |
| 12 | Apex of Power | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 93 | `ramp_engine` | `draw` | 471 | candidate_zero_natural_exposure; cut_expanded_protected_exposure:471; cut_high_exposure:471; cut_miracle_core_spell_payoff_requires_explicit_override |
| 13 | Dance with Calamity | Monument to Endurance | `blocked_cut_cross_lane` | 87 | `draw_filter_value` | `ramp` | 56 | candidate_zero_natural_exposure; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp; cut_removes_ramp_or_treasure_role |
| 14 | Dance with Calamity | Big Score | `blocked_cut_repeated_benchmark_reject` | 87 | `draw_filter_value` | `ramp` | 34 | candidate_zero_natural_exposure; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp,treasure_maker; cut_miracle_core_spell_payoff_requires_explicit_override; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 15 | Olórin's Searing Light | Rise of the Eldrazi | `blocked_candidate_lane_mismatch` | 81 | `spot_removal` | `wincon` | 56 | candidate_active_rule_not_hand_filter; cut_cross_lane:wincon; cut_cross_lane_role_signals:spot_removal; cut_cross_lane_secondary_tags:removal,wincon; cut_is_wincon; cut_miracle_core_spell_payoff_requires_explicit_override |
| 16 | Valakut Awakening // Valakut Stoneforge | Artist's Talent | `blocked_cut_core_or_high_exposure` | 81 | `draw_filter_value` | `draw` | 494 | cut_expanded_protected_exposure:494; cut_high_exposure:494; cut_miracle_core_spell_payoff_requires_explicit_override |
| 17 | Valakut Awakening // Valakut Stoneforge | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 81 | `draw_filter_value` | `draw` | 471 | cut_expanded_protected_exposure:471; cut_high_exposure:471; cut_miracle_core_spell_payoff_requires_explicit_override |
| 18 | Wheel of Fortune | Artist's Talent | `blocked_cut_core_or_high_exposure` | 81 | `draw_filter_value` | `draw` | 494 | cut_expanded_protected_exposure:494; cut_high_exposure:494; cut_miracle_core_spell_payoff_requires_explicit_override |
| 19 | Wheel of Fortune | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 81 | `draw_filter_value` | `draw` | 471 | cut_expanded_protected_exposure:471; cut_high_exposure:471; cut_miracle_core_spell_payoff_requires_explicit_override |
| 20 | Olórin's Searing Light | Monument to Endurance | `blocked_candidate_lane_mismatch` | 73 | `spot_removal` | `ramp` | 56 | candidate_active_rule_not_hand_filter; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp; cut_removes_ramp_or_treasure_role |
| 21 | Olórin's Searing Light | Big Score | `blocked_cut_repeated_benchmark_reject` | 73 | `spot_removal` | `ramp` | 34 | candidate_active_rule_not_hand_filter; cut_cross_lane:ramp; cut_cross_lane_role_signals:ramp_engine; cut_cross_lane_secondary_tags:ramp,treasure_maker; cut_miracle_core_spell_payoff_requires_explicit_override; cut_removes_ramp_or_treasure_role; cut_repeated_prior_rejects:2 |
| 22 | Dance with Calamity | Artist's Talent | `blocked_cut_core_or_high_exposure` | 65 | `draw_filter_value` | `draw` | 494 | candidate_zero_natural_exposure; cut_expanded_protected_exposure:494; cut_high_exposure:494; cut_miracle_core_spell_payoff_requires_explicit_override |
| 23 | Dance with Calamity | Esper Sentinel | `blocked_cut_core_or_high_exposure` | 65 | `draw_filter_value` | `draw` | 471 | candidate_zero_natural_exposure; cut_expanded_protected_exposure:471; cut_high_exposure:471; cut_miracle_core_spell_payoff_requires_explicit_override |
| 24 | Olórin's Searing Light | Artist's Talent | `blocked_candidate_lane_mismatch` | 51 | `spot_removal` | `draw` | 494 | candidate_active_rule_not_hand_filter; cut_expanded_protected_exposure:494; cut_high_exposure:494; cut_miracle_core_spell_payoff_requires_explicit_override |
| 25 | Olórin's Searing Light | Esper Sentinel | `blocked_candidate_lane_mismatch` | 51 | `spot_removal` | `draw` | 471 | candidate_active_rule_not_hand_filter; cut_expanded_protected_exposure:471; cut_high_exposure:471; cut_miracle_core_spell_payoff_requires_explicit_override |

## Guardrails

- `do_not_cut_high_exposure_draw_or_wincon`: Esper Sentinel, Monument to Endurance, and Rise of the Eldrazi have high measured exposure or core wincon roles.
- `big_score_is_benchmark_only`: Big Score is the least-exposed visible cut, but it still provides discard, draw, treasures, and miracle density.
- `expanded_search_same_lane_only`: Full deck-607 cut search may only advance hand-filter swaps against non-anchor draw/engine/unknown slots with active runtime and measured exposure.
