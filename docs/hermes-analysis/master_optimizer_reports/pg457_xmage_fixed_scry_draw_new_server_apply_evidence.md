# PG457 XMage Fixed Scry Draw Apply Evidence

Status: `closed`.

PG457 promoted fixed scry/draw instant-or-sorcery cards into `xmage_fixed_scry_and_draw_cards_spell_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg457`
- Family: `xmage_fixed_scry_draw_card_spell`
- Battle model scope: `xmage_fixed_scry_and_draw_cards_spell_v1`
- Selected cards: `9`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Scry | Draw | Resolution order |
| --- | ---: | ---: | --- |
| `Behold the Multiverse` | `2` | `2` | `scry_then_draw` |
| `Deliberate` | `2` | `1` | `scry_then_draw` |
| `Foresee` | `4` | `2` | `scry_then_draw` |
| `Introduction to Prophecy` | `2` | `1` | `scry_then_draw` |
| `Opt` | `1` | `1` | `scry_then_draw` |
| `Preordain` | `2` | `1` | `scry_then_draw` |
| `Scour All Possibilities` | `2` | `1` | `scry_then_draw` |
| `Serum Visions` | `2` | `1` | `draw_then_scry` |
| `Tamiyo's Epiphany` | `4` | `2` | `scry_then_draw` |

## Evidence

- Precheck: `9` target rows, `0` missing targets, `6` stale generated shadow rows to deprecate.
- Apply: transaction committed, `9` rule rows upserted; deprecated generated shadows: `Opt=2, Preordain=2, Serum Visions=2`.
- Postcheck: `9` verified/auto rows and `9` oracle hash rows.
- Direct PostgreSQL verification: `9` rows with complete scry/draw parameters.
- Sync: `4413` SQLite rows inserted/updated; `4388` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26151`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG457 safe batch proposals: `126`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg457_xmage_fixed_scry_draw_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg457_xmage_fixed_scry_draw_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg457_xmage_fixed_scry_draw_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg457_fixed_scry_draw_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg457_fixed_scry_draw_new_server_recheck.md`
