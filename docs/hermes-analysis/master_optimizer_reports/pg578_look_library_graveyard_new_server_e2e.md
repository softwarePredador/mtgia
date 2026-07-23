# PG578 Look Library Graveyard New Server E2E Validation

- Generated at: `2026-07-06T22:58:00Z`
- Apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_apply_evidence.md`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_sync_report.json`

## PostgreSQL To SQLite Sync

Command:

```bash
server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --only-card 'Forbidden Alchemy' --only-card 'Nagging Thoughts' --only-card 'Resentful Revelation' --only-card 'Tapping at the Window' --report docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_sync_report.json
```

Result:

- `database_target=127.0.0.1:15432/halder`;
- `pg_rows_loaded=4`;
- `sqlite_inserted_or_updated=4`;
- `canonical_snapshot_rows_exported=6651`;
- selected cards were exactly the four PG578 cards.

## Tests

Commands and results:

- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: `677` tests passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `348` tests passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py`: passed.

## Queue And Exact-Scope Recheck

- Post-PG578 queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg578_look_library_graveyard_new_server_commander_legal.md`
- Post-PG578 archived queue summary:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg578_look_library_graveyard_new_server_commander_legal.md`
- Post-PG578 exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg578_look_library_graveyard_new_server_recheck.md`
- Post-PG578 exact-scope recheck JSON:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg578_look_library_graveyard_new_server_recheck.json`

Result:

- `target_identity_count` moved from `25343` to `25339`;
- `xmage_authoritative_source_count` moved from `25029` to `25025`;
- top recursion work unit moved from `1799` to `1795`;
- post-apply exact-scope recheck returned `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`.

## Audits

- Global readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg578_look_library_graveyard_new_server.md`
- Global readiness JSON:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg578_look_library_graveyard_new_server.json`
- XMage strategy consistency:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
- XMage strategy consistency JSON:
  `docs/hermes-analysis/deduplicated-report-content/cb3f1e0efbd91f01394f80a98e1c85f2f4dbee8cde287522e635af626bcd2a6f.json`
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260706_post_pg578_look_library_graveyard_new_server_wrapped.md`
- PG/Hermes/SQLite contract JSON:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260706_post_pg578_look_library_graveyard_new_server_wrapped.json`
- Operational alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260706_post_pg578_look_library_graveyard_new_server.md`
- Operational alignment JSON:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260706_post_pg578_look_library_graveyard_new_server.json`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260706_post_pg578_look_library_graveyard_new_server.md`
- Legacy contamination JSON:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260706_post_pg578_look_library_graveyard_new_server.json`

Results:

- XMage strategy consistency: `26/26` pass.
- PG/Hermes/SQLite contract: `51/51` pass when run through
  `server/bin/with_new_server_pg.sh`.
- Operational alignment: pass.
- Legacy contamination: pass.
- `./scripts/quality_gate.sh server-target`: pass.

Residual:

- `global_card_oracle_battle_readiness` remains `action_required` because the
  global all-card adaptation backlog is intentionally still open after this
  four-card package.
