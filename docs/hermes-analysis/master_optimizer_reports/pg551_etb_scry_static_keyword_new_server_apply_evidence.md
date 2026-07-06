# PG551 ETB Scry Static Keyword New Server Apply Evidence

- Generated at: `2026-07-06T05:04:13+00:00`
- Deploy id: `pg551_etb_scry_static_keyword_new_server`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_manifest.json`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite target: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Scope

PG551 extends the safe creature ETB fixed scry mapper from PG550 to XMage rows
where `ScryEffect` plus `EntersBattlefieldTriggeredAbility` is combined only
with static self keyword abilities. The promoted runtime scope remains:

- `xmage_creature_etb_scry_v1`

The runtime proof now checks both the fixed ETB scry event and the expected
self keyword on the resulting permanent. Supported keyword variants in this
package are `flying`, `flash`, and `defender`.

Current blocked ETB-scry neighbors remain outside this package:

- `Cascade Seer`: `etb_scry_oracle_not_fixed`
- `Cryptic Annelid`: `etb_scry_oracle_not_simple`

## Cards Applied

| Card | Scry count | Keyword proof | Runtime proof state |
| --- | ---: | --- | --- |
| `Augury Owl` | 3 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 3 cards, and permanent retained `flying` |
| `Cloudreader Sphinx` | 2 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 2 cards, and permanent retained `flying` |
| `Faerie Seer` | 2 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 2 cards, and permanent retained `flying` |
| `Glider Kids` | 1 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `flying` |
| `Grey Havens Navigator` | 1 | `flash` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `flash` |
| `Horizon Scholar` | 2 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 2 cards, and permanent retained `flying` |
| `Senate Griffin` | 1 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `flying` |
| `Silver Raven` | 1 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `flying` |
| `Thaumaturge's Familiar` | 1 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `flying` |
| `Wall of Runes` | 1 | `defender` | ETB trigger emitted `etb_scry_resolved`, looked at 1 card, and permanent retained `defender` |
| `Willow-Wind` | 2 | `flying` | ETB trigger emitted `etb_scry_resolved`, looked at 2 cards, and permanent retained `flying` |

## PostgreSQL Apply

Evidence files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_precheck_output.txt`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_apply_output.txt`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_postcheck_output.txt`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_rollback.sql`

Precheck found all 11 target card rows, `0` existing expected rows, and `0`
shadow rows scheduled for deprecation.

Apply result:

- `deprecated_shadow_rows`: 0
- `upserted_rows`: 11
- transaction result: `COMMIT`

Postcheck result:

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`

## Hermes / SQLite Sync

Evidence files:

- Sync output: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_sync_output.txt`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_sync_report.json`

Sync result:

- `pg_rows_loaded`: 8887
- `sqlite_inserted_or_updated`: 8651
- `canonical_snapshot_rows_exported`: 6390

## Runtime / E2E

Evidence files:

- E2E JSON: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_e2e.json`
- E2E MD: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_e2e.md`

E2E status: `pass`

- validated PostgreSQL source of truth: 11 rows
- validated SQLite/Hermes cache: 11 rows
- validated canonical snapshot fallback: 11 rows
- validated runtime card effect lookup: 11 rows
- battle execution scenarios: 11
- battle execution events: 11
- each scenario validated the expected self keyword through
  `battle.card_has_keyword`

## Audits

| Audit | Status |
| --- | --- |
| `pg_hermes_sqlite_contract_audit_20260706_post_pg551_etb_scry_static_keyword_new_server_final.json` | `pass` (`51/51`) |
| `xmage_strategy_consistency_audit_20260706_post_pg551_etb_scry_static_keyword_new_server_final.json` | `pass` (`26/26`) |
| `operational_surface_alignment_audit_20260706_post_pg551_etb_scry_static_keyword_new_server_final.json` | `pass` |
| `legacy_contamination_audit_20260706_post_pg551_etb_scry_static_keyword_new_server_final.json` | `pass` |
| `global_card_oracle_battle_readiness_20260706_post_pg551_etb_scry_static_keyword_new_server.json` | `action_required` |

The readiness audit remains `action_required` because the global all-card XMage
adaptation queue is not finished; it is not a regression for PG551.

## Remaining Global Queue

Post-PG551 queue summary:

- `target_identity_count`: 25604
- `xmage_authoritative_source_count`: 25290
- `xmage_missing_source_exception_count`: 314
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_authoritative_adapter_required_count`: 25290
- `adapter_work_unit_count`: 11363

The final exact-scope split after PG551 returned:

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

That means the creature ETB scry subpattern with safe static self keywords is
exhausted and the next package must target a different XMage work unit/family.

## Cleanup Policy

The raw queue JSON files for this package are temporary processing artifacts and
should not be committed because each is large. The compact `.md` queue
summaries, package SQL, postcheck outputs, sync reports, E2E reports, and audit
reports are retained as durable evidence.
