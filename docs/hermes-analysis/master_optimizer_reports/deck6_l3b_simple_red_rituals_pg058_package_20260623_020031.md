# PG058 Deck 6 L3B Simple Red Ritual Package

Scope: `Rite of Flame` and `Seething Song` in Deck 6.

PostgreSQL remains the source of truth. Hermes SQLite must be synced from PostgreSQL after apply.

## Oracle review

- `Rite of Flame`: sorcery `{R}`. Oracle adds `{R}{R}`, then `{R}` for each card named Rite of Flame in each graveyard. In Commander singleton Deck 6 the durable runtime baseline is `mana_produced=2`; named-copy graveyard scaling is recorded as `annotation_only` because the current executor does not dynamically count named card copies across all graveyards.
- `Seething Song`: instant `{2}{R}`. Oracle adds `{R}{R}{R}{R}{R}`. Runtime maps this to `mana_produced=5`; color is annotated because the current ritual executor adds to the generic pool.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_precheck_20260623_020031.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_apply_20260623_020031.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_postcheck_20260623_020031.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_rollback_20260623_020031.sql`

## Expected precheck

- `deck_target_cards=2`
- `target_rule_rows=5`
- `target_runtime_rows=2`
- `generated_review_only_rows=2`
- `curated_shadow_rows_to_disable=1`
- `trusted_missing_hash_rows=3`
- `trusted_without_scope_rows=2`
- `target_runtime_rows_without_produces=1`
- `active_card_id_mismatch_same_oracle_rows=0`
- `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`
- `target_names_missing_rules=0`

## Apply behavior

- Backs up all current rule rows for both target names to `manaloom_deploy_audit.pg058_deck6_l3b_simple_red_rituals_20260623_020031`.
- Updates the trusted runtime rows with `oracle_hash`, `produces='R'`, `mana_produced`, `battle_model_scope`, and explicit runtime-abstraction status.
- Disables generated `review_only` shadows and the legacy curated Seething Song shadow row.
- Does not swap decks.

## Rollback

The rollback deletes current rows for the two target normalized names and restores the exact pre-PG058 snapshot from `manaloom_deploy_audit.pg058_deck6_l3b_simple_red_rituals_20260623_020031`.

## Central auditor reconciliation

- When these SQL files surfaced as untracked worktree artifacts after commit
  `955f4d25`, PostgreSQL already matched the post-apply state for both target
  cards. The central auditor did not re-run the apply SQL to avoid duplicating
  the backup-table creation.
- Current-state precheck output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_precheck_20260623_020031.out`.
- Apply output produced before central-auditor reconciliation:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_apply_20260623_020031.out`.
- Postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_postcheck_20260623_020031.out`.
- Scoped SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg058_deck6_l3b_simple_red_rituals_20260623_020031.json`.
- Full SQLite-from-PG refresh after the scoped sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg058_full_refresh_20260623_020814.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3b_simple_red_rituals_pg058_focused_events_20260623_020031.jsonl`.
- Final deck 6 audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_021017.json`
  reports `high=30`, `medium=8`, `pass=62`.
- Final deck 606 audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_021017.json`
  reports `high=38`, `medium=8`, `pass=35`.
