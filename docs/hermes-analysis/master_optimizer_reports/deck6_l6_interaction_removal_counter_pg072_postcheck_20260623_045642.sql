\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'get lost'
      AND logical_rule_key = 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea'
      AND oracle_hash = '6b6517e1b5b60db5cf6bbcd991dbc1ec'
      AND effect_json->>'effect' = 'remove_permanent'
      AND effect_json->>'target' = 'creature_enchantment_or_planeswalker'
      AND effect_json->>'map_tokens_created' = '2'
      AND effect_json->>'battle_model_scope' = 'destroy_creature_enchantment_planeswalker_create_two_map_tokens_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) + count(*) FILTER (
    WHERE normalized_name = 'pyroblast'
      AND logical_rule_key = 'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
      AND oracle_hash = 'ecf9ad1f393a664f16867aab8a6edf77'
      AND effect_json->>'effect' = 'counter'
      AND effect_json->>'requires_blue_target' = 'true'
      AND effect_json->>'battle_model_scope' = 'blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:8e7da3df51386d58c857a596433f73ea',
        'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
      )
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:8e7da3df51386d58c857a596433f73ea',
        'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg072_deck6_l6_interaction_removal_counter_20260623_045642
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name IN ('get lost', 'pyroblast');

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
WHERE normalized_name IN ('get lost', 'pyroblast')
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
