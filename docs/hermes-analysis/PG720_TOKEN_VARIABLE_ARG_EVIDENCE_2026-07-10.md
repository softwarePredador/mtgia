# PG720 Token Variable Argument Evidence - 2026-07-10

Status: `applied_synced_validated`

Current PostgreSQL target: `server/bin/with_new_server_pg.sh`

## Scope

PG720 adds exact XMage parser support for `CreateTokenEffect(tokenVariable)` when the variable resolves to exactly one `new XToken(...)` class in the local XMage source.

The parser remains conservative:

- direct `new XToken(...)` arguments keep the existing path;
- a variable argument is accepted only when it has a single token class assignment;
- ambiguous variable assignments remain blocked as `token_source_create_token_not_fixed`.

Promoted cards:

- `Ant Queen`
- `Broodmate Dragon`
- `Roc Egg`
- `Sprouting Thrinax`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_rollback.sql`

Precheck:

- `target_card_rows=1` for each promoted card
- `existing_rule_rows=0`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=0`

Apply/postcheck:

- `deprecated_shadow_rows=0`
- `upserted_rows=4`
- all four promoted rows have `promoted_rule_rows=1`
- all four promoted rows have `promoted_verified_auto_rows=1`
- all four promoted rows have `promoted_oracle_hash_rows=1`

Promoted rules:

- `Ant Queen`: `battle_rule_v1:6c6a795001e21e4f389c32adde4533d0`
- `Broodmate Dragon`: `battle_rule_v1:4063c079795837e8b94c581cf24ee0a8`
- `Roc Egg`: `battle_rule_v1:5385b7d23648efeaf502bff68b2a7f0b`
- `Sprouting Thrinax`: `battle_rule_v1:302fae4cf3a57e7203c835da45e5b69c`

## Sync

`docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_pg_to_sqlite_sync.json`

- `pg_rows_loaded=6245`
- `sqlite_inserted_or_updated=6240`
- `canonical_snapshot_rows_exported=6196`

`docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_metadata_sync.json`

- requested unique names: `7156`
- PostgreSQL cards matched: `7339`
- SQLite cache alias rows: `7258`
- `deck_cards` matched: `2699/2699`

## E2E

`docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_e2e_validation.md`

- Status: `pass`
- PostgreSQL source rows validated: `4`
- SQLite cache rows validated: `4`
- Canonical snapshot cards validated: `4`
- Runtime `get_card_effect` cards validated: `4`
- Battle execution scenarios: `4`

Runtime behavior validated:

- `Ant Queen` activates token ability and creates one `Insect Token`.
- `Broodmate Dragon` enters and creates one `Dragon Token` with `flying`.
- `Roc Egg` dies and creates one `Bird Token`.
- `Sprouting Thrinax` dies and creates three `Saproling Token` permanents.

## Final Audits

Post-PG720 reports:

- PG/Hermes/SQLite contract: `pass`, `51/51`
- XMage strategy consistency: `pass`, `26/26`
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- Server target quality gate: `pass`

Tests:

- `python3 -m py_compile xmage_authoritative_exact_scope_split.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `949` tests passed
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`: `240` tests passed

## Queue Delta

Post-PG720 readiness:

- `battle_and_oracle_ready=6294`
- `snapshot_has_verified_rule=6319`
- `battle_family_mapper_required=27582`

Post-PG720 authoritative queue:

- `target_identity_count=24659`
- `xmage_authoritative_adapter_required_count=24346`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7094`

Conclusion: PG720 is closed. The global objective remains active because the remaining work is still `24346` XMage-backed adapter translations plus `313` source-missing/manual exceptions.
