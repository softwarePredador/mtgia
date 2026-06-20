# Battle Decision Trace Contract Audit - 2026-06-19T17:12Z

## Scope

Artifact-only validation of the current `decision_trace_v1` surface. This
audit does not change PostgreSQL, swaps, product code, automation code, or git
state.

Inputs:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609`
- Latest decision trace:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/seed_786135854/replay.decision_trace.jsonl`
- Replay decision audit:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/seed_786135854/replay_decision_audit.json`
- Strategy audit:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/seed_786135854/strategy_audit.json`
- Research review:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609/research_review.json`
- Generated contract JSON:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/decision_trace_contract_170609/decision_trace_contract.json`

## Current Latest Snapshot

- `timestamp_utc`: `2026-06-19T17:06:09Z`
- `run_dir`: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_170609`
- `events`: `1073`
- `decisions`: `152`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `strategy_findings`: `0`
- high/critical action, strategy blocker, replay-decision high/critical and
  forensic high/critical seed lists: empty.
- final status remains `review_required` because
  `mandatory_gate_divergences=['effect_coverage=review_required']`.

## Contract Summary

- Static `emit_decision_trace(...)` call sites: `34`
- Static decision types emitted by engine: `15`
- Latest decision rows: `152`
- Latest observed decision types: `10`
- Rows missing generic/strategy required fields: `0`
- Static types not observed in latest: `5`
- Observed non-static types: `0`

`replay_decision_auditor.py` proves generic shape only:
`status_scope=turn_and_decision_trace_invariants`,
`human_replay_complete=not_evaluated_by_replay_decision_auditor`, and
`rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.

`battle_decision_strategy_auditor.py` returned
`verdict=usable_for_strategy_learning` and `findings=0`, but it has specialized
branches for only `7/15` static decision types:

- `board_wipe`
- `cast_spell`
- `mulligan_decision`
- `pass_no_action`
- `tutor`
- `wheel`
- `worldfire_reset`

`battle_decision_research_review.py` maps research categories to `8/15` static
decision types:

- `board_wipe`
- `cast_spell`
- `combat_attack`
- `mulligan_decision`
- `pass_no_action`
- `response`
- `tutor`
- `wheel`

## Status Counts

Static decision-type ownership:

| Status | Static types |
| --- | ---: |
| `full_specific_contract` | 6 |
| `generic_only_gap` | 6 |
| `research_only_partial_contract` | 2 |
| `strategy_only_partial_contract` | 1 |

Observed decision-type ownership:

| Status | Observed types |
| --- | ---: |
| `full_specific_contract` | 5 |
| `generic_only_gap` | 3 |
| `research_only_partial_contract` | 2 |

Observed rows without full strategy+research ownership:

- `observed_without_full_contract_rows=38`
- `observed_generic_only_gap_rows=13`

## Decision Type Matrix

| Decision type | Latest count | Strategy branch | Research category | Status | Score component keys observed |
| --- | ---: | --- | --- | --- | --- |
| `activated_sacrifice_damage` | 0 | no | - | `generic_only_gap` | - |
| `attack_trigger_artifact_tutor` | 0 | no | - | `generic_only_gap` | - |
| `board_wipe` | 0 | yes | `board_wipe_wheel` | `full_specific_contract` | - |
| `cast_spell` | 35 | yes | `cast_spell`, `fast_mana_one_shot`, `mox_land_discard`, `sacrifice_land` | `full_specific_contract` | `cmc`, `remaining_options`, `threat_score` |
| `combat_attack` | 24 | no | `combat_attack` | `research_only_partial_contract` | `attackers`, `multi_defender_available`, `target_life_before`, `target_reason`, `total_power` |
| `lorehold_upkeep_rummage` | 4 | no | - | `generic_only_gap` | `discard_destination`, `drawn_card`, `miracle_cost` |
| `mulligan_decision` | 8 | yes | `mulligan` | `full_specific_contract` | `card_flow_count`, `colors`, `early_play`, `early_ramp`, `expensive_count`, `hand_size`, `keep_score`, `lands`, `mulligan_count`, `nonlands` |
| `pass_no_action` | 69 | yes | `pass_no_action` | `full_specific_contract` | `affordable_card_count`, `available_mana`, `castable_now_count`, `hand_nonland_count`, `main_phase_action_taken`, `minimum_hand_cmc`, `phase_is_main`, `reactive_option_count`, `stack_empty` |
| `response` | 1 | no | `response` | `research_only_partial_contract` | `available_instants`, `stack_threat_score` |
| `saga_chapter_resolution` | 1 | no | - | `generic_only_gap` | `candidate_count`, `chapter`, `selected_reason` |
| `tutor` | 1 | yes | `tutor` | `full_specific_contract` | `candidate_count`, `selected_reason`, `target_type` |
| `utility_artifact_activation` | 8 | no | - | `generic_only_gap` | `activation_cost_generic`, `cards_exchanged`, `hand_to_top`, `miracle_cost`, `peek_top_count`, `top_after`, `top_before` |
| `utility_land_activation` | 0 | no | - | `generic_only_gap` | - |
| `wheel` | 1 | yes | `board_wipe_wheel` | `full_specific_contract` | `draw_count`, `hand_size_before`, `model_scope`, `net_cards_for_player`, `opponent_hand_sizes`, `opponent_net_cards`, `opponent_refill_risk`, `payoff_expected`, `timing_justified`, `total_opponent_net_cards`, `wheel_payoffs` |
| `worldfire_reset` | 0 | yes | - | `strategy_only_partial_contract` | - |

## Operational Reading

The latest trace is clean for required fields and generic decision invariants.
That is useful, but it is not the same as full strategic ownership per decision
type.

Observed generic-only gaps remain:

- `utility_artifact_activation=8`
- `lorehold_upkeep_rummage=4`
- `saga_chapter_resolution=1`

Observed partial contracts also remain:

- `combat_attack=24` has research review coverage but no dedicated strategy
  auditor branch.
- `response=1` has research review coverage but no dedicated strategy auditor
  branch.

Static unobserved gaps remain:

- `activated_sacrifice_damage`
- `attack_trigger_artifact_tutor`
- `utility_land_activation`

Static partial ownership remains:

- `worldfire_reset` has a strategy branch but no research category.

Therefore `strategy_findings=0`, `decision_audit_decision_findings=0`, and
`verdict=usable_for_strategy_learning` should be read as "clean for current
generic and implemented strategy rules", not as proof that all decision kinds
are fully strategy-trusted.

## Required Follow-Up

- Add a recurring decision-trace contract manifest to the battle strategy audit
  summary, with counters for:
  `decision_trace_static_types_total`,
  `decision_trace_observed_types_total`,
  `decision_trace_observed_generic_only_gap_rows`,
  `decision_trace_observed_without_full_contract_rows`.
- Add type-specific strategy branches, research categories, fixtures, or
  explicit waivers for `utility_artifact_activation`,
  `lorehold_upkeep_rummage`, `saga_chapter_resolution`,
  `activated_sacrifice_damage`, `attack_trigger_artifact_tutor`, and
  `utility_land_activation`.
- Decide whether `combat_attack` and `response` are acceptable with
  research-only ownership or require dedicated strategy-auditor branches before
  treating their decisions as fully learning-grade.
- Add a research category or explicit waiver for `worldfire_reset`.
