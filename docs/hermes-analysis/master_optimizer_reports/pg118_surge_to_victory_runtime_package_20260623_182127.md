# PG118 Surge to Victory Runtime

Prepared at: `2026-06-23 18:21:27 -03`

Scope:

- Promote `Surge to Victory` as an Oracle/XMage-backed executable combat-finisher rule.
- Deprecate the two legacy active rows that currently keep the deck 607 audit in
  `high` because one is `needs_review/review_only` and the other is trusted but
  lacks `oracle_hash`.
- Keep PostgreSQL as source of truth, then sync the promoted row into Hermes
  SQLite.

Audit backup table:

- `manaloom_deploy_audit.pg118_surge_to_victory_runtime_20260623_182127`

Target rule:

- `card_name=Surge to Victory`
- `logical_rule_key=battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e`
- `oracle_hash=5381f78ff0798b9afad371e0fa495831`
- `effect=pump_all`
- `battle_model_scope=graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1`

Legacy rows to disable:

- `battle_rule_v1:4ea05a4d2ce8454073d85afff5e3f790`
- `battle_rule_v1:cc95729e96832afbdb1eb194ec6212d4`

Runtime contract:

- On resolution, the spell exiles the best instant or sorcery from your
  graveyard.
- Your creatures get `+X/+0` until end of turn, where `X` is that card's mana
  value.
- Each time one of your creatures deals combat damage to a player that turn,
  the exiled spell is copied and cast without paying its mana cost.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg118_surge_to_victory_runtime_precheck_20260623_182127.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg118_surge_to_victory_runtime_apply_20260623_182127.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg118_surge_to_victory_runtime_postcheck_20260623_182127.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg118_surge_to_victory_runtime_rollback_20260623_182127.sql`

Execution order:

1. Run precheck and confirm exactly one Oracle-hash-matched `cards` row.
2. Apply the package and confirm one new promoted row plus two deprecated legacy
   rows.
3. Run postcheck and confirm the promoted row is `verified/auto` with the
   expected scope and hash.
4. Sync `Surge to Victory` from PostgreSQL to Hermes SQLite.
5. Rerun the deck 607 coherence audit and confirm `Surge to Victory` leaves the
   `high` queue.
