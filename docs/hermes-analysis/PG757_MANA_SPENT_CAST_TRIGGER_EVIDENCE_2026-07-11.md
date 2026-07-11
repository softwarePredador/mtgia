# PG757 Mana-Spent Cast Trigger Evidence - 2026-07-11

Status: `applied_postchecked_sqlite_synced_e2e_passed_audits_passed`

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Scope

Closed the exact XMage -> ManaLoom subpattern
`xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1`.

Promoted cards:

- `Gilanra, Caller of Wirewood`: tap for `{G}`; when that mana is spent to
  cast a spell with mana value 6 or greater, draw 1 card.
- `Lapis Orb of Dragonkind`: tap for `{U}`; when that mana is spent to cast a
  Dragon creature spell, scry 2.
- `Scaled Nurturer`: tap for `{G}`; when that mana is spent to cast a Dragon
  creature spell, gain 2 life.

The related split also left these mana-source variants blocked for later
families because they require separate runtime modeling:

- `Brass Infiniscope`
- `Codie, Vociferous Codex`
- `Coveted Jewel`
- `Jade Orb of Dragonkind`
- `Khalni Gem`
- `Sage of the Maze`
- `Shaman of Forgotten Ways`
- `Strixhaven Stadium`
- `Zaxara, the Exemplary`

## Runtime And Tooling Changes

- `battle_analyst_v9.py` now tracks conditional mana spent during cost payment
  and resolves `mana_spent_cast_trigger` effects after the cast payment commits.
- Supported trigger effects in this batch are `draw_cards`, `scry`, and
  `gain_life`.
- `xmage_authoritative_exact_scope_split.py` recognizes the exact safe Oracle
  subpatterns and keeps adjacent unsupported mana-source variants blocked.
- `xmage_batch_pg_package_builder.py` preserves `mana_spent_cast_trigger` in
  package manifests and creates focused E2E cast-trigger scenarios.
- `battle_package_end_to_end_validation.py` validates that the promoted source
  is tapped, its mana is spent on a qualifying spell, and the delayed trigger
  resolves with the expected draw/scry/life result.

## PostgreSQL Package

Generated SQL files:

- `docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_rollback.sql`

Precheck:

- target card rows: `3`
- existing rule rows: `0`
- expected rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- upserted rows: `3`
- deprecated shadow rows: `0`
- transaction committed.

Postcheck:

| Card | Promoted rule rows | Verified auto rows | Oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Gilanra, Caller of Wirewood` | 1 | 1 | 1 | 0 |
| `Lapis Orb of Dragonkind` | 1 | 1 | 1 | 0 |
| `Scaled Nurturer` | 1 | 1 | 1 | 0 |

## Sync And E2E

SQLite/Hermes sync report:

- `pg_rows_loaded`: `10072`
- `sqlite_inserted_or_updated`: `9850`
- `canonical_snapshot_rows_exported`: `7464`
- target snapshot updates: 3 promoted cards.

E2E result: `pass`

| Card | Focused scenario result |
| --- | --- |
| `Gilanra, Caller of Wirewood` | trigger count `1`, draw count `1` |
| `Lapis Orb of Dragonkind` | trigger count `1`, scry count `2` |
| `Scaled Nurturer` | trigger count `1`, life gain `2` |

## PG757B Trusted Rule Oracle Hash Backfill

The PG/Hermes/SQLite contract audit exposed older trusted executable rows that
still lacked `oracle_hash`. They were not created by PG757, but they blocked
the current cross-store contract. PG757B backfilled those rows from
`cards.oracle_text` with a dedicated rollback table.

Generated SQL files:

- `docs/hermes-analysis/master_optimizer_reports/pg757b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg757b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Precheck:

- trusted executable rules missing `oracle_hash`: `55`
- missing `card_id`: `0`
- unmatched `card_id`: `0`
- matched empty Oracle text: `0`
- safe backfill rows: `55`

Apply:

- backup table:
  `manaloom_deploy_audit.pg757b_trusted_rule_oracle_hash_backfill_20260711`
- backup rows: `55`
- backfilled rows: `55`

Postcheck:

- trusted executable rules still missing `oracle_hash`: `0`
- backfilled rows matching current `cards.oracle_text` hash: `55`

After the PG757B sync, `pg_hermes_sqlite_contract_audit` passed `51/51`
checks.

## Post-PG757 Global Counters

Readiness report after PG757:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg757_mana_spent_cast_trigger_new_server.json`

- `battle_and_oracle_ready`: `6423`
- `snapshot_has_verified_rule`: `6502`
- `battle_family_mapper_required`: `27399`
- `trusted_rule_oracle_hash_backfill`: `54`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`

Readiness report after PG757B:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg757b_hash_backfill_new_server.json`

- `battle_and_oracle_ready`: `6477`
- `snapshot_has_verified_rule`: `6502`
- `battle_family_mapper_required`: `27399`
- `trusted_rule_oracle_hash_backfill`: cleared from active lane counts.
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`

XMage authoritative queue:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg757b_hash_backfill_new_server_commander_legal.json`

- `target_identity_count`: `24476`
- `xmage_authoritative_source_count`: `24163`
- `xmage_authoritative_adapter_required_count`: `24163`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`

## Validation Commands

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py
```

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py -k "mana_spent" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k "mana_spent" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k "mana_spent"
```

```bash
./server/bin/with_new_server_pg.sh python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py \
  --manifest docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_manifest.json \
  --output-json docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_e2e.json \
  --output-md docs/hermes-analysis/master_optimizer_reports/pg757_mana_spent_cast_trigger_new_server_e2e.md
```
