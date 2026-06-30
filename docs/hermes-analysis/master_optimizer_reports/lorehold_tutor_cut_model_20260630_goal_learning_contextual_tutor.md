# Lorehold Tutor Cut Model - 2026-06-30

- Generated at: `2026-06-30T22:06:24Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck id: `607`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260630_goal_learning_deck607_current.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v2_role_fix.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_candidate_exposure_profile_20260627_v1.json`
- Prior package reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_recurring_seed_window_20260628_v1_run.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_20260628_091321.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_witch_confirm_20260628_091458.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v5_20260628_092712.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_family_benchmark_matrix_20260628_v6_20260628_093001.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_decision_contract_20260628_v1_20260628_190000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_outcome_audit_20260628_actionability_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_forced_exposure_probe_decision_20260630.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_forced_signal_natural_confirm_decision_20260630.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_gate_decision_20260630.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_decision_20260630_goal_learning.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_decision_20260630_goal_learning.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_possibility_storm_creative_technique_decision_20260630_goal_learning.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `2`
- Evaluated pairs: `188`
- Direct gate-ready pairs: `0`
- Status counts: `{"blocked": 104, "blocked_ramp_floor_mismatch": 8, "manual_cut_model_required": 2, "manual_role_review_required": 4, "protected_benchmark_required": 70}`
- Recommended next action: `do_not_gate_direct_tutor_swap; benchmark same-access cuts or build additive package`

## Tutor Candidates

| Candidate | Active Rules | Exposure | Role | Prior Evidence |
| --- | ---: | ---: | --- | --- |
| Enlightened Tutor | 1 | 202 | `tutor_access` | enlightened_access_benchmark_cut_land_tax -66.67pp / seed -66.67pp; enlightened_access_benchmark_cut_land_tax -66.67pp / seed -66.67pp; enlightened_access_benchmark_cut_land_tax +0.00pp / seed +0.00pp; enlightened_access_benchmark_cut_land_tax +8.33pp / seed +8.33pp; enlightened_engine_access_cut_thor -44.45pp / seed -44.45pp; enlightened_engine_access_cut_thor -44.45pp / seed -44.45pp; enlightened_engine_access_cut_thor -44.45pp / seed -44.45pp |
| Gamble | 1 | 228 | `tutor_access` | gamble_approach_access_cut_creative +3.70pp / seed -44.45pp; gamble_approach_access_cut_creative +3.70pp / seed -44.45pp; gamble_approach_access_cut_creative +3.70pp / seed -44.45pp; gamble_access_benchmark_cut_land_tax -66.67pp / seed -66.67pp; gamble_access_benchmark_cut_land_tax -66.67pp / seed -66.67pp; gamble_access_benchmark_cut_land_tax -8.33pp / seed -8.33pp; gamble_access_cut_thor -55.56pp / seed -55.56pp; gamble_access_cut_thor -55.56pp / seed -55.56pp; gamble_access_cut_thor -55.56pp / seed -55.56pp |

## Top Manual Benchmarks

| Rank | Candidate | Cut | Status | Score | Lane | Cut Status | Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Enlightened Tutor | Artist's Talent | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 463 | cut is protected support; needs explicit same-access benchmark before battle |
| 2 | Enlightened Tutor | Big Score | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 38 | cut is protected support; needs explicit same-access benchmark before battle |
| 3 | Enlightened Tutor | Call Forth the Tempest | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 8 | cut is protected support; needs explicit same-access benchmark before battle |
| 4 | Enlightened Tutor | Esper Sentinel | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 456 | cut is protected support; needs explicit same-access benchmark before battle |
| 5 | Enlightened Tutor | Hit the Mother Lode | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 11 | cut is protected support; needs explicit same-access benchmark before battle |
| 6 | Enlightened Tutor | Improvisation Capstone | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 59 | cut is protected support; needs explicit same-access benchmark before battle |
| 7 | Enlightened Tutor | Library of Leng | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 713 | cut is protected support; needs explicit same-access benchmark before battle |
| 8 | Enlightened Tutor | Monument to Endurance | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 56 | cut is protected support; needs explicit same-access benchmark before battle |
| 9 | Enlightened Tutor | Reforge the Soul | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 23 | cut is protected support; needs explicit same-access benchmark before battle |
| 10 | Enlightened Tutor | Rise of the Eldrazi | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 54 | cut is protected support; needs explicit same-access benchmark before battle |
| 11 | Enlightened Tutor | Scroll Rack | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 2345 | cut is protected support; needs explicit same-access benchmark before battle |
| 12 | Enlightened Tutor | Sensei's Divining Top | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 2972 | cut is protected support; needs explicit same-access benchmark before battle |
| 13 | Enlightened Tutor | Smothering Tithe | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 854 | cut is protected support; needs explicit same-access benchmark before battle |
| 14 | Enlightened Tutor | Starfall Invocation | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 359 | cut is protected support; needs explicit same-access benchmark before battle |
| 15 | Enlightened Tutor | Tempt with Bunnies | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 31 | cut is protected support; needs explicit same-access benchmark before battle |
| 16 | Enlightened Tutor | Unexpected Windfall | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 33 | cut is protected support; needs explicit same-access benchmark before battle |
| 17 | Gamble | Artist's Talent | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 463 | cut is protected support; needs explicit same-access benchmark before battle |
| 18 | Gamble | Big Score | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 38 | cut is protected support; needs explicit same-access benchmark before battle |
| 19 | Gamble | Call Forth the Tempest | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 8 | cut is protected support; needs explicit same-access benchmark before battle |
| 20 | Gamble | Esper Sentinel | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 456 | cut is protected support; needs explicit same-access benchmark before battle |

## Direct Gate Candidates

- None. No direct tutor swap is seed-safe from current evidence.

## Prior Tutor Evidence

- `enlightened_access_benchmark_cut_land_tax` adds Enlightened Tutor, cuts Land Tax: delta `-66.67pp`, strong seed `-66.67pp`, decision `reject_or_rework`
- `enlightened_access_benchmark_cut_land_tax` adds Enlightened Tutor, cuts Land Tax: delta `-66.67pp`, strong seed `-66.67pp`, decision `insufficient_card_outcome_used_sample`
- `enlightened_access_benchmark_cut_land_tax` adds Enlightened Tutor, cuts Land Tax: delta `+0.00pp`, strong seed `+0.00pp`, decision `tie_watch_strategy_regression`
- `enlightened_access_benchmark_cut_land_tax` adds Enlightened Tutor, cuts Land Tax: delta `+8.33pp`, strong seed `+8.33pp`, decision `forced_access_signal_requires_natural_confirmation`
- `enlightened_engine_access_cut_thor` adds Enlightened Tutor, cuts Thor, God of Thunder: delta `-44.45pp`, strong seed `-44.45pp`, decision `reject_or_rework`
- `enlightened_engine_access_cut_thor` adds Enlightened Tutor, cuts Thor, God of Thunder: delta `-44.45pp`, strong seed `-44.45pp`, decision `reject_or_rework`
- `enlightened_engine_access_cut_thor` adds Enlightened Tutor, cuts Thor, God of Thunder: delta `-44.45pp`, strong seed `-44.45pp`, decision `reject_or_rework`
- `gamble_approach_access_cut_creative` adds Gamble, cuts Creative Technique: delta `+3.70pp`, strong seed `-44.45pp`, decision `probation_deeper_gate_only`
- `gamble_approach_access_cut_creative` adds Gamble, cuts Creative Technique: delta `+3.70pp`, strong seed `-44.45pp`, decision `probation_deeper_gate_only`
- `gamble_approach_access_cut_creative` adds Gamble, cuts Creative Technique: delta `+3.70pp`, strong seed `-44.45pp`, decision `probation_deeper_gate_only`
- `gamble_access_benchmark_cut_land_tax` adds Gamble, cuts Land Tax: delta `-66.67pp`, strong seed `-66.67pp`, decision `reject_or_rework`
- `gamble_access_benchmark_cut_land_tax` adds Gamble, cuts Land Tax: delta `-66.67pp`, strong seed `-66.67pp`, decision `insufficient_card_outcome_used_sample`
- `gamble_access_benchmark_cut_land_tax` adds Gamble, cuts Land Tax: delta `-8.33pp`, strong seed `-8.33pp`, decision `forced_access_no_lift_reject_or_rework`
- `gamble_access_cut_thor` adds Gamble, cuts Thor, God of Thunder: delta `-55.56pp`, strong seed `-55.56pp`, decision `reject_or_rework`
- `gamble_access_cut_thor` adds Gamble, cuts Thor, God of Thunder: delta `-55.56pp`, strong seed `-55.56pp`, decision `reject_or_rework`
- `gamble_access_cut_thor` adds Gamble, cuts Thor, God of Thunder: delta `-55.56pp`, strong seed `-55.56pp`, decision `reject_or_rework`

## Guardrails

- `do_not_repeat_thor_or_creative_tutor_cuts`: Thor and Creative Technique both have prior strong-seed regressions in tutor packages.
- `do_not_trade_tutor_for_early_mana_without_benchmark`: The current shell is mana-hungry; direct tutor-over-ramp swaps are cross-lane and not seed-safe.
- `same_access_benchmark_before_gate`: Land Tax/topdeck engines have high measured exposure and require explicit access-lane comparison before battle.
