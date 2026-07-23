# PG510 XMage ETB Dynamic Count Damage Apply Evidence

- Date: `2026-07-05`
- Deploy id: `xmage_pg510_etb_dynamic_count_damage_new_server`
- Runtime family: `xmage_creature_etb_dynamic_count_damage_target_v1`
- Promoted cards: `8`
- Cards: `Basalt Ravager`, `Explosive Prodigy`, `Firefist Adept`,
  `Gruesome Scourger`, `Kessig Malcontents`, `Outrage Shaman`,
  `Thundering Sparkmage`, `Volley Veteran`

## Scope

PG510 promotes exact creature enters-the-battlefield dynamic damage triggers
whose damage amount is derived from a supported battlefield/count source:

- greatest shared creature type count;
- colors among permanents you control;
- controlled battlefield subtype counts such as Wizard, Human, and Goblin;
- controlled creatures count;
- red mana symbols in mana costs of permanents you control;
- party count.

It does not authorize broad `xmage_*_review_v1` promotion, unrelated direct
damage rows, composite dynamic counts, or source/cost forms still listed as
blocked in the post-PG510 split report.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` now maps the exact ETB dynamic
  count damage source/oracle pairs for the eight promoted cards and rejects
  source/oracle mismatches before package generation.
- `battle_analyst_v9.py` now resolves dynamic damage from supported count
  sources: battlefield permanent count, colors among controlled permanents,
  party count, greatest shared creature type count, and controlled permanent
  mana-symbol count.
- `test_xmage_authoritative_exact_scope_split.py` covers all eight XMage source
  translations.
- `test_xmage_exact_scope_runtime.py` exercises the runtime count sources.

## PostgreSQL Evidence

Package files:

- package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_package.md`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_manifest.json`
- precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_precheck.out`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_apply.out`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_postcheck.out`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_rollback.sql`

Results:

- precheck found one target card row for each promoted card and zero existing
  rule rows for the selected logical keys.
- apply result: `deprecated_shadow_rows=0`, `upserted_rows=8`, `COMMIT`.
- postcheck result: every promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync And Runtime Evidence

- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg510_etb_dynamic_count_damage_new_server.json`
- Sync result: `selected_card_count=8`, `pg_rows_loaded=8`,
  `sqlite_inserted_or_updated=8`, `canonical_snapshot_rows_exported=6005`.
- Runtime lookup:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_new_server_runtime_get_card_effect.out`
- Runtime lookup resolves all 8 cards to
  `xmage_creature_etb_dynamic_count_damage_target_v1` with the expected
  damage amount source and target fields. Registry metadata such as
  `review_status` and `logical_rule_key` is verified through PostgreSQL and
  SQLite direct queries rather than through `get_card_effect`.

## Validation Evidence

- Focused parser test:
  `test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_creature_etb_dynamic_battlefield_count_damage_maps_to_runtime`
  - `OK`
- Focused runtime test:
  `test_xmage_exact_scope_runtime.XMageExactScopeRuntimeTest.test_creature_etb_dynamic_count_damage_supports_runtime_count_sources`
  - `OK`
- Combined unit/sync guard suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg510_etb_dynamic_count_damage_unittest.out`
  - `Ran 845 tests`
  - `OK`
- XMage strategy consistency:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
  - `26/26` pass
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260705_post_pg510_etb_dynamic_count_damage.md`
  - status `pass`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260705_post_pg510_etb_dynamic_count_damage.md`
  - status `pass`
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg510_etb_dynamic_count_damage.md`
  - `51/51` pass

## Queue Impact

Post-PG510 readiness:

- `battle_and_oracle_ready=4938`
- `battle_family_mapper_required=28935`
- `snapshot_has_any_rule=6008`
- `snapshot_has_verified_rule=4760`

Post-PG510 authoritative queue:

- `target_identity_count=26012`
- `xmage_authoritative_source_count=25698`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25698`

Final exact-scope recheck on the rebuilt post-PG510 queue:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `adapter_work_unit_counts={}`

## Decision

PG510 is applied and should not be rebuilt. The ETB dynamic count damage
subpattern promoted here is closed for the eight exact XMage-backed cards.
The next work must start from the rebuilt post-PG510 queue and target a new
exact subpattern from the remaining blocked reasons.
