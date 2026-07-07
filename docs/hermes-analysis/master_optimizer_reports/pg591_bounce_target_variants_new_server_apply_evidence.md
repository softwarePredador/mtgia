# PG591 Bounce Target Variants Apply Evidence

Status: `applied_and_validated`

Target database: `127.0.0.1:15432/halder`

## Scope

- Deploy id: `PG591`
- Family: `xmage_return_target_to_hand_spell`
- Battle model scope: `xmage_return_target_to_hand_spell_v1`
- Selected cards: `6`
- Cards: `Bounce Off`, `Cut the Earthly Bond`, `Depart the Realm`, `Hoodwink`, `Into Thin Air`, `Wipe Away`

## PostgreSQL

- Precheck: `6` target identities, `0` existing rule rows, `0` shadow rows to deprecate.
- Apply: `6` upserted rows, `0` deprecated shadow rows.
- Postcheck: every selected card has `1` promoted rule row, `review_status=verified`, `execution_status=auto`, and `oracle_hash` present.

## Sync

- PG -> SQLite/snapshot sync: `9077` SQLite rows inserted/updated.
- Canonical snapshot export: `6758` rows.
- Metadata sync: `2699/2699` deck card rows matched; `107` `card_id` updates; `1` unresolved alias remains in the sync report.

## Runtime/E2E

- End-to-end package validation: `pass`.
- Scenarios: `6`.
- Runtime events: `18`.
- Result: each selected card moved the legal target to hand and left the illegal target on battlefield.

## Audits

- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`.
- `xmage_strategy_consistency_audit`: `pass`, `26/26`.
- `operational_surface_alignment_audit`: `pass`.
- `legacy_contamination_audit`: `pass`.
- `quality_gate.sh server-target`: `pass`.

## Backlog Delta

- Post-PG590 target identity count: `25234`.
- Post-PG591 target identity count: `25228`.
- Delta: `-6`.
- Post-PG591 XMage authoritative adapter required count: `24914`.
- Manual semantic decision units remaining: `314`.
