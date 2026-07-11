# PG788 Next Safe Existing Scopes Evidence - 2026-07-11

Status: `applied_synced_validated`

Target: new-server PostgreSQL via `./server/bin/with_new_server_pg.sh`
(`127.0.0.1:15432/halder`).

## Scope

PG788 promoted 10 post-PG787 safe exact XMage scopes already supported by the
ManaLoom runtime:

- Amateur Auteur
- Ancestral Recall
- Black Lotus
- Cleanse
- Crusade
- Nimble Pilferer
- Novellamental
- Pradesh Gypsies
- River's Favor
- Timmy, Power Gamer

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_package_manifest.json`

## PG788 Apply

- Package selected count: `10`
- Precheck: `10` target rows, `0` existing rows, `0` shadows
- Apply: `10` rows upserted into PostgreSQL
- Postcheck: `10/10` promoted with `review_status=verified`,
  `execution_status=auto`, and matching `oracle_hash`

## PG788B Contract Backfill

The post-PG788 PG/Hermes/SQLite contract audit found one remaining failure:
trusted executable PostgreSQL rules without `oracle_hash`.

PG788B backfilled only that metadata gap:

- Precheck: `trusted_executable_rules_missing_oracle_hash=55`
- Apply: `backfilled_rows=55`
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`,
  `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`

Backfill files:

- `docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync

Final sync used the PostgreSQL-owned sync path:

```bash
./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json
```

Final sync report:

- `pg_rows_loaded=10161`
- `sqlite_inserted_or_updated=10049`
- `canonical_snapshot_rows_exported=7550`
- `database_target=127.0.0.1:15432/halder`

Metadata sync:

- `docs/hermes-analysis/master_optimizer_reports/pg788b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`
- `postgres_target=127.0.0.1:15432/halder`
- `requested_unique_names=7562`
- `postgres_cards_matched=7744`
- `sqlite_cache_alias_rows=7672`
- `deck_cards_backfill.matched_cache_rows=2699/2699`

## E2E

Final E2E after PG788B:

- Report JSON:
  `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_post_hash_backfill_e2e_validation.json`
- Report MD:
  `docs/hermes-analysis/master_optimizer_reports/pg788_next_safe_existing_scopes_new_server_post_hash_backfill_e2e_validation.md`
- Status: `pass`
- PostgreSQL source rows validated: `10`
- SQLite cache rows validated: `10`
- canonical snapshot rows validated: `10`
- runtime lookup rows validated: `10`
- battle execution scenarios: `7`
- battle execution events: `14`

Runtime scenarios exercised:

- Amateur Auteur activated destroy ability
- Ancestral Recall target player draws 3 cards
- Black Lotus contextual self-sacrifice mana production
- Cleanse destroys matching creatures
- Crusade static global power/toughness boost
- River's Favor aura static power/toughness attachment
- Timmy, Power Gamer hand-to-battlefield activation

Static/self restriction rows without direct battle scenario were still validated
through PostgreSQL, SQLite, snapshot, and runtime lookup:

- Nimble Pilferer
- Novellamental
- Pradesh Gypsies

## Final Audits

- XMage strategy consistency:
  `xmage_strategy_consistency_audit_20260711_post_pg788b_hash_backfill_new_server_final`
  passed `26/26`
- Operational surface alignment:
  `operational_surface_alignment_audit_20260711_post_pg788b_hash_backfill_new_server_final`
  passed
- Legacy contamination:
  `legacy_contamination_audit_20260711_post_pg788b_hash_backfill_new_server_final`
  passed
- PG/Hermes/SQLite contract:
  `pg_hermes_sqlite_contract_audit_20260711_post_pg788b_hash_backfill_new_server_final_v2`
  passed `51/51`
- Server target quality gate:
  `./scripts/quality_gate.sh server-target` passed

## Global Queue After PG788B

Readiness:

- `battle_and_oracle_ready=6556`
- `battle_family_mapper_required=27310`
- `snapshot_has_verified_rule=6591`
- `snapshot_has_any_rule=7756`

XMage authoritative queue:

- `target_identity_count=27263`
- `xmage_authoritative_source_count=24328`
- `xmage_authoritative_adapter_required_count=24328`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=2935`

The global all-card goal remains active.
