# PG673 Simple Activated Untap Target Apply Evidence

- Date: `2026-07-08`
- PostgreSQL target: `127.0.0.1:15432/halder`
- Package: `pg673_simple_activated_untap_target_new_server_package`
- Family: `xmage_permanent_simple_activated_untap_target`
- Cards promoted: `16`

## Cards

`Arbor Elf`, `Argothian Elder`, `Blossom Dryad`, `Filigree Sages`,
`Fyndhorn Brownie`, `Greenside Watcher`, `Jandor's Saddlebags`,
`Juniper Order Druid`, `Kiora's Follower`, `Ley Druid`,
`Magewright's Stone`, `Rime Tender`, `Sculptor of Winter`,
`Seeker of Skybreak`, `Voltaic Construct`, `Voyaging Satyr`.

## PostgreSQL Apply

- Precheck:
  `16/16` target card rows found, `0` expected rules already present, `0`
  shadow rows scheduled for deprecation.
- Apply:
  `16` rows upserted into `card_battle_rules`.
- Postcheck:
  `16/16` promoted rows, `16/16` verified/auto,
  `16/16` matching Oracle hash, `0` backup rows.

## PG673B Hash Backfill

The PG/Hermes/SQLite contract audit found an older unrelated integrity gap:
`44` trusted executable rules lacked `oracle_hash`. PG673B was applied as a
metadata-only fix from `cards.oracle_text`.

- PG673B precheck: `44` backfillable rows, `0` unsafe rows.
- PG673B apply: `44` `oracle_hash` values backfilled.
- PG673B postcheck: `0` trusted executable rules missing `oracle_hash`;
  `44/44` backfilled rows match the current `cards.oracle_text` hash.

## Sync And E2E

- Metadata sync:
  `8051` PostgreSQL cards matched, `7987` SQLite cache alias rows.
- PG -> SQLite sync after PG673:
  `9674` PostgreSQL rows loaded, `9437` SQLite rows inserted/updated,
  `7107` canonical snapshot rows exported.
- PG -> SQLite sync after PG673B:
  `9674` PostgreSQL rows loaded, `9437` SQLite rows inserted/updated,
  `7107` canonical snapshot rows exported.
- E2E package validation:
  status `pass`.
  PostgreSQL `16/16`, SQLite `16/16`, snapshot `16/16`,
  runtime `get_card_effect` `16/16`, battle execution `16` scenarios and
  `32` replay events.

## Final Global Counts

- `battle_and_oracle_ready`: `6084`
- `snapshot_has_verified_rule`: `6112`
- `snapshot_has_any_rule`: `7314`
- `battle_family_mapper_required`: `27792`
- Commander-legal queue `target_identity_count`: `24869`
- `xmage_authoritative_adapter_required`: `24556`
- `xmage_missing_source_exception`: `313`
- `xmage_authoritative_parser_gap`: `0`
- Remaining `untap_target::xmage_targeted_untap_variant_review_v1`: `234`
- Post-PG673B exact split recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

## Validation Commands

- `python3 -m py_compile` on touched runtime/builder/validator/test scripts:
  pass.
- Focused pytest:
  `153 passed in 1.99s`.
- Package E2E:
  pass.
- XMage strategy consistency audit:
  `26/26` pass.
- Operational surface alignment audit:
  `48/48` pass.
- Legacy contamination audit:
  `32/32` pass.
- PG/Hermes/SQLite contract audit after PG673B:
  `51/51` pass.

## Residual Test Note

Full `unittest discover` ran `2669` tests with `1` failure in
`test_report_retention_audit.py`. The failure is the report-retention cleanup
gate, not PG673 behavior:

- `tracked_raw_count=1651`
- `unreferenced_tracked_raw_count=768`
- `ignored_local_count=692`
- `ignored_local_bytes=2921132181`

This residual requires a separate report-retention cleanup decision. The PG673
runtime, package, sync, E2E, and contract gates passed.
