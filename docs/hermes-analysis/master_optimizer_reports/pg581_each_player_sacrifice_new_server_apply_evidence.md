# PG581 Each Player Sacrifice New Server Apply Evidence

Date: 2026-07-06

Database target: `127.0.0.1:15432/halder` through
`./server/bin/with_new_server_pg.sh`.

## Scope

Family:
`xmage_each_player_sacrifice_fixed_permanents_spell`.

Runtime scope:
`xmage_each_player_sacrifice_fixed_permanents_spell_v1`.

Cards promoted:

- Barter in Blood
- Crack the Earth
- Innocent Blood
- Renounce the Guilds
- Simplify
- Tergrid's Shadow
- Tremble

Explicitly excluded:

- Tectonic Break: blocked by `board_wipe_sacrifice_count_not_fixed` because
  the XMage source uses `GetXValue`.

## PostgreSQL Evidence

Precheck:

- target card rows: `7`
- existing rule rows: `0`
- expected rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- deprecated shadow rows: `0`
- upserted rows: `7`

Postcheck:

- promoted rule rows: `7`
- promoted `verified_auto` rows: `7`
- promoted rows with `oracle_hash`: `7`
- backup rows: `0`

SQL artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg581_each_player_sacrifice_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg581_each_player_sacrifice_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg581_each_player_sacrifice_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg581_each_player_sacrifice_new_server_package_rollback.sql`

## Sync And Runtime Evidence

PG -> SQLite sync:

- selected card count: `7`
- PG rows loaded: `7`
- SQLite rows inserted or updated: `7`
- canonical snapshot rows exported: `6661`

E2E package validation:

- status: `pass`
- scenarios: `7`
- event count: `32`
- stages passed:
  - PostgreSQL source of truth
  - SQLite Hermes cache
  - canonical snapshot fallback
  - runtime `get_card_effect`
  - battle execution

Battle execution covered:

- fixed creature sacrifice count `1` and `2`
- fixed land sacrifice
- fixed enchantment sacrifice
- fixed permanent sacrifice
- multicolored permanent filter
- controller-choice lowest-value sacrifice model

## Queue Delta

Before PG581:

- `target_identity_count=25334`
- `xmage_authoritative_source_count=25020`
- `xmage_authoritative_adapter_required_count=25020`
- board wipe work unit: `407`

After PG581:

- `target_identity_count=25327`
- `xmage_authoritative_source_count=25013`
- `xmage_authoritative_adapter_required_count=25013`
- board wipe work unit: `400`

Post-PG581 exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

Final audits:

- PG/Hermes/SQLite contract: `pass`, `51/51`
- XMage strategy consistency: `pass`, `26/26`
- operational surface alignment: `pass`
- legacy contamination: `pass`
