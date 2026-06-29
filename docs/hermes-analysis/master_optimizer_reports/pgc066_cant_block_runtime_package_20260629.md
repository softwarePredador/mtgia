# PGC066 Cant Block Runtime Package

- Package ID: `pgc066_cant_block_runtime`
- Database target: `143.198.230.247:5433/halder`
- Applied UTC: `2026-06-29`
- Scope: promote "can't block this turn" effects from annotation-only metadata to battle runtime execution.

## Cards

| Card | Result |
| --- | --- |
| `Sundering Eruption // Volcanic Fissure` | `cant_block_mode_status` promoted to `runtime_executor_v1`. The land-destruction branch now also applies the nonfliers-cannot-block rider through the battle executor. Card is fully clean in the current PGC066 residual probe. |
| `Untimely Malfunction` | `cant_block_mode_status` promoted to `runtime_executor_v1`. Modal selection can now choose the target-creature-cannot-block mode without destroying the target. Card is fully clean in the current PGC066 residual probe. |

## Evidence

| Stage | File | Result |
| --- | --- | --- |
| Precheck | `pgc066_cant_block_runtime_precheck_20260629.out` | Trusted target rows were present for both cards before apply. |
| Apply | `pgc066_cant_block_runtime_apply_20260629.out` | PostgreSQL package applied. |
| Postcheck | `pgc066_cant_block_runtime_postcheck_20260629.out` | `target_rows=2`, `sundering_cant_block_runtime_rows=1`, `untimely_cant_block_runtime_rows=1`, `remaining_annotation_rows=0`. |
| PG -> SQLite/snapshot | `pgc066_cant_block_runtime_pg_to_sqlite_20260629.out` | `selected_card_count=2`, `pg_rows_loaded=2`, `sqlite_inserted_or_updated=2`, `canonical_snapshot_rows_exported=3258`. |
| E2E gate | `pgc066_e2e_validation_20260629.md` | PG, SQLite, snapshot, `get_card_effect`, and no-override battle execution all passed. |
| Focused battle tests | `pgc066_cant_block_focused_tests_20260629.out` | Land removal, modal interaction cache, synthetic runtime coverage, and real SQLite rule tests passed. |
| Full battle harness | `pgc066_test_battle_analyst_v10_3_20260629.out` | Full battle suite passed after runtime and mapper changes. |
| XMage effect mapper | `pgc066_test_xmage_to_manaloom_effect_hints_20260629.out` | `249` mapper tests passed; modal target-creature-cannot-block and nonfliers-cannot-block signatures map to runtime scopes. |
| XMage batch classifier | `pgc066_test_xmage_semantic_family_batch_pipeline_20260629.out` | `236` classifier tests passed; new runtime scopes classify as batch candidates after precheck. |
| Residual probe | `annotation_runtime_batch_probe_20260629_pgc066.md` | Clean cards increased to `12/39`; residual cards decreased to `27/39`; runtime executor value paths increased to `41`. |

## Runtime Behavior Added

- `prepare_declared_removal_targets` can now select a legal creature target for modal `cant_block` effects when the current mode is not a destroy mode.
- `resolve_declared_single_removal` applies `set_until_eot` state for the selected target-creature-cannot-block mode and emits `cant_block_until_eot_resolved` instead of moving that target to graveyard.
- Normal removal resolution can now apply a separate nonfliers-cannot-block rider after removing the declared target.
- The existing blocking pipeline already excludes creatures marked with `creature_cannot_block`, and end-of-turn cleanup clears the temporary state.

## XMage Batch Acceleration

- `xmage_to_manaloom_effect_hints.py` now maps `Untimely Malfunction` style modal signatures to `modal_destroy_artifact_redirect_target_cant_block_runtime_v1`.
- `xmage_to_manaloom_effect_hints.py` now maps `Sundering Eruption // Volcanic Fissure` style land-destruction plus nonfliers-cannot-block signatures to `destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_runtime_v1`.
- `xmage_semantic_family_classifier.py` accepts both new runtime scopes as batch PostgreSQL candidates after source precheck.

## Residual

- `Sundering Eruption // Volcanic Fissure`: no residual annotation-only fields in the current PGC066 probe.
- `Untimely Malfunction`: no residual annotation-only fields in the current PGC066 probe.
- The remaining `27/39` residual cards are tracked separately in `pgc066_residual_runtime_family_plan_20260629.md`.
