# Lorehold Next Action Planner - 2026-06-27

- Generated at: `2026-06-28T00:25:00Z`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260627_v2.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v1.json`
- Tutor cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_model_20260627_v1.json`
- Hand-filter cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260627_v2_prior_aware.json`
- Prior package reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Gate-ready now: `0`
- Action count: `5`
- Action statuses: `{"mana_model_required_before_gate": 1, "multi_card_or_non_squee_cut_required": 1, "runtime_required_before_strategy_gate": 1, "same_lane_benchmark_ready": 1, "tutor_land_tax_benchmarks_rejected": 1}`
- Recommended next action: `run_hand_filter_benchmark_gate`
- Miner candidate statuses: `{"blocked_runtime_rule_gap": 61, "high_frequency_runtime_ready_unexplored": 20, "runtime_ready_unexplored": 172, "tested_negative_add_requires_new_cut": 17}`
- Miner pairing statuses: `{"blocked_no_safe_cut_in_lane": 8, "manual_cut_review_required": 2, "needs_lane_model_before_gate": 2}`

## Action Queue

| Priority | Action | Status | Lane | Candidates | Cuts | Why |
| ---: | --- | --- | --- | --- | --- | --- |
| 2 | `run_hand_filter_benchmark_gate` | `same_lane_benchmark_ready` | `hand_filter` | Wheel of Fortune | Big Score | The hand-filter cut model has exposure evidence and has skipped prior exact rejects; the next pair needs package preflight plus a small equal gate. |
| 3 | `preserve_squee_build_recursion_package` | `multi_card_or_non_squee_cut_required` | `graveyard_recursion` | Volcanic Vision, Restoration Seminar | Squee, Goblin Nabob, Farewell, Furygale Flocking, Mizzix's Mastery, Pinnacle Monk // Mystic Peak | Recursion variants are frequent and runtime-ready, but the obvious cut is Squee, which has direct exposure as the current recursion engine. |
| 4 | `use_mana_base_validator_not_battle_gate` | `mana_model_required_before_gate` | `mana_base` | Plateau, Clifftop Retreat, Boseiju, Who Shelters All | Ancient Tomb, Arid Mesa, Battlefield Forge, Bloodstained Mire, Command Beacon | Mana-base variants are frequent, but lands are blocked as core cuts. A battle equal gate is too noisy until color-source odds and utility-land value are modeled. |
| 5 | `batch_xmage_runtime_rule_gaps` | `runtime_required_before_strategy_gate` | `runtime_rules` | 61 candidates | none | 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them. |
| 90 | `avoid_rejected_tutor_land_tax_swaps` | `tutor_land_tax_benchmarks_rejected` | `tutor_access` | Enlightened Tutor, Gamble | Land Tax | The tutor cut model found no direct seed-safe swap, and the highest same-access Land Tax benchmarks already lost the equal gate. |

## Action Details

### P2 run_hand_filter_benchmark_gate

- Status: `same_lane_benchmark_ready`
- Lane: `hand_filter`
- Blocker: the proposed cut is still a benchmark, not a promotion
- Blocker: Big Score provides ramp, discard, draw, and Treasure, so a win-rate gate must prove the tradeoff
- Next step: Run the exact package preflight to check prior-negative evidence.
- Next step: Run the smallest equal gate only if preflight is clear.
- Next step: If rejected, add the exact report to prior package defaults and rerun this model.

### P3 preserve_squee_build_recursion_package

- Status: `multi_card_or_non_squee_cut_required`
- Lane: `graveyard_recursion`
- Blocker: Squee is protected as the current champion recursion engine
- Blocker: single-card Volcanic/Restoration over Squee is blocked
- Blocker: same-lane non-Squee cuts require stronger role evidence
- Next step: Keep Squee in the champion shell while testing any recursion expansion.
- Next step: Search for a non-Squee cut or a multi-card package that preserves the current recursion engine.
- Next step: Do not gate Volcanic Vision or Restoration Seminar over Squee.

### P4 use_mana_base_validator_not_battle_gate

- Status: `mana_model_required_before_gate`
- Lane: `mana_base`
- Blocker: current land cuts are blocked_core_cut
- Blocker: battle gate cannot isolate mana consistency from game variance
- Next step: Run or extend the mana-base validator for color sources, untapped timing, and utility-land cost.
- Next step: Only produce a land package if the odds model improves without cutting required colored sources.

### P5 batch_xmage_runtime_rule_gaps

- Status: `runtime_required_before_strategy_gate`
- Lane: `runtime_rules`
- Blocker: missing active battle rule
- Next step: Group the blocked cards by XMage semantic family.
- Next step: Implement the runtime mapper once per family, then rerun the miner before choosing gates.

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

## Method Notes

- This planner is a decision layer, not a promotion engine.
- A runtime-ready card is not gate-ready unless a safe cut model exists.
- Exposure evidence is used to protect proven roles and to decide which lane needs profiling next.
- PostgreSQL and SQLite are not mutated by this script.
