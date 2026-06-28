# Lorehold Next Action Planner - 2026-06-27

- Generated at: `2026-06-28T00:54:55Z`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260627_v2.json`
- Exposure profiles: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v1.json`
- Tutor cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_cut_model_20260627_v1.json`
- Hand-filter cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260627_v3_big_score_rejected.json`
- Recursion cut model reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_cut_model_20260627_v2_pinnacle_rejected.json`
- Mana-base validator reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_validator_20260627_v1.json`
- Prior package reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Gate-ready now: `0`
- Action count: `5`
- Action statuses: `{"mana_base_preflight_ready": 1, "no_hand_filter_benchmark_ready": 1, "no_recursion_benchmark_ready": 1, "runtime_required_before_strategy_gate": 1, "tutor_land_tax_benchmarks_rejected": 1}`
- Recommended next action: `run_mana_base_validated_preflight`
- Miner candidate statuses: `{"blocked_runtime_rule_gap": 61, "high_frequency_runtime_ready_unexplored": 20, "runtime_ready_unexplored": 172, "tested_negative_add_requires_new_cut": 17}`
- Miner pairing statuses: `{"blocked_no_safe_cut_in_lane": 8, "manual_cut_review_required": 2, "needs_lane_model_before_gate": 2}`

## Action Queue

| Priority | Action | Status | Lane | Candidates | Cuts | Why |
| ---: | --- | --- | --- | --- | --- | --- |
| 4 | `run_mana_base_validated_preflight` | `mana_base_preflight_ready` | `mana_base` | Plateau | Radiant Summit, Turbulent Steppe, Sacred Foundry | The mana-base validator found deterministic land upgrades that preserve Boros color access and avoid protected utility cuts. |
| 5 | `batch_xmage_runtime_rule_gaps` | `runtime_required_before_strategy_gate` | `runtime_rules` | 61 candidates | none | 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them. |
| 90 | `avoid_hand_filter_without_new_cut` | `no_hand_filter_benchmark_ready` | `hand_filter` | none | none | The hand-filter cut model found no clean benchmark after prior rejects and protected cuts. |
| 90 | `avoid_recursion_without_non_squee_cut` | `no_recursion_benchmark_ready` | `graveyard_recursion` | none | none | The recursion cut model found no safe non-Squee benchmark after protected cuts and prior rejects. |
| 90 | `avoid_rejected_tutor_land_tax_swaps` | `tutor_land_tax_benchmarks_rejected` | `tutor_access` | Enlightened Tutor, Gamble | Land Tax | The tutor cut model found no direct seed-safe swap, and the highest same-access Land Tax benchmarks already lost the equal gate. |

## Action Details

### P4 run_mana_base_validated_preflight

- Status: `mana_base_preflight_ready`
- Lane: `mana_base`
- Next step: Build the smallest exact land package from the top validator swap.
- Next step: Use package preflight rather than a noisy battle gate; only battle-test if the deterministic model is disputed.
- Next step: Do not cut fetches, Ancient Tomb, Command Beacon, or prior negative land-gate cuts.

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

## Method Notes

- This planner is a decision layer, not a promotion engine.
- A runtime-ready card is not gate-ready unless a safe cut model exists.
- Exposure evidence is used to protect proven roles and to decide which lane needs profiling next.
- PostgreSQL and SQLite are not mutated by this script.
