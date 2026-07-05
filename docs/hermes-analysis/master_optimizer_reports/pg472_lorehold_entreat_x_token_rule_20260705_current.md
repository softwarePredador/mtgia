# PG472 Lorehold Entreat X-Token Rule Package

- Generated at: `2026-07-05T02:31:34Z`
- Status: `auto_rule_package_generated_no_apply_keep_607`
- PostgreSQL writes executed: `False`
- Deck 607 mutated: `False`
- Proposed review status: `verified`
- Proposed execution status: `auto`
- Logical rule key: `battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e`

## Rule Shape

- Effect: `token_maker`
- Scope: `xmage_x_create_creature_tokens_spell_v1`
- Normal cost: `{X}{X}{W}{W}{W}`
- Native miracle cost: `{X}{W}{W}`
- Token count source: `x_value`
- Native miracle runtime: `runtime_executor_v1`

## Generated Files

- `manifest_json`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current.json`
- `markdown`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current.md`
- `precheck_sql`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_precheck.sql`
- `apply_sql`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_apply.sql`
- `rollback_sql`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_rollback.sql`
- `postcheck_sql`: `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_postcheck.sql`

## Decision

- This package is generated as `verified` / `auto`, but it was not applied.
- Normal X-token casting and native miracle XWW casting are covered by runtime tests.
- A natural 607 battle gate is still required before any deck mutation.
