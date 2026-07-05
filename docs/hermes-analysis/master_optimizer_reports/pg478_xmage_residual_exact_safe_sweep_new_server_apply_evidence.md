# PG478 XMage Residual Exact Safe Sweep Evidence

Status: `pass`

Database target: `143.198.230.247:5433/halder`

PG478 promoted `15` verified/auto PostgreSQL battle-rule rows across `9`
runtime-backed XMage scopes:

- Badlands Revival
- Bonecaller Cleric
- Crucible of Worlds
- Elvish Hexhunter
- Eternal Taskmaster
- Festive Funeral
- Ghoul's Feast
- Hana Kami
- Pillardrop Warden
- Pull Through the Weft
- Ramunap Excavator
- Select for Inspection
- The Unspeakable
- Valgavoth's Faithful
- Voyage's End

PostgreSQL apply/postcheck verified `15/15` promoted rows, `15/15` Oracle
hashes, `15/15` verified/auto rows, `backup_rows=2`, and `failed_cards=[]`.

During validation, the canonical snapshot export exposed a stale-cache bug:
`Select for Inspection` and `Voyage's End` were correct in PostgreSQL and
SQLite as `effect=composite_resolution`, but the exported snapshot could still
carry old `remove_permanent`/`remove_creature` effects after Oracle
normalization. The fix in
`docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py`
makes trusted `manual`/`curated` verified runtime adapter rows authoritative
over Oracle normalization when they carry an explicit runtime scope, composite
components, or XMage effect metadata.

Regression coverage:

- `test_sync_battle_card_rules_pg_selection.SyncBattleCardRulesPgSelectionTests.test_export_canonical_snapshot_keeps_verified_composite_rule_over_stale_snapshot_effect`
- existing trusted-runtime Oracle normalization preservation test

Validation passed:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_sync_battle_card_rules_pg_selection.py test_sync_battle_card_rules_manual_preserve.py`: `752` tests passed.
- `python3 test_xmage_batch_pg_package_builder.py`: pass.
- `python3 -m py_compile ...`: pass.
- PG -> SQLite sync after snapshot fix: `pg_rows_loaded=4547`,
  `sqlite_inserted_or_updated=4539`, `canonical_snapshot_rows_exported=4514`.
- PG478 E2E after snapshot fix: `status=pass` across PostgreSQL, SQLite,
  canonical snapshot, runtime `get_card_effect`, and no-override battle gate.
- Extra SQLite/snapshot manifest verification: pass.
- XMage strategy consistency audit: `26/26` pass.
- Operational surface alignment audit: `39/39` pass.
- Legacy contamination audit: `32/32` pass.
- PG/Hermes/SQLite contract audit with live PostgreSQL: `51/51` pass.

Post-PG478 Commander-legal queue:

- `target_identity_count=26339`
- `xmage_authoritative_source_count=26025`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26025`
- `adapter_work_unit_count=11393`
- `exact_split_proposal_count=0`
- `safe_for_batch_pg_package_count=0`

Interpretation: PG478 closes the residual exact safe candidates available after
PG477. The next work is no longer another direct exact package from the current
splitter output; it is implementing/splitting new family subpatterns from the
blocked reasons, then regenerating the queue and package candidates.
