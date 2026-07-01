# PG325 PostgreSQL Apply Evidence

- Generated at: `2026-07-01T19:46:00-03:00`
- Deploy: `PG325`
- Slug: `xmage_recursion_exile_self_wave`
- Backup table: `manaloom_deploy_audit.pg325_xmage_recursion_exile_self_wave_20260701_194250`
- Selected cards: `Flood of Recollection`, `Restock`, `Treasured Find`
- Family: `xmage_graveyard_to_hand_exile_self_spell`

## Precheck

- PostgreSQL precheck matched `3/3` target card rows by Oracle hash.
- `expected_rule_rows_before=0` for all selected cards.
- `would_deprecate_shadow_rows=0`.

## Apply

- `deprecated_shadow_rows=0`.
- `upserted_rows=3`.
- Transaction committed.

## Postcheck

- `promoted_rule_rows=3/3`.
- `promoted_verified_auto_rows=3/3`.
- `promoted_oracle_hash_rows=3/3`.
- `backup_rows=0`.

## Sync And Validation

- PG -> Hermes/SQLite sync loaded `7198` PostgreSQL rules.
- SQLite inserted/updated `6992` rows.
- Canonical snapshot exported `4789` rows.
- E2E validation passed for PostgreSQL source of truth, SQLite Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  battle package gate.
- The PG325 manifest now requires deterministic effect fields including
  `target`, `count`, `destination`, `target_controller`, `target_constraints`,
  and `exiles_self`; the rerun E2E passed against those stronger checks.
- Focused runtime test proves the recovered cards move to hand and the source
  spell resolves to exile when `exiles_self=true`.
