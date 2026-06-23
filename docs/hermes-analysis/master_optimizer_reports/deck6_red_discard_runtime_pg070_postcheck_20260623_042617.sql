\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'faithless looting'
      AND logical_rule_key = 'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa'
      AND oracle_hash = '2e734d8bae3f331866abf1b030c92781'
      AND effect_json->>'effect' = 'loot'
      AND effect_json->>'count' = '2'
      AND effect_json->>'battle_model_scope' = 'draw_two_discard_two_flashback_annotation_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) + count(*) FILTER (
    WHERE normalized_name = 'gamble'
      AND logical_rule_key = 'battle_rule_v1:2861739f22e978549e28d2339288df2a'
      AND oracle_hash = '9b3fc8ab7f664f6c084e0bda0ccf9a7c'
      AND effect_json->>'effect' = 'tutor'
      AND effect_json->>'target' = 'any'
      AND effect_json->>'discard_after_tutor_random' = 'true'
      AND effect_json->>'battle_model_scope' = 'any_card_to_hand_then_random_discard_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa',
        'battle_rule_v1:2861739f22e978549e28d2339288df2a'
      )
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa',
        'battle_rule_v1:2861739f22e978549e28d2339288df2a'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg070_deck6_red_discard_runtime_20260623_042617
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name IN ('faithless looting', 'gamble');

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
  deck_role_json
FROM card_battle_rules
WHERE normalized_name IN ('faithless looting', 'gamble')
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
