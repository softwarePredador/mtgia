# PG834A Trusted Rule Oracle Hash Backfill New Server

- Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`
- Scope: trusted or executable `card_battle_rules` rows whose `oracle_hash` is blank while `cards.oracle_text` is present.
- Mutation: set `card_battle_rules.oracle_hash = md5(cards.oracle_text)` and append an audit note.
- Review/execution status preserved: no rule is promoted or enabled by this package.
- Backup table: `manaloom_deploy_audit.pg834a_trusted_rule_oracle_hash_backfill_new_server_20260712`

Files:

- `pg834a_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg834a_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg834a_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg834a_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
