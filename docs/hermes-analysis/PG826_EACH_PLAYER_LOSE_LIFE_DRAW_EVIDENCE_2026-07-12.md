# PG826 Each Player Lose Life + Draw Evidence - 2026-07-12

Status: `applied_synced_e2e_passed`.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

XMage exact subpattern:
`DrawCardSourceControllerEffect + LoseLifeAllPlayersEffect`.

Promoted cards:

- `Crushing Disappointment`: each player loses 2 life, then controller draws 2.
- `Risky Shortcut`: controller draws 2, then each player loses 2 life.

Runtime scope:
`xmage_each_player_lose_life_draw_card_spell_v1`.

Also fixed one existing splitter parsing bug caught by the full focused suite:
source text such as `monocolored creature` and `multicolored creature or
multicolored enchantment` no longer gets misread as `red creature`.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg826_each_player_lose_life_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg826_each_player_lose_life_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg826_each_player_lose_life_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg826_each_player_lose_life_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg826_each_player_lose_life_draw_new_server_package_manifest.json`

Precheck result:

- `Crushing Disappointment`: 1 target card row, 0 existing rule rows.
- `Risky Shortcut`: 1 target card row, 0 existing rule rows.

Apply result:

- `upserted_rows`: 2
- `deprecated_shadow_rows`: 0

Postcheck result:

- `Crushing Disappointment`: 1 promoted row, verified/auto/hash present.
- `Risky Shortcut`: 1 promoted row, verified/auto/hash present.

## Sync And E2E

PG -> SQLite sync:

- `pg_rows_loaded`: 2
- `sqlite_inserted_or_updated`: 2
- `canonical_snapshot_rows_exported`: 7736

Metadata sync:

- PostgreSQL target: `127.0.0.1:15432/halder`
- PostgreSQL cards matched: 8674
- SQLite cache alias rows: 8613

Battle package E2E:

- Status: `pass`
- Scenarios: 2
- `Crushing Disappointment`: drew 2, controller life 18, opponent life 17,
  order `lose_life_then_draw`.
- `Risky Shortcut`: drew 2, controller life 18, opponent life 17,
  order `draw_then_lose_life`.

## Tests And Audits

Focused tests:

```bash
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py
```

Result: `1528 passed`.

Audits:

- `xmage_strategy_consistency_audit_20260712_post_pg826_each_player_lose_life_draw_new_server_final`: `pass`, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260712_post_pg826_each_player_lose_life_draw_new_server_final`: `pass`, 51 checks.
- `operational_surface_alignment_audit_20260712_post_pg826_each_player_lose_life_draw_new_server_final`: `pass`.
- `legacy_contamination_audit_20260712_post_pg826_each_player_lose_life_draw_new_server_final`: `pass`.
- `./scripts/quality_gate.sh server-target`: `pass`.

## Queue Impact

Readiness after PG826:

- `snapshot_has_any_rule`: 7942
- `snapshot_has_verified_rule`: 6788
- `battle_and_oracle_ready`: 6681
- `battle_family_mapper_required`: 27113
- `battle_rule_verification_required`: 70

XMage authoritative queue after PG826:

- `target_identity_count`: 24202
- `xmage_authoritative_source_count`: 23889
- `xmage_authoritative_adapter_required_count`: 23889
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313
- `manual_semantic_decision_units_remaining`: 313

Exact-scope split recheck:

- `safe_for_batch_pg_package_count`: 0
- Remaining proposals: 2 runtime-partial simple mana-source rows
  (`Codie, Vociferous Codex`, `Strixhaven Stadium`).
