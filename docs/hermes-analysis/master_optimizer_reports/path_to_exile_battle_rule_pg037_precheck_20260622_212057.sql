\pset pager off
\set ON_ERROR_STOP on

WITH oracle_stats AS (
  SELECT
    count(*) AS card_rows,
    count(DISTINCT oracle_id) AS distinct_oracle_ids,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '861c960a37be744e45f13200349e2532'
    ) AS expected_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'path to exile'
),
rule_stats AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
        AND effect_json->>'effect' = 'remove_creature'
        AND effect_json->>'target' = 'creature'
        AND effect_json->>'instant' = 'true'
        AND effect_json->>'destination' = 'exile'
        AND effect_json->>'exile_target' = 'true'
        AND effect_json->>'target_controller_basic_land_tapped' = 'true'
        AND effect_json->>'basic_land_compensation_status' = 'annotation_only'
        AND effect_json->>'battle_model_scope' =
          'path_to_exile_creature_exile_basic_land_compensation_annotation_v1'
        AND (effect_json->>'cmc')::numeric = 1.0
        AND review_status = 'active'
        AND execution_status = 'auto'
        AND source = 'curated'
        AND oracle_hash = '861c960a37be744e45f13200349e2532'
    ) AS exact_executable_rule_rows,
    count(*) FILTER (
      WHERE logical_rule_key <> 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
        AND effect_json->>'effect' = 'remove_creature'
        AND review_status NOT IN ('rejected', 'deprecated')
        AND execution_status IN ('auto', 'executable', 'review_only')
    ) AS legacy_enabled_removal_rows,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND coalesce(oracle_hash, '') = ''
    ) AS trusted_executable_without_oracle_hash_rows
  FROM card_battle_rules
  WHERE normalized_name = 'path to exile'
)
SELECT
  'pg037_path_to_exile_precheck_counts' AS check_name,
  oracle_stats.card_rows,
  oracle_stats.distinct_oracle_ids,
  oracle_stats.expected_oracle_hash_rows,
  rule_stats.exact_executable_rule_rows,
  rule_stats.legacy_enabled_removal_rows,
  rule_stats.trusted_executable_without_oracle_hash_rows
FROM oracle_stats, rule_stats;

SELECT
  'pg037_path_to_exile_precheck_rules' AS check_name,
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
WHERE normalized_name = 'path to exile'
ORDER BY source, review_status, execution_status, logical_rule_key;
