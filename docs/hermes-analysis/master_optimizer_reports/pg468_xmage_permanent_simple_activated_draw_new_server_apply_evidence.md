# PG468 XMage Permanent Simple Activated Draw Apply Evidence

Status: `closed`.

PG468 promoted permanent simple activated draw rules into
`xmage_permanent_simple_activated_draw_v1` using local XMage source as the
behavioral authority.

## Scope

- Deploy ID: `pg468`
- Family: `xmage_permanent_simple_activated_draw`
- Battle model scope: `xmage_permanent_simple_activated_draw_v1`
- Selected cards: `5`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Mana cost | Requires tap | Discard cost | Draw |
| --- | --- | --- | --- | --- |
| `Goblin Picker` | `{R}` | `true` | `1` | `1` |
| `Mental Discipline` | `{1}{U}` | `false` | `1` | `1` |
| `Merchant of the Vale // Haggle` | `{2}{R}` | `false` | `1` | `1` |
| `Oread of Mountain's Blaze` | `{2}{R}` | `false` | `1` | `1` |
| `Rummaging Goblin` | `{0}` | `true` | `1` | `1` |

## Evidence

- Focused tests: `718` checks passed, including exact-scope extraction,
  activated draw runtime lookup, activation cost fields, discard cost fields,
  and package generation.
- Precheck: `5` target rows, `0` missing targets, `0` existing expected rows,
  and `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `5` rule rows upserted.
- Postcheck: `5` verified/auto rows and `5` oracle hash rows.
- Direct PostgreSQL verification: `5` rows with exact activated draw count,
  activation mana cost, tap requirement, discard count, source, execution
  status, and Oracle hash.
- Sync: `4491` SQLite rows inserted/updated; `4466` canonical snapshot rows
  exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime
  lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy
  contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26073`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG468 safe batch proposals: `48`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg468_xmage_permanent_simple_activated_draw_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg468_xmage_permanent_simple_activated_draw_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg468_xmage_permanent_simple_activated_draw_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg468_permanent_simple_activated_draw_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg468_permanent_simple_activated_draw_new_server_recheck.md`
