# PG059 Sync Metadata Restore Package

Generated at: `2026-06-23T02:23:28Z`

## Scope

Restore PostgreSQL metadata for trusted rows already closed by previous batches
after a reviewed JSON sync drift removed `oracle_hash` and selected
oracle-runtime annotations from the active curated rows.

Cards:

- `Fellwar Stone`
- `Mana Vault`
- `Mox Amber`
- `Seething Song`
- `Silence`
- `Talisman of Conviction`
- `Valakut Awakening // Valakut Stoneforge`

## Expected Precheck

- `target_cards=7`
- `target_rule_rows=7`
- `target_missing_hash_rows=0`
- `target_hash_mismatch_rows=0`
- `target_missing_effect_patch_rows=6`
- `target_card_id_missing_rows=0`
- `backup_table_exists=0`

## Apply

- Backs up target rows to
  `manaloom_deploy_audit.pg059_sync_metadata_restore_20260623_022328`.
- Confirms/restores `oracle_hash` from current `cards.oracle_text`.
- Restores previously validated oracle-runtime annotation keys for the six
  non-hash-only rows.
- Does not change deck contents or apply deck swaps.

## Code Guard

`sync_battle_card_rules_pg.py` now preserves existing `oracle_hash` and curated
metadata on same-key conflicts, preventing future reviewed JSON syncs from
erasing PG-only evidence fields.

## Rollback

Run `pg059_sync_metadata_restore_rollback_20260623_022328.sql` to restore the
backup rows.
