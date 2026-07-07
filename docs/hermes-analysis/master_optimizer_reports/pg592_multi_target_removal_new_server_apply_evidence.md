# PG592 Multi-Target Removal Apply Evidence

- Generated UTC: `2026-07-07`
- Database target: `127.0.0.1:15432/halder`
- Package: `pg592_multi_target_removal_new_server`
- Scope: XMage-authoritative fixed multi-target destroy, exile, and return-to-hand spells.

## Runtime And Splitter

- Added fixed multi-target extraction for `DestroyTargetEffect`, `ExileTargetEffect`, and `ReturnToHandTargetEffect`.
- Supported only fixed numeric or `up to N` target counts with Oracle/XMage source agreement.
- Deliberately blocked dynamic/X target counts, target-pointer rewrites, and unsupported target constructors.
- Added package builder and E2E support for `multi_target_removal` scenarios so multi-target cards do not fall through the single-target runner.

## Selected PostgreSQL Batch

Selected proposals: `15`.

Families:

- `xmage_return_multi_target_to_hand_spell`: `7`
- `xmage_destroy_multi_target_spell`: `6`
- `xmage_exile_multi_target_spell`: `2`

Cards:

- `Aether Gale`
- `Captivating Gyre`
- `Curtains' Call`
- `Dust to Dust`
- `Hex`
- `Into the Core`
- `Into the Void`
- `Peace and Quiet`
- `Quicksilver Geyser`
- `Rack and Ruin`
- `Rain of Salt`
- `Sea God's Scorn`
- `Undo`
- `Violent Ultimatum`
- `Waterwhirl`

## PostgreSQL Apply

`pg592_multi_target_removal_new_server_package_apply.sql` was applied against the new-server PostgreSQL target.

Postcheck result:

- Promoted rule rows: `15/15`
- Promoted `verified/auto` rows: `15/15`
- Promoted oracle-hash rows: `15/15`
- Existing shadow rows backed up/deprecated: `2` rows for `Rain of Salt`

## Integrity Backfill

`pg592b_trusted_oracle_hash_backfill_new_server_apply.sql` was applied after the first PG/Hermes/SQLite contract audit found trusted executable rows missing `oracle_hash`.

Postcheck result:

- Missing trusted executable `oracle_hash` rows: `0`
- Backed up rows: `44`
- Verified updated rows: `44`

## Sync And Validation

PostgreSQL to SQLite sync:

- `pg592_multi_target_removal_new_server_pg_to_sqlite_sync.json`
- Canonical snapshot rows exported: `6772`
- PostgreSQL rows loaded: `9328`
- SQLite rows inserted/updated: `9092`

Metadata sync:

- `pg592_multi_target_removal_new_server_metadata_sync.json`
- `deck_cards` rows matched: `2699/2699`
- `card_id` rows updated: `108`

Post-backfill sync:

- `pg592b_trusted_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- Canonical snapshot rows exported: `6772`
- PostgreSQL rows loaded: `9328`
- SQLite rows inserted/updated: `9092`

E2E:

- `pg592_multi_target_removal_new_server_e2e.md`
- Status: `pass`
- PostgreSQL validated rows: `15`
- SQLite/Hermes cache validated rows: `15`
- Canonical snapshot validated cards: `15`
- Runtime `get_card_effect` validated cards: `15`
- Battle execution: `15` scenarios, `67` events
- Legal targets moved to the expected destination; nonmatching target remained on battlefield.

Audits:

- `xmage_strategy_consistency_audit_20260707_post_pg592_multi_target_removal_new_server_final`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260707_post_pg592_multi_target_removal_new_server_final`: `pass`, `48/48`
- `legacy_contamination_audit_20260707_post_pg592_multi_target_removal_new_server_final`: `pass`, `32/32`
- `pg_hermes_sqlite_contract_audit_20260707_post_pg592_multi_target_removal_new_server_after_hash_backfill_final`: `pass`, `51/51`
- `scripts/quality_gate.sh server-target`: `pass`

## Queue Delta

Post-PG592 queue:

- `target_identity_count`: `25213`
- `xmage_authoritative_source_count`: `24899`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `24899`
- `manual_semantic_decision_units_remaining`: `314`

Post-PG592 exact-scope probe:

- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`
- `blocked_count`: `0`

Interpretation: the multi-target removal subpattern is closed for the current supported exact scope. The global goal remains active because the refreshed queue still contains unresolved adapter work units in other families.
