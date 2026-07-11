# PG787 Creature Enters Tapped Evidence - 2026-07-11

Status: `applied_new_server_verified`

Scope:

- `xmage_creature_enters_tapped_v1`
- Exact Oracle: `This creature enters tapped.`
- XMage source signatures:
  - `EntersBattlefieldTappedAbility`
  - `EntersBattlefieldAbility(new TapSourceEffect())`

Cards promoted:

- Crooked Custodian
- Diregraf Ghoul
- Forgotten Sentinel
- Rotting Legion
- Rusted Sentinel
- Scarwood Treefolk
- Shambling Ghoul
- Unhallowed Phalanx
- Wolf Cove Villager

PostgreSQL package:

- Precheck: 9 target rows, 0 existing matching rules, 0 shadow rows to deprecate.
- Apply: 9 rows upserted into `public.card_battle_rules`.
- Postcheck: 9/9 promoted rows are `review_status=verified`, `execution_status=auto`, with matching `oracle_hash`.
- Database target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.

Sync and E2E:

- `sync_battle_card_rules_pg.py`: 9 PG rows loaded, 9 SQLite rows inserted/updated, canonical snapshot exported with 6458 rows.
- `sync_pg_card_metadata_to_hermes.py`: PostgreSQL target confirmed on new server; Hermes cache updated.
- `battle_package_end_to_end_validation.py`: status `pass`; PostgreSQL, SQLite, canonical snapshot, runtime lookup, and 9 battle execution scenarios passed.
- Battle execution validated that each promoted creature enters the battlefield with `actual_tapped=true`.

Global delta:

- `battle_and_oracle_ready`: 6547 -> 6556.
- `battle_family_mapper_required`: 27329 -> 27320.
- `snapshot_has_verified_rule`: 6572 -> 6581.

Governance gates:

- `xmage_strategy_consistency_audit`: pass, 26/26.
- `operational_surface_alignment_audit`: pass.
- `pg_hermes_sqlite_contract_audit`: pass, 51/51.
- `legacy_contamination_audit`: pass.
- `scripts/quality_gate.sh server-target`: pass.

Local evidence files:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg787_creature_enters_tapped_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg787_creature_enters_tapped_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg787_creature_enters_tapped_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg787_creature_enters_tapped_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg787_creature_enters_tapped_new_server.json`
