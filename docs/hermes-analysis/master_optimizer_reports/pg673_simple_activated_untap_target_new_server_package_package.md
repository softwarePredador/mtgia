# PG673 XMage Batch PostgreSQL Package

Status: `applied_validated_synced`.

This package was generated from XMage batch proposals. SQL was applied after
precheck on the new PostgreSQL target and validated by postcheck, sync, E2E,
and alignment audits.

- Generated at: `2026-07-08T21:27:12+00:00`
- Selected cards: `["Arbor Elf", "Argothian Elder", "Blossom Dryad", "Filigree Sages", "Fyndhorn Brownie", "Greenside Watcher", "Jandor's Saddlebags", "Juniper Order Druid", "Kiora's Follower", "Ley Druid", "Magewright's Stone", "Rime Tender", "Sculptor of Winter", "Seeker of Skybreak", "Voltaic Construct", "Voyaging Satyr"]`
- Families: `{"xmage_permanent_simple_activated_untap_target": 16}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg673_simple_activated_untap_target_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg673_simple_activated_untap_target_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg673_simple_activated_untap_target_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg673_simple_activated_untap_target_new_server_package_postcheck.sql`
- package: `docs/hermes-analysis/master_optimizer_reports/pg673_simple_activated_untap_target_new_server_package_package.md`

Apply gate:

- Applied via `server/bin/with_new_server_pg.sh` against `127.0.0.1:15432/halder`.
- Precheck: `16/16` target rows found, `0` expected rows already present, `0`
  shadow rows to deprecate.
- Apply/postcheck: `16` rows upserted; `16/16` promoted rows verified/auto with
  matching Oracle hash.
- E2E: `pass`, including PostgreSQL, SQLite, canonical snapshot,
  `get_card_effect`, and `16` activated untap execution scenarios.
