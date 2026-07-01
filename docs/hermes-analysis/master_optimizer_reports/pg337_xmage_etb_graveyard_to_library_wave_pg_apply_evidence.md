# PG337 XMage ETB Graveyard-To-Library PostgreSQL Apply Evidence

- Generated at: `2026-07-01T23:18:26+00:00`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_manifest.json`
- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg337_etb_graveyard_to_library_wave.md`

## Scope

Promoted the exact XMage-authoritative creature ETB graveyard-to-library
subpattern:

- `xmage_creature_etb_put_graveyard_card_on_library_v1`

Selected cards:

- `Dukhara Scavenger`
- `Meldweb Curator`

Blocked examples remained blocked intentionally:

- `Nantuko Tracer`: Oracle/source uses `target card from a graveyard` and the
  owner's library, not the controller's own graveyard/library.
- `Swiftgear Drake`: Oracle is not a simple self-graveyard top/bottom library
  pattern for this adapter.
- `Biblioplex Assistant` and `Monastery Messenger`: source target pattern is
  not supported by this exact self-graveyard adapter.

## Precheck

Command:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_precheck.sql
```

Result:

| Card | Target Rows | Existing Expected Rows | Shadow Rows To Deprecate |
| --- | ---: | ---: | ---: |
| Dukhara Scavenger | 1 | 0 | 0 |
| Meldweb Curator | 1 | 0 | 0 |

## Apply

Command:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_apply.sql
```

Result:

- `deprecated_shadow_rows`: `0`
- `upserted_rows`: `2`
- Transaction ended with `COMMIT`.

## Postcheck

Command:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_postcheck.sql
```

Result:

| Card | Promoted Rows | Verified/Auto Rows | Oracle Hash Rows | Backup Rows |
| --- | ---: | ---: | ---: | ---: |
| Dukhara Scavenger | 1 | 1 | 1 | 0 |
| Meldweb Curator | 1 | 1 | 1 | 0 |

## Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --include-needs-review \
  --apply-sqlite-from-pg \
  --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json \
  --report docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_pg_to_sqlite_sync.json
```

Result:

- `pg_rows_loaded`: `7251`
- `sqlite_inserted_or_updated`: `7045`
- `canonical_snapshot_rows_exported`: `4840`

## E2E

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_e2e_validation.json`

Result:

- Status: `pass`
- PostgreSQL source of truth: `2/2`
- Hermes SQLite cache: `2/2`
- Canonical snapshot fallback: `2/2`
- Runtime `get_card_effect`: `2/2`

## Queue Reduction

Post-PG336 baseline:

- `battle_and_oracle_ready`: `2382`
- `battle_family_mapper_required`: `30165`
- `target_identity_count`: `27242`
- `xmage_authoritative_adapter_required_count`: `26928`
- top recursion work unit: `1924`

Post-PG337:

- `battle_and_oracle_ready`: `2384`
- `battle_family_mapper_required`: `30163`
- `target_identity_count`: `27240`
- `xmage_authoritative_adapter_required_count`: `26926`
- top recursion work unit: `1922`

Supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg337_supported_recheck.md`
- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`
- `considered_supported_work_unit_rows`: `7947`
