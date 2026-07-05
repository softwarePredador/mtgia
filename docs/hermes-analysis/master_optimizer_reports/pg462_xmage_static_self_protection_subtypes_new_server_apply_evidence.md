# PG462 XMage Static Self Protection Subtypes Apply Evidence

Status: `closed`.

PG462 promoted static self-protection-from-subtypes creatures into `xmage_static_self_protection_from_subtypes_creature_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg462`
- Family: `xmage_static_self_protection_from_subtypes_creature`
- Battle model scope: `xmage_static_self_protection_from_subtypes_creature_v1`
- Selected cards: `8`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Protected subtypes | Keywords | Target |
| --- | --- | --- | --- |
| `Baneslayer Angel` | `['demon', 'dragon']` | `['flying', 'first_strike', 'lifelink']` | `self/self` |
| `Dragonstalker` | `['dragon']` | `['flying']` | `self/self` |
| `Elite Inquisitor` | `['vampire', 'werewolf', 'zombie']` | `['first_strike', 'vigilance']` | `self/self` |
| `Grave Bramble` | `['zombie']` | `['defender']` | `self/self` |
| `Kitsune Riftwalker` | `['arcane', 'spirit']` | `None` | `self/self` |
| `Midnight Duelist` | `['vampire']` | `None` | `self/self` |
| `Nath's Buffoon` | `['elf']` | `None` | `self/self` |
| `Shoreline Raider` | `['kavu']` | `None` | `self/self` |

## Evidence

- Precheck: `8` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `8` rule rows upserted.
- Postcheck: `8` verified/auto rows and `8` oracle hash rows.
- Direct PostgreSQL verification: `8` rows with complete subtype-protection parameters.
- Sync: `4453` SQLite rows inserted/updated; `4428` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26111`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG462 safe batch proposals: `86`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg462_xmage_static_self_protection_subtypes_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg462_xmage_static_self_protection_subtypes_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg462_xmage_static_self_protection_subtypes_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg462_static_self_protection_subtypes_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg462_static_self_protection_subtypes_new_server_recheck.md`
