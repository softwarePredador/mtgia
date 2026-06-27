# PG244 Lorehold Ghostly Prison Deck Swap Package

Status: `prepared_read_only_pg_already_promoted_no_apply`.

This package promotes the battle-validated Lorehold pressure swap:
`Ghostly Prison` over `Promise of Loyalty` for the PostgreSQL materialized
Lorehold deck linked to Hermes `deck_id=6`.

No PostgreSQL mutation was performed by this package. The read-only live
precheck shows the PostgreSQL deck already has the target state:
`Promise of Loyalty=0`, `Ghostly Prison=1`, `ready_to_apply=false`.

## Evidence

- Decision report: `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_decision_20260627.md`
- Integration gate: `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721_ghostly_prison_pressure_cut_promise.md`
- Aggregate controlled gates: baseline `13/59/0`, candidate `27/45/0`, delta `+19.44pp`.
- Instrumented gate: `Ghostly Prison` restricted `20` attackers and charged `52` total attack tax.
- Runtime rule guard: `battle_rule_v1:99151859bece89ba3ead032e05b1f65a`, oracle hash `5725b39ca4bb7c5e8e4bebf0d246be13`, verified/auto `attack_tax` for `2` per attacking creature.

## Files

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_manifest.json`
- precheck output: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_precheck.out`
- precheck error: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_precheck.err`
- sync dry-run failure: `docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_sync_dryrun_failure.md`

## Live Precheck Result

Read-only precheck ran successfully against PostgreSQL on `2026-06-27`.

- deck: `Runtime Lorehold Learned 19e93de3cca`
- deck shape: `100` rows, quantity `100`
- `Promise of Loyalty`: `0`
- `Ghostly Prison`: `1`
- `Ghostly Prison` verified rule rows: `1`
- existing PG244 backup table: `0`
- `ready_to_apply`: `false`

Interpretation: do not run `apply` now. The source deck is already in the
target state, and the guarded apply is intentionally blocked because it only
supports the old exact pre-state.

The precheck stderr contains PostgreSQL warnings about disk space while creating
relation-cache init files. The query still returned the expected row.

## Sync Status

PG -> Hermes dry-run was attempted after the precheck, but PostgreSQL failed
while creating a temporary file with `No space left on device`. No Hermes write
was requested and no sync report was produced.

Local Hermes `knowledge.db` was checked directly after that failure:

- deck `6` has `Ghostly Prison=1`
- deck `6` has `Promise of Loyalty=0`
- deck shape is `100` rows, quantity `100`

## Apply Gate

Do not run apply for the current live state. If a future precheck shows
`ready_to_apply = t`, the required sequence after explicit approval is:

1. Read-only precheck:
   `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_precheck.sql`
2. Apply only if `ready_to_apply = t`:
   `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_apply.sql`
3. Postcheck:
   `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_postcheck.sql`
4. PG to Hermes sync:
   `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --pg-deck-id 528c877f-f829-4207-95e6-73981776c323 --target-deck-id 6 --apply --report docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_sync_report.json`
5. Affected coherence audit and focused battle smoke.

Rollback command if postcheck fails after apply:

`psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg244_lorehold_ghostly_prison_deck_swap_rollback.sql`

## Guard Summary

- Target PG deck: `528c877f-f829-4207-95e6-73981776c323`.
- Requires commander deck shape `100` rows and quantity `100`.
- Requires exactly one non-commander `Promise of Loyalty` row.
- Requires no existing `Ghostly Prison` row before apply.
- Requires `Ghostly Prison` to be Commander-legal, white color identity, and backed by the verified auto attack-tax rule.
- Refuses reapply if backup table already exists.
