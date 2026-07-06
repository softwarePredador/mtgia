# PG572 Activated Life Gain Sacrifice Target E2E

- Generated at: `2026-07-06T20:58:00+00:00`
- Database target: `127.0.0.1:15432/halder`
- Scope: `xmage_permanent_simple_activated_life_gain_v1`
- Cards: `Claws of Gix`, `Dark Heart of the Wood`, `Gutless Ghoul`, `Overgrown Estate`, `Ravenous Baloth`, `Starved Rusalka`

## Runtime Validation

- `py_compile` passed for the splitter, runtime, zone-transition tests, and split unittest file.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py` passed `663` tests.
- `server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` passed with exit code `0`.
- Focused runtime coverage includes `test_claws_of_gix_life_gain_sacrifices_target_permanent_cost` and `test_ravenous_baloth_life_gain_sacrifices_beast_only`.

## PostgreSQL And Sync Validation

- Package precheck found `6/6` target card rows, `0` existing expected rows, and `0` shadow rows to deprecate.
- PostgreSQL apply promoted `6/6` rows with `review_status=verified`, `execution_status=auto`, and `6/6` Oracle hashes.
- PG -> Hermes/SQLite sync loaded `6` PostgreSQL rows, updated `6` SQLite rows, and exported `6611` canonical snapshot rows.
- Post-sync queue moved from `target_identity_count=25387` to `25381` and from `xmage_authoritative_source_count=25073` to `25067`.
- Post-sync exact-scope recheck returned `proposal_count=0` and `safe_for_batch_pg_package_count=0`.

## Residual Boundary

PG572 does not authorize activated life-gain rows with discard, exile-from-graveyard, tap-another-permanent, dynamic life gain, non-simple Oracle text, or unsupported sacrifice target filters. Those remain blocked under exact split reason counts and need their own mapper/runtime package.
