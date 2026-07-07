# PG629 Activated Destroy Multi-Sacrifice Apply Evidence

- Generated UTC: `2026-07-07T18:06:53Z`
- Database target: `127.0.0.1:15432/halder`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg629_activated_destroy_multi_sacrifice_new_server_package_manifest.json`
- Scope: `xmage_permanent_simple_activated_destroy_target_v1`
- Cards: `Earthblighter`, `Keldon Arsonist`, `Krark-Clan Engineers`, `Sandstone Deadfall`

## Precheck

- Target card rows: `4`
- Existing rule rows: `0`
- Shadow rows to deprecate: `0`

## Apply

- Deprecated shadow rows: `0`
- Upserted rows: `4`
- Transaction: `COMMIT`

## Postcheck

- Promoted rule rows: `4/4`
- Promoted `verified/auto` rows: `4/4`
- Promoted `oracle_hash` rows: `4/4`
- Backup rows: `0`

## Sync And E2E

- PG -> SQLite selected cards: `4`
- SQLite inserted/updated rows: `4`
- Canonical snapshot rows exported: `6970`
- E2E status: `pass`
- E2E stages: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and battle execution all passed.

## Queue Impact

- `target_identity_count`: `25016 -> 25012`
- `xmage_authoritative_adapter_required_count`: `24703 -> 24699`
- `removal_destroy::targeted_destroy_variant_v1`: `510 -> 506`
- Post-apply exact split recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`
