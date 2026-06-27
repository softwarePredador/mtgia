# Lorehold Next Action Planner - 2026-06-27

- Generated at: `2026-06-27T23:46:23Z`
- Miner report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json`
- Manual review: `docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260627_v3_role_fix.json`
- Exposure profiles: `docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v2_role_fix.json, docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_exposure_profile_20260627_v2_role_fix.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Gate-ready now: `0`
- Action count: `5`
- Action statuses: `{"cut_benchmark_required_before_gate": 1, "cut_model_required_before_gate": 1, "mana_model_required_before_gate": 1, "multi_card_or_non_squee_cut_required": 1, "runtime_required_before_strategy_gate": 1}`
- Recommended next action: `build_tutor_seed_safe_cut_model`
- Miner candidate statuses: `{"blocked_runtime_rule_gap": 61, "high_frequency_runtime_ready_unexplored": 20, "runtime_ready_unexplored": 172, "tested_negative_add_requires_new_cut": 17}`
- Miner pairing statuses: `{"blocked_no_safe_cut_in_lane": 8, "manual_cut_review_required": 2, "needs_lane_model_before_gate": 2}`

## Action Queue

| Priority | Action | Status | Lane | Candidates | Cuts | Why |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `build_tutor_seed_safe_cut_model` | `cut_model_required_before_gate` | `tutor_access` | Enlightened Tutor, Gamble | none | Tutor cards are runtime-ready, exposed in local evidence, and high-frequency in Lorehold variants, but prior tests regressed the protected strong seed when the cut was wrong. |
| 2 | `profile_hand_filter_cut_benchmarks` | `cut_benchmark_required_before_gate` | `hand_filter` | Apex of Power, Olórin's Searing Light, Valakut Awakening // Valakut Stoneforge, Wheel of Fortune, Dance with Calamity | Artist's Talent, Big Score, Esper Sentinel, Monument to Endurance, Rise of the Eldrazi | Apex/Valakut/Wheel-style cards are high-frequency runtime-ready candidates, but every visible cut is protected same-lane support. This lane needs measured cut value first. |
| 3 | `preserve_squee_build_recursion_package` | `multi_card_or_non_squee_cut_required` | `graveyard_recursion` | Volcanic Vision, Restoration Seminar | Squee, Goblin Nabob, Farewell, Furygale Flocking, Mizzix's Mastery, Pinnacle Monk // Mystic Peak | Recursion variants are frequent and runtime-ready, but the obvious cut is Squee, which has direct exposure as the current recursion engine. |
| 4 | `use_mana_base_validator_not_battle_gate` | `mana_model_required_before_gate` | `mana_base` | Plateau, Clifftop Retreat, Boseiju, Who Shelters All | Ancient Tomb, Arid Mesa, Battlefield Forge, Bloodstained Mire, Command Beacon | Mana-base variants are frequent, but lands are blocked as core cuts. A battle equal gate is too noisy until color-source odds and utility-land value are modeled. |
| 5 | `batch_xmage_runtime_rule_gaps` | `runtime_required_before_strategy_gate` | `runtime_rules` | 61 candidates | none | 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them. |

## Action Details

### P1 build_tutor_seed_safe_cut_model

- Status: `cut_model_required_before_gate`
- Lane: `tutor_access`
- Blocker: no seed-safe cut model is proven
- Blocker: do not repeat Thor or blind Creative Technique cuts
- Blocker: gate only after preflight proves no prior-negative exact package
- Next step: Mine current champion cards that overlap tutor access without touching locked win/protection engines.
- Next step: Require cut_safety status not locked/core and no prior negative cut evidence.
- Next step: Create one explicit package, run preflight, then run a small equal gate only if preflight is clean.

### P2 profile_hand_filter_cut_benchmarks

- Status: `cut_benchmark_required_before_gate`
- Lane: `hand_filter`
- Blocker: all current cut options are protected_same_lane_benchmark_required
- Blocker: blindly cutting draw/filter support can reduce miracle setup density
- Blocker: unprofiled or zero-exposure cards cannot justify a blind cut
- Next step: Run the exposure profiler for the candidate and protected cut cards in this lane.
- Next step: Choose at most one explicit same-lane tradeoff with measured low exposure or low strategic dependence.
- Next step: Reject the lane for now if every cut card has higher exposure or a locked role.
- Zero natural exposure cards: Apex of Power, Dance with Calamity

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
