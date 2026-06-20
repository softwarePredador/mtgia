# PG-002 Learned-Deck Metadata Canonicalization Package - 2026-06-20

Status: applied and validated
Owner: Auditor Central / single operator

## Scope

- Table: `commander_learned_decks`
- Column: `metadata`
- Rows in package: `59`
- Mutation type: JSON metadata replacement with canonical metadata computed by
  `server/bin/canonicalize_learned_deck_metadata.dart`
- Deck swaps: none
- PostgreSQL writes executed in this package cycle: `UPDATE 59`, committed at
  `2026-06-20 08:32 -0300`

## Source Artifact

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`

Dry-run summary:

- `status=PASS`
- `mode=dry_run`
- `db_mutations=false`
- `chunk_count=6`
- `checked=60`
- `reported=60`
- `changed=59`
- `applied=0`
- `learned_deck:82` / `Lorehold, the Historian`: `changed=false`

## SQL Package

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`

## Precheck Evidence

Command executed, SELECT-only:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql
```

Result:

```text
expected_rows=59
matched_rows=59
before_matches=59
already_after_rows=0
would_change_rows=59
active_matches=59
```

## Apply Command - Executed

Executed in the Auditor Central thread after Rafael switched this thread to
single-operator deploy ownership:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql
```

## Rollback Command - Only If Needed After Apply

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql
```

## Postcheck Command - Required After Apply

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql
```

Postcheck result:

```text
expected_rows=59
matched_rows=59
after_matches=59
still_before_rows=0
active_matches=59
all_post_apply_checks_ok=true
```

## Validation

- Auditor Central package reconciliation at `2026-06-20 08:26 -0300`:
  - dry-run artifact has `60` total results and `59` rows with `changed=true`;
  - precheck/apply/rollback/postcheck SQL each contain the same `59` unique
    `(row_id, source_ref)` pairs;
  - all `59` SQL pairs exactly match the dry-run `changed=true` set;
  - live SELECT-only precheck still returns `expected_rows=59`,
    `matched_rows=59`, `before_matches=59`, `already_after_rows=0`,
    `would_change_rows=59`, and `active_matches=59`.
- `cd server && dart analyze bin/canonicalize_learned_deck_metadata.dart test/canonicalize_learned_deck_metadata_cli_test.dart`
  - result: no issues found
- `cd server && dart test test/canonicalize_learned_deck_metadata_cli_test.dart -r expanded`
  - result: `3/3` tests passed
- `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  - result: `21` tests passed
- JSON validation:
  `python3 -m json.tool docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
  - result: valid JSON
- Apply result:
  - `UPDATE 59`
  - `COMMIT`
- Post-apply canonicalizer dry-run:
  - command: `dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --limit=60 --progress`
  - result: `status=PASS`, `db_mutations=false`, `checked=60`,
    `reported=0`, `changed=0`, `applied=0`
- Post-apply learned-deck coherence audit:
  - `active_learned_decks=60`
  - severity `high=2`, `medium=13`
  - `commander_deck_quantity_mismatch=1`, `commander_quantity_mismatch=1`
  - `land_count_high_review=1`, `land_count_low_review=7`
  - `some_core_metadata_zero=5`

## Decision

PG-002 is applied and validated. Do not re-run the apply SQL unless a future
SELECT proves rollback or drift. Keep rollback SQL as emergency evidence.
