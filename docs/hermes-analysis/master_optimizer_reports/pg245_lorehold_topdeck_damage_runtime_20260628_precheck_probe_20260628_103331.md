# PG245 PostgreSQL Connectivity Probe

Generated at: `2026-06-28T10:33:31Z`

Status: `postgres_unreachable_pg_isready_no_response`

Read-only evidence. `mutations_performed=[]`.

- Deploy: `PG245` / `lorehold_topdeck_damage_runtime`
- Target: `143.198.230.247:5433/halder`
- Attempted command: `pg_isready -h 143.198.230.247 -p 5433 -d halder`
- Result: `143.198.230.247:5433 - no response`
- Selected cards: `["Twinflame Tyrant", "Verge Rangers"]`

Next required sequence:

- rerun `pg_isready` until PostgreSQL responds
- run `pg245_lorehold_topdeck_damage_runtime_20260628_precheck.sql`
- only apply `pg245_lorehold_topdeck_damage_runtime_20260628_apply.sql` if precheck returns a matched card row for every proposed card
- run postcheck
- sync PostgreSQL `card_battle_rules` back into Hermes SQLite
- rerun focused runtime/family tests and affected battle gates
