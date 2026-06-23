\pset pager off
\set ON_ERROR_STOP on

SELECT
  'pg037_path_to_exile_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'path to exile'
      AND logical_rule_key = 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
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
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'path to exile'
      AND logical_rule_key <> 'battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd'
      AND effect_json->>'effect' = 'remove_creature'
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_removal_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'path to exile'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND coalesce(oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows;

SELECT
  'pg037_path_to_exile_rule_postcheck' AS check_name,
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

SELECT
  'pg037_path_to_exile_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'path to exile';
