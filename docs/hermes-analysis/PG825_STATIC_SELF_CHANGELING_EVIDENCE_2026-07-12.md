# PG825 Static Self Changeling Evidence - 2026-07-12

Status: applied on new server PostgreSQL and synced to Hermes/SQLite.

## Scope

PG825 promoted the exact XMage-derived `xmage_static_self_changeling_creature_v1`
scope for no-effect/no-signal `ChangelingAbility` creatures with only safe
static self keywords and exact Oracle text.

Cards promoted:

- Avian Changeling
- Changeling Sentinel
- Chitinous Graspling
- Game-Trail Changeling
- Gangly Stompling
- Impostor of the Sixth Pride
- Mischievous Sneakling
- Mistform Ultimus
- Prideful Feastling
- Universal Automaton
- Venomous Changeling
- Woodland Changeling

Runtime behavior added:

- `permanent_has_subtype` treats `changeling`, `all_creature_types`, or
  `universal_creature_subtypes` as matching any requested creature subtype.
- `_card_subtype_matches` delegates to `permanent_has_subtype`, so subtype
  filters and static cost/filter logic can use the same runtime behavior.
- E2E runner `changeling_subtype_identity` proves direct subtype matching,
  positive subtype filters, excluded subtype filters, and self keyword
  preservation.

## Tests

Focused tests:

```text
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k "changeling"
```

Result: `6 passed, 2033 deselected`.

## PG825 Package

Split:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_pg825_static_self_changeling_creature_new_server.json`
- `safe_for_batch_pg_package_count=12`
- `family_counts={"xmage_simple_mana_source_with_unmodeled_auxiliary":2,"xmage_static_self_changeling_creature":12}`

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_package_manifest.json`
- `selected_count=12`

Precheck/apply/postcheck:

- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_precheck.out`
- `target_card_rows=1` for 12/12, `expected_rule_rows_before=0` for 12/12
- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_apply.out`
- `upserted_rows=12`, `deprecated_shadow_rows=0`
- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_postcheck.out`
- `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and
  `promoted_oracle_hash_rows=1` for 12/12

Sync/E2E:

- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=12`, `sqlite_inserted_or_updated=12`
- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_metadata_sync.json`
- `deck_cards matched=2699/2699`
- `docs/hermes-analysis/master_optimizer_reports/pg825_static_self_changeling_creature_new_server_e2e_validation.md`
- E2E status `pass`; PG, SQLite, snapshot, runtime, and 12 battle scenarios passed.

## PG825B Hash Backfill

PG825B cleared trusted executable rules that were verified/auto but still had
empty `oracle_hash`.

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg825b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg825b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg825b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg825b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Results:

- Precheck: `would_backfill_rows=32`, `distinct_cards=31`,
  `unsafe_hash_groups=0`, backup table absent.
- Apply: `backup_rows=32`, `updated_rows=32`.
- Postcheck: `verified_auto_rules_missing_oracle_hash=0`,
  `updated_rows_with_current_oracle_hash=32`.
- Sync: `docs/hermes-analysis/master_optimizer_reports/pg825b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
  with `pg_rows_loaded=10356`, `sqlite_inserted_or_updated=10134`,
  `canonical_snapshot_rows_exported=7734`.

## Final Routing

Post-PG825B readiness:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg825b_hash_backfill_new_server.md`
- `snapshot_has_any_rule=7940`
- `snapshot_has_verified_rule=6786`
- `battle_and_oracle_ready=6679`
- `battle_family_mapper_required=27115`
- `battle_rule_verification_required=70`
- `trusted_rule_oracle_hash_backfill` absent

Post-PG825B queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg825b_hash_backfill_new_server_commander_legal.md`
- `target_identity_count=24204`
- `xmage_authoritative_source_count=23891`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23891`
- `xmage_missing_source_exception_count=313`

Post-PG825B split recheck:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg825b_hash_backfill_new_server_recheck.md`
- `safe_for_batch_pg_package_count=0`
- `proposal_count=2`, both `runtime_partial_requires_family_runtime`

## Audits

- `pg_hermes_sqlite_contract_audit_20260712_post_pg825b_hash_backfill_new_server_final`: pass `51/51`
- `xmage_strategy_consistency_audit_20260712_post_pg825b_hash_backfill_new_server_final`: pass `26/26`
- `operational_surface_alignment_audit_20260712_post_pg825b_hash_backfill_new_server_final`: pass
- `legacy_contamination_audit_20260712_post_pg825b_hash_backfill_new_server_final`: pass
- `./scripts/quality_gate.sh server-target`: pass
