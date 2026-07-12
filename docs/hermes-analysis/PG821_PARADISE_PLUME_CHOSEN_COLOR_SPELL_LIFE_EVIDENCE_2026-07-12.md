# PG821 Paradise Plume Chosen Color Spell Life Evidence - 2026-07-12

Status: applied on the new-server PostgreSQL target through
`server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Scope

PG821 promotes the XMage-backed exact adapter for `Paradise Plume`.

- XMage source class: `ParadisePlume`
- XMage behavior:
  - `AsEntersBattlefieldAbility(new ChooseColorEffect(...))`
  - `ParadisePlumeSpellCastTriggeredAbility`
  - `SimpleManaAbility(... new AddManaChosenColorEffect(), new TapSourceCost())`
- ManaLoom mana scope: `xmage_simple_tap_mana_source_permanent_v1`
- Composite trigger component: `xmage_spell_cast_gain_life_v1`
- Trigger rule: whenever a player casts a spell of the chosen color, you may
  gain `1` life.

This is an exact source/runtime adapter. It does not promote a generic review
scope.

## Implementation

- Runtime: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Splitter:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- Package builder:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- Tests:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`

## SQL Package

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_manifest.json`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_package.md`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_rollback.sql`
- Backup table:
  `manaloom_deploy_audit.pg821_paradise_plume_chosen_color_spell_20260712_085838`

## PostgreSQL Apply Evidence

Precheck:

- Card: `Paradise Plume`
- Oracle hash: `a2880170c087ee9a6c80e6b600d90f87`
- Target card rows: `1`
- Existing exact rule rows before apply: `0`
- Shadow rows to deprecate: `0`

Apply:

- Deprecated shadow rows: `0`
- Upserted rows: `1`

Postcheck:

- Promoted rule rows: `1`
- Promoted verified/auto rows: `1`
- Promoted oracle-hash rows: `1`
- Backup rows: `0`

Current verified PostgreSQL row:

- Card: `Paradise Plume`
- Rule: `battle_rule_v1:8e6d57e4b283029ea7dffebfc3f096a5`
- Review/execution: `verified` / `auto`
- Oracle hash: `a2880170c087ee9a6c80e6b600d90f87`
- Battle model scope: `xmage_simple_tap_mana_source_permanent_v1`
- `chosen_color_mana`: `true`
- Composite component count: `1`
- Composite component scope: `xmage_spell_cast_gain_life_v1`
- Composite component `spell_cast_gain_life_required_chosen_color`: `true`
- Composite component `spell_cast_gain_life_amount`: `1`
- Composite component `spell_cast_gain_life_any_player`: `true`

## Sync

Battle-rule sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_pg_to_sqlite_sync.json`
- `canonical_snapshot_rows_exported`: `7698`
- `pg_rows_loaded`: `10320`
- `sqlite_inserted_or_updated`: `10098`

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8636`
- SQLite cache alias rows: `8575`
- `deck_cards` backfill matched: `2699/2699`
- `card_id_updates`: `107`
- unresolved: `1`

## Validation

Focused tests:

- `python3 -m py_compile ...`: `pass`
- `test_xmage_authoritative_exact_scope_split.py -k chosen_color_mana_source_spell_cast_gain_life`: `pass`
- `test_xmage_exact_scope_runtime.py -k composite_chosen_color_spell_cast_gain_life`: `pass`
- `pytest test_xmage_batch_pg_package_builder.py -k chosen_color_mana_source_manifest_creates_spell_cast_life_scenario`: `1 passed`

E2E:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg821_paradise_plume_chosen_color_spell_life_new_server_e2e.md`
- Status: `pass`
- PostgreSQL source of truth: `pass`
- SQLite Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime `get_card_effect`: `pass`
- Battle execution: `pass`
- Scenario: `Paradise Plume gains life when matching spell is cast`
- Battle event: `trigger_spell_controller=Opponent`, `life_after=21`,
  `life_gained=1`

Global readiness:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg821_paradise_plume_chosen_color_spell_life_new_server.md`
- `battle_and_oracle_ready`: `6643`
- `battle_family_mapper_required`: `27151`
- `battle_rule_verification_required`: `70`
- `snapshot_has_verified_rule`: `6750`

Gates:

- `xmage_strategy_consistency_audit_20260712_post_pg821_paradise_plume_chosen_color_spell_life_new_server_final`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260712_post_pg821_paradise_plume_chosen_color_spell_life_new_server_final`: `pass`
- `legacy_contamination_audit_20260712_post_pg821_paradise_plume_chosen_color_spell_life_new_server_final`: `pass`
- `pg_hermes_sqlite_contract_audit_20260712_post_pg821_paradise_plume_chosen_color_spell_life_new_server_final`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`
