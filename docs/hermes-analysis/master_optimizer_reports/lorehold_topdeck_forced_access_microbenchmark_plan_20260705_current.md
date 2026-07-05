# Lorehold Topdeck Forced Access Microbenchmark Plan

- generated_at: `2026-07-05T06:18:22Z`
- status: `topdeck_microbenchmark_plan_ready_but_no_executable_package_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- target_card_count: `5`
- microbenchmark_design_count: `5`
- runnable_now_count: `0`
- natural_promotion_allowed_count: `0`
- recommended_next_action: `mine_new_safe_cut_models_before_running_topdeck_forced_access`

## Source Reports

- `forced_access_audit`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_audit_20260705_current.json`
- `package_preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_unprotected_staple_relearn_preflight_20260704_current.json`

## Runtime Contract

- supported_modes: `opening_hand, library_top`
- primary_mode_for_current_targets: `opening_hand`
- why_opening_hand: The five current targets are enablers or hand filters. The diagnostic must prove whether early access to the card changes miracle/topdeck execution, not merely that the card can be drawn.
- promotion_boundary: A forced-access result can show card visibility and use, but cannot promote a deck or mutate 607 without a later natural gate.

## Microbenchmarks

| Card | Mode | Package status | Runnable | Prior packages | Blockers | Next action |
| --- | --- | --- | ---: | ---: | --- | --- |
| Penance | `opening_hand` | `blocked_prior_reject_and_cut_safety` | `false` | 2 | `cut_safety_blocked, deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` | `do_not_reuse_blocked_cut; create_new_same_lane_cut_model_before_diagnostic` |
| Galvanoth | `opening_hand` | `blocked_prior_reject_and_cut_safety` | `false` | 4 | `cut_safety_blocked, deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` | `do_not_reuse_blocked_cut; create_new_same_lane_cut_model_before_diagnostic` |
| Dragon's Rage Channeler | `opening_hand` | `blocked_cut_safety_new_cut_required` | `false` | 1 | `cut_safety_blocked, deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` | `find_nonprotected_same_lane_cut_before_forced_access` |
| Valakut Awakening // Valakut Stoneforge | `opening_hand` | `blocked_prior_reject_new_cut_required` | `false` | 1 | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row, prior_exact_or_strategy_reject` | `do_not_retest_prior_pair; declare_new_cut_and_failure_hypothesis` |
| Wheel of Fortune | `opening_hand` | `blocked_prior_reject_new_cut_required` | `false` | 1 | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row, prior_exact_or_strategy_reject` | `do_not_retest_prior_pair; declare_new_cut_and_failure_hypothesis` |

## Command Templates

### Penance
- runnable_now: `false`
- reason: requires package manifest with a declared safe temporary cut before execution
```bash
MANALOOM_FOCUS_ACCESS_CARDS='["Penance"]' MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages penance_topdeck_protection_cut_squelcher --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260705 --stem lorehold_topdeck_forced_access_microbenchmark_20260705_current --package-file '<package_manifest_with_safe_cut_required>' --forced-access-mode opening_hand
```
### Galvanoth
- runnable_now: `false`
- reason: requires package manifest with a declared safe temporary cut before execution
```bash
MANALOOM_FOCUS_ACCESS_CARDS='["Galvanoth"]' MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages galvanoth_topdeck_freecast --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260705 --stem lorehold_topdeck_forced_access_microbenchmark_20260705_current --package-file '<package_manifest_with_safe_cut_required>' --forced-access-mode opening_hand
```
### Dragon's Rage Channeler
- runnable_now: `false`
- reason: requires package manifest with a declared safe temporary cut before execution
```bash
MANALOOM_FOCUS_ACCESS_CARDS='["Dragon'"'"'s Rage Channeler"]' MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages dragon_rage_channeler_cut_scarlet_witch --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260705 --stem lorehold_topdeck_forced_access_microbenchmark_20260705_current --package-file '<package_manifest_with_safe_cut_required>' --forced-access-mode opening_hand
```
### Valakut Awakening // Valakut Stoneforge
- runnable_now: `false`
- reason: requires package manifest with a declared safe temporary cut before execution
```bash
MANALOOM_FOCUS_ACCESS_CARDS='["Valakut Awakening // Valakut Stoneforge"]' MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages valakut_hand_filter_cut_big_score --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260705 --stem lorehold_topdeck_forced_access_microbenchmark_20260705_current --package-file '<package_manifest_with_safe_cut_required>' --forced-access-mode opening_hand
```
### Wheel of Fortune
- runnable_now: `false`
- reason: requires package manifest with a declared safe temporary cut before execution
```bash
MANALOOM_FOCUS_ACCESS_CARDS='["Wheel of Fortune"]' MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages wheel_hand_filter_cut_big_score --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260705 --stem lorehold_topdeck_forced_access_microbenchmark_20260705_current --package-file '<package_manifest_with_safe_cut_required>' --forced-access-mode opening_hand
```

## Decision

- allow_execution_now: `false`
- allow_deck_mutation_now: `false`
- allow_natural_gate_now: `false`
- promotion_allowed: `false`
- reason: All five topdeck targets are valid learning designs, but current package evidence is blocked by prior rejects, protected cuts, or missing safe-cut manifests. The next work is cut-model mining before running forced-access battle commands.
