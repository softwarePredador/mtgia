# PG533 Destroy Target Create Treasure Apply Evidence

Status: `applied_and_validated`.

Package: `docs/hermes-analysis/master_optimizer_reports/pg533_destroy_treasure_new_server_package_package.md`

Applied cards:

- `Contract Killing`
- `Crack Open`
- `Grim Bounty`

Precheck:

- target rows: `3`
- existing matching rule rows: `0`
- expected rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- `upserted_rows=3`
- `deprecated_shadow_rows=0`

Postcheck:

- `promoted_rule_rows=1` for each selected card
- `promoted_verified_auto_rows=1` for each selected card
- `promoted_oracle_hash_rows=1` for each selected card
- backup rows: `0`

PostgreSQL -> SQLite/Hermes sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg533_destroy_treasure_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=6184`

Battle package E2E:

- report: `docs/hermes-analysis/master_optimizer_reports/pg533_destroy_treasure_new_server_e2e_validation.md`
- status: `pass`
- scenarios: `3`
- events: `12`
- `Contract Killing`: removed target and created `2` Treasures for spell controller
- `Crack Open`: removed target and created `1` Treasure for spell controller
- `Grim Bounty`: removed target and created `1` Treasure for spell controller

Post-sync queue:

- pre-cycle `target_identity_count=25829`
- post-cycle `target_identity_count=25826`
- post-cycle `xmage_authoritative_source_count=25512`
- post-cycle `xmage_authoritative_adapter_required_count=25512`
- post-cycle `treasure_maker::single_treasure_creation_v1=32`
- exact-scope recheck `proposal_count=0`
- exact-scope recheck `safe_for_batch_pg_package_count=0`

Final audits:

- `xmage_strategy_consistency_audit_20260705_post_pg533_destroy_treasure_new_server_final.md`: `pass`, 26/26
- `pg_hermes_sqlite_contract_audit_20260705_post_pg533_destroy_treasure_new_server_final_with_pg.md`: `pass`, 51/51
- `operational_surface_alignment_audit_20260705_post_pg533_destroy_treasure_new_server_final.md`: `pass`
- `legacy_contamination_audit_20260705_post_pg533_destroy_treasure_new_server_final.md`: `pass`

Residual boundary:

PG533 only authorizes one-shot spells whose local XMage source has exactly one
`DestroyTargetEffect` and one `CreateTokenEffect(new TreasureToken(), N?)`,
whose Oracle text exactly says to destroy the supported target and create a
fixed number of Treasure tokens for the spell controller. It does not authorize
triggered Treasure makers, activated Treasure makers, Treasure plus damage,
Treasure plus initiative/venture, Treasure plus exile/play, Aura/Equipment
Treasure patterns, or target-controller compensation tokens.
