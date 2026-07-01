# PG328 XMage Recursion Choose-One Wave - PostgreSQL Apply Evidence

- Generated at: `2026-07-01T20:17:20Z`
- Deploy id: `PG328`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_manifest.json`
- Selected cards: `Ghoulcaller's Chant`, `March of the Drowned`, `Raise the Draugr`, `Return from Extinction`, `Unbury`
- Exact scope: `xmage_return_choose_one_graveyard_cards_to_hand_spell_v1`

## Precheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_precheck.sql`

- Target rows found: `5/5`
- Expected rule rows before apply: `0`
- Shadow rows scheduled for deprecation: `0`

| Card | Target rows | Expected rows before | Shadow rows |
| --- | ---: | ---: | ---: |
| `Ghoulcaller's Chant` | 1 | 0 | 0 |
| `March of the Drowned` | 1 | 0 | 0 |
| `Raise the Draugr` | 1 | 0 | 0 |
| `Return from Extinction` | 1 | 0 | 0 |
| `Unbury` | 1 | 0 | 0 |

## Apply

`psql -f docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_apply.sql`

- Transaction: `COMMIT`
- `deprecated_shadow_rows=0`
- `upserted_rows=5`

## Postcheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_postcheck.sql`

| Card | Promoted rows | Verified/auto rows | Matching oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Ghoulcaller's Chant` | 1 | 1 | 1 | 0 |
| `March of the Drowned` | 1 | 1 | 1 | 0 |
| `Raise the Draugr` | 1 | 1 | 1 | 0 |
| `Return from Extinction` | 1 | 1 | 1 | 0 |
| `Unbury` | 1 | 1 | 1 | 0 |

## PG -> Hermes/SQLite Sync

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_pg_to_sqlite_sync.json`

- `pg_rows_loaded=7214`
- `sqlite_inserted_or_updated=7008`
- `canonical_snapshot_rows_exported=4805`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## E2E

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py --manifest docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_manifest.json --output-json docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_e2e_validation.json --output-md docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: `5/5`
- SQLite Hermes cache: `5/5`
- Canonical snapshot fallback: `5/5`
- Runtime `get_card_effect`: `5/5`
- Battle execution no-override gate: `pass`

## Focused Tests

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `154` tests passed.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `86` tests passed.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests passed.

## Post-Apply Queue Reduction

- All-card readiness: `battle_and_oracle_ready=2347`, `battle_family_mapper_required=30200`, `snapshot_has_verified_rule=3495`.
- Authoritative queue: `target_identity_count=27277`, `xmage_authoritative_source_count=26963`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26963`.
- `recursion::xmage_graveyard_return_variant_review_v1`: `1964 -> 1959`.
- Existing supported splitter recheck: `proposal_count=0` over `7984` considered supported rows.

## Final Audits

- XMage strategy consistency: `pass` (`26/26` checks).
- Operational surface alignment: `pass`.
- PG/Hermes/SQLite contract: `pass`, with inherited warning `trusted_executable_rules_missing_oracle_hash=1418` for old executable rows. PG328 rows have `5/5` matching Oracle hashes.
- Legacy contamination: `pass`.
