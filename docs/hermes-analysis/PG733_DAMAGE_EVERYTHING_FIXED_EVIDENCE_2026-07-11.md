# PG733 damage everything fixed evidence - 2026-07-11

Status: applied on new server PostgreSQL through `server/bin/with_new_server_pg.sh`.

## Scope

Implemented and promoted the exact XMage -> ManaLoom family:

- `xmage_fixed_damage_each_creature_each_player_spell_v1`
- XMage signal: `DamageEverythingEffect(N)` on a simple one-shot spell
- Supported Oracle form: `<name> deals N damage to each creature and each player.`
- Supported values: fixed integer damage only
- Explicitly blocked for this wave: X damage, filtered creature scopes, additional costs, cycling/madness/kicker variants, activated/triggered variants, and multi-effect composite damage

Promoted cards:

- Dakmor Plague
- Dry Spell
- Famine
- Fire Tempest
- Inferno
- Rain of Embers
- Steam Blast

Examples intentionally still blocked by this exact-scope split:

- Delete
- Hurricane
- Sickening Dreams
- Squall Line

## Runtime and tests

Runtime changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - extended `damage_wipe` to support `damage_players`
  - deals fixed damage to each creature and each player through the existing replacement-aware player damage path
  - emits `damage_players`, `players_damaged`, and `damaged_players` in `damage_wipe_resolved`

Package/test tooling changed:

- `xmage_authoritative_exact_scope_split.py`
- `xmage_batch_pg_package_builder.py`
- `battle_package_end_to_end_validation.py`
- focused tests for splitter, package builder, runtime, and battle E2E runner

Focused test results:

```text
python3 -m py_compile ...                                             PASS
python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k damage_everything
  Ran 2 tests: OK
python3 -m unittest test_xmage_exact_scope_runtime.py -k damage_wipe_can_damage_each_creature_and_each_player
  Ran 1 test: OK
python3 -m pytest -q test_xmage_batch_pg_package_builder.py -k damage_wipe
  1 passed, 172 deselected
python3 -m pytest -q test_battle_package_end_to_end_validation.py -k damage_wipe
  1 passed, 94 deselected
```

## PostgreSQL package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_package_package.md`

Precheck:

- target card rows: 7
- expected rule rows before apply: 0 for all 7
- existing shadow rows deprecated: 2, both on `Inferno`

Apply/postcheck:

- deprecated shadow rows: 2
- upserted rows: 7
- promoted verified auto rows: 7
- promoted oracle hash rows: 7

## Sync and E2E

Sync artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_sync_report.json`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_battle_rule_sync_report.json`

Canonical snapshot fallback:

- exported rows: 6,267 trusted runtime fallback entries
- stale `needs_review`/`review_only` fallback entries from the previous snapshot are not retained by this PG -> SQLite export path

E2E artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_e2e.json`
- `docs/hermes-analysis/master_optimizer_reports/pg733_damage_everything_fixed_new_server_e2e.md`

E2E status: `pass`

Validated stages:

- PostgreSQL source of truth: 7 rows
- SQLite/Hermes cache: 7 rows
- canonical snapshot fallback: 7 cards
- runtime `get_card_effect`: 7 cards
- battle execution: 7 scenarios, 28 events

Each promoted card destroyed both test creatures and dealt fixed damage to both players through the `damage_wipe` execution runner.

## Final audits

Passed:

- `xmage_strategy_consistency_audit_20260711_post_pg733_damage_everything_fixed_new_server`
- `operational_surface_alignment_audit_20260711_post_pg733_damage_everything_fixed_new_server`
- `legacy_contamination_audit_20260711_post_pg733_damage_everything_fixed_new_server`
- `pg_hermes_sqlite_contract_audit_20260711_post_pg733_damage_everything_fixed_new_server`
- `./scripts/quality_gate.sh server-target`

Post-PG733 readiness:

- total cards: 34,331
- `battle_and_oracle_ready`: 6,365
- snapshot cards with verified battle rule: 6,390
- battle family mapper required: 27,511

Commander-legal XMage queue after PG733:

- target identities: 24,588
- XMage authoritative adapter required: 24,275
- parser gaps: 0
- missing-source exceptions: 313

Post-PG733 exact-scope recheck:

- proposal count: 0 for the currently supported exact split set
- safe batch PG package count: 0

The global goal remains active; PG733 closed this exact fixed `DamageEverythingEffect(N)` subfamily and reduced the Commander-legal XMage adapter queue by 7 identities.
