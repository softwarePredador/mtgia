\pset pager off

CREATE TEMP TABLE pg086_angels_grace_postcheck AS
SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  cbr.logical_rule_key,
  cbr.oracle_hash,
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

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE oracle_hash = '627c4ce7adf5be44b93e2b850159e5d9') AS target_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' = 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1') AS expected_scope_rows,
  count(*) FILTER (WHERE effect_json->>'oracle_runtime_scope' = 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation') AS expected_runtime_scope_rows,
  count(*) FILTER (WHERE (effect_json->>'split_second')::boolean IS TRUE) AS split_second_annotation_rows,
  count(*) FILTER (WHERE (effect_json->>'opponents_cant_win_this_turn')::boolean IS TRUE) AS opponents_cant_win_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'angel''s grace'
      AND source = 'generated'
      AND execution_status <> 'disabled'
  ) AS non_disabled_shadow_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'angel''s grace'
      AND source = 'generated'
      AND execution_status = 'disabled'
  ) AS disabled_shadow_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg086_deck608_angels_grace_20260623_084922
  ) AS backup_rows
FROM pg086_angels_grace_postcheck;

SELECT
  name,
  logical_rule_key,
  oracle_hash,
  review_status,
  execution_status,
  rule_version,
  effect_json,
  deck_role_json
FROM pg086_angels_grace_postcheck;
