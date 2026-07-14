# Competing Battle Rule Scope Cleanup

Date: 2026-07-14

## Finding

The clean full-suite validation found five card/effect/scope groups with more
than one verified executable logical rule. Three of them changed the selected
runtime or fallback behavior: Chrome Mox, Mox Diamond, and Wear // Tear.

The stale fast-mana rules incorrectly advertised `WUBRGC`; the exact PG255
rules preserve the card-specific additional cost and produce only colored
mana. The older Wear // Tear row targeted only artifacts, while the retained
rule supports artifact or enchantment and fuse metadata.

## Apply Contract

- Apply: `docs/hermes-analysis/master_optimizer_reports/rule_competing_scope_cleanup_20260714_apply.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/rule_competing_scope_cleanup_20260714_rollback.sql`
- Expected stale rows: `9`
- Expected retained exact rows: `9`
- Expected competing verified executable exact-scope groups after apply: `0`

The nine deprecated rows cover Chrome Mox, Mox Diamond, Wear // Tear,
Brainstone, Nature's Claim, Pirate's Pillage, Izzet Signet, Mind Stone, and
Stonespeaker Crystal. No rule is deleted. The apply creates a nine-row backup in
`manaloom_deploy_audit.rule_competing_scope_cleanup_20260714` before changing
status to `deprecated/disabled`.

## Prevention

`pg_hermes_sqlite_contract_audit.py` now fails when PostgreSQL has two distinct
verified executable logical keys for the same `card_id`, effect, and exact
`battle_model_scope`. The SQLite half applies the equivalent check by
`normalized_name`, preventing a stale cache or fallback snapshot from hiding
the same conflict.

## Applied Result

- PostgreSQL apply: `9` rows changed to `deprecated/disabled` after a guarded
  `9/9` stale/replacement precheck.
- Rollback backup: `9` rows in
  `manaloom_deploy_audit.rule_competing_scope_cleanup_20260714`.
- PostgreSQL writes during PG-to-SQLite sync: `0`.
- PG rows loaded: `10,644`; SQLite rows refreshed: `10,419`.
- Canonical fallback rows: `7,907`.
- Canonical fallback SHA-256:
  `f07a416ab420bfcd73ffe8fa8bf5f80d3742a3111a51ea63010bf09053d60486`.
- PG/Hermes/SQLite contract: `55/55` checks passed.
- Focused runtime and contract checks: `11` tests passed.

The selected fallback keys now match the exact retained rows for Chrome Mox,
Mox Diamond, Wear // Tear, Brainstone, Nature's Claim, Pirate's Pillage,
Izzet Signet, Mind Stone, and Stonespeaker Crystal.
