# PGC064 Copy Spell Choose New Targets Runtime Package

- Package ID: `pgc064_copy_spell_choose_new_targets_runtime`
- Database target: `143.198.230.247:5433/halder`
- Applied UTC: `2026-06-29`
- Scope: promote copied instant/sorcery spell target reselection from `annotation_only` to `runtime_executor_v1`.

## Cards

| Card | Result |
| --- | --- |
| `Dualcaster Mage` | Clean after ETB copy target-selection runtime validation. |
| `Reverberate` | Clean after response copy target-selection runtime validation. |
| `Reiterate` | `choose_new_targets_status` promoted, but card remains residual for `buyback_status`. |

`Return the Favor` was intentionally excluded. It also needs spree cost modeling, change-target mode separation, and activated/triggered ability copy support.

## Evidence

| Stage | File | Result |
| --- | --- | --- |
| Precheck | `pgc064_copy_spell_choose_new_targets_runtime_precheck_20260629.out` | `target_rows=3`, `choose_new_targets_annotation_rows=3`, backup absent. |
| Apply | `pgc064_copy_spell_choose_new_targets_runtime_apply_20260629.out` | PostgreSQL package applied. |
| Postcheck | `pgc064_copy_spell_choose_new_targets_runtime_postcheck_20260629.out` | `choose_new_targets_runtime_rows=3`, `clean_promoted_rows=2`, `reiterate_runtime_choose_targets_buyback_residual_rows=1`. |
| PG -> SQLite/snapshot | `pgc064_copy_spell_choose_new_targets_runtime_pg_to_sqlite_20260629.out` | `pg_rows_loaded=3`, `sqlite_inserted_or_updated=6`, snapshot rows exported. |
| E2E gate | `pgc064_e2e_validation_20260629.md` | PG, SQLite, snapshot, `get_card_effect`, and no-override battle execution all passed. |
| Focused tests | `pgc064_copy_spell_target_selection_focused_tests_20260629.out` | Reverberate, Reiterate, Dualcaster, and direct runtime retarget tests passed. |
| Full battle harness | `pgc064_test_battle_analyst_v10_3_20260629.out` | `593` battle tests passed. |
| XMage effect mapper | `pgc064_test_xmage_to_manaloom_effect_hints_20260629.out` | `247` tests passed; direct copy target spell now maps to runtime target selection. |
| XMage batch classifier | `pgc064_test_xmage_semantic_family_batch_pipeline_20260629.out` | `234` tests passed; classifier accepts both historical `may` and canonical runtime scope. |

## Runtime Behavior Added

- `copy_spell_on_stack` now accepts player context and stores `_copy_target_selection`.
- Runtime status is honored only when `may_choose_new_targets=true` and `choose_new_targets_status` is runtime-enabled.
- Copied spells with declared targets can retarget to a legal alternate target.
- Retargeting emits replay fields including `copy_target_selection_status`, `copy_target_selection_pipeline`, `target_reassignment_performed`, and `copy_spell_target`.
- Ranking prefers opponent permanents over the copy controller's own permanents for removal-style copied spells.

## Residual

- `Reiterate`: `buyback_status`.
- `Return the Favor`: `spree_additional_cost_status`, `change_target_mode_status`, `copy_activated_triggered_ability_status`.
