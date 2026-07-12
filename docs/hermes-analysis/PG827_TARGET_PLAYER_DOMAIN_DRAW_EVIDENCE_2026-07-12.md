# PG827 Target Player Domain Draw Evidence - 2026-07-12

Status: `applied_synced_e2e_passed`.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

XMage exact subpattern:
`DrawCardTargetEffect(DomainValue.TARGET)`.

Promoted card:

- `Allied Strategies`: target player draws one card for each basic land type
  among lands they control.

Runtime scope:
`xmage_fixed_target_player_draw_spell_v1` with
`draw_count_source=domain_basic_land_types`.

`Huddle Up` stayed blocked because its Oracle/source represent a multi-target
Assist spell, not the same one-target domain draw pattern.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg827_target_player_domain_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg827_target_player_domain_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg827_target_player_domain_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg827_target_player_domain_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg827_target_player_domain_draw_new_server_package_manifest.json`

Precheck result:

- `Allied Strategies`: 1 target card row, 0 existing rule rows.

Apply result:

- `upserted_rows`: 1
- `deprecated_shadow_rows`: 0

Postcheck result:

- `Allied Strategies`: 1 promoted row, verified/auto/hash present.

## Sync And E2E

PG -> SQLite sync:

- `pg_rows_loaded`: 1
- `sqlite_inserted_or_updated`: 1
- `canonical_snapshot_rows_exported`: 7737

Metadata sync:

- PostgreSQL target: `127.0.0.1:15432/halder`
- PostgreSQL cards matched: 8675
- SQLite cache alias rows: 8614

Battle package E2E:

- Status: `pass`
- Scenario count: 1
- `Allied Strategies`: target player `Spell Controller`, drew 4 cards from
  four unique basic land types while duplicate Plains did not increase the
  count.

## Tests And Audits

Focused tests:

```bash
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py
```

Result: `1531 passed`.

Audits:

- `xmage_strategy_consistency_audit_20260712_post_pg827_target_player_domain_draw_new_server_final`: `pass`, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260712_post_pg827_target_player_domain_draw_new_server_final`: `pass`, 51 checks.
- `operational_surface_alignment_audit_20260712_post_pg827_target_player_domain_draw_new_server_final`: `pass`.
- `legacy_contamination_audit_20260712_post_pg827_target_player_domain_draw_new_server_final`: `pass`.
- `./scripts/quality_gate.sh server-target`: `pass`.

## Queue Impact

Readiness after PG827:

- `snapshot_has_any_rule`: 7943
- `snapshot_has_verified_rule`: 6789
- `battle_and_oracle_ready`: 6682
- `battle_family_mapper_required`: 27112
- `battle_rule_verification_required`: 70

XMage authoritative queue after PG827:

- `target_identity_count`: 24201
- `xmage_authoritative_source_count`: 23888
- `xmage_authoritative_adapter_required_count`: 23888
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313
- `manual_semantic_decision_units_remaining`: 313

Exact-scope split recheck:

- `safe_for_batch_pg_package_count`: 0
- Remaining proposals: 2 runtime-partial simple mana-source rows
  (`Codie, Vociferous Codex`, `Strixhaven Stadium`).
