# PG062 Deck 6 L1 Fetchland Cleanup Package

Scope: `Arid Mesa`, `Bloodstained Mire`, `Flooded Strand`, `Marsh Flats`,
`Prismatic Vista`, `Scalding Tarn`, `Windswept Heath`, and
`Wooded Foothills`.

This is a land/mana-base cleanup package. It does not implement a dynamic
fetchland activation executor. The trusted runtime row remains `effect=land`;
the pay-life/sacrifice/search/shuffle oracle clauses are recorded as
`annotation_only`, while the current battle runtime's name-based opening-hand
fetchland color-fixing behavior remains covered by existing tests.

## Files

- Precheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_precheck_20260623_024200.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_apply_20260623_024200.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_postcheck_20260623_024200.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l1_fetchlands_pg062_rollback_20260623_024200.sql`

## Intended Changes

- Add current PostgreSQL `cards.oracle_text` hash to the trusted curated
  executable land row for each target card.
- Add explicit `battle_model_scope`, `oracle_runtime_scope`, family marker,
  `modeled_functions`, and `annotation_only_functions` metadata.
- Disable generated `needs_review`/`review_only` shadows after the trusted row
  is proven present for each target card.
- Preserve the current deck list; no `deck_cards` mutation or deck swap.

## Expected Precheck

- `deck_target_cards=8`
- `target_rule_rows=16`
- `trusted_runtime_rows=8`
- `trusted_missing_hash_rows=8`
- `trusted_without_scope_rows=8`
- `trusted_bad_effect_rows=0`
- `generated_review_only_rows=8`
- `target_bad_type_rows=0`
- `target_faces_json_rows=0`
- `target_missing_fetch_oracle_rows=0`
- `backup_table_exists=0`

## Expected Postcheck

- `target_cards=8`
- `target_rule_rows=16`
- `trusted_runtime_rows=8`
- `trusted_missing_hash_rows=0`
- `trusted_hash_mismatch_rows=0`
- `trusted_missing_scope_rows=0`
- `trusted_bad_effect_rows=0`
- `active_review_only_or_needs_review_rows=0`
- `disabled_generated_shadow_rows=8`
- `target_bad_type_rows=0`
- `target_faces_json_rows=0`
- `backup_rows=16`

## Rollback

Run `deck6_l1_fetchlands_pg062_rollback_20260623_024200.sql` to restore all 16
pre-PG062 `card_battle_rules` rows from
`manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200`.
