# PG463 XMage Creature Dies Gain Life Apply Evidence

Status: `closed`.

PG463 promoted fixed creature dies life-gain triggers into `xmage_creature_dies_gain_life_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg463`
- Family: `xmage_creature_dies_gain_life`
- Battle model scope: `xmage_creature_dies_gain_life_v1`
- Selected cards: `7`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Life gained on dies | Trigger | Keywords |
| --- | --- | --- | --- |
| `Anodet Lurker` | `3` | `dies` | `None` |
| `Enatu Golem` | `4` | `dies` | `None` |
| `Grasping Longneck` | `2` | `dies` | `['reach']` |
| `Guardian Automaton` | `3` | `dies` | `None` |
| `Highland Game` | `2` | `dies` | `None` |
| `Onulet` | `2` | `dies` | `None` |
| `Tarpan` | `1` | `dies` | `None` |

## Evidence

- Precheck: `7` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `7` rule rows upserted.
- Postcheck: `7` verified/auto rows and `7` oracle hash rows.
- Direct PostgreSQL verification: `7` rows with complete dies life-gain parameters.
- Sync: `4460` SQLite rows inserted/updated; `4435` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26104`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG463 safe batch proposals: `79`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg463_xmage_creature_dies_gain_life_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg463_xmage_creature_dies_gain_life_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg463_xmage_creature_dies_gain_life_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg463_creature_dies_gain_life_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg463_creature_dies_gain_life_new_server_recheck.md`
