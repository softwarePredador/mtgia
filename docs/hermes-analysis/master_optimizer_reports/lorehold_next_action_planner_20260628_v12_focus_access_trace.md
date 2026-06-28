# Lorehold Next Action Planner - 2026-06-28

- Generated at: `2026-06-28T03:31:41Z`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260627_v3_role_fix.json`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Trace audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_failure_targeted_trace_audit_20260628_v3_focus_access.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v2_role_fix.json`
- Tutor cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_model_20260627_v1.json`
- Hand-filter cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260627_v3_big_score_rejected.json`
- Recursion cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_cut_model_20260627_v2_pinnacle_rejected.json`
- Mana-base validator reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_validator_20260627_v3_plateau_lane_rejected.json`
- Prior package reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Gate-ready now: `0`
- Action count: `7`
- Action statuses: `{"focus_access_trace_ready_for_package_design": 1, "hypothesis_queue_exhausted_requires_new_synthesis": 1, "no_hand_filter_benchmark_ready": 1, "no_mana_base_preflight_ready": 1, "no_recursion_benchmark_ready": 1, "runtime_required_before_strategy_gate": 1, "tutor_land_tax_benchmarks_rejected": 1}`
- Recommended next action: `review_focus_access_trace_then_define_next_deck_or_runtime_package`
- Miner candidate statuses: `{"blocked_runtime_rule_gap": 61, "high_frequency_runtime_ready_unexplored": 20, "runtime_ready_unexplored": 172, "tested_negative_add_requires_new_cut": 17}`
- Miner pairing statuses: `{"blocked_no_safe_cut_in_lane": 8, "manual_cut_review_required": 2, "needs_lane_model_before_gate": 2}`

## Action Queue

| Priority | Action | Status | Lane | Candidates | Cuts | Why |
| ---: | --- | --- | --- | --- | --- | --- |
| -2 | `review_focus_access_trace_then_define_next_deck_or_runtime_package` | `focus_access_trace_ready_for_package_design` | `strategy_learning` | Land Tax, Library of Leng, Lorehold, the Historian, Scroll Rack, Sensei's Divining Top, Squee, Goblin Nabob, The Mind Stone, Urza's Saga | none | The latest failure-targeted audit has per-game access snapshots for the weak seeds. The blocker moved from missing telemetry to deciding whether access density, conversion timing, or runtime sequencing should be tested next. |
| -1 | `build_failure_targeted_synergy_hypotheses` | `hypothesis_queue_exhausted_requires_new_synthesis` | `strategy_learning` | Urza's Saga, Library of Leng, Sensei's Divining Top, Scroll Rack, Squee, Goblin Nabob, The Mind Stone, Land Tax | none | The current hypothesis queue has 0 gate-ready packages and 13 tested negatives. The next move must explain the failed seeds and existing-engine sequencing before another card swap. |
| 5 | `batch_xmage_runtime_rule_gaps` | `runtime_required_before_strategy_gate` | `runtime_rules` | 61 candidates | none | 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them. |
| 90 | `avoid_hand_filter_without_new_cut` | `no_hand_filter_benchmark_ready` | `hand_filter` | none | none | The hand-filter cut model found no clean benchmark after prior rejects and protected cuts. |
| 90 | `avoid_mana_base_without_safe_color_swap` | `no_mana_base_preflight_ready` | `mana_base` | Plateau, Clifftop Retreat, Boseiju, Who Shelters All | Ancient Tomb, Arid Mesa, Battlefield Forge, Bloodstained Mire, Command Beacon | The mana-base validator found no deterministic swap that preserves color sources and protected utility roles. |
| 90 | `avoid_recursion_without_non_squee_cut` | `no_recursion_benchmark_ready` | `graveyard_recursion` | none | none | The recursion cut model found no safe non-Squee benchmark after protected cuts and prior rejects. |
| 90 | `avoid_rejected_tutor_land_tax_swaps` | `tutor_land_tax_benchmarks_rejected` | `tutor_access` | Enlightened Tutor, Gamble | Land Tax | The tutor cut model found no direct seed-safe swap, and the highest same-access Land Tax benchmarks already lost the equal gate. |

## Action Details

### P-2 review_focus_access_trace_then_define_next_deck_or_runtime_package

- Status: `focus_access_trace_ready_for_package_design`
- Lane: `strategy_learning`
- Blocker: seed 7 and seed 20260625 still lose 0-9 in the candidate-only access diagnostics
- Blocker: Squee and Land Tax are not naturally accessible in the weak seeds even though seed 42 wins when access appears early
- Blocker: prior exact tutor-over-Land-Tax benchmarks are negative, so the next package must preserve protected engine pieces unless a same-lane cut model proves otherwise
- Next step: Build a small access package that increases early Top/Rack/Library/Squee reach without repeating rejected Land Tax cuts.
- Next step: Prefer cards already in local oracle/rule scope, then gate only the package that preserves seed-42 miracle/topdeck telemetry.
- Next step: If the package cannot be evaluated because a card lacks runtime behavior, route that card to XMage/runtime implementation before battle.

### P-1 build_failure_targeted_synergy_hypotheses

- Status: `hypothesis_queue_exhausted_requires_new_synthesis`
- Lane: `strategy_learning`
- Blocker: all current package hypotheses are prior-negative
- Blocker: protected cuts cannot be repeated without same-lane proof
- Blocker: seed 7 and seed 20260625 still show missing-engine or conversion failures
- Next step: Mine seed 7 and seed 20260625 traces for missing-engine versus engine-failed-to-convert patterns.
- Next step: Audit utilization of existing engine pieces before adding cards: Urza's Saga, Library of Leng, Top, Rack, Squee, The Mind Stone, and Land Tax when present.
- Next step: Generate a fresh candidate package queue that suppresses exact prior negatives and rejects locked cuts before battle.
- Next step: Only register a new package when it targets a named failure mode and preserves seed-42 miracle/topdeck telemetry.

### P5 batch_xmage_runtime_rule_gaps

- Status: `runtime_required_before_strategy_gate`
- Lane: `runtime_rules`
- Blocker: missing active battle rule
- Next step: Group the blocked cards by XMage semantic family.
- Next step: Implement the runtime mapper once per family, then rerun the miner before choosing gates.

### P90 avoid_hand_filter_without_new_cut

- Status: `no_hand_filter_benchmark_ready`
- Lane: `hand_filter`
- Blocker: no preflight_benchmark_ready hand-filter pair remains
- Next step: Search for a different non-core cut or a multi-card package before another hand-filter gate.

### P90 avoid_mana_base_without_safe_color_swap

- Status: `no_mana_base_preflight_ready`
- Lane: `mana_base`
- Blocker: no validator-ready land swap
- Blocker: battle gate cannot isolate mana consistency from game variance
- Next step: Move to runtime/XMage rule-gap batching before another land test.
- Next step: Reopen mana base only with a new candidate or a cut that the validator marks preflight-ready.

### P90 avoid_recursion_without_non_squee_cut

- Status: `no_recursion_benchmark_ready`
- Lane: `graveyard_recursion`
- Blocker: no preflight_benchmark_ready recursion pair remains
- Next step: Do not cut Squee, Farewell, Furygale Flocking, Mizzix's Mastery, or Pinnacle Monk for current recursion candidates.
- Next step: Return to this lane only with a different cut or a multi-card package that preserves the current engine.

### P90 avoid_rejected_tutor_land_tax_swaps

- Status: `tutor_land_tax_benchmarks_rejected`
- Lane: `tutor_access`
- Blocker: Gamble over Land Tax was rejected by prior gate evidence
- Blocker: Enlightened Tutor over Land Tax was rejected by prior gate evidence
- Blocker: Thor and Creative Technique tutor cuts already have prior regression evidence
- Next step: Do not rerun exact tutor-over-Land-Tax packages without a changed shell or explicit override.
- Next step: Search for an additive tutor/access package or a different low-exposure non-access cut.
- Next step: Rerun the tutor cut model after any new shell change before another tutor gate.

## Guardrails

- `no_automatic_gate_without_safe_cut`: The current miner reports zero gate-ready pairings; a new gate must come from a fresh cut model or explicit preflight, not from the raw candidate list.
- `do_not_repeat_negative_exact_packages`: Prior negative add/cut evidence must demote exact retests until the cut model changes.
- `austere_emeria_tradeoff_rejected`: Austere over Emeria already lost its gate and must not be rerun as the same tradeoff.
- `manual_review_has_no_auto_gate`: Manual review confirms the current unresolved candidates require modeling before battle.
- `current_hypothesis_queue_exhausted`: The latest hypothesis queue has no gate-ready package; generate new failure-targeted hypotheses instead of rerunning prior-negative swaps.

## Method Notes

- This planner is a decision layer, not a promotion engine.
- A runtime-ready card is not gate-ready unless a safe cut model exists.
- Exposure evidence is used to protect proven roles and to decide which lane needs profiling next.
- An exhausted hypothesis queue routes back to failure-targeted strategy synthesis before any new gate.
- A completed focus-access trace routes to package design; do not regenerate the same payload unless the deck list changes.
- PostgreSQL and SQLite are not mutated by this script.
