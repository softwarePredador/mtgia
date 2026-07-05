# PG508 ETB Destroy Residual Apply Evidence

Date: 2026-07-05

Deploy id: `xmage_pg508_etb_destroy_residual_new_server`

Runtime family: `xmage_creature_etb_destroy_target_v1`

## Scope

PG508 promotes the remaining exact ETB destroy target predicates that were
blocked after PG507 by `etb_destroy_target_not_supported`.

Promoted cards:

- `Armaggon, Future Shark`: destroy up to three target creatures.
- `Final-Sting Faerie`: destroy target creature dealt damage this turn.
- `Gilt-Leaf Winnower`: destroy target non-Elf creature whose power and
  toughness are not equal.
- `Kraul Whipcracker`: destroy target token an opponent controls.
- `Lurking Deadeye`: destroy target creature dealt damage this turn.
- `Nekrataal`: destroy target nonartifact, nonblack creature.
- `Ogre Gatecrasher`: destroy target creature with defender.
- `Stingerfling Spider`: destroy target creature with flying.

## PostgreSQL Evidence

Package files:

- Manifest: `xmage_pg508_etb_destroy_residual_new_server_manifest.json`
- Package: `xmage_pg508_etb_destroy_residual_new_server_package.md`
- Precheck: `xmage_pg508_etb_destroy_residual_new_server_precheck.sql`
- Apply: `xmage_pg508_etb_destroy_residual_new_server_apply.sql`
- Postcheck: `xmage_pg508_etb_destroy_residual_new_server_postcheck.sql`
- Rollback: `xmage_pg508_etb_destroy_residual_new_server_rollback.sql`

Execution evidence:

- Precheck: 8 target rows, 0 existing rows, 0 shadow rows.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=8`, `COMMIT`.
- Postcheck: all 8 rows have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.
- Direct PostgreSQL postcheck: all 8 rows are `curated`, `verified`, `auto`,
  and use `battle_model_scope=xmage_creature_etb_destroy_target_v1`.

## Sync And Runtime Evidence

- PG -> Hermes/SQLite sync:
  `xmage_pg508_etb_destroy_residual_new_server_pg_to_sqlite_sync.json`.
- Sync counts: `selected_card_count=8`, `pg_rows_loaded=8`,
  `sqlite_inserted_or_updated=8`, `canonical_snapshot_rows_exported=5992`.
- Runtime lookup:
  `xmage_pg508_etb_destroy_residual_new_server_runtime_get_card_effect.out`.
- Runtime lookup confirms `trigger=enters_battlefield`, exact
  `etb_remove_effect`, exact target constraints, `review_status=verified`,
  `execution_status=auto`, and persisted `oracle_hash` for all 8 cards.

## Validation Evidence

- Splitter unit suite: `526` tests passed.
- Focused battle test:
  `xmage_pg508_etb_destroy_residual_focused_battle_tests.out` exited `0`.
- Full battle suite:
  `xmage_pg508_etb_destroy_residual_new_server_full_battle_suite_post_sync.out`
  has `632` PASS lines and `full_battle_suite_exit_code=0`.
- XMage strategy audit: `pass`, `26/26`.
- Operational surface audit: `pass`.
- Legacy contamination audit: `pass`.
- PG/Hermes/SQLite contract audit: `pass`, `51/51`.
- Deckbuilding contract audit: `pass`.

## Queue Impact

Global readiness after PG508:

- `battle_and_oracle_ready=4925`
- `battle_family_mapper_required=28948`

Post-sync authoritative queue:

- `target_identity_count=26025`
- `xmage_authoritative_source_count=25711`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25711`

Final exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `etb_destroy_target_not_supported` is absent from blocked reasons.

## Boundary

PG508 is applied and should not be rebuilt. It closes only the exact ETB
destroy residual target predicates listed above. It does not authorize broad
`xmage_*_review_v1` promotion, modal ETB destroy effects, unsupported source
effect counts, or unrelated destroy target blockers.
