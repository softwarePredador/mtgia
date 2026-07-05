# PG244 Lorehold Ghostly Prison Deck Swap Package

- Deploy ID: `PG244`
- Target PostgreSQL deck: `528c877f-f829-4207-95e6-73981776c323`
- Hermes deck id: `6`
- Proposed row change: `Promise of Loyalty` -> `Ghostly Prison`
- Status: `prepared_read_only_pg_already_promoted_no_apply`
- Apply guard: exact 100-card deck shape, one Promise row, zero Ghostly rows,
  Ghostly Prison Commander legality/color identity, verified attack-tax runtime
  rule, and empty PG244 backup table.
- Rollback guard: exactly one PG244 backup row and current Ghostly-over-Promise
  state before restoring the original deck_card row.

Files:

- `pg244_lorehold_ghostly_prison_deck_swap_precheck.sql`
- `pg244_lorehold_ghostly_prison_deck_swap_apply.sql`
- `pg244_lorehold_ghostly_prison_deck_swap_rollback.sql`
- `pg244_lorehold_ghostly_prison_deck_swap_postcheck.sql`
- `pg244_lorehold_ghostly_prison_deck_swap_manifest.json`

No SQL in this package should be executed without an explicit operator command
for the exact file and target database.
