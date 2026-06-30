# Lorehold Tutor Cut Model - 2026-06-28

- Generated at: `2026-06-30T20:28:44Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Deck id: `607`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v2_role_fix.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_candidate_exposure_profile_20260627_v1.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Candidate count: `2`
- Evaluated pairs: `188`
- Direct gate-ready pairs: `0`
- Status counts: `{"blocked": 102, "blocked_ramp_floor_mismatch": 8, "manual_cut_model_required": 2, "manual_role_review_required": 4, "protected_benchmark_required": 72}`
- Recommended next action: `do_not_gate_direct_tutor_swap; benchmark same-access cuts or build additive package`

## Tutor Candidates

| Candidate | Active Rules | Exposure | Role | Prior Evidence |
| --- | ---: | ---: | --- | --- |
| Enlightened Tutor | 1 | 202 | `tutor_access` | enlightened_engine_access_cut_thor -44.45pp / seed -44.45pp |
| Gamble | 1 | 228 | `tutor_access` | gamble_approach_access_cut_creative +3.70pp / seed -44.45pp; gamble_access_cut_thor -55.56pp / seed -55.56pp |

## Top Manual Benchmarks

| Rank | Candidate | Cut | Status | Score | Lane | Cut Status | Exposure | Blockers |
| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |
| 1 | Enlightened Tutor | Land Tax | `protected_benchmark_required` | 50 | `selection` | `requires_same_lane_gate` | 296 | cut is protected support; needs explicit same-access benchmark before battle |
| 2 | Gamble | Land Tax | `protected_benchmark_required` | 50 | `selection` | `requires_same_lane_gate` | 296 | cut is protected support; needs explicit same-access benchmark before battle |
| 3 | Enlightened Tutor | Library of Leng | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 91 | cut is protected support; needs explicit same-access benchmark before battle |
| 4 | Enlightened Tutor | Scroll Rack | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 788 | cut is protected support; needs explicit same-access benchmark before battle |
| 5 | Enlightened Tutor | Sensei's Divining Top | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 626 | cut is protected support; needs explicit same-access benchmark before battle |
| 6 | Gamble | Library of Leng | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 91 | cut is protected support; needs explicit same-access benchmark before battle |
| 7 | Gamble | Scroll Rack | `protected_benchmark_required` | 30 | `topdeck_miracle_setup` | `requires_same_lane_gate` | 788 | cut is protected support; needs explicit same-access benchmark before battle |
| 8 | Gamble | Sensei's Divining Top | `protected_benchmark_required` | 30 | `hand_filter` | `requires_same_lane_gate` | 626 | cut is protected support; needs explicit same-access benchmark before battle |
| 9 | Enlightened Tutor | Molecule Man | `manual_role_review_required` | 25 | `topdeck_miracle_setup` | `manual_review_needed` | 5 | cut has local role/runtime uncertainty |
| 10 | Gamble | Molecule Man | `manual_role_review_required` | 25 | `topdeck_miracle_setup` | `manual_review_needed` | 5 | cut has local role/runtime uncertainty |
| 11 | Enlightened Tutor | Artist's Talent | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 12 | Enlightened Tutor | Big Score | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 13 | Enlightened Tutor | Call Forth the Tempest | `protected_benchmark_required` | 15 | `topdeck_miracle_setup` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 14 | Enlightened Tutor | Esper Sentinel | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 15 | Enlightened Tutor | Hit the Mother Lode | `protected_benchmark_required` | 15 | `topdeck_miracle_setup` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 16 | Enlightened Tutor | Improvisation Capstone | `protected_benchmark_required` | 15 | `topdeck_miracle_setup` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 17 | Enlightened Tutor | Monument to Endurance | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 18 | Enlightened Tutor | Reforge the Soul | `protected_benchmark_required` | 15 | `topdeck_miracle_setup` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 19 | Enlightened Tutor | Rise of the Eldrazi | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |
| 20 | Enlightened Tutor | Smothering Tithe | `protected_benchmark_required` | 15 | `hand_filter` | `requires_same_lane_gate` | unmeasured | cut is protected support; needs explicit same-access benchmark before battle |

## Direct Gate Candidates

- None. No direct tutor swap is seed-safe from current evidence.

## Prior Tutor Evidence

- `enlightened_engine_access_cut_thor` adds Enlightened Tutor, cuts Thor, God of Thunder: delta `-44.45pp`, strong seed `-44.45pp`, decision `reject_or_rework`
- `gamble_approach_access_cut_creative` adds Gamble, cuts Creative Technique: delta `+3.70pp`, strong seed `-44.45pp`, decision `probation_deeper_gate_only`
- `gamble_access_cut_thor` adds Gamble, cuts Thor, God of Thunder: delta `-55.56pp`, strong seed `-55.56pp`, decision `reject_or_rework`

## Guardrails

- `do_not_repeat_thor_or_creative_tutor_cuts`: Thor and Creative Technique both have prior strong-seed regressions in tutor packages.
- `do_not_trade_tutor_for_early_mana_without_benchmark`: The current shell is mana-hungry; direct tutor-over-ramp swaps are cross-lane and not seed-safe.
- `same_access_benchmark_before_gate`: Land Tax/topdeck engines have high measured exposure and require explicit access-lane comparison before battle.
