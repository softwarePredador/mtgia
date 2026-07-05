# Lorehold Current Best Baseline Synthesis

- Generated at: `2026-07-05T09:43:30Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `current_best_baseline_synthesis_keep_607`
- Artifact contract: `pass`
- Unknown or invalid artifacts: `0`
- Strategy top deck is 607: `true`
- Current positive signal count: `0`
- Overridden historical positive signal count: `1`
- Sidecar matrix-eligible rows: `0`
- Sidecar safe-cut ready count: `0`
- Floor trace cut blockers: `6`
- Recommended next action: `define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate`

## Decision

- keep_607_as_current_best_baseline: `true`
- deck_action_allowed: `false`
- candidate_deck_materialization_allowed_now: `false`
- natural_battle_gate_ready_now: `false`
- promotion_allowed: `false`
- reason: The governed artifact surface is classified, deck_607 ranks first structurally, current sidecar/cut routes have zero eligible rows, and the only positive promotion signal is historical and overridden.

## Historical Positive Signals Overridden

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json`: cut_methodology_reaudit_20260629 sets ready_for_real_deck_change=false and marks the candidate battle-cleared only with methodology caveat

## Current Positive Signals

- none

## Source Reports

- `artifact_audit`: `../../master_optimizer_reports/lorehold_artifact_contract_audit_20260705_brain_seed_unlock_current.json`
- `cut_methodology_reaudit`: `docs/hermes-analysis/master_optimizer_reports/lorehold_cut_methodology_reaudit_20260629.json`
- `gap_floor_trace_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_gap_floor_trace_miner_20260705_current.json`
- `sidecar_cut_planner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json`
- `strategy_matrix`: `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json`

## Validation

- PASS: current evidence supports keeping 607 as the protected baseline.
