# PGC068 Return the Favor Spree Stack Object Runtime Package

- Package ID: `pgc068_return_favor_spree_stack_object_runtime`
- Database target: `143.198.230.247:5433/halder`
- Applied UTC: `2026-06-29`
- Scope: promote Return the Favor's remaining annotation-only runtime blockers.

## Cards

| Card | Result |
| --- | --- |
| `Return the Favor` | Promote selected-mode spree additional costs to runtime, change copy target scope to stack object, and promote activated/triggered ability copy to runtime. Existing change-target mode remains runtime. |

## Runtime Behavior Added

- `spree_additional_cost_status=runtime_executor_v1` requires the selected response mode's `+{1}` cost before the spell can be cast.
- `copy_activated_triggered_ability_status=runtime_executor_v1` allows copying triggered/activated ability stack objects, not only instant or sorcery spells.
- `target=stack_object` and `copy_stack_object_types` encode the XMage `CopyTargetStackObjectEffect` filter.
- `change_target_mode_status=runtime_executor_v1` keeps the existing single-target redirect executor.

## Evidence

| Stage | File | Result |
| --- | --- | --- |
| Precheck | `pgc068_return_favor_spree_stack_object_runtime_precheck_20260629.out` | `target_rows=1`, `trusted_target_rows=1`, `current_spree_annotation_rows=1`, `current_copy_ability_annotation_rows=1`, backup absent. |
| Apply | `pgc068_return_favor_spree_stack_object_runtime_apply_20260629.out` | PostgreSQL package applied with backup table and `APPLY_OK`. |
| Postcheck | `pgc068_return_favor_spree_stack_object_runtime_postcheck_20260629.out` | `backup_rows=1`, `target_rows=1`, `return_favor_runtime_rows=1`, `remaining_annotation_rows=0`. |
| PG -> SQLite/snapshot | `pgc068_return_favor_spree_stack_object_runtime_pg_to_sqlite_20260629.out` | `selected_card_count=1`, `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`, `canonical_snapshot_rows_exported=3258`. |
| E2E gate | `pgc068_e2e_validation_20260629.md` | PG, SQLite, snapshot, `get_card_effect`, copy-spell, copy-triggered-ability, and change-target execution passed. |
| Focused battle tests | `pgc068_return_favor_focused_tests_20260629.out` | `6` focused tests passed. |
| Full battle harness | `pgc068_test_battle_analyst_v10_3_20260629.out` | Full battle regression harness passed. |
| XMage effect mapper | `pgc068_test_xmage_to_manaloom_effect_hints_20260629.out` | `250` mapper tests passed. |
| XMage batch classifier | `pgc068_test_xmage_semantic_family_batch_pipeline_20260629.out` | `237` classifier tests passed. |
| Residual probe | `annotation_runtime_batch_probe_20260629_pgc068.md` | Clean cards increased to `14/39`; residual cards decreased to `25/39`; runtime executor value paths increased to `45`. |

## Residual

- `Return the Favor`: no residual annotation-only fields in the current PGC068 probe.
- Remaining residual cards are tracked in `pgc068_residual_runtime_family_plan_20260629.md`.
