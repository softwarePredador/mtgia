# PG598 Dynamic Counter Unless Pays Apply Evidence

- Generated UTC: 2026-07-07.
- Database target: `127.0.0.1:15432/halder`.
- Package: `docs/hermes-analysis/master_optimizer_reports/pg598_dynamic_counter_unless_new_server_package_manifest.json`.
- Family: `xmage_counter_unless_pays_dynamic_spell`.
- Scope: `xmage_counter_target_spell_unless_controller_pays_generic_v1`.

## PostgreSQL Apply

- Precheck: 7 target rows, 1 canonical card row per card, 0 existing rule rows, 0 shadow rows to deprecate.
- Applied SQL: `docs/hermes-analysis/master_optimizer_reports/pg598_dynamic_counter_unless_new_server_package_apply.sql`.
- Apply result: 7 upserted rows, 0 deprecated shadow rows.
- Postcheck: each of the 7 cards has 1 promoted rule row, 1 verified/auto row, and 1 oracle-hash-matching row.

Promoted cards:

- Clash of Wills
- Concerted Defense
- Evasive Action
- Ixidor's Will
- Spell Stutter
- Syncopate
- Thassa's Rebuff

## Runtime Coverage

Runtime formulas added:

- `x_value`
- `party_count`
- `domain_basic_land_types`
- `battlefield_subtype_count`
- `controlled_subtype_count`
- `devotion_to_blue`

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py`: 734 tests passed.
- `test_xmage_batch_pg_package_builder.py`: 69 tests passed.
- `test_xmage_exact_scope_runtime.py`: 373 tests passed.

## Sync And E2E

- PG -> SQLite/snapshot final sync: `docs/hermes-analysis/master_optimizer_reports/pg598_dynamic_counter_unless_new_server_pg_to_sqlite_sync_after_hash_backfill.json`.
- Sync result: 9,371 PG rows loaded, 9,135 SQLite rows inserted/updated, 6,814 canonical snapshot rows exported.
- Package E2E: `docs/hermes-analysis/master_optimizer_reports/pg598_dynamic_counter_unless_new_server_e2e_validation.md`.
- E2E result: pass, 7 scenarios executed.
- E2E taxes resolved:
  - Clash of Wills: 3 from `x_value`
  - Concerted Defense: 5 from `party_count`
  - Evasive Action: 3 from `domain_basic_land_types`
  - Ixidor's Will: 4 from `battlefield_subtype_count`
  - Spell Stutter: 4 from `controlled_subtype_count`
  - Syncopate: 3 from `x_value`, exile replacement true
  - Thassa's Rebuff: 3 from `devotion_to_blue`

## Contract Backfill

During final PG/Hermes/SQLite contract audit, 44 trusted curated/manual executable rows were found without `oracle_hash`. They predated PG598 and were backfilled from `md5(cards.oracle_text)`.

- Backfill precheck: 44 candidates, 44 with source Oracle text.
- Backfill apply: 44 rows updated.
- Contract audit after resync: pass, 51/51 checks.

## Post-Apply Queue

- Post-PG598 queue: target identities 25,170; XMage authoritative adapter-required 24,856; missing-source exceptions 314; parser gap 0.
- Post-PG598 recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0` for this dynamic counter-unless family.
- Global readiness: `battle_and_oracle_ready=5,780`, `battle_family_mapper_required=28,093`.

## Final Audits

- XMage strategy consistency: pass, 26/26.
- Operational surface alignment: pass.
- Legacy contamination audit: pass.
- PostgreSQL/Hermes/SQLite contract audit: pass, 51/51.
- Server target gate: pass.
