# PG114 Emeria's Call Token-Maker PostgreSQL Package

Status: `applied_validated_runtime_synced`.

Scope:

- Target table: `public.card_battle_rules`.
- Target card: `Emeria's Call // Emeria, Shattered Skyclave`.
- Expected PostgreSQL card match: exactly `1` row by normalized name and `oracle_hash=2fab1a2b9eb87041bc9e93f3b8d52831`.
- Durable rule key: `battle_rule_v1:ae4a933d873bec332ec2a46106b79277`.
- Runtime family: `token_maker`.

Runtime/test evidence before apply:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg114_emerias_call_token_maker_precheck_20260623_200501.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg114_emerias_call_token_maker_apply_20260623_200501.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg114_emerias_call_token_maker_rollback_20260623_200501.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg114_emerias_call_token_maker_postcheck_20260623_200501.sql`

Applied sequence:

- Precheck confirmed `card_rows=1`, `existing_rule_rows=0`, and
  `shadow_rows=0`.
- Apply inserted/updated `1` PostgreSQL `card_battle_rules` row and committed.
- Postcheck confirmed `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, and `active_shadow_rows=0`.
- PostgreSQL -> Hermes sync, focused tests, full battle analyst suite, and
  deck/global coherence audits passed for this checkpoint.
- Rollback remains available through the backup table
  `manaloom_deploy_audit.pg114_emerias_call_token_maker_20260623_200501`.
