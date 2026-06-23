\pset pager off
\set ON_ERROR_STOP on

WITH target_card AS (
  SELECT *
  FROM cards
  WHERE lower(name) = 'winds of abandon'
),
exact_rule AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'winds of abandon'
    AND logical_rule_key = 'battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c'
    AND effect_json->>'effect' = 'remove_creature'
    AND effect_json->>'target' = 'creature'
    AND effect_json->>'target_restriction' = 'you_dont_control'
    AND effect_json->>'target_controller' = 'opponent'
    AND effect_json->>'sorcery' = 'true'
    AND effect_json->>'destination' = 'exile'
    AND effect_json->>'exile_target' = 'true'
    AND effect_json->>'target_controller_basic_land_tapped' = 'true'
    AND effect_json->>'basic_land_compensation_status' = 'annotation_only'
    AND effect_json->>'overload_cost' = '{4}{W}{W}'
    AND effect_json->>'overload_status' = 'annotation_only'
    AND effect_json->>'overload_target_rewrite' = 'target_to_each'
    AND effect_json->>'battle_model_scope' =
      'winds_of_abandon_opponent_creature_exile_basic_land_overload_annotation_v1'
    AND effect_json->>'oracle_runtime_scope' =
      'single_target_creature_you_do_not_control_exile_runtime_basic_land_and_overload_annotation'
    AND (effect_json->>'cmc')::numeric = 2.0
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND source = 'curated'
    AND oracle_hash = '05e38c4458b7b803d038978b46f11f72'
),
legacy_rows AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'winds of abandon'
    AND logical_rule_key <> 'battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c'
    AND effect_json->>'effect' = 'remove_creature'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only')
),
trusted_without_hash AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'winds of abandon'
    AND source IN ('manual', 'curated')
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable')
    AND coalesce(oracle_hash, '') = ''
)
SELECT 'card_rows' AS check_name, count(*)::text AS value FROM target_card
UNION ALL
SELECT 'distinct_oracle_ids', count(DISTINCT oracle_id)::text FROM target_card
UNION ALL
SELECT 'expected_oracle_hash_rows', count(*)::text
FROM target_card
WHERE md5(coalesce(oracle_text, '')) = '05e38c4458b7b803d038978b46f11f72'
UNION ALL
SELECT 'exact_executable_rule_rows', count(*)::text FROM exact_rule
UNION ALL
SELECT 'legacy_enabled_removal_rows', count(*)::text FROM legacy_rows
UNION ALL
SELECT 'trusted_executable_without_oracle_hash_rows', count(*)::text FROM trusted_without_hash;

SELECT
  'pg095_winds_of_abandon_postcheck_rules' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'winds of abandon'
ORDER BY source, review_status, execution_status, logical_rule_key;
