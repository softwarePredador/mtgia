# PG399b Backfill Oracle Hashes - New Server

Scope: metadata-only backfill for two pre-existing trusted executable
PostgreSQL battle rules that lacked `oracle_hash`.

Cards:

- `Angel's Grace`
- `Seething Song`

Reason: `pg_hermes_sqlite_contract_audit` after PG399 still passed with one
residual warning: `trusted_executable_rules_missing_oracle_hash=2`. The warning
was already present after PG398, but PostgreSQL is the source of truth, so this
package updates PostgreSQL first and lets the normal PostgreSQL -> SQLite sync
refresh Hermes.

Safety:

- Updates only `source='curated'`, `review_status='verified'`,
  `execution_status='auto'` rows with an empty `oracle_hash`.
- Computes the hash from current `cards.oracle_text` by `card_id`.
- Creates a backup table in `manaloom_deploy_audit` before updating.
- Does not alter `effect_json`, `deck_role_json`, status, card identity, or
  executable behavior.
