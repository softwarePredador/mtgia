# PG766 Zaxara X Spell Hydra Counter Evidence - 2026-07-11

Status: `applied_new_server_verified`.

Scope:

- Card: `Zaxara, the Exemplary`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/z/ZaxaraTheExemplary.java`
- ManaLoom scope: `xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1`
- Logical rule key: `battle_rule_v1:58a25a96c5e3a7c34298ed75986ed05a`
- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

XMage behavior modeled:

- `Deathtouch`
- `{T}: Add two mana of any one color.`
- Whenever the controller casts a spell with `{X}` in its mana cost, create a
  `0/0 green Hydra creature token`, then put `X` `+1/+1` counters on it.

Runtime and mapper changes:

- Added exact split scope for simple tap mana source plus spell-cast X-token
  counter trigger.
- Extended spell-cast token runtime to require `{X}` mana cost when configured.
- Passed trigger spell `x_value` into token creation.
- Added token entering counter application and event evidence.
- Extended package E2E manifest/runner to validate token counters.

Focused validation:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py

PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_mana_source_x_spell_token_counter_trigger_maps_zaxara \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_mana_source_x_spell_token_counter_scenario_uses_x_spell_and_counters \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_spell_cast_token_maker_runner_applies_x_value_token_counters
```

Result: `3 passed`.

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_e2e.json`
- `docs/hermes-analysis/master_optimizer_reports/pg766_zaxara_new_server_e2e.md`

PostgreSQL apply evidence:

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`.
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`.
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`, `backup_rows=0`.

Direct PostgreSQL validation:

```text
Zaxara, the Exemplary|zaxara, the exemplary|battle_rule_v1:58a25a96c5e3a7c34298ed75986ed05a|verified|auto|2|bdb261d7904dbecf9ddaa6ddb01f9b40|xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1|true|x_value
```

SQLite/Hermes sync:

- `pg_rows_loaded=10089`
- `sqlite_inserted_or_updated=9867`
- `canonical_snapshot_rows_exported=7481`

E2E result:

- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical
  snapshot fallback, runtime get-card-effect, battle execution.
- Battle execution: one spell-cast trigger created one `Hydra Token` with
  `token_plus_one_counters=[2]` from `x_value=2`.

Post-apply audits:

- XMage strategy consistency: `pass`, `26/26`.
- PostgreSQL/Hermes/SQLite contract audit: `pass`, `51/51`.
- Operational surface alignment: `pass`.
- Legacy contamination audit: `pass`.
- Global readiness remains `action_required` because the global backlog is not
  complete.

Post-PG766 backlog deltas:

- `battle_and_oracle_ready`: `6494`
- `battle_family_mapper_required`: `27382`
- `snapshot_has_verified_rule`: `6519`
- XMage authoritative adapter required: `24146`
- XMage parser gaps: `0`
- Missing source exceptions: `313`
- `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: `239`
