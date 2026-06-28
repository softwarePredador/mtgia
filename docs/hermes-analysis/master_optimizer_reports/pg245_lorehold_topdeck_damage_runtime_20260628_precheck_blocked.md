# PG245 PostgreSQL Precheck Blocked

Generated at: `2026-06-28T01:55:02+00:00`

Status: `postgres_precheck_blocked_connection_closed`

Read-only evidence. `mutations_performed=[]`.

- Deploy: `PG245` / `lorehold_topdeck_damage_runtime`
- Target: `143.198.230.247:5433/halder`
- Attempted file: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_precheck.sql`
- Blocked step: `precheck`
- Sanitized error: `server closed the connection unexpectedly before precheck execution`
- Selected cards: `["Twinflame Tyrant", "Verge Rangers"]`

Next required sequence:

- rerun precheck when PostgreSQL accepts connections
- only apply pg245_lorehold_topdeck_damage_runtime_20260628_apply.sql if precheck returns a matched card row for every proposed card
- run postcheck
- sync PostgreSQL card_battle_rules back into Hermes SQLite
- rerun focused runtime/family tests and affected battle gates
