# PG341 XMage Recursion Auxiliary Spell Wave Apply Evidence

- generated_at: `2026-07-02T00:38:31+00:00`
- db_target: `143.198.230.247:5433/halder`
- sql: `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_apply.sql`
- exit_code: `0`

## stdout

```
BEGIN
CREATE SCHEMA
SELECT 2
DO
 deprecated_shadow_rows 
------------------------
                      2
(1 row)

 upserted_rows 
---------------
             5
(1 row)

COMMIT
```

## stderr

```
psql:docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_apply.sql:3: NOTICE:  schema "manaloom_deploy_audit" already exists, skipping
```
