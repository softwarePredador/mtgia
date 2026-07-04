# PG407 PostgreSQL Apply Evidence

- Generated at: `2026-07-04T13:28:14Z`
- Database: `127.0.0.1:15432/halder`
- Mutations performed: `["postgres_apply_pg407_x_damage_new_server"]`

## Apply

`{"backup_rows": 0, "backup_table": "manaloom_deploy_audit.pg407_x_damage_new_server_package_20260704_132533", "deprecated_shadow_rows": 0, "manual_apply_command": "psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg407_x_damage_new_server_package_apply.sql", "upserted_rows": 3}`

## Precheck Before Apply

`{"cards": ["Blaze", "Heat Ray", "Volcanic Geyser"], "existing_expected_rows_before": 0, "missing_targets": [], "row_count": 3, "source": "manual precheck output captured in Codex session before apply", "total_target_card_rows": 3, "would_deprecate_shadow_rows": 0}`

## Postcheck

`{"backup_rows": 0, "cards": ["Blaze", "Heat Ray", "Volcanic Geyser"], "failed_cards": [], "promoted_oracle_hash_rows": 3, "promoted_rule_rows": 3, "promoted_verified_auto_rows": 3, "row_count": 3}`
