# PG662 Counter Draw Special Targets Evidence

- Database target: `127.0.0.1:15432/halder`
- Package: `pg662_counter_draw_special_targets_new_server`
- Cards promoted: `Confound`, `Hindering Light`, `Intervene`, `Keep Safe`, `Laquatus's Disdain`, `Rebuff the Wicked`, `Turn Aside`
- Families: `xmage_counter_target_draw_card_spell=4`, `xmage_counter_target_spell=3`

## Result

- Precheck found `7` target rows, `0` existing expected rows, and `2` stale generated review-only rows to deprecate.
- Apply promoted `7` verified/auto rules and deprecated `2` stale shadows.
- Postcheck confirmed `7/7` promoted rows with matching `oracle_hash`.
- PG -> Hermes/SQLite sync loaded `5969` PostgreSQL rows, updated `5955` SQLite rows, and exported `5932` canonical snapshot rows.
- E2E passed `7` counter-response scenarios. `Confound`, `Hindering Light`, `Keep Safe`, and `Laquatus's Disdain` each drew `1` card on counter.
- Final readiness: `battle_and_oracle_ready=6029`, `snapshot_has_verified_rule=6057`.
- Final queue: `xmage_authoritative_adapter_required_count=24611`, `xmage_authoritative_parser_gap_count=0`, `xmage_missing_source_exception_count=313`.
- Final audits passed: XMage strategy, operational surface, legacy contamination, and PG/Hermes/SQLite contract.

## Evidence

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260708_pg662_counter_draw_special_targets_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260708_post_pg662_counter_draw_special_targets_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260708_post_pg662_counter_draw_special_targets_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260708_post_pg662_counter_draw_special_targets_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260708_post_pg662_counter_draw_special_targets_new_server_final.md`
