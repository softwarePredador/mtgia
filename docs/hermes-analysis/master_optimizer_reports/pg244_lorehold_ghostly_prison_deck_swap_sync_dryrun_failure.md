# PG244 Sync Dry-Run Failure

- generated_at: `2026-06-27T22:45:45Z`
- command_type: `PG -> Hermes sync dry-run`
- postgres_writes: `false`
- hermes_writes: `false`
- report_generated: `false`

## Result

The dry-run did not complete because PostgreSQL could not allocate a temporary
file:

`psycopg2.errors.DiskFull: could not write to file "base/pgsql_tmp/pgsql_tmp23407.0": No space left on device`

The same session also emitted relation-cache init warnings with `No space left
on device`.

## Interpretation

This is an operational storage issue on the PostgreSQL side, not a Ghostly
Prison rule or deck-shape failure.

The read-only PG244 precheck completed before this and showed the target
PostgreSQL deck already has `Ghostly Prison=1` and `Promise of Loyalty=0`.

Local Hermes `knowledge.db` was checked directly after the failed dry-run:

- deck `6` has `Ghostly Prison=1`
- deck `6` has `Promise of Loyalty=0`
- deck `6` shape is `100` rows and quantity `100`

Next sync attempt should wait until PostgreSQL temporary-file space is cleared.
