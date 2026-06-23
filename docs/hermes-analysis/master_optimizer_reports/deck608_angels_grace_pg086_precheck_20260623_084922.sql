\pset pager off

CREATE TEMP TABLE pg086_angels_grace_target AS
SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  '627c4ce7adf5be44b93e2b850159e5d9'::text AS expected_oracle_hash,
  cbr.logical_rule_key,
  cbr.oracle_hash AS current_rule_oracle_hash,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version,
  cbr.effect_json,
  cbr.deck_role_json
FROM cards c
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE c.name = 'Angel''s Grace'
  AND cbr.normalized_name = 'angel''s grace'
  AND cbr.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

WITH
shadow AS (
  SELECT count(*) AS generated_shadow_rows
  FROM card_battle_rules
  WHERE normalized_name = 'angel''s grace'
    AND source = 'generated'
    AND execution_status <> 'disabled'
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE computed_oracle_hash = expected_oracle_hash) AS oracle_hash_match_rows,
  count(*) FILTER (WHERE current_rule_oracle_hash IS NULL OR current_rule_oracle_hash = '') AS missing_rule_hash_rows,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' IS NULL) AS missing_scope_rows,
  (SELECT generated_shadow_rows FROM shadow) AS generated_shadow_rows,
  to_regclass('manaloom_deploy_audit.pg086_deck608_angels_grace_20260623_084922') IS NOT NULL AS backup_table_already_exists
FROM pg086_angels_grace_target;

SELECT
  name,
  type_line,
  mana_cost,
  computed_oracle_hash,
  expected_oracle_hash,
  logical_rule_key,
  current_rule_oracle_hash,
  review_status,
  execution_status,
  rule_version,
  effect_json,
  deck_role_json
FROM pg086_angels_grace_target;
