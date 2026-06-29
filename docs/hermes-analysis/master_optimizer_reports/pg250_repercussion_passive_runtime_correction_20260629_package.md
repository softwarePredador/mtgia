# PG250 Repercussion Passive Runtime Correction

Status: `applied_postchecked_synced`.

Purpose:

- Correct the PG249 `Repercussion` row after focused runtime validation showed
  the card must be modeled as a passive global enchantment trigger, not an
  immediate `direct_damage` spell.
- Preserve the PG249 backup lineage by using a separate PG250 backup table and
  rollback script.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_rollback.sql`

Expected result:

- `deprecated_rows=1` for the PG249 immediate `direct_damage` row.
- `upserted_rows=1` for
  `battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017`.
- Postcheck must show `promoted_passive_rows=1` and
  `active_nonmatching_rows=0`.

Apply evidence:

- precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_145507_precheck.out`
- apply output:
  `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_145507_apply.out`
- postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg250_repercussion_passive_runtime_correction_20260629_145507_postcheck.out`
- Apply result: `deprecated_rows=1`, `upserted_rows=1`.
- Postcheck result: `promoted_passive_rows=1`,
  `active_nonmatching_rows=0`.

SQLite/Hermes sync evidence:

- sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg250_repercussion_passive_runtime_correction_20260629_145521.json`
- Sync result: `pg_rows_loaded=2`, `sqlite_inserted_or_updated=2`.
- Final runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg249_pg250_runtime_ready_exact_family_batch_20260629_145521_get_card_effect_probe.json`
