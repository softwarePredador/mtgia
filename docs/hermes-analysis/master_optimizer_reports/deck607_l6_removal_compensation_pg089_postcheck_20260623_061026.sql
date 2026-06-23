\pset pager off

CREATE TEMP TABLE pg089_l6_removal_compensation_target AS
SELECT
  'Generous Gift'::text AS name,
  'generous gift'::text AS normalized_name,
  'battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c'::text AS expected_logical_rule_key,
  '9363edd299df8476da36798bd527cde1'::text AS expected_oracle_hash,
  'destroy_target_permanent_create_3_3_green_elephant_for_controller_v1'::text AS expected_scope,
  'permanent'::text AS expected_target,
  1::integer AS expected_creature_tokens
UNION ALL
SELECT
  'Stroke of Midnight',
  'stroke of midnight',
  'battle_rule_v1:9b50d2f897b561c8c390c9e0e04da417',
  'a885e8190e19cf23b1f4c82563ca111b',
  'destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1',
  'nonland_permanent',
  1;

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE r.oracle_hash = t.expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE r.oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE r.effect_json->>'battle_model_scope' = t.expected_scope) AS target_expected_scope_rows,
  count(*) FILTER (WHERE r.effect_json->>'target' = t.expected_target) AS target_expected_target_rows,
  count(*) FILTER (WHERE (r.effect_json->>'target_controller_creature_tokens')::int = t.expected_creature_tokens) AS target_expected_compensation_rows,
  count(*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE r.rule_version >= 2) AS rule_version_at_least_2_rows
FROM pg089_l6_removal_compensation_target t
JOIN card_battle_rules r
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.expected_logical_rule_key;

SELECT
  count(*) AS non_disabled_shadow_rows
FROM card_battle_rules r
JOIN pg089_l6_removal_compensation_target t
  ON r.normalized_name = t.normalized_name
WHERE r.logical_rule_key <> t.expected_logical_rule_key
  AND r.execution_status <> 'disabled';

SELECT
  count(*) AS disabled_shadow_rows
FROM card_battle_rules r
JOIN pg089_l6_removal_compensation_target t
  ON r.normalized_name = t.normalized_name
WHERE r.logical_rule_key <> t.expected_logical_rule_key
  AND r.execution_status = 'disabled';

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026;

SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json,
  r.review_status,
  r.execution_status,
  r.rule_version
FROM card_battle_rules r
JOIN pg089_l6_removal_compensation_target t
  ON r.normalized_name = t.normalized_name
ORDER BY r.normalized_name, r.execution_status, r.logical_rule_key;
