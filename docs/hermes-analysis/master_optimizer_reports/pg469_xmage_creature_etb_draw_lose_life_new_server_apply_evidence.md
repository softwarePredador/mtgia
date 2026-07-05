# PG469 XMage Creature ETB Draw Lose Life Apply Evidence

Status: `closed`.

PG469 promoted creature enter-the-battlefield draw and lose life rules into
`xmage_creature_etb_draw_lose_life_v1` using local XMage source as the
behavioral authority.

## Scope

- Deploy ID: `pg469`
- Family: `xmage_creature_etb_draw_lose_life`
- Battle model scope: `xmage_creature_etb_draw_lose_life_v1`
- Selected cards: `4`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Trigger | Draw | Life loss |
| --- | --- | --- | --- |
| `Dusk Legion Zealot` | `enters_battlefield` | `1` | `1` |
| `Phyrexian Gargantua` | `enters_battlefield` | `2` | `2` |
| `Phyrexian Rager` | `enters_battlefield` | `1` | `1` |
| `Tithebearer Giant` | `enters_battlefield` | `1` | `1` |

## Evidence

- Focused tests: `718` checks passed, including exact-scope extraction,
  ETB draw/life-loss runtime lookup, fixed amount preservation, and package
  generation.
- Precheck: `4` target rows, `0` missing targets, `0` existing expected rows,
  and `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `4` rule rows upserted.
- Postcheck: `4` verified/auto rows and `4` oracle hash rows.
- Direct PostgreSQL verification: `4` rows with exact ETB trigger, draw count,
  life-loss count, source, execution status, and Oracle hash.
- Sync: `4495` SQLite rows inserted/updated; `4470` canonical snapshot rows
  exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime
  lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy
  contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26069`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG469 safe batch proposals: `44`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg469_xmage_creature_etb_draw_lose_life_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg469_xmage_creature_etb_draw_lose_life_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg469_xmage_creature_etb_draw_lose_life_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg469_creature_etb_draw_lose_life_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg469_creature_etb_draw_lose_life_new_server_recheck.md`
