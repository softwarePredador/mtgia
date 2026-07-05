# PG467 XMage Creature ETB Library Search Battlefield Apply Evidence

Status: `closed`.

PG467 promoted creature enter-the-battlefield library search to battlefield
rules into `xmage_creature_etb_library_search_to_battlefield_v1` using local
XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg467`
- Family: `xmage_creature_etb_library_search_to_battlefield`
- Battle model scope: `xmage_creature_etb_library_search_to_battlefield_v1`
- Selected cards: `6`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Target | Count | Destination | Enters tapped |
| --- | --- | --- | --- | --- |
| `Farhaven Elf` | `basic_land_to_battlefield` | `1` | `battlefield` | `true` |
| `Kor Cartographer` | `plains_to_battlefield` | `1` | `battlefield` | `true` |
| `Ondu Giant` | `basic_land_to_battlefield` | `1` | `battlefield` | `true` |
| `Quandrix Cultivator` | `basic_forest_or_island_to_battlefield` | `1` | `battlefield` | `false` |
| `Quirion Trailblazer` | `basic_land_to_battlefield` | `1` | `battlefield` | `true` |
| `Wild Wanderer` | `basic_land_to_battlefield` | `1` | `battlefield` | `true` |

## Evidence

- Focused tests: `718` checks passed, including exact-scope extraction,
  runtime lookup, and package generation.
- Precheck: `6` target rows, `0` missing targets, `0` existing expected rows,
  and `2` stale generated shadow rows to deprecate.
- Apply: transaction committed, `6` rule rows upserted.
- Postcheck: `6` verified/auto rows and `6` oracle hash rows.
- Direct PostgreSQL verification: `6` rows with exact trigger, target,
  destination, count, tapped flag, source, execution status, and Oracle hash.
- Sync: `4486` SQLite rows inserted/updated; `4461` canonical snapshot rows
  exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime
  lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy
  contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26078`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG467 safe batch proposals: `53`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg467_xmage_creature_etb_library_search_battlefield_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg467_xmage_creature_etb_library_search_battlefield_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg467_xmage_creature_etb_library_search_battlefield_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg467_creature_etb_library_search_battlefield_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg467_creature_etb_library_search_battlefield_new_server_recheck.md`
