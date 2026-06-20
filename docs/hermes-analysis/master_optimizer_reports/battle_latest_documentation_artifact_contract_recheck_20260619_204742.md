# Battle Latest Documentation And Artifact Contract Recheck - 2026-06-19T20:47:42Z

## Scope

Read-only recheck of the current battle audit artifacts and documentation
routers. No runtime code, PostgreSQL, swaps, commits, or automation settings
were changed.

Primary latest artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/summary.json`

## Latest Summary

- `timestamp_utc=2026-06-19T20:38:55Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`
- `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`
- `strategy_low_confidence_seeds=["63202025","63202031"]`

No high/critical action findings or strategy blockers were present in this
latest run.

## Documentation Router Recheck

Current evidence:

- `BATTLE_REPLAY_GATE_MATRIX.md` is now current as of `2026-06-19T20:38Z` and
  its current gate reading points to run `20260619_203855`.
- `BATTLE_SYSTEM_LOGIC.md` still contains a top-of-file historical snapshot:
  `2026-06-19T16:42:53Z` with
  `battle_replay_final_status=review_required`.
- `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` still says
  `BATTLE_REPLAY_GATE_MATRIX.md` is updated for latest `20260619_184721`, even
  though the matrix itself is now on `20260619_203855`.

Operational reading:

- The stale part of `BV-058` is no longer the gate matrix current reading.
- `BV-058` remains open because the documentation router/status index still
  carries stale current-state wording and can steer a reader to old status
  snapshots.

## Event Static Contract Recheck

Current evidence from `event_contract_static.json`:

- `.summary.status=event_contract_static_ready`
- `.summary.static_engine_sources` includes:
  - `battle_analyst_v9.py`
  - `battle_sba_support.py`
  - `battle_replacement_support.py`
- `.summary.observed_not_static_literal=[]`
- `.summary.all_event_types_total=100`
- `.summary.static_event_types_total=100`
- `.summary.observed_event_types_total=52`
- `.summary.static_fixture_accepted_waiver_total=48`
- `field_findings_count=0`

Current test artifact:

- `test_battle_event_contract_static_audit.log`: `5 tests passed`

Fresh validation executed after the documentation update:

- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`:
  `5 tests passed`

Operational reading:

- The original open condition from `BV-070` is closed in latest `20260619_203855`.
- Static extraction now covers the support emitters that were previously only
  observed dynamically.
- `BV-070` can be removed from `Achados abertos` with this evidence.

## Test Provenance Recheck

Current evidence:

- `summary.json` has no usable `test_results` matrix; querying
  `.test_results` returns `null`.
- The run directory has `15` `test_*.log` files.
- `test_battle_effect_coverage_known_cards.log` is still empty
  (`0` bytes, `0` lines).
- Other test logs contain PASS or `tests passed` output, including:
  - `test_battle_action_critic.log`
  - `test_battle_decision_strategy_auditor.log`
  - `test_battle_event_contract_static_audit.log`
  - `test_battle_focused_template_dispatch_audit.log`
  - `test_battle_unknown_template_backlog_audit.log`

Operational reading:

- `BV-073` remains open in latest `20260619_203855`.
- The run likely executed the tests because the wrapper produced a trusted
  summary after `set -e` style gates, but the primary `summary.json` still does
  not prove exact test commands, exit codes, durations, or stdout/stderr paths.
- A blank per-test log remains ambiguous without consulting wrapper/global log
  behavior.

## Unknown Effect Semantic Recheck

Current summary fields:

- `mandatory_gate_statuses.effect_coverage.unknown_effects=0`
- `effect_coverage_unknowns=0`
- `effect_coverage_effect_totals_unknown=41`
- `focused_template_ready_unknown_effect_count=28`
- `focused_template_ready_effect_totals={"remove_permanent":1,"unknown":28}`
- `unknown_template_backlog_cards=0`
- `focused_template_dispatch_status=focused_template_dispatch_ready`

Operational reading:

- `BV-068` remains open.
- The effect coverage gate's `unknown_effects=0` is not the same denominator as
  `effect_totals.unknown=41`.
- A handoff must continue to separate source-unknown backlog from effect label
  unknowns.

## Commands Used

- `jq` over latest `summary.json`, `event_contract_static.json`,
  `effect_coverage.json`, and `runtime_surface_manifest.json`.
- `rg` over `BATTLE_SYSTEM_LOGIC.md`,
  `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`,
  `BATTLE_REPLAY_GATE_MATRIX.md`, and
  `BATTLE_VALIDATION_REGISTER_2026-06-19.md`.
- `wc` and `sed` over latest `test_*.log` files.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py`.
