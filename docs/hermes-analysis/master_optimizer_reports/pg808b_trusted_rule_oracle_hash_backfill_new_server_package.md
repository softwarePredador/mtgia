# PG808B Trusted Rule Oracle Hash Backfill

- Deploy id: `pg808b`
- Slug: `trusted_rule_oracle_hash_backfill_new_server`
- Scope: metadata-only backfill for trusted executable `card_battle_rules`
  rows where `oracle_hash` is blank but `cards.oracle_text` is present.
- Source of hash: `md5(cards.oracle_text)`.
- Target rows: `source IN ('curated', 'manual')`,
  `review_status IN ('verified', 'active')`,
  `execution_status IN ('auto', 'executable')`,
  blank `oracle_hash`, non-empty Oracle text.
- Expected effect: remove the transient `trusted_rule_oracle_hash_backfill`
  readiness lane before continuing the next XMage adapter batch.

Files:

- `pg808b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg808b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg808b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- `pg808b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
