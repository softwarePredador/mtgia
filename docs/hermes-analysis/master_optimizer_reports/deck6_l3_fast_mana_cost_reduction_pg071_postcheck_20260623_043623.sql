\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'lotus petal'
      AND logical_rule_key = 'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d'
      AND oracle_hash = 'a5b9069217908acfd75c5704b414b035'
      AND effect_json->>'effect' = 'ramp_ritual'
      AND effect_json->>'mana_produced' = '1'
      AND effect_json->>'sacrifice_self_for_mana' = 'true'
      AND effect_json->>'battle_model_scope' = 'zero_mana_artifact_sacrifice_one_mana_one_shot_runtime_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) + count(*) FILTER (
    WHERE normalized_name = 'ruby medallion'
      AND logical_rule_key = 'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
      AND oracle_hash = '52bc55846d69bacf3afba1ffa734b81e'
      AND effect_json->>'effect' = 'passive'
      AND effect_json->>'cost_reduction_status' = 'annotation_only_no_dynamic_cost_executor'
      AND effect_json->>'battle_model_scope' = 'red_spell_cost_reduction_annotation_only_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d',
        'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
      )
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:d3366a0b9063a1af91a75a6398c1962d',
        'battle_rule_v1:bd05ea5e0a5343c1bf8f2284d001471a'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg071_deck6_l3_fast_mana_cost_reduction_20260623_043623
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name IN ('lotus petal', 'ruby medallion');

SELECT
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM card_battle_rules
WHERE normalized_name IN ('lotus petal', 'ruby medallion')
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
