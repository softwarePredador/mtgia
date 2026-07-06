# PG578 Look Library Graveyard New Server Apply Evidence

- Generated at: `2026-07-06T22:58:00Z`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_manifest.json`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_apply.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_postcheck.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_rollback.sql`

## Scope

PG578 promoted four XMage-authoritative `LookLibraryAndPickControllerEffect`
spell rules whose Oracle and XMage source agree on fixed look count, fixed pick
count, hand destination, and graveyard rest destination:

- `Forbidden Alchemy`
- `Nagging Thoughts`
- `Resentful Revelation`
- `Tapping at the Window`

The promoted runtime scope is
`xmage_look_library_pick_to_hand_rest_graveyard_spell_v1`.

## Precheck

Command:

```bash
server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_precheck.sql
```

Result:

- `target_card_rows=1` for all four cards;
- `existing_rule_rows=0` for all four cards;
- `expected_rule_rows_before=0` for all four cards;
- `would_deprecate_shadow_rows=0` for all four cards.

## Apply

Command:

```bash
server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_apply.sql
```

Result:

- backup table: `manaloom_deploy_audit.pg578_look_library_graveyard_new_server_20260706_225325`;
- backup rows: `0`;
- deprecated shadow rows: `0`;
- upserted rows: `4`;
- transaction committed.

## Postcheck

Command:

```bash
server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_postcheck.sql
```

Result:

- `promoted_rule_rows=1` for all four cards;
- `promoted_verified_auto_rows=1` for all four cards;
- `promoted_oracle_hash_rows=1` for all four cards;
- `backup_rows=0`.
