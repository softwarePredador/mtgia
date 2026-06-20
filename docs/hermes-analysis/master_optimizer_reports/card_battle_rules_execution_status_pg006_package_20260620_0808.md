# PG-006 Package - card_battle_rules execution_status migration drift

Prepared: 2026-06-20 08:08 -0300
Owner: Auditor Central / single operator
Status: applied and validated

## Scope

- Table: `card_battle_rules`
- Column: `execution_status`
- Migration record: `schema_migrations.version='029'`
- Constraint: `chk_card_battle_rules_execution_status`
- Rollback support table:
  `manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808`

No deck swaps, commits, pushes, or battle-rule promotions are part of this
package.

## Read-only evidence

- `dart run bin/migrate.dart --status` reports migration `029
  add_card_battle_rules_execution_status` as pending.
- Live `card_battle_rules.execution_status` already exists as `NOT NULL` with
  default `'auto'::text`.
- The live database has no
  `chk_card_battle_rules_execution_status` constraint.
- Live counts before apply:
  - `execution_status=auto`: `3721`
  - `execution_status=review_only`: `1467`
  - `generated / needs_review / auto`: `1970`
  - `generated / needs_review / review_only`: `1467`
- Current `server/lib/ai/candidate_quality_data_support.dart` defines
  `card_intelligence_snapshot.battle_rules` JSON with `execution_status`, but
  the live view definition does not mention `execution_status` before PG-006.
- Auditor Central source/package validation at `2026-06-20 08:21 -0300`:
  `optimizeCandidateQualitySummaryViewStatement` and
  `cardIntelligenceSnapshotViewStatement` both match the SQL embedded in the
  PG-006 apply package after whitespace normalization.
- Migration 029's built-in `UPDATE` only changes rows where
  `execution_status IS NULL OR execution_status = ''`. Because the current
  drift rows are already `auto`, running the native migration now would add the
  missing constraint and migration record but would not normalize those `1970`
  `needs_review` rows.

## Files

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`

## Precheck command

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql
```

## Apply command

Executed in the Auditor Central thread at `2026-06-20 08:30 -0300` after
Rafael switched this thread to single-operator deploy ownership:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql
```

Expected apply effect:

- Create rollback support schema/table if missing.
- Capture the pre-apply statuses for rows being normalized.
- Normalize current `needs_review` rows to `execution_status='review_only'`.
- Add `chk_card_battle_rules_execution_status`.
- Refresh `optimize_candidate_quality_summary` and `card_intelligence_snapshot`
  using the current backend view definitions.
- Record migration `029` in `schema_migrations`.

Expected row count from the current precheck: `1970` normalized rows.

Actual apply result:

- `COMMIT`
- `normalized_rows=1970`
- rollback backup inserted `1970` rows into
  `manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808`
- migration `029` inserted

## Postcheck command

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql
```

Postcheck must show:

- migration `029` recorded;
- `chk_card_battle_rules_execution_status` present;
- `remaining_needs_review_not_review_only=0`;
- backup row count equals the apply-normalized row count.
- `card_intelligence_snapshot` view definition mentions `execution_status`.

Actual postcheck result:

- migration `029` recorded;
- `chk_card_battle_rules_execution_status` present;
- `execution_status_counts={"auto":1751,"review_only":3437}`;
- `generated / needs_review / review_only = 3437`;
- `remaining_needs_review_not_review_only=0`;
- `rollback_backup_rows=1970`;
- `card_intelligence_snapshot_view.mentions_execution_status=true`;
- `dart run bin/migrate.dart --status` reports `29/29` migrations executed.

## Rollback command

Run only after explicit Rafael approval for rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql
```

Rollback restores statuses from the deploy audit backup table, removes the
execution-status check constraint, and removes the migration `029` record.

Rollback boundary:

- It restores row values and reopens migration `029`.
- It does not revert the refreshed view definitions. The current backend source
  expects `execution_status` inside `card_intelligence_snapshot.battle_rules`,
  and the `execution_status` column remains present after rollback.
