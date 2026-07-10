# PG724 Face of Fear And Hash Backfill Evidence - 2026-07-10

Status: `closed`

Database target: `127.0.0.1:15432/halder` through
`./server/bin/with_new_server_pg.sh`.

## Scope

PG724 promotes the next safe exact-scope candidate found after PG723:

- `Face of Fear`
- family: `xmage_permanent_simple_activated_self_keyword_until_eot`
- scope: `xmage_permanent_simple_activated_self_keyword_until_eot_v1`
- behavior: `{2}{B}, discard a card`: this creature gains fear until end of
  turn.

PG724B is a companion contract fix. After PG724, the PG/Hermes contract exposed
55 older trusted executable rows with missing `oracle_hash`. All 55 were
fillable from `cards.oracle_text` by existing `card_id`, so PG724B backfilled
them with backup and rollback SQL.

## PG724 PostgreSQL Package

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_rollback.sql`

Precheck:

- target rows found by Oracle hash: `1/1`
- existing rule rows before apply: `0`
- shadow rows to deprecate: `0`

Apply:

- deprecated shadow rows: `0`
- upserted rows: `1`
- transaction: `COMMIT`

Postcheck:

- promoted rule rows: `1/1`
- promoted `verified/auto` rows: `1/1`
- promoted matching `oracle_hash` rows: `1/1`
- backup rows: `0`

## PG724 Sync And E2E

PG -> SQLite rule sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_pg_to_sqlite_sync.json`
- PG rows loaded: `1`
- SQLite inserted/updated: `1`
- canonical snapshot rows exported: `7317`

PG metadata -> Hermes sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8264`
- SQLite cache alias rows: `8201`
- deck card backfill: `2699/2699`
- card-id updates applied: `86`
- unresolved metadata aliases: `1` (`Surgical Suite/Hospital Room`), unrelated
  to PG724 and covered by the passing final contract audit.

Final package E2E after hash backfill:

- report: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_e2e_validation_after_hash_backfill.md`
- status: `pass`
- PostgreSQL source-of-truth rows: `1`
- SQLite/Hermes rows: `1`
- canonical snapshot cards: `1`
- runtime `get_card_effect` cards: `1`
- battle execution scenarios: `1`
- replay events: `2`

Battle evidence:

- `Face of Fear` paid `{2}{B}`, discarded `1` card, did not tap, and gained
  `fear` until end of turn.

## PG724B Hash Backfill

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg724b_trusted_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724b_trusted_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724b_trusted_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg724b_trusted_oracle_hash_backfill_new_server_rollback.sql`

Precheck:

- fillable trusted executable missing-hash rows: `55`
- fillable cards: `54`
- fillable identities: `55`
- missing computed hashes: `0`

Apply:

- backup rows: `55`
- backfilled rows: `55`
- transaction: `COMMIT`

Postcheck:

- trusted executable rules still missing `oracle_hash`: `0`
- backup rows: `55`
- updated rows from backup set: `55`
- updated rows with `oracle_hash`: `55`

Sync after backfill:

- report: `docs/hermes-analysis/master_optimizer_reports/pg724b_trusted_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- PG rows loaded: `9917`
- SQLite inserted/updated: `9695`
- canonical snapshot rows exported: `7317`

## Tests

Focused mapper test:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m unittest \
  test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_activated_self_keyword_maps_discard_cost -v
```

Result: `1 test OK`.

Focused E2E runner test:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m pytest test_battle_package_end_to_end_validation.py \
  -k 'simple_activated_self_keyword_runner_executes_keyword_effect' -q
```

Result: `1 passed, 82 deselected`.

Note: one attempted mapper test name did not exist; the correct mapper test
above passed.

## Final Readiness

Report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260710_post_pg724b_hash_backfill_new_server.md`

- all known cards: `34331`
- `snapshot_has_verified_rule`: `6347`
- `snapshot_has_any_rule`: `7523`
- `battle_and_oracle_ready`: `6322`
- `battle_family_mapper_required`: `27554`
- `trusted_rule_oracle_hash_backfill`: absent from lane counts
- ready-product QA cards: `275` ready, `89` mapper-required

Delta from post-PG723:

- `snapshot_has_verified_rule`: `6346 -> 6347`
- `battle_and_oracle_ready`: `6321 -> 6322`
- `battle_family_mapper_required`: `27555 -> 27554`

Authoritative XMage queue:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260710_post_pg724b_hash_backfill_new_server_commander_legal.md`
- target identities: `24631`
- XMage authoritative source count: `24318`
- missing-source exceptions: `313`
- parser gaps: `0`
- adapter-required identities: `24318`
- adapter work units: `11298`

Exact-scope recheck:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260710_post_pg724b_hash_backfill_new_server_recheck.md`
- proposals: `0`
- safe for batch package: `0`

## Final Gates

- `xmage_strategy_consistency_audit`: `pass`, `26/26`
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`

## Current Next Work

There is no remaining safe exact-scope package candidate in the current split.
The next real work is implementing a new subpattern/runtime mapper from the
blocked reason counts, then rebuilding the queue and package. Highest practical
lanes include:

- activated source-cost support for add-counters/self-boost/targeted effects;
- non-simple draw/effect classes where XMage source is resolved;
- mana-source blockers such as conditional mana, pay-life source costs, and
  unsafe ability classes.
