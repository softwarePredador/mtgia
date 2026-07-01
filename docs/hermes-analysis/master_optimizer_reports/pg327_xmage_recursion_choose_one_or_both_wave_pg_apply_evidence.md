# PG327 XMage Recursion Choose-One-Or-Both Wave - PostgreSQL Apply Evidence

- Generated at: `2026-07-01T20:08:37Z`
- Deploy id: `PG327`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_manifest.json`
- Selected cards: `Aid the Fallen`, `Fortuitous Find`, `Grim Discovery`, `Remember the Fallen`, `Reviving Melody`, `Season of Renewal`, `Survivors' Bond`
- Exact scope: `xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1`

## Precheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_precheck.sql`

- Target rows found: `7/7`
- Expected rule rows before apply: `0`
- Shadow rows scheduled for deprecation: `0`

| Card | Target rows | Expected rows before | Shadow rows |
| --- | ---: | ---: | ---: |
| `Aid the Fallen` | 1 | 0 | 0 |
| `Fortuitous Find` | 1 | 0 | 0 |
| `Grim Discovery` | 1 | 0 | 0 |
| `Remember the Fallen` | 1 | 0 | 0 |
| `Reviving Melody` | 1 | 0 | 0 |
| `Season of Renewal` | 1 | 0 | 0 |
| `Survivors' Bond` | 1 | 0 | 0 |

## Apply

`psql -f docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_apply.sql`

- Transaction: `COMMIT`
- `deprecated_shadow_rows=0`
- `upserted_rows=7`

## Postcheck

`psql -f docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_postcheck.sql`

| Card | Promoted rows | Verified/auto rows | Matching oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Aid the Fallen` | 1 | 1 | 1 | 0 |
| `Fortuitous Find` | 1 | 1 | 1 | 0 |
| `Grim Discovery` | 1 | 1 | 1 | 0 |
| `Remember the Fallen` | 1 | 1 | 1 | 0 |
| `Reviving Melody` | 1 | 1 | 1 | 0 |
| `Season of Renewal` | 1 | 1 | 1 | 0 |
| `Survivors' Bond` | 1 | 1 | 1 | 0 |

## PG -> Hermes/SQLite Sync

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --export-canonical-fallback-json docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --report docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_pg_to_sqlite_sync.json`

- `pg_rows_loaded=7209`
- `sqlite_inserted_or_updated=7003`
- `canonical_snapshot_rows_exported=4800`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## E2E

`python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py --manifest docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_manifest.json --output-json docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_e2e_validation.json --output-md docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: `7/7`
- SQLite Hermes cache: `7/7`
- Canonical snapshot fallback: `7/7`
- Runtime `get_card_effect`: `7/7`
- Battle execution no-override gate: `pass`

## Focused Tests

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `152` tests passed.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `84` tests passed.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests passed.

## Post-Apply Queue Reduction

- All-card readiness: `battle_and_oracle_ready=2342`, `battle_family_mapper_required=30205`, `snapshot_has_verified_rule=3490`.
- Authoritative queue: `target_identity_count=27282`, `xmage_authoritative_source_count=26968`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26968`.
- `recursion::xmage_graveyard_return_variant_review_v1`: `1971 -> 1964`.
- Existing supported splitter recheck: `proposal_count=0` over `7989` considered supported rows.

## Final Audits

- XMage strategy consistency: `pass` (`26/26` checks).
- Operational surface alignment: `pass`.
- PG/Hermes/SQLite contract: `pass`, with inherited warning `trusted_executable_rules_missing_oracle_hash=1418` for old executable rows. PG327 rows have `7/7` matching Oracle hashes.
- Legacy contamination: `pass`.
