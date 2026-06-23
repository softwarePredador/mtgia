\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'esper sentinel'
      AND logical_rule_key = 'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d'
      AND oracle_hash = 'd8e8e60e34140942af13aa1be250a961'
      AND effect_json->>'effect' = 'draw_engine'
      AND effect_json->>'trigger' = 'opponent_noncreature_spell'
      AND effect_json->>'opponent_first_noncreature_spell_each_turn' = 'true'
      AND effect_json->>'tax_amount_equals_source_power' = 'true'
      AND effect_json->>'battle_model_scope' = 'first_opponent_noncreature_spell_power_tax_draw_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) + count(*) FILTER (
    WHERE normalized_name = 'wheel of misfortune'
      AND logical_rule_key = 'battle_rule_v1:402155f35799993b812ca441586017cd'
      AND oracle_hash = 'fa744c33b4bc56c05977ec9c378e5b7d'
      AND effect_json->>'effect' = 'draw_cards'
      AND effect_json->>'count' = '7'
      AND effect_json->>'wheel_like' = 'true'
      AND effect_json->>'misfortune_secret_number_model' = 'true'
      AND effect_json->>'battle_model_scope' = 'wheel_of_misfortune_secret_number_damage_discard_draw_compact_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d',
        'battle_rule_v1:402155f35799993b812ca441586017cd'
      )
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d',
        'battle_rule_v1:402155f35799993b812ca441586017cd'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg073_deck6_l4_card_flow_20260623_051141
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name IN ('esper sentinel', 'wheel of misfortune');

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
WHERE normalized_name IN ('esper sentinel', 'wheel of misfortune')
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
