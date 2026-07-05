# PG465 XMage Static Cast Flash Permission Apply Evidence

Status: `closed`.

PG465 promoted static cast-as-though-flash permission permanents into `xmage_static_cast_spells_as_flash_permission_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg465`
- Family: `xmage_static_cast_spells_as_flash_permission`
- Battle model scope: `xmage_static_cast_spells_as_flash_permission_v1`
- Selected cards: `7`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Filter | Controller | Any player | Keywords |
| --- | --- | --- | --- | --- |
| `High Fae Trickster` | `nonland_spells` | `self` | `false` | `['flash', 'flying']` |
| `Hypersonic Dragon` | `sorcery_spells` | `self` | `false` | `['flying', 'haste']` |
| `Quick Sliver` | `sliver_spells` | `any_player` | `true` | `['flash']` |
| `Raff Capashen, Ship's Mage` | `historic_spells` | `self` | `false` | `['flash', 'flying']` |
| `Shimmer Myr` | `artifact_spells` | `self` | `false` | `['flash']` |
| `Vernal Equinox` | `creature_or_enchantment_spells` | `any_player` | `true` | `None` |
| `Yeva, Nature's Herald` | `green_creature_spells` | `self` | `false` | `['flash']` |

## Evidence

- Precheck: `7` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `7` rule rows upserted.
- Postcheck: `7` verified/auto rows and `7` oracle hash rows.
- Direct PostgreSQL verification: `7` rows with complete flash-permission filters, controller scope, any-player flag, and keyword parameters.
- Sync: `4474` SQLite rows inserted/updated; `4449` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass` after stale SQLite cleanup, PG/Hermes/SQLite contract `pass` after stale SQLite cleanup.
- Cleanup: removed stale zero-byte sibling SQLite artifact `docs/hermes-analysis/manaloom-knowledge/knowledge.db`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26090`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG465 safe batch proposals: `65`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg465_xmage_static_cast_flash_permission_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg465_xmage_static_cast_flash_permission_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg465_xmage_static_cast_flash_permission_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg465_static_cast_flash_permission_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg465_static_cast_flash_permission_new_server_recheck.md`
