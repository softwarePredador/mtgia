# PG326 XMage Recursion Fixed-Target Wave - PostgreSQL Apply Evidence

- Generated at: `2026-07-01T19:57:10Z`
- Deploy id: `PG326`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_manifest.json`
- Selected cards: `Boggart Birth Rite`, `Death's Duet`, `Reborn Hope`, `Revive`
- Exact scope: `xmage_return_target_graveyard_card_to_hand_spell_v1`

## Precheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_precheck.sql`

- Target rows found: `4/4`
- Expected rule rows before apply: `0`
- Shadow rows scheduled for deprecation: `0`

| Card | Target rows | Expected rows before | Shadow rows |
| --- | ---: | ---: | ---: |
| `Boggart Birth Rite` | 1 | 0 | 0 |
| `Death's Duet` | 1 | 0 | 0 |
| `Reborn Hope` | 1 | 0 | 0 |
| `Revive` | 1 | 0 | 0 |

## Apply

`psql -f docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_apply.sql`

- Transaction: `COMMIT`
- `deprecated_shadow_rows=0`
- `upserted_rows=4`

## Postcheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_postcheck.sql`

| Card | Promoted rows | Verified/auto rows | Matching oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Boggart Birth Rite` | 1 | 1 | 1 | 0 |
| `Death's Duet` | 1 | 1 | 1 | 0 |
| `Reborn Hope` | 1 | 1 | 1 | 0 |
| `Revive` | 1 | 1 | 1 | 0 |

## PG -> Hermes/SQLite Sync

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_pg_to_sqlite_sync.json`

- `pg_rows_loaded=7202`
- `sqlite_inserted_or_updated=6996`
- `canonical_snapshot_rows_exported=4793`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## E2E

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py --manifest docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_manifest.json --output-json docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_e2e_validation.json --output-md docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: `4/4`
- SQLite Hermes cache: `4/4`
- Canonical snapshot fallback: `4/4`
- Runtime `get_card_effect`: `4/4`
- Battle execution no-override gate: `pass`

## Focused Tests

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `150` tests passed.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `83` tests passed.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests passed.

## Post-Apply Queue Reduction

- All-card readiness: `battle_and_oracle_ready=2335`, `battle_family_mapper_required=30212`, `snapshot_has_verified_rule=3483`.
- Authoritative queue: `target_identity_count=27289`, `xmage_authoritative_source_count=26975`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26975`.
- `recursion::xmage_graveyard_return_variant_review_v1`: `1975 -> 1971`.
- Existing supported splitter recheck: `proposal_count=0` over `7996` considered supported rows.

## Final Audits

- XMage strategy consistency: `pass` (`26/26` checks).
- Operational surface alignment: `pass`.
- PG/Hermes/SQLite contract: `pass`, with inherited warning `trusted_executable_rules_missing_oracle_hash=1418` for old executable rows. PG326 rows have `4/4` matching Oracle hashes.
- Legacy contamination: `pass`.
