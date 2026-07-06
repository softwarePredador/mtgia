# PG550 ETB Scry New Server Apply Evidence

- Generated at: `2026-07-06T04:47:30+00:00`
- Deploy id: `pg550_etb_scry_new_server`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_package_manifest.json`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite target: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Scope

PG550 promotes the safe creature ETB fixed scry rows where XMage has exactly
`ScryEffect` plus `EntersBattlefieldTriggeredAbility`, no target, no condition,
and Oracle/source both say a fixed `scry N`.

Runtime-backed scope covered by this package:

- `xmage_creature_etb_scry_v1`

The package deliberately excludes dynamic `scry X` and multiple scry sequences.
Current blocked neighbors:

- `Cascade Seer`: `etb_scry_oracle_not_fixed`
- `Cryptic Annelid`: `etb_scry_oracle_not_simple`

## Cards Applied

| Card | Scry count | Runtime proof state |
| --- | ---: | --- |
| `Automatic Librarian` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Chrome Cat` | 1 | ETB trigger emitted `etb_scry_resolved` and looked at 1 card |
| `Galadhrim Guide` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Lost Legion` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Octoprophet` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Omenspeaker` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Prophet of the Peak` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |
| `Rumbling Sentry` | 1 | ETB trigger emitted `etb_scry_resolved` and looked at 1 card |
| `Sage's Row Savant` | 2 | ETB trigger emitted `etb_scry_resolved` and looked at 2 cards |

## PostgreSQL Apply

Evidence files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_precheck_output.txt`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_apply_output.txt`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_postcheck_output.txt`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_package_rollback.sql`

Precheck found all 9 target card rows, `0` existing expected rows, and `0`
shadow rows scheduled for deprecation.

Apply result:

- `deprecated_shadow_rows`: 0
- `upserted_rows`: 9
- transaction result: `COMMIT`

Postcheck result:

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`

## Hermes / SQLite Sync

Evidence files:

- Sync output: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_sync_output.txt`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_sync_report.json`

Sync result:

- `pg_rows_loaded`: 8876
- `sqlite_inserted_or_updated`: 8640
- `canonical_snapshot_rows_exported`: 6379

## Runtime / E2E

Evidence files:

- E2E JSON: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_e2e.json`
- E2E MD: `docs/hermes-analysis/master_optimizer_reports/pg550_etb_scry_new_server_e2e.md`

E2E status: `pass`

- validated PostgreSQL source of truth: 9 rows
- validated SQLite/Hermes cache: 9 rows
- validated canonical snapshot fallback: 9 rows
- validated runtime card effect lookup: 9 rows
- battle execution scenarios: 9
- battle execution events: 9

## Audits

| Audit | Status |
| --- | --- |
| `pg_hermes_sqlite_contract_audit_20260706_post_pg550_etb_scry_new_server_with_pg.json` | `pass` (`51/51`) |
| `xmage_strategy_consistency_audit_20260706_post_pg550_etb_scry_new_server_final.json` | `pass` (`26/26`) |
| `operational_surface_alignment_audit_20260706_post_pg550_etb_scry_new_server_final.json` | `pass` |
| `legacy_contamination_audit_20260706_post_pg550_etb_scry_new_server_final.json` | `pass` |
| `global_card_oracle_battle_readiness_20260706_post_pg550_etb_scry_new_server.json` | `action_required` |

The readiness audit remains `action_required` because the global all-card XMage
adaptation queue is not finished; it is not a regression for PG550.

## Remaining Global Queue

Post-PG550 queue summary:

- `target_identity_count`: 25615
- `xmage_authoritative_source_count`: 25301
- `xmage_missing_source_exception_count`: 314
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_authoritative_adapter_required_count`: 25301
- `adapter_work_unit_count`: 11366

The final exact-scope split after PG550 returned:

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

That means the fixed creature ETB scry subpattern is exhausted and the next
package must target a different XMage work unit/family.

## Cleanup Policy

The raw queue JSON files for this package are temporary processing artifacts and
should not be committed because each is large. The compact `.md` queue
summaries, package SQL, postcheck outputs, sync reports, E2E reports, and audit
reports are retained as durable evidence.
