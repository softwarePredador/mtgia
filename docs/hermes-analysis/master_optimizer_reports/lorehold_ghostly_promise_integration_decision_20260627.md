# Lorehold Ghostly Prison Integration Decision

- generated_at: `2026-06-27`
- package: `ghostly_prison_pressure_cut_promise`
- add: `Ghostly Prison`
- cut: `Promise of Loyalty`
- decision: `ready_for_postgresql_apply_package_preparation`
- postgres_writes: `false`
- source_db_mutated: `false`
- hermes_sync: `not_run`

## Decision Summary

`Ghostly Prison` over `Promise of Loyalty` remains positive after the battle
gate was instrumented to attribute attack restrictions to their source
permanent. The current evidence is strong enough to prepare a separate
PostgreSQL apply package for the deck source of truth, but this commit does not
mutate PostgreSQL or Hermes.

The reason for not applying directly is source-of-truth hygiene: battle/Hermes
candidate DBs are laboratory evidence. The live deck mutation must happen in a
separate PostgreSQL package with precheck, exact row target, rollback, apply,
Hermes sync, and post-apply validation.

## Post-Instrumentation Gate

Gate:
`lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721`

- Games: `24` baseline vs `24` candidate.
- Baseline: `6/18/0`, WR `25.00%`.
- Candidate: `8/16/0`, WR `33.33%`.
- Delta: `+8.33pp`.
- Candidate `Ghostly Prison`: `7` cost-paid/cast events, `5` resolved events.
- Baseline `Promise of Loyalty`: `0` cost-paid/cast/resolved events.
- Miracle games: baseline `15/24`, candidate `14/24`.
- Source-attributed pressure:
  - `events=18`
  - `attackers_before=46`
  - `attackers_after=26`
  - `attackers_restricted=20`
  - `tax_paid=52`
  - `source=Ghostly Prison`

The source-attribution metric is the key new proof. It shows that `Ghostly
Prison` was not merely cast; it repeatedly changed combat against Lorehold.

## Aggregate Gate Evidence

Includes the prior three controlled gates plus the post-instrumentation gate.

| Gate | Games | Baseline | Candidate | Delta | Source-attributed pressure |
| --- | ---: | ---: | ---: | ---: | --- |
| `v1_games2_opp8_seed42` | 16 vs 16 | 3/13/0, 18.75% | 7/9/0, 43.75% | +25.00pp | not instrumented |
| `v2_seed7_smoke_opp8` | 8 vs 8 | 1/7/0, 12.50% | 4/4/0, 50.00% | +37.50pp | not instrumented |
| `v3_seed99_games3_opp8` | 24 vs 24 | 3/21/0, 12.50% | 8/16/0, 33.33% | +20.83pp | not instrumented |
| `integration_v2_seed314_games3_opp8` | 24 vs 24 | 6/18/0, 25.00% | 8/16/0, 33.33% | +8.33pp | Ghostly: 20 attackers restricted, 52 tax paid |

Aggregate:

- Baseline: `13/59/0`, WR `18.06%`.
- Candidate: `27/45/0`, WR `37.50%`.
- Aggregate delta: `+19.44pp`.
- No stalls in the completed gates.

## Operational Note

A larger `5x8` integration gate was attempted with
`lorehold_ghostly_promise_integration_gate_20260627_v1_seed314_games5_opp8`,
but it did not complete within the interactive window and was interrupted after
more than three minutes with no final artifact. Its temporary candidate DB
directory was removed. The completed `3x8` post-instrumentation gate is the
current accepted integration evidence.

## Acceptance Criteria Status

- Win-rate gate remains positive: `pass`.
- Miracle plan did not collapse: `pass`.
- Runtime source attribution exists: `pass`.
- `Ghostly Prison` source restricted meaningful attackers: `pass`.
- PostgreSQL mutation prepared/applied: `not_applied`.
- Hermes sync after PostgreSQL mutation: `not_run`.

## Next Step

Prepare a PostgreSQL apply package that swaps `Promise of Loyalty` to `Ghostly
Prison` for the relevant Lorehold source deck, with:

- precheck proving the exact deck/card rows to change;
- rollback SQL;
- apply SQL;
- expected row counts;
- Hermes sync from PostgreSQL after apply;
- post-sync battle smoke confirming the live deck now contains `Ghostly Prison`
  and still passes the pressure gate.
