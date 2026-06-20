# Battle latest runtime surface manifest denominator recheck

Generated: 2026-06-19T20:52:28-03:00

## Scope

Read-only recheck of `BV-071` against the current recurring battle audit snapshot:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/runtime_surface_manifest.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/summary.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`

No code, PostgreSQL, deck swap, commit or push was performed.

## Current artifact evidence

`runtime_surface_manifest.json.summary`:

- `total_files=108`
- `unclassified_files=[]`
- `automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`
- `category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`
- `gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`

`summary.json`:

- `runtime_surface_manifest_total_files=108`
- `runtime_surface_manifest_category_counts` is populated with the same category counts.
- `runtime_surface_manifest_automation_coverage_counts` is populated with the same coverage counts.
- `runtime_surface_manifest_gate_expected_counts=null`
- `runtime_surface_manifest_status=null`

`runtime_surface_manifest.md`:

- Reports `Total related Python files: 108`.
- Reports category and automation coverage tables.
- Lists all file rows with `Path`, `Category`, `Owner`, `Role`, `Gate expected`, and `Automation coverage`.

## Test denominator evidence

`docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` still validates:

- `assert summary["total_files"] >= 98`
- `assert summary["unclassified_files"] == []`
- Only presence of coverage keys such as `covered_by_recurring_run` and `outside_recurring_run`.
- Category membership is checked, but exact current counts are not pinned.
- Each file row must have non-empty `owner`, `gate_expected` and `automation_coverage`.

## Result

`BV-071` remains open.

The manifest itself is current and detailed, but the regression test still allows the denominator to drift from `108` down to any value `>=98`. The principal `summary.json` also omits `runtime_surface_manifest_gate_expected_counts`, even though the manifest artifact contains those counts.

Task for "Ajustar battle":

- Pin the current manifest denominator or require a versioned snapshot/waiver when `total_files` changes from `108`.
- Assert exact `category_counts`, `automation_coverage_counts`, and `gate_expected_counts`, or compare against a checked-in expected snapshot.
- Publish `runtime_surface_manifest_gate_expected_counts` and a manifest status field in `summary.json`.
- Keep the existing per-file checks for `owner`, `gate_expected`, and `automation_coverage`.
