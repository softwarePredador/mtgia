# Battle Latest 235553 Optimizer Surface Gate Coverage Recheck

Status: BV-074 remains open.

Scope: read-only audit of optimizer/scorecard surfaces against the current
recurring battle audit artifact. No code, database, deck swap, commit, or push
was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553`.
- `summary.json` timestamp: `2026-06-19T23:55:53Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `runtime_surface_manifest_status=runtime_surface_manifest_ready`.
- `runtime_surface_manifest_gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`.
- `runtime_surface_manifest.json` generated at `2026-06-19T23:58:39Z`.
- Manifest category count: `optimizer/scorecard=15`.
- Manifest automation coverage: every optimizer/scorecard file is `outside_recurring_run`.

## Optimizer/Scorecard Manifest Rows

All rows below are listed by the current `runtime_surface_manifest.json`.

| Path | Role | Gate expected | Automation coverage |
| --- | --- | --- | --- |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` | test | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_slot_optimizer_real_roles.py` | test | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_universal_optimizer_known_cards.py` | test | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py` | script | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |

## Covered Gate Surfaces

The shared helper is present in `master_optimizer_common.py`:

- `load_battle_gate_summary(...)` loads the official latest summary and emits
  `missing_summary` plus `battle_gate_summary_missing` when the file is absent
  (`master_optimizer_common.py:561-571`).
- `battle_gate_report_lines(...)` emits `audit_summary`,
  `battle_replay_final_status`, `battle_replay_final_status_reason`,
  `battle_gate_weight`, `mandatory_gate_divergences`,
  `mandatory_gate_statuses`, strategy confidence split, focused template,
  effect coverage residual, review-rule denominator, decision taxonomy, and
  forensic lineage fields (`master_optimizer_common.py:580-623`).
- `battle_gate_cli_lines(...)` emits the CLI version of the same guardrail
  fields (`master_optimizer_common.py:626-654`).

The helper is currently wired into these operational surfaces:

- `master_optimizer_baseline.py` extends the markdown report with
  `battle_gate_report_lines()` before matchup rows (`master_optimizer_baseline.py:30-40`).
- `master_optimizer_quality_gate.py` extends the markdown report with
  `battle_gate_report_lines()` before candidate rows (`master_optimizer_quality_gate.py:60-69`).
- `master_optimizer_confirmation.py` extends the markdown report with
  `battle_gate_report_lines()` before tested candidate rows (`master_optimizer_confirmation.py:250-259`).
- `master_optimizer_handoff.py` extends the markdown report with
  `battle_gate_report_lines()` before confirmed candidates (`master_optimizer_handoff.py:62-74`).
- `slot_optimizer.py` prints `battle_gate_cli_lines()` before optimizer scan
  arguments and filter stats (`slot_optimizer.py:608-619`).
- `test_master_optimizer_hashes.py` verifies that the helper output contains
  `battle_replay_final_status`, `battle_gate_weight`, mandatory divergence,
  strategy confidence, effect residual, denominator, taxonomy, and forensic
  fields (`test_master_optimizer_hashes.py:170-250`).

## Missing Gate Surfaces

Static search for `battle_gate`, `mandatory_gate`,
`battle_replay_final_status`, `mandatory_gate_divergences`,
`BATTLE_REPLAY_GATE`, and `BATTLE_VALIDATION` across all 15 manifest
optimizer/scorecard files found no gate wiring in the files below.

These files still produce user-facing reports or operational CLI output:

- `master_optimizer_apply.py` prints a markdown report with confirmation delta,
  hashes, rollback path, deck counts, and the local-SQLite mutation note, then
  optionally writes `master_optimizer_apply_*` (`master_optimizer_apply.py:208-226`).
- `master_optimizer_loop.py` prints a preflight plan/report and optionally
  writes `master_optimizer_preflight_*` (`master_optimizer_loop.py:236-307`).
- `master_optimizer_post_apply_gate.py` prints post-apply WR, delta, rollback
  path, and status, then optionally writes `master_optimizer_post_apply_gate_*`
  (`master_optimizer_post_apply_gate.py:96-117`).
- `master_optimizer_product_handoff.py` renders product-facing apply handoff
  details and required checks, inserts a handoff row in local SQLite, prints the
  markdown, and optionally writes `master_optimizer_product_handoff_*`
  (`master_optimizer_product_handoff.py:74-160`).
- `master_optimizer_rollback.py` prints rollback status and restored deck
  summary, then optionally writes `master_optimizer_rollback_*`
  (`master_optimizer_rollback.py:130-149`).
- `universal_optimizer.py` prints optimizer candidate counts, quick/full phase
  WR output, an `>>> APPLYING` line for full-phase deltas, baseline WR, and top
  results (`universal_optimizer.py:151-172`, `universal_optimizer.py:255-289`).

Tests are also incomplete for this boundary:

- `test_master_optimizer_hashes.py` covers the helper function output only.
- `test_slot_optimizer_real_roles.py` and
  `test_universal_optimizer_known_cards.py` contain no `battle_gate`,
  `battle_replay_final_status`, or `mandatory_gate_divergences` assertions.
- No current test was found that fails when `apply`, `loop`,
  `post_apply_gate`, `product_handoff`, `rollback`, or `universal_optimizer`
  output loses the battle gate block.

## Register Decision

BV-074 remains open.

The current recurring battle audit is trusted by its own final aggregate, but
that does not prove every optimizer/scorecard handoff surface propagates the
aggregate. The missing files can still be read as operational evidence without
displaying `battle_replay_final_status`, `mandatory_gate_divergences`, the
strategy high/low-confidence split, or `battle_gate_weight`.

## Task For "Ajustar battle"

1. Add `battle_gate_report_lines(...)` or `battle_gate_cli_lines(...)` to every
   optimizer/scorecard output that displays WR, delta, apply, rollback,
   preflight, or product handoff data.
2. For `universal_optimizer.py`, either add the same gate banner before any WR
   or apply output, or mark the script explicitly deprecated/blocked for
   optimizer handoff when the gate is unavailable.
3. Add regression tests that execute/render each optimizer/scorecard surface and
   assert presence of:
   - `battle_replay_final_status`
   - `battle_replay_final_status_reason`
   - `mandatory_gate_divergences`
   - `battle_gate_weight=required_for_optimizer_wr_evidence`
   - strategy high/low-confidence fields
4. Keep the missing-summary fallback behavior from `master_optimizer_common.py`
   so optimizer output cannot silently omit the battle gate when the summary is
   absent.
