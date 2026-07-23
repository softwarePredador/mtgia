# PG507 XMage ETB Destroy Target Apply Evidence

- Status: `applied_synced_validated`
- Deploy id: `PG507`
- Slug: `xmage_pg507_etb_destroy_target_new_server`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- Scope: all-card Commander-legal XMage authoritative adapter queue, not Lorehold-only
- Deck 607 mutated: `false`
- PostgreSQL target: new server via configured `.credentials.env`

## Cards Promoted

| Card | Battle scope | Effect | Target | Constraints | Controller |
| --- | --- | --- | --- | --- | --- |
| `Angel of Despair` | `xmage_creature_etb_destroy_target_v1` | `remove_permanent` | `permanent` | `{"card_types":["permanent"]}` | `any` |
| `Dark Hatchling` | `xmage_creature_etb_destroy_target_v1` | `remove_creature` | `creature` | `{"card_types":["creature"],"exclude_colors":["B"]}` | default opponent target selection |

## PostgreSQL Evidence

- Precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_precheck.out`
  - target card rows: `2`
  - existing rule rows before apply: `0`
  - expected rule rows before apply: `0`
  - shadow rows to deprecate: `0`
- Apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_apply.out`
  - `upserted_rows=2`
  - `deprecated_shadow_rows=0`
  - transaction committed
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_postcheck.out`
  - `promoted_rule_rows=1` for each card
  - `promoted_verified_auto_rows=1` for each card
  - `promoted_oracle_hash_rows=1` for each card
  - `backup_rows=0`
- Direct PG check: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_pg_direct_postcheck.out`
  - both rows are `source=curated`, `review_status=verified`, `execution_status=auto`

## Sync And Runtime Evidence

- PostgreSQL to SQLite sync: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_pg_to_sqlite_sync.json`
  - `selected_card_count=2`
  - `pg_rows_loaded=2`
  - `sqlite_inserted_or_updated=2`
  - `canonical_snapshot_rows_exported=5984`
- Runtime lookup: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_runtime_get_card_effect.out`
  - `Angel of Despair` resolves as `remove_permanent` with `target_controller=any`
  - `Dark Hatchling` resolves as `remove_creature` with `exclude_colors=["B"]`

## Test Evidence

- Splitter unit tests: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_probe_splitter_tests.out`
  - `Ran 526 tests`
  - `OK`
- Focused battle runtime test: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_focused_battle_tests.out`
  - `focused_battle_test_exit_code=0`
- Full battle suite after sync: `docs/hermes-analysis/master_optimizer_reports/xmage_pg507_etb_destroy_target_new_server_full_battle_suite_post_sync.out`
  - `632` PASS lines
  - no recorded `FAIL`, `ERROR`, `Traceback`, or `AssertionError`

## Post-Apply Global Recheck

- Readiness report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg507_etb_destroy_target_new_server.md`
  - `battle_and_oracle_ready=4917`
  - `battle_family_mapper_required=28956`
- XMage authoritative queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg507_etb_destroy_target_new_server_commander_legal.md`
  - `target_identity_count=26033`
  - `xmage_authoritative_source_count=25719`
  - `xmage_missing_source_exception_count=314`
  - `xmage_authoritative_parser_gap_count=0`
  - `xmage_authoritative_adapter_required_count=25719`
- Final exact-scope recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg507_etb_destroy_target_new_server_final_recheck.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`
  - `etb_destroy_target_not_supported=8`

## Surface Audits

- XMage strategy consistency: `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md` -> `pass`
- Operational surface alignment: `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260705_post_pg507_etb_destroy_target_new_server.md` -> `pass`
- Legacy contamination audit: `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260705_post_pg507_etb_destroy_target_new_server.md` -> `pass`
- PostgreSQL/Hermes/SQLite contract audit: `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg507_etb_destroy_target_new_server.md` -> `pass`
- Deckbuilding contract surface audit: `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_post_pg507_etb_destroy_target_new_server.md` -> `pass`

## Cleanup

- The transient 41 MB queue JSON was removed after generating the stable Markdown summary and final splitter evidence.
- The orphaned `lorehold_artifact_contract_audit_20260705_post_pg505_pg506_deck607_impact.json` result was removed because it belonged to the reverted PG505/PG506 Lorehold contamination path.
- The empty first-attempt focused-test output was removed; the kept focused-test output is `xmage_pg507_etb_destroy_target_new_server_focused_battle_tests.out`.
