# PG772 Fixed Draw Then Gain Life Evidence - 2026-07-11

Status: `applied_and_validated`.

Database target: `server/bin/with_new_server_pg.sh` -> `127.0.0.1:15432/halder`.

## Runtime/parser change

- Extended `xmage_fixed_controller_gain_life_draw_card_spell_v1` to accept fixed `draw N cards and gain N life` in addition to the previous `gain N life. draw ...` form.
- Preserves composite resolution order with `resolution_order`.
- Keeps dynamic X/count cases blocked.
- Treats neutral auxiliary Oracle lines such as `Affinity for artifacts` as non-resolution text for this exact scope.

## PG772 promoted card

- `Voyage Home`
- XMage source: `DrawCardSourceControllerEffect(3, true)` then `GainLifeEffect(3)`, with `AffinityForArtifactsAbility`.
- Scope: `xmage_fixed_controller_gain_life_draw_card_spell_v1`
- Logical rule key: `battle_rule_v1:920d25f2f6af55d8a9dcea0d87f0d966`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg772_fixed_draw_gain_life_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772_fixed_draw_gain_life_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772_fixed_draw_gain_life_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772_fixed_draw_gain_life_new_server_rollback.sql`

Apply evidence:

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`.
- Apply: `upserted_rows=1`.
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.

E2E evidence:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg772_fixed_draw_gain_life_new_server_e2e.md`
- Status: `pass`
- Battle execution: `Voyage Home` drew `3`, life changed from `10` to `13`, `resolution_order=draw_then_gain`.
- PostgreSQL, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, and focused battle execution all passed.

## PG772B hash backfill

Purpose: clear the post-PG772 `trusted_rule_oracle_hash_backfill` lane for trusted executable rules.

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg772b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg772b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Apply evidence:

- Precheck: `trusted_executable_rules_missing_oracle_hash=55`, `matched_card_rows=55`, `proposed_hash_rows=55`.
- Apply: `backfilled_rows=55`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`.

## Final counters

Readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg772b_hash_backfill_new_server.md`
- `battle_and_oracle_ready=6508`
- `battle_family_mapper_required=27368`
- `snapshot_has_any_rule=7700`
- `snapshot_has_verified_rule=6533`
- `trusted_rule_oracle_hash_backfill` absent from final lane counts

XMage authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg772b_hash_backfill_new_server.md`
- `target_identity_count=24445`
- `xmage_authoritative_source_count=24132`
- `xmage_authoritative_adapter_required_count=24132`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact split after PG772B:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg772b_hash_backfill_new_server.md`
- `safe_for_batch_pg_package_count=0`
- Remaining selected proposals are `3` runtime-partial simple mana-source rows, not PG-safe package candidates.

Audits:

- XMage strategy consistency: `pass`, `26/26`.
- PG/Hermes/SQLite contract: `pass`, `51/51`.
- Operational surface alignment: `pass`.
- Legacy contamination audit: `pass`.

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k life_gain_draw`
- Result: `3` tests passed.
