# PG406 PostgreSQL Apply Evidence

- Generated at: `2026-07-04T13:04:51.126113+00:00`
- Database: `127.0.0.1:15432/halder`
- Mutations performed: `["postgres_apply_pg406_tutor_to_hand_new_server"]`

## Apply

`{"backup_rows": 14, "backup_table": "manaloom_deploy_audit.pg406_tutor_to_hand_new_server_20260704_130304", "deprecated_shadow_rows": 14, "manual_apply_command": "psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_apply.sql", "upserted_rows": 35}`

## Precheck Before Apply

`{"cards": ["Borderland Ranger", "Call the Gatewatch", "Cateran Summons", "Civic Wayfinder", "Daru Cavalier", "Deadeye Quartermaster", "Diabolic Tutor", "District Guide", "Eerie Procession", "Environmental Scientist", "Farfinder", "Gatecreeper Vine", "Goblin Matron", "Heliod's Pilgrim", "Howling Wolf", "Ignite the Beacon", "Merchant Scroll", "Nesting Wurm", "Open the Armory", "Plea for Guidance", "Ranger of Eos", "Rune-Scarred Demon", "Safewright Quest", "Sarkhan's Triumph", "Screaming Seahawk", "Seek the Horizon", "Skyshroud Sentinel", "Solve the Equation", "Squadron Hawk", "Sylvan Ranger", "Time of Need", "Totem-Guide Hartebeest", "Transit Mage", "Trapmaker's Snare", "Tribute Mage"], "existing_expected_rows_before": 0, "missing_targets": [], "row_count": 35, "source": "manual precheck output captured in Codex session before apply", "total_target_card_rows": 35, "would_deprecate_shadow_rows": 14}`

## Postcheck

`{"backup_rows": 14, "cards": ["Borderland Ranger", "Call the Gatewatch", "Cateran Summons", "Civic Wayfinder", "Daru Cavalier", "Deadeye Quartermaster", "Diabolic Tutor", "District Guide", "Eerie Procession", "Environmental Scientist", "Farfinder", "Gatecreeper Vine", "Goblin Matron", "Heliod's Pilgrim", "Howling Wolf", "Ignite the Beacon", "Merchant Scroll", "Nesting Wurm", "Open the Armory", "Plea for Guidance", "Ranger of Eos", "Rune-Scarred Demon", "Safewright Quest", "Sarkhan's Triumph", "Screaming Seahawk", "Seek the Horizon", "Skyshroud Sentinel", "Solve the Equation", "Squadron Hawk", "Sylvan Ranger", "Time of Need", "Totem-Guide Hartebeest", "Transit Mage", "Trapmaker's Snare", "Tribute Mage"], "failed_cards": [], "promoted_oracle_hash_rows": 35, "promoted_rule_rows": 35, "promoted_verified_auto_rows": 35, "row_count": 35}`
