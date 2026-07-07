# PG582 Exile Restricted Targets New Server Apply Evidence

- PostgreSQL wrapper: `./server/bin/with_new_server_pg.sh`
- PostgreSQL target: `127.0.0.1:15432/halder`
- Deploy ID: `PG582`
- Package: `pg582_exile_restricted_targets_new_server`
- Family: `xmage_exile_target_spell`
- Scope: `xmage_exile_target_spell_v1`

## Promoted Cards

- `Complete Disregard`
- `Exorcise`
- `Glare of Heresy`
- `Gravkill`
- `Grotesque Demise`
- `Oblivion Strike`
- `Pillar of Light`
- `Radiant Purge`
- `Reaver Ambush`

## PostgreSQL Package Evidence

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_rollback.sql`

Observed results:

- precheck found `9` target card rows, `0` existing target rule rows, `0`
  expected rule rows before apply, and `0` shadow rows to deprecate;
- apply reported `upserted_rows=9` and `deprecated_shadow_rows=0`;
- postcheck confirmed `9` promoted rows, `9` `verified_auto` rows, and `9`
  promoted rows carrying `oracle_hash`.

## Sync And E2E

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_sync_report.json`
- E2E JSON:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_e2e.json`
- E2E Markdown:
  `docs/hermes-analysis/master_optimizer_reports/pg582_exile_restricted_targets_new_server_e2e.md`

Observed results:

- PG -> SQLite sync loaded `9` PostgreSQL rows, updated `9` SQLite rows, and
  exported `6670` canonical snapshot rows;
- E2E status: `pass`;
- E2E validated `9` PostgreSQL rows, `9` SQLite rows, `9` canonical snapshot
  rows, `9` runtime `get_card_effect` rows, and `9` battle scenarios;
- battle execution generated `18` events: each promoted card exiled the legal
  target and left the illegal fixture target on the battlefield.

## Follow-Up Integrity Backfill

The first final PG/Hermes/SQLite audit failed because `44` older trusted
executable PostgreSQL rules still lacked `oracle_hash`. PG582 did not create
those rows, but this cycle closed the drift so the final contract audit is
clean.

- Backfill precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg582_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Backfill apply:
  `docs/hermes-analysis/master_optimizer_reports/pg582_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Backfill postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg582_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Backfill rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg582_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Observed results:

- precheck found `44` resolvable trusted executable rows missing `oracle_hash`;
- apply backed up and updated `44` rows;
- postcheck reported `trusted_executable_rules_missing_oracle_hash=0`;
- final PG/Hermes/SQLite audit passed `51/51`.
