# PG116 Big Score + Tempt with Bunnies Shadow Cleanup

Prepared at: `2026-06-23 17:51:18 -03`

Scope:

- Preserve the already promoted executable rows for `Big Score` and
  `Tempt with Bunnies`.
- Deprecate only the stale `needs_review` shadow rows that still surface these
  cards as high-priority in the deck 607 coherence audit.
- Sync the cleaned rule set back into Hermes SQLite after apply/postcheck.

Audit backup table:

- `manaloom_deploy_audit.pg116_big_score_tempt_bunnies_shadow_cleanup_20260623_175118`

Promoted rows that must remain active:

- `Big Score`
  - `battle_rule_v1:af9f14d18cc283719be2ef2680b6f1ed`
  - `oracle_hash=9c4fbe06104051a2e8b1d295d307b26a`
- `Tempt with Bunnies`
  - `battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86`
  - `battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80`
  - `oracle_hash=201f6c7234bfef550f3d497e736f0d7a`

Shadow rows to deprecate:

- `Big Score`
  - `battle_rule_v1:1c91b96cef3218cfe2eaed9484a5661b`
  - `battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca`
- `Tempt with Bunnies`
  - `battle_rule_v1:030b2f3e0f549a462c3c8ea429877980`

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg116_big_score_tempt_bunnies_shadow_cleanup_precheck_20260623_175118.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg116_big_score_tempt_bunnies_shadow_cleanup_apply_20260623_175118.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg116_big_score_tempt_bunnies_shadow_cleanup_postcheck_20260623_175118.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg116_big_score_tempt_bunnies_shadow_cleanup_rollback_20260623_175118.sql`

Execution order:

1. Confirm exactly one Oracle-hash-matched `cards` row for each card.
2. Confirm the promoted executable rows already exist before any mutation.
3. Deprecate only the listed shadow keys.
4. Sync `Big Score` and `Tempt with Bunnies` from PostgreSQL to Hermes SQLite.
5. Rerun the deck 607 coherence audit and confirm both cards leave the high queue.
