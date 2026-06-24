# XMage PG166-PG183 Apply Summary

Approval gate: Rafael approved this lane in chat with `sincronize, suba pg se
for preciso, commite, faca tudo`.

PostgreSQL remains the source of truth. Hermes SQLite was refreshed only as
runtime cache evidence.

## PostgreSQL

- PG166-PG181 applied `15` prepared packages.
- PG166-PG181 upserted `54` battle rule rows.
- PG166-PG181 deprecated `80` stale shadow rows.
- PG182 restored `oracle_hash` provenance for the active verified/auto
  `Seething Song` rule: `updated_rows=1`, postcheck `matching_oracle_hash_rows=1`.
- PG183 restored `oracle_hash` provenance for the active verified/auto
  `Angel's Grace` rule: `updated_rows=1`, postcheck
  `matching_oracle_hash_rows=1`.

## Hermes Sync

- PG166-PG181 sync: `pg_rows_loaded=5500`,
  `sqlite_inserted_or_updated=5356`, `canonical_snapshot_rows_exported=3243`.
- PG182 sync: `pg_rows_loaded=5500`,
  `sqlite_inserted_or_updated=5328`, `canonical_snapshot_rows_exported=3243`.
- PG183 sync: `pg_rows_loaded=5500`,
  `sqlite_inserted_or_updated=5328`, `canonical_snapshot_rows_exported=3243`.

## Queue

After PG166-PG181 and sync, the package lane for the current scope is closed:

- `package_already_prepared=0`
- `package_ready_unprepared=0`
- `split_scope_backlog=68`
- `runtime_family_backlog=24`
- `manual_mapper_backlog=352`
- `blocked_missing_xmage_source=2`

PG182 and PG183 were provenance repair packages found by the runtime/audit
tests, not new queue-family promotions.

## Validation

- Strategy consistency audit:
  `xmage_strategy_consistency_audit_20260624_pg166_183_postsync_real_v1_default.json`
  passed `17/17`.
- Battle strategy audit run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_154831`.
- Battle audit command exit code: `0`.
- Seeds completed: `16/16`.
- Internal test results: `18` total, `18` pass.
- Final battle replay status remains `blocked` because mandatory gates still
  report:
  `decision_trace_taxonomy=review_required`,
  `event_contract_static=review_required`,
  `forensic_audit=blocked`,
  `replay_decision_audit=review_required`, and
  `strategy_audit=review_required`.
