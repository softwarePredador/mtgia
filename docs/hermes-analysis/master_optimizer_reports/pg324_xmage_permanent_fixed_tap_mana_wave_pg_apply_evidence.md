# PG324 XMage Permanent Fixed Tap Mana Wave - PostgreSQL Apply Evidence

- Applied at: `2026-07-01T19:25Z`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_apply.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_postcheck.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_rollback.sql`
- Backup table: `manaloom_deploy_audit.pg324_xmage_permanent_fixed_tap_mana_wave_20260701_19244`

## Scope

PG324 promoted `16` XMage-authoritative exact permanent mana-source rules using
`xmage_simple_tap_mana_source_permanent_v1` with fixed produced mana symbols
and optional simple activation mana cost.

Selected cards:

- `Apprentice Wizard`
- `Fyndhorn Elder`
- `Golgari Signet`
- `Greenweaver Druid`
- `Gruul Signet`
- `Gyre Engineer`
- `Knotvine Mystic`
- `Kozilek's Channeler`
- `Llanowar Tribe`
- `Nantuko Elder`
- `Orzhov Signet`
- `Palladium Myr`
- `Rakdos Signet`
- `Selesnya Signet`
- `Sunastian Falconer`
- `Weaver of Currents`

## Precheck

Precheck returned `16` rows. Every proposed card had exactly one
Oracle-hash-matched target card row:

- `target_card_rows=1` for `16/16`
- `expected_rule_rows_before=0` for `16/16`
- `would_deprecate_shadow_rows=14`

## Apply

Apply completed successfully:

- backup rows selected: `14`
- deprecated shadow rows: `14`
- upserted rows: `16`
- transaction: `COMMIT`

## Postcheck

Postcheck returned `16` rows:

- promoted rule rows: `16/16`
- promoted verified/auto rows: `16/16`
- promoted Oracle hash rows: `16/16`
- backup rows: `14`

## Sync And E2E

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_pg_to_sqlite_sync.json`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_e2e_validation.md`

Sync result:

- `pg_rows_loaded=7195`
- `sqlite_inserted_or_updated=6989`
- `canonical_snapshot_rows_exported=4786`
- `pg_skipped_lower_priority=0`

E2E result:

- PostgreSQL source of truth: `16/16`
- SQLite Hermes cache: `16/16`
- canonical snapshot fallback: `16/16`
- runtime `get_card_effect`: `16/16`
- status: `pass`
