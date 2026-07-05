# PG459 XMage Creature Dies Fixed Damage Apply Evidence

Status: `closed`.

PG459 promoted creature dies fixed-damage triggers into `xmage_creature_dies_fixed_damage_target_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg459`
- Family: `xmage_creature_dies_fixed_damage_target`
- Battle model scope: `xmage_creature_dies_fixed_damage_target_v1`
- Selected cards: `8`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Damage | Target | Optional | Target constraints |
| --- | ---: | --- | --- | --- |
| `Bogardan Firefiend` | `2` | `creature` | `None` | `{'card_types': ['creature']}` |
| `Careless Celebrant` | `2` | `creature_or_planeswalker` | `None` | `{'card_types': ['creature', 'planeswalker']}` |
| `Footlight Fiend` | `1` | `any_target` | `None` | `{'scope': 'any_target'}` |
| `Goblin Arsonist` | `1` | `any_target` | `True` | `{'scope': 'any_target'}` |
| `Mudbutton Torchrunner` | `3` | `any_target` | `None` | `{'scope': 'any_target'}` |
| `Perilous Myr` | `2` | `any_target` | `None` | `{'scope': 'any_target'}` |
| `Pitchburn Devils` | `3` | `any_target` | `None` | `{'scope': 'any_target'}` |
| `Pyre Spawn` | `3` | `any_target` | `None` | `{'scope': 'any_target'}` |

## Evidence

- Precheck: `8` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `8` rule rows upserted.
- Postcheck: `8` verified/auto rows and `8` oracle hash rows.
- Direct PostgreSQL verification: `8` rows with complete dies-damage parameters.
- Sync: `4429` SQLite rows inserted/updated; `4404` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26135`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG459 safe batch proposals: `110`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg459_xmage_creature_dies_fixed_damage_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg459_xmage_creature_dies_fixed_damage_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg459_xmage_creature_dies_fixed_damage_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg459_creature_dies_fixed_damage_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg459_creature_dies_fixed_damage_new_server_recheck.md`
