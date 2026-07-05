# Lorehold External Identity Cache Apply Package

- Generated at: `2026-07-05T01:48:27Z`
- Status: `external_identity_cache_apply_package_prepared_not_applied_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- SQLite apply executed: `False`

## SQL Files

- `precheck`: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_precheck.sql`
- `apply`: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_apply_sqlite.sql`
- `postcheck`: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_postcheck.sql`
- `rollback`: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_rollback_sqlite.sql`

## Package Rows

| Card | Post-Import Status | Commander | Color Fit |
| --- | --- | ---: | ---: |
| Brain in a Jar | `identity_ready_then_runtime_or_cut_safety_required` | `True` | `True` |
| Entreat the Angels | `identity_ready_then_runtime_or_cut_safety_required` | `True` | `True` |
| Haze of Rage | `identity_ready_then_combo_runtime_and_cut_safety_required` | `True` | `True` |
| Late to Dinner | `identity_ready_then_shell_contract_required` | `True` | `True` |
| Miraculous Recovery | `identity_ready_then_shell_contract_required` | `True` | `True` |
| Strata Scythe | `identity_ready_then_shell_contract_required` | `True` | `True` |

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: The package is ready for human/apply review, but it has not been executed. Identity cache readiness is not deck-quality or battle promotion evidence.
