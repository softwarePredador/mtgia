# PGC067 Buyback Runtime Package

- Package ID: `pgc067_buyback_runtime`
- Database target: `143.198.230.247:5433/halder`
- Applied UTC: `2026-06-29`
- Scope: promote mana buyback from annotation-only metadata to battle runtime execution.

## Cards

| Card | Result |
| --- | --- |
| `Reiterate` | `buyback_status` promoted to `runtime_executor_v1` with `buyback_cost={3}`. The response-copy path now pays buyback when the full locked cost is available and returns the resolved spell to hand; without the extra mana it resolves to graveyard. Card is fully clean in the PGC067 residual probe. |

## Evidence

| Stage | File | Result |
| --- | --- | --- |
| Precheck | `pgc067_buyback_runtime_precheck_20260629.out` | `target_rows=1`, `trusted_target_rows=1`, `current_buyback_annotation_rows=1`, backup absent. |
| Apply | `pgc067_buyback_runtime_apply_20260629.out` | PostgreSQL package applied. |
| Postcheck | `pgc067_buyback_runtime_postcheck_20260629.out` | `backup_rows=1`, `target_rows=1`, `reiterate_buyback_runtime_rows=1`, `remaining_annotation_rows=0`. |
| PG -> SQLite/snapshot | `pgc067_buyback_runtime_pg_to_sqlite_20260629.out` | `selected_card_count=1`, `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`, `canonical_snapshot_rows_exported=3258`. |
| E2E gate | `pgc067_e2e_validation_20260629.md` | PG, SQLite, snapshot, `get_card_effect`, and no-override battle execution all passed. |
| Focused battle tests | `pgc067_buyback_focused_tests_20260629.out` | Reiterate no-buyback, synthetic buyback, real SQLite buyback, Green Sun target guard, and copied X-value tests passed. |
| XMage effect mapper | `pgc067_test_xmage_to_manaloom_effect_hints_20260629.out` | `250` mapper tests passed; `BuybackAbility("{3}")` on copy-stack spells maps to buyback runtime. |
| XMage batch classifier | `pgc067_test_xmage_semantic_family_batch_pipeline_20260629.out` | `237` classifier tests passed; Reiterate-style buyback copy spells classify as batch candidates after precheck. |
| Residual probe | `annotation_runtime_batch_probe_20260629_pgc067.md` | Clean cards increased to `13/39`; residual cards decreased to `26/39`; runtime executor value paths increased to `42`. |

## Runtime Behavior Added

- `buyback_status=runtime_executor_v1` enables optional additional buyback cost selection.
- Mana buyback cost is modeled through the existing locked-cost machinery via `additional_costs`.
- If buyback is paid, `finish_resolved_spell` sends the resolved spell to hand and emits `buyback_returned_to_hand`.
- If buyback cannot be paid, the same spell remains castable for base cost and resolves to graveyard.
- Countered spells do not use the buyback replacement, because the runtime hook is only in resolved-spell finalization.

## XMage Batch Acceleration

- `xmage_to_manaloom_effect_hints.py` now recognizes `CopyTargetStackObjectEffect + TargetSpell + BuybackAbility("{...}")`.
- `xmage_semantic_family_classifier.py` accepts `copy_stack_instant_or_sorcery_new_targets_runtime_buyback_runtime_v1` as a batch-safe targeted-interaction candidate after PostgreSQL precheck.

## Residual

- `Reiterate`: no residual annotation-only fields in the current PGC067 probe.
- Remaining residual cards are tracked in `pgc067_residual_runtime_family_plan_20260629.md`.
