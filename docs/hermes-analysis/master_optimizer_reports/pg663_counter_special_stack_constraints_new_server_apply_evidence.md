# PG663 Counter Special Stack Constraints Evidence

- Database target: `127.0.0.1:15432/halder`
- Cards closed: `Avoid Fate`, `Double Negative`, `Outwit`, `Second Guess`
- Family: `xmage_counter_target_spell`
- Runtime scope: `xmage_counter_target_spell_v1`

## Apply

- Precheck: `4` target card rows, `0` expected rows already present, `0` stale shadows.
- Apply: `4` promoted rows, `0` shadow rows deprecated.
- Postcheck: `4/4` promoted rows are `verified`/`auto` and carry `oracle_hash`.

## Contract Repair

The first PG/Hermes/SQLite audit after PG663 found old trusted executable curated/manual rules missing `oracle_hash` in the current new-server PostgreSQL. Reapplying the narrow PG661 metadata-only backfill found `44` safe groups, updated `44` rows, backed up `44` rows, and reduced missing trusted executable hashes to `0`.

## Sync And Validation

- PG -> SQLite sync after hash repair: `5973` PG rows loaded, `5959` SQLite rows inserted/updated, `5936` canonical snapshot rows exported.
- Metadata sync: `7096` PostgreSQL card rows matched, `7015` SQLite alias rows, `deck_cards` matched `2699/2699`, `73` card-id cache updates, `1` known unresolved alias.
- E2E package validation: `pass`, `4` battle execution scenarios.
- Final readiness: `battle_and_oracle_ready=6033`, `snapshot_has_verified_rule=6061`, `snapshot_has_any_rule=7264`, `battle_family_mapper_required=27843`.
- Final authoritative queue: `xmage_authoritative_adapter_required_count=24607`, `xmage_authoritative_parser_gap_count=0`, `xmage_missing_source_exception_count=313`.
- Final audits: XMage strategy `26/26` pass, operational alignment pass, legacy contamination pass, PG/Hermes/SQLite contract `51/51` pass.
