\pset pager off

SELECT
  'pg029_blasphemous_act_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'blasphemous act'
      AND logical_rule_key = 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
      AND effect_json->>'effect' = 'damage_wipe'
      AND effect_json->>'battle_model_scope' = 'blasphemous_act_damage_13_each_creature_v1'
      AND effect_json->>'damage' = '13'
      AND effect_json->>'damage_scope' = 'each_creature'
      AND effect_json->>'generic_cost_reduction_runtime' = 'annotation_only'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = '826022a579db4551b45ad35e4cfab973'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'blasphemous act'
      AND logical_rule_key <> 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
      AND effect_json->>'effect' IN ('board_wipe', 'damage_wipe')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_wipe_rows;

SELECT
  'pg029_blasphemous_act_rule_postcheck' AS check_name,
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
WHERE normalized_name = 'blasphemous act'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg029_blasphemous_act_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'blasphemous act';
