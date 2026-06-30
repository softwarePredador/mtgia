# Lorehold Focus-Access Package Generator - 2026-06-30

- Generated at: `2026-06-30T15:07:20Z`
- Planner: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_after_profiled_gate.json`
- Trace audit: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_failure_targeted_trace_audit_20260630_after_profiled_gate.json`
- Miner report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json`
- Design contract: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_focus_access_package_design_20260628_v1.md`
- Squee probe: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_graveyard_entry_probe_20260628_v1.json`
- Access model: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json`
- Runtime gap queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json`
- Hand-filter cut model: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `do_not_create_blind_swap; run focused trace/runtime/cut-model work first`
- Package candidates evaluated: `52`
- Gate-ready packages: `0`
- Package statuses: `{"blocked_no_safe_cut": 30, "blocked_no_target_failure_mode": 15, "blocked_prior_negative_exact": 3, "blocked_protected_cut": 2, "trace_or_runtime_probe_required": 2}`
- Seed-42 anchor available: `true`
- Squee probe status: `squee_route_modeled_but_access_gap_remains`
- Access model status: `squee_route_modeled_access_density_needed`
- Operational work items: `4`
- Top operational work: `runtime_rule_gap_batch`

## Gate-Ready Packages

- None. The generator refused to create a blind swap.

## Blocked Package Review

| Status | Add | Cut | Lane | Failure Mode | Main Blockers |
| --- | --- | --- | --- | --- | --- |
| `blocked_no_safe_cut` | `Apex of Power` | `Artist's Talent` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Apex of Power` | `Big Score` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Apex of Power` | `Esper Sentinel` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Apex of Power` | `Monument to Endurance` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Apex of Power` | `Rise of the Eldrazi` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Volcanic Vision` | `Farewell` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Volcanic Vision` | `Furygale Flocking` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Volcanic Vision` | `Mizzix's Mastery` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Olórin's Searing Light` | `Artist's Talent` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Olórin's Searing Light` | `Big Score` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Olórin's Searing Light` | `Esper Sentinel` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Olórin's Searing Light` | `Monument to Endurance` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Olórin's Searing Light` | `Rise of the Eldrazi` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Restoration Seminar` | `Farewell` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Restoration Seminar` | `Furygale Flocking` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Restoration Seminar` | `Mizzix's Mastery` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Restoration Seminar` | `Pinnacle Monk // Mystic Peak` | `graveyard_recursion` | `squee_graveyard_entry_route` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Valakut Awakening // Valakut Stoneforge` | `Artist's Talent` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Valakut Awakening // Valakut Stoneforge` | `Esper Sentinel` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Valakut Awakening // Valakut Stoneforge` | `Monument to Endurance` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Valakut Awakening // Valakut Stoneforge` | `Rise of the Eldrazi` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Wheel of Fortune` | `Artist's Talent` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Wheel of Fortune` | `Esper Sentinel` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Wheel of Fortune` | `Monument to Endurance` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Wheel of Fortune` | `Rise of the Eldrazi` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Dance with Calamity` | `Artist's Talent` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Dance with Calamity` | `Big Score` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Dance with Calamity` | `Esper Sentinel` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Dance with Calamity` | `Monument to Endurance` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_safe_cut` | `Dance with Calamity` | `Rise of the Eldrazi` | `hand_filter` | `seed20260625_conversion_under_pressure` | cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Plateau` | `Ancient Tomb` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Plateau` | `Arid Mesa` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Plateau` | `Battlefield Forge` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Plateau` | `Bloodstained Mire` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Plateau` | `Command Beacon` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Clifftop Retreat` | `Ancient Tomb` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Clifftop Retreat` | `Arid Mesa` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Clifftop Retreat` | `Battlefield Forge` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Clifftop Retreat` | `Bloodstained Mire` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| `blocked_no_target_failure_mode` | `Clifftop Retreat` | `Command Beacon` | `mana_base` | `` | missing_target_failure_mode, cut_not_gate_ready |
| ... | ... | ... | ... | ... | 12 more rows omitted |

## Instrumentation Route

- Status: `trace_or_runtime_probe_required`
- Next action: `do_not_create_blind_swap; run focused trace/runtime/cut-model work first`
- `squee_access_density_model`: failure `squee_graveyard_entry_route`, seeds `7, 20260625`; Squee discard/return is modeled when accessed; access model found 0 preflight-ready access swaps and requires a new seed-safe cut or runtime upgrade.
- `contextual_tutor_cut_model`: failure `seed7_missing_engine_access`, seeds `7`; Enlightened Tutor and Gamble have runtime support but no safe cut option.
- `hand_filter_non_core_cut_search`: failure `seed20260625_conversion_under_pressure`, seeds `20260625`; Hand-filter candidates only pair with protected same-lane support cuts.
- `runtime_rule_gap_batch`: failure `blocked_runtime_rule_gap`, seeds `-`; 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them.

## Operational Work Queue

| Rank | Work | Impact | Blocks | Runtime Gaps | PG To Promote | Next Command |
| ---: | --- | ---: | ---: | ---: | --- | --- |
| 1 | `runtime_rule_gap_batch` | 72 | 0 | 12 | `false` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_gap_family_queue.py --output-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box` |
| 2 | `squee_access_density_model` | 43 | 9 | 0 | `false` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_access_cut_model.py --stem lorehold_access_cut_model_20260630_after_profiled_gate` |
| 3 | `contextual_tutor_cut_model` | 39 | 2 | 0 | `false` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_tutor_cut_model.py --stem lorehold_tutor_cut_model_20260630_after_profiled_gate` |
| 4 | `hand_filter_non_core_cut_search` | -1 | 23 | 0 | `false` | `do_not_repeat_without_new_cut_or_runtime_evidence` |

### 1. runtime_rule_gap_batch

- Failure mode: `blocked_runtime_rule_gap`
- Target seeds: `-`
- Reason: 61 variant-only cards still cannot be trusted in battle because the local runtime does not have an active rule for them.
- Evidence inputs: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.json`
- Blocked package statuses: `{}`
- Promotion criteria: Group blocked cards by XMage semantic family.; Promote only cards with valid XMage source and a ManaLoom mapper/test scenario.; Rerun the variant gap miner before using newly modeled cards in deck gates.
- Runtime families:
  - `passive`: 2 cards, support `runtime_family_partially_supported_review_required`, samples `Blood Moon, Karn, the Great Creator`
  - `recursion`: 2 cards, support `runtime_family_partially_supported_review_required`, samples `Charmbreaker Devils, Leyline Dowser`
  - `board_wipe_choice`: 2 cards, support `runtime_family_required`, samples `Chandra's Ignition, Karn's Sylex`
  - `token_maker`: 2 cards, support `runtime_family_required`, samples `Ancient Gold Dragon, Prototype Portal`
  - `draw_engine`: 1 cards, support `runtime_family_partially_supported_review_required`, samples `Naktamun Lorespinner // Wheel of Fortune`

### 2. squee_access_density_model

- Failure mode: `squee_graveyard_entry_route`
- Target seeds: `7, 20260625`
- Reason: Squee discard/return is modeled when accessed; access model found 0 preflight-ready access swaps and requires a new seed-safe cut or runtime upgrade.
- Evidence inputs: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_graveyard_entry_probe_20260628_v1.json`
- Blocked package statuses: `{"blocked_no_safe_cut": 7, "blocked_protected_cut": 2}`
- Promotion criteria: Find a non-protected access package that improves Squee/Top/Rack/Library reach.; Preserve seed-42 Squee, miracle, and topdeck telemetry before broader gates.; Use Hidden Retreat as PG271-synced if selected; do not rerun its PostgreSQL apply.

### 3. contextual_tutor_cut_model

- Failure mode: `seed7_missing_engine_access`
- Target seeds: `7`
- Reason: Enlightened Tutor and Gamble have runtime support but no safe cut option.
- Evidence inputs: `-`
- Blocked package statuses: `{"trace_or_runtime_probe_required": 2}`
- Promotion criteria: Find a tutor package that does not cut Land Tax, Thor, Creative Technique, or protected topdeck engines.; Pass seed-7 access sequence review before any broader battle gate.; Reject exact pairs with prior strong-seed regression.

### 4. hand_filter_non_core_cut_search

- Failure mode: `seed20260625_conversion_under_pressure`
- Target seeds: `20260625`
- Reason: Hand-filter candidates only pair with protected same-lane support cuts.
- Evidence inputs: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.json`
- Blocked package statuses: `{"blocked_no_safe_cut": 23}`
- Promotion criteria: Find a non-core hand-filter cut outside protected support slots.; Reject Big Score, Esper Sentinel, Monument, Rise, and Artist's Talent cuts unless a same-lane benchmark proves safety.; Target the seed-20260625 conversion-under-pressure failure explicitly.

## Guardrails

- Target failure mode required before any package.
- Protected cards cannot be cut: `Boros Signet`, `Land Tax`, `Library of Leng`, `Scroll Rack`, `Sensei's Divining Top`, `Squee, Goblin Nabob`, `The Mind Stone`, `Urza's Saga`
- Prior negative exact matches are blocked.
- Runtime status must be `active_or_materialized`.
- Seed 42 is the first anchor gate before broader testing.
