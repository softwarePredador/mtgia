# PG846 ETB Context Draw Evidence - 2026-07-12

Status: `applied_and_validated`

## Scope

PG846 promotes the XMage `EntersBattlefieldTriggeredAbility + DrawCardSourceControllerEffect`
subpattern for conditional ETB draw creatures.

Cards promoted:

- `Clockwork Servant` - adamant: at least three same-color mana spent to cast it.
- `Orator of Ojutai` - revealed or controlled Dragon as it was cast.
- `Silkweaver Elite` - revolt: permanent left battlefield under your control this turn.
- `Skyship Buccaneer` - raid: controller attacked this turn.
- `Storm Fleet Spy` - raid: controller attacked this turn.

Runtime/model scope: `xmage_creature_etb_draw_cards_v1`.

## PostgreSQL

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_rollback.sql`

New server target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

Precheck result:

- target card rows: `5`
- existing matching rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply result:

- upserted rows: `5`
- deprecated shadow rows: `0`

Postcheck result:

- promoted rule rows: `1` per card
- promoted verified auto rows: `1` per card
- promoted oracle hash rows: `1` per card

## Sync

Metadata sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_metadata_sync.json`
- requested unique names: `8537`
- postgres cards matched: `8728`
- sqlite alias rows: `8667`
- deck_cards backfill: `2699/2699`
- unresolved: `1`

Battle rule sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_sqlite_sync.json`
- include_needs_review: `true`
- pg_rows_loaded: `10532`
- sqlite_inserted_or_updated: `10310`
- canonical_snapshot_rows_exported: `7796`
- snapshot path: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Validation

Focused tests:

- `python3 -m py_compile` on changed runtime/package/split/E2E scripts: pass
- `pytest test_xmage_authoritative_exact_scope_split.py -k creature_etb_conditional_draw`: `3 passed`
- `pytest test_xmage_batch_pg_package_builder.py -k 'creature_etb_conditional_draw or contextual_conditional_draw'`: `2 passed`
- `pytest test_battle_package_end_to_end_validation.py -k creature_etb_conditional_draw`: `1 passed`

End-to-end package validation:

- report: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_e2e.md`
- status: `pass`
- stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution
- battle scenarios: `5`
- battle events: `5`
- each promoted card drew `1` card in the focused ETB scenario

Audits:

- `xmage_strategy_consistency_audit_20260712_post_pg846_etb_context_draw_new_server`: pass `26/26`
- `pg_hermes_sqlite_contract_audit_20260712_post_pg846_etb_context_draw_new_server_final`: pass `51/51`

Readiness after PG846:

- `battle_and_oracle_ready`: `6745`
- `snapshot_has_verified_rule`: `6852`
- `battle_family_mapper_required`: `27049`
- `battle_rule_verification_required`: `70`
- `generic_runtime_or_no_card_rule`: `359`
- `official_oracle_identity_unavailable`: `3`

Queue after PG846:

- `xmage_authoritative_adapter_required_count`: `23825`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
- `draw_engine::xmage_draw_card_variant_review_v1`: `1541`

Exact recheck:

- report: `xmage_authoritative_exact_scope_split_20260712_post_pg846_etb_context_draw_new_server_recheck`
- `safe_for_batch_pg_package_count`: `0`
- only remaining proposal: `The Golden Throne`, still `runtime_partial_requires_family_runtime`

## Runtime Notes

Runtime support added:

- ETB draw condition `controller_spent_same_color_mana_to_cast`
- ETB draw condition `controller_revealed_or_controlled_subtype_as_cast`
- ETB draw condition `controller_permanent_left_battlefield_this_turn`
- ETB draw condition `controller_attacked_this_turn`

The `Player` runtime now records permanents leaving the battlefield for common
move/sacrifice paths, which is required for revolt-style conditions.
