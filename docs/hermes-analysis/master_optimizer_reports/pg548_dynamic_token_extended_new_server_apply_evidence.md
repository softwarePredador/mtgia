# PG548 Dynamic Token Extended New Server Apply Evidence

- Generated at: `2026-07-06T04:08:22+00:00`
- Deploy id: `pg548_dynamic_token_extended_new_server`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_package_manifest.json`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite target: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Scope

PG548 promotes the remaining safe spell-based dynamic token-count variants for:

- `xmage_dynamic_count_create_creature_tokens_spell_v1`

New runtime-backed count sources covered by this package:

- `attacking_creatures`
- `domain_basic_land_types`
- `controller_graveyard_instant_sorcery_count`
- `controller_hand_count`

The package deliberately excludes ETB/dies dynamic token creation because those
use a different trigger adapter path and require a separate runtime contract.

## Cards Applied

| Card | Count source | Runtime proof state |
| --- | --- | --- |
| `Flurry of Wings` | `attacking_creatures` | 3 attacking creatures produced 3 Bird Soldier tokens |
| `Ordered Migration` | `domain_basic_land_types` | 3 basic land types produced 3 Bird tokens |
| `Rise from the Tides` | `controller_graveyard_instant_sorcery_count` | 3 instant/sorcery graveyard cards produced 3 tapped Zombie tokens |
| `Spontaneous Generation` | `controller_hand_count` | 4 controller hand cards produced 4 Saproling tokens |
| `Spore Burst` | `domain_basic_land_types` | 3 basic land types produced 3 Saproling tokens |

## PostgreSQL Apply

Evidence files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_precheck_output.txt`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_apply_output.txt`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_postcheck_output.txt`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_package_rollback.sql`

Precheck found all 5 target card rows and no active nonmatching shadow rows.

Apply result:

- `deprecated_shadow_rows`: 0
- `upserted_rows`: 5
- transaction result: `COMMIT`

Postcheck result:

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`

## Hermes / SQLite Sync

Evidence files:

- Sync output: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_sync_output.txt`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_sync_report.json`

Sync result:

- `pg_rows_loaded`: 8855
- `sqlite_inserted_or_updated`: 8619
- `canonical_snapshot_rows_exported`: 6359

## Runtime / E2E

Evidence files:

- E2E JSON: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_e2e.json`
- E2E MD: `docs/hermes-analysis/master_optimizer_reports/pg548_dynamic_token_extended_new_server_e2e.md`

E2E status: `pass`

- validated PostgreSQL source of truth: 5 rows
- validated SQLite/Hermes cache: 5 rows
- validated canonical snapshot fallback: 5 rows
- validated runtime card effect lookup: 5 rows
- battle execution scenarios: 5
- battle execution events: 10

## Audits

| Audit | Status |
| --- | --- |
| `pg_hermes_sqlite_contract_audit_20260706_post_pg548_dynamic_token_extended_new_server_with_pg.json` | `pass` (`51/51`) |
| `xmage_strategy_consistency_audit_20260706_post_pg548_dynamic_token_extended_new_server.json` | `pass` (`26/26`) |
| `operational_surface_alignment_audit_20260706_post_pg548_dynamic_token_extended_new_server.json` | `pass` |
| `legacy_contamination_audit_20260706_post_pg548_dynamic_token_extended_new_server.json` | `pass` |
| `global_card_oracle_battle_readiness_20260706_post_pg548_dynamic_token_extended_new_server.json` | `action_required` |

The readiness audit remains `action_required` because the global all-card XMage
adaptation queue is not finished; it is not a regression for PG548.

## Remaining Global Queue

Post-PG548 queue summary:

- `target_identity_count`: 25636
- `xmage_authoritative_source_count`: 25322
- `xmage_missing_source_exception_count`: 314
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_authoritative_adapter_required_count`: 25322
- `adapter_work_unit_count`: 11366
- `token_maker`: 2345

The final exact-scope split after PG548 returned:

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

That means this spell-based dynamic token-count subpattern is exhausted and the
next package must target a different XMage work unit/family.

## Cleanup Policy

The raw queue JSON files for this package are temporary processing artifacts and
should not be committed because each is large. The compact `.md` queue summaries,
package SQL, postcheck outputs, sync reports, E2E reports, and audit reports are
retained as durable evidence.
