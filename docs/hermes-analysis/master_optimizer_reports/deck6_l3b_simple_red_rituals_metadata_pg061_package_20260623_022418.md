# PG061 Deck 6 L3B Simple Red Ritual Metadata Confirmation

Scope: `Rite of Flame` and `Seething Song`.

PG060's apply attempt aborted before a durable backup table existed. By the
time the state was rechecked, PostgreSQL already held the intended Seething Song
metadata. PG061 therefore captures a current-state backup and reapplies the same
metadata idempotently so the state is auditable and has a rollback.

No executor, deck list, or shadow row state is changed.

## Files

- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_apply_20260623_022418.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_postcheck_20260623_022418.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_metadata_pg061_rollback_20260623_022418.sql`

## Rollback

Rollback restores all five current-state `card_battle_rules` rows for
`Rite of Flame` and `Seething Song` from
`manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418`.
