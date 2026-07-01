# PG329 XMage Recursion Battlefield Simple Wave - PostgreSQL Apply Evidence

- Applied at: `2026-07-01T20:33Z`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_apply.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_postcheck.sql`

## Precheck

- Target card rows: `3/3`
- Existing matching rule rows: `0/3`
- Expected rule rows before apply: `0/3`
- Shadow rows scheduled for deprecation: `0`

Target rows:

- `Ashen Powder` -> `battle_rule_v1:edf213db3ea1551941983dd3d9a8ce4c`
- `Helping Hand` -> `battle_rule_v1:10d934ad92de0065f345f6b463df6911`
- `Hymn of Rebirth` -> `battle_rule_v1:6c21b07e86b0625f859ea8797a5c9a71`

## Apply

- Deprecated shadow rows: `0`
- Upserted rows: `3`
- Transaction status: `COMMIT`

## Postcheck

- Promoted rule rows: `3/3`
- Promoted verified/auto rows: `3/3`
- Promoted Oracle-hash rows: `3/3`
- Backup rows: `0`

Postcheck rows:

- `Ashen Powder`: promoted `1`, verified/auto `1`, oracle hash `1`
- `Helping Hand`: promoted `1`, verified/auto `1`, oracle hash `1`
- `Hymn of Rebirth`: promoted `1`, verified/auto `1`, oracle hash `1`

## Sync And Validation

- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_e2e_validation.md`
- Post-PG329 queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg329_recursion_battlefield_simple_wave_commander_legal.md`
- Post-PG329 readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg329_recursion_battlefield_simple_wave_recheck.md`

Measured result:

- `battle_and_oracle_ready`: `2347 -> 2350`
- `battle_family_mapper_required`: `30200 -> 30197`
- `target_identity_count`: `27277 -> 27274`
- `xmage_authoritative_source_count`: `26963 -> 26960`
- `xmage_authoritative_adapter_required_count`: `26963 -> 26960`
- `recursion::xmage_graveyard_return_variant_review_v1`: `1959 -> 1956`
