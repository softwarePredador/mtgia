# PG547 Dynamic Token Counts New Server Apply Evidence

- Generated at: `2026-07-06T03:43:00+00:00`
- Deploy id: `pg547_dynamic_token_counts_new_server`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_manifest.json`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite target: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Scope

PG547 promotes one additional exact XMage-to-ManaLoom token translation family:

- `xmage_dynamic_count_create_creature_tokens_spell_v1`

It also reuses the existing controlled-subtype token scope for one newly parsed inline count case:

- `xmage_controlled_subtype_create_creature_tokens_spell_v1`

## Cards Applied

| Card | Scope | Count source |
| --- | --- | --- |
| `Crash the Party` | `xmage_dynamic_count_create_creature_tokens_spell_v1` | `controlled_tapped_creatures` |
| `Deploy to the Front` | `xmage_dynamic_count_create_creature_tokens_spell_v1` | `all_creatures_on_battlefield` |
| `Fungal Sprouting` | `xmage_dynamic_count_create_creature_tokens_spell_v1` | `greatest_power_among_controlled_creatures` |
| `Goblin Gathering` | `xmage_dynamic_count_create_creature_tokens_spell_v1` | `named_cards_in_controller_graveyard_plus_base` |
| `Howl of the Night Pack` | `xmage_controlled_subtype_create_creature_tokens_spell_v1` | `controlled_permanents_with_subtype` |

## PostgreSQL Apply

Evidence files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_precheck_output.txt`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_apply_output.txt`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_postcheck_output.txt`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_rollback.sql`

Precheck found all 5 target card rows. `Deploy to the Front` had 2 previous `needs_review` shadow rows; apply deprecated those nonmatching rows before promoting the exact XMage-derived rule.

Apply result:

- `deprecated_shadow_rows`: 2
- `upserted_rows`: 5
- transaction result: `COMMIT`

Postcheck result:

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`

## Hermes / SQLite Sync

Evidence files:

- Sync output: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_sync_output.txt`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_sync_report.json`

Sync result:

- `pg_rows_loaded`: 8850
- `sqlite_inserted_or_updated`: 8614
- `canonical_snapshot_rows_exported`: 6354

## Runtime / E2E

Evidence files:

- E2E JSON: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_e2e.json`
- E2E MD: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_e2e.md`

E2E status: `pass`

- validated PostgreSQL source of truth: 5 rows
- validated SQLite/Hermes cache: 5 rows
- validated canonical snapshot fallback: 5 rows
- validated runtime card effect lookup: 5 rows
- battle execution scenarios: 5
- battle execution events: 10

The battle execution checks confirmed dynamic token counts for the seeded support states:

- `Crash the Party`: 3 tapped Rhino Warrior tokens from 3 controlled tapped creatures
- `Deploy to the Front`: 4 Soldier tokens from 4 total creatures on battlefield
- `Fungal Sprouting`: 4 Saproling tokens from greatest controlled creature power 4
- `Goblin Gathering`: 4 Goblin tokens from base 2 plus 2 named graveyard cards
- `Howl of the Night Pack`: 3 Wolf tokens from 3 controlled Forest permanents

## Audits

| Audit | Status |
| --- | --- |
| `pg_hermes_sqlite_contract_audit_20260706_post_pg547_dynamic_token_counts_new_server_with_pg.json` | `pass` (`51/51`) |
| `xmage_strategy_consistency_audit_20260706_post_pg547_dynamic_token_counts_new_server.json` | `pass` (`26/26`) |
| `operational_surface_alignment_audit_20260706_post_pg547_dynamic_token_counts_new_server.json` | `pass` (`39/39`) |
| `legacy_contamination_audit_20260706_post_pg547_dynamic_token_counts_new_server.json` | `pass` (`32/32`) |
| `global_card_oracle_battle_readiness_20260706_post_pg547_dynamic_token_counts_new_server.json` | `action_required` |

The readiness audit is still `action_required` because the global all-card XMage adaptation queue is not finished; it is not a regression for PG547.

## Remaining Global Queue

Post-PG547 queue summary:

- `target_identity_count`: 25641
- `xmage_authoritative_source_count`: 25327
- `xmage_missing_source_exception_count`: 314
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_authoritative_adapter_required_count`: 25327
- `adapter_work_unit_count`: 11366

The final exact-scope split after PG547 returned:

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

That means this dynamic token-count subpattern is exhausted and the next package must target a different XMage work unit/family.

## Cleanup Policy

The raw queue JSON files for this package were temporary processing artifacts and are intentionally not committed because each is about 40MB. The compact `.md` queue summaries and focused split/evidence reports are retained.
