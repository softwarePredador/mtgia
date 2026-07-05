# PG461 XMage Fixed Damage Scry Apply Evidence

Status: `closed`.

PG461 promoted fixed-damage-then-scry spells into `xmage_fixed_damage_target_and_scry_spell_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg461`
- Family: `xmage_fixed_damage_scry_spell`
- Battle model scope: `xmage_fixed_damage_target_and_scry_spell_v1`
- Selected cards: `8`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Damage | Target | Scry | Timing | Target constraints |
| --- | ---: | --- | ---: | --- | --- |
| `Bolt of Keranos` | `3` | `any_target` | `1` | `sorcery` | `{'scope': 'any_target'}` |
| `Fateful End` | `3` | `any_target` | `1` | `instant` | `{'scope': 'any_target'}` |
| `Jaya's Firenado` | `5` | `creature_or_planeswalker` | `1` | `sorcery` | `{'card_types': ['creature', 'planeswalker']}` |
| `Jaya's Greeting` | `3` | `creature` | `1` | `instant` | `{'card_types': ['creature']}` |
| `Lightning Javelin` | `3` | `any_target` | `1` | `sorcery` | `{'scope': 'any_target'}` |
| `Magma Jet` | `2` | `any_target` | `2` | `instant` | `{'scope': 'any_target'}` |
| `Piercing Light` | `2` | `creature` | `1` | `instant` | `{'card_types': ['creature'], 'combat_state': 'attacking_or_blocking'}` |
| `Spark Jolt` | `1` | `any_target` | `1` | `instant` | `{'scope': 'any_target'}` |

## Evidence

- Precheck: `8` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `8` rule rows upserted.
- Postcheck: `8` verified/auto rows and `8` oracle hash rows.
- Direct PostgreSQL verification: `8` rows with complete damage+scry parameters.
- Sync: `4445` SQLite rows inserted/updated; `4420` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26119`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG461 safe batch proposals: `94`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg461_fixed_damage_scry_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg461_fixed_damage_scry_new_server_recheck.md`
