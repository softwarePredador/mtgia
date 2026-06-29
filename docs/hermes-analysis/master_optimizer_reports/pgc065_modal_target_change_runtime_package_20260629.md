# PGC065 Modal Target Change Runtime Package

- Package ID: `pgc065_modal_target_change_runtime`
- Database target: `143.198.230.247:5433/halder`
- Applied UTC: `2026-06-29`
- Scope: promote modal single-target stack target change from `annotation_only` to `runtime_executor_v1`.

## Cards

| Card | Result |
| --- | --- |
| `Return the Favor` | `change_target_mode_status` promoted to runtime and validated through a real response window. Card remains residual for `spree_additional_cost_status` and `copy_activated_triggered_ability_status`. |
| `Untimely Malfunction` | `redirect_target_mode_status` promoted to runtime and validated through a real response window. Card remains residual for `cant_block_mode_status`. |

## Evidence

| Stage | File | Result |
| --- | --- | --- |
| Precheck | `pgc065_modal_target_change_runtime_precheck_20260629.out` | `target_rows=2`, trusted target rows present, backup absent, current annotation rows present. |
| Apply | `pgc065_modal_target_change_runtime_apply_20260629.out` | PostgreSQL package applied. |
| Postcheck | `pgc065_modal_target_change_runtime_postcheck_20260629.out` | `return_change_target_runtime_rows=1`, `untimely_redirect_runtime_rows=1`, expected residual rows preserved. |
| PG -> SQLite/snapshot | `pgc065_modal_target_change_runtime_pg_to_sqlite_20260629.out` | `selected_card_count=2`, `pg_rows_loaded=2`, `sqlite_inserted_or_updated=4`, snapshot rows exported. |
| E2E gate | `pgc065_e2e_validation_20260629.md` | PG, SQLite, snapshot, `get_card_effect`, and no-override battle execution all passed. |
| Focused battle tests | `pgc065_modal_target_change_focused_tests_20260629.out` | Existing redirect tests, modal fake-runtime test, PGC092 cache tests, and real PGC065 card response test passed. |
| Full battle harness | `pgc065_test_battle_analyst_v10_3_20260629.out` | Full battle suite passed after runtime and mapper changes. |
| XMage effect mapper | `pgc065_test_xmage_to_manaloom_effect_hints_20260629.out` | `249` mapper tests passed; modal copy/change-target and destroy-artifact/redirect signatures now map to partial runtime scopes. |
| XMage batch classifier | `pgc065_test_xmage_semantic_family_batch_pipeline_20260629.out` | `236` classifier tests passed; new modal target-change scopes classify as batch PG candidates after precheck. |
| Residual probe | `annotation_runtime_batch_probe_20260629_pgc065.md` | Clean cards remain `10/39`; residual cards remain `29/39`; runtime executor value paths increased from `37` to `39`. |

## Runtime Behavior Added

- `priority_round` now recognizes modal effects that can change a single target on a stack object, not only legacy `redirect_removal`.
- `resolve_redirect_removal` emits `redirect_target_mode_status` and `change_target_mode_status` provenance fields when present.
- Replay events now include `target_change_pipeline=single_target_stack_object_redirect_runtime_v1`.
- E2E scenario proves both cards leave hand as responses, pay mana, choose a legal alternate target, and mutate the original stack object's declared target.

## XMage Batch Acceleration

- `xmage_to_manaloom_effect_hints.py` now maps `CopyTargetStackObjectEffect + ChooseNewTargetsTargetEffect + TargetStackObject` to the partial runtime scope used by `Return the Favor`.
- `xmage_to_manaloom_effect_hints.py` now maps `DestroyTargetEffect + ChooseNewTargetsTargetEffect + TargetStackObject` artifact modal signatures to the partial runtime scope used by `Untimely Malfunction`.
- `xmage_semantic_family_classifier.py` accepts both scopes as `targeted_interaction` batch candidates after PostgreSQL precheck.

## Residual

- `Return the Favor`: `spree_additional_cost_status`, `copy_activated_triggered_ability_status`.
- `Untimely Malfunction`: `cant_block_mode_status`.
- These residuals are intentionally not hidden by the target-change promotion.
