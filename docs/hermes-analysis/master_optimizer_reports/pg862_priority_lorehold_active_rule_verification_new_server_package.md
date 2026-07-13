# PG862 Priority Active Rule Verification Package

Status: `prepared_for_new_server_apply`.

Scope: promote the four current priority rules that already have exact
`active/auto` runtime coverage and current Oracle hashes:

- `Fellwar Stone`
- `Library of Leng`
- `Scroll Rack`
- `Talisman of Conviction`

Focused runtime proof:

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_priority_lorehold_card_runtime.py`
- Result: `19 passed` via unittest output (`Ran 19 tests ... OK`).

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg862_priority_lorehold_active_rule_verification_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg862_priority_lorehold_active_rule_verification_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg862_priority_lorehold_active_rule_verification_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg862_priority_lorehold_active_rule_verification_new_server_postcheck.sql`

Required sequence: precheck, apply, postcheck, PG -> SQLite sync, priority audit,
global readiness recheck, contract audits.
