# PG373 Destroy + Draw Spell Wave Apply Evidence - 2026-07-02

Status: `applied_synced_validated`.

## Scope

- Scope: `xmage_destroy_target_and_draw_card_spell_v1`.
- Family: `xmage_destroy_target_draw_card_spell`.
- Cards promoted: `7`.
- Cards: `Aura Blast`, `Bright Reprisal`, `Implode`, `Mirrodin Avenged`,
  `Slice in Twain`, `Smash`, `You Are Already Dead`.
- Runtime basis: `composite_resolution` with `remove_creature` /
  `remove_permanent` plus `draw_cards`, resolving the source spell only once.

## Implementation

- Splitter: `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  now maps exact `DestroyTargetEffect + DrawCardSourceControllerEffect` spell
  signatures.
- Runtime test: `test_composite_destroy_draw_spell_resolves_both_components_once`
  proves target removal, card draw, and single source-card graveyard movement.
- Splitter tests prove exact mapping and block dynamic source/oracle draw cases.

## Package Evidence

- Split report:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg373_destroy_draw_spell_wave.md`
- Package:
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_precheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_apply.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_postcheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_rollback.sql`
- Precheck: `7` target card rows matched, `0` existing expected rows, `0`
  shadow rows to deprecate.
- Apply: `upserted_rows=7`, `deprecated_shadow_rows=0`.
- Postcheck: `7/7` promoted rows are `verified`, `auto`, and have
  `oracle_hash`.

## Tests

Command:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
```

Result: `451 tests`, `OK`.

## Sync And Audits

- PostgreSQL -> Hermes/SQLite rule sync:
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_pg_to_sqlite_sync.json`
  - `canonical_snapshot_rows_exported=5012`
  - `sqlite_inserted_or_updated=7236`
- PostgreSQL card metadata sync:
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_pg_metadata_sync.json`
- End-to-end package validation:
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_e2e_validation.md`
  - status `pass`
  - PostgreSQL, SQLite, canonical snapshot, and runtime lookup each validated
    `7/7`.
- Contract audit after docs update:
  - `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg373_destroy_draw_spell_wave_final.md`
  - status `pass`, `49/49`.
- Strategy/operational/legacy audits:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
    status `pass`, `26/26`.
  - `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
    status `pass`.
  - `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
    status `pass`.

## Queue Delta

- Post-PG372 adapter required: `26743`.
- Post-PG373 adapter required: `26736`.
- Delta: `7` identities promoted.
- Parser gaps remained `0`.
- Missing-source exceptions remained `314`.
- Post-PG373 supported splitter recheck:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg373_supported_recheck.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`
  - `draw_effect_class_not_pure=532`

Stop condition remains unmet: the refreshed post-PG373 queue still has
`26736` `xmage_authoritative_adapter_required` identities plus `314`
missing-source exceptions.
