# PG399c Backfill All Trusted Oracle Hashes - New Server

Scope: metadata-only backfill for trusted executable PostgreSQL battle rules
with empty `oracle_hash`.

Reason: after PG399b fixed the two SQLite-visible rows, a PostgreSQL source of
truth query still found 40 additional trusted executable rules without
`oracle_hash`. This package backfills all remaining rows matching:

- `source IN ('curated', 'manual')`
- `review_status IN ('verified', 'active')`
- `execution_status IN ('auto', 'executable')`
- empty `oracle_hash`
- non-empty current `cards.oracle_text` joined by `card_id`

Safety:

- Computes `oracle_hash` from the current PostgreSQL `cards.oracle_text`.
- Creates a backup table in `manaloom_deploy_audit` before updating.
- Does not alter `effect_json`, `deck_role_json`, status, card identity, or
  executable behavior.
- Adds a PostgreSQL-side contract audit check so trusted executable rules
  without `oracle_hash` become a hard failure in future runs.
