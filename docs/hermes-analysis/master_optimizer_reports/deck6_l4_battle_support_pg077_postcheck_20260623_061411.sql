\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'jeska''s will'
      AND logical_rule_key = 'battle_rule_v1:c8621a807cc65adc820a8b8189979f70'
      AND oracle_hash = 'e323893e6c38ee2d618b4f9c737fadee'
      AND effect_json->>'effect' = 'ramp_ritual'
      AND effect_json->>'produces' = 'R'
      AND effect_json->>'mana_produced_from_target_opponent_hand_size' = 'true'
      AND effect_json->>'impulse_exile_top_count' = '3'
      AND effect_json->>'battle_model_scope' = 'choose_both_with_commander_red_by_target_opponent_hand_impulse_top_three_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) + count(*) FILTER (
    WHERE normalized_name = 'mizzix''s mastery'
      AND logical_rule_key = 'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
      AND oracle_hash = '8b822f0c58e4ab4e91f9e4946e8c04e9'
      AND effect_json->>'effect' = 'overload_recursion'
      AND effect_json->>'target' = 'instant_or_sorcery_graveyard'
      AND effect_json->>'casts_copies_without_paying_mana' = 'true'
      AND effect_json->>'exiles_self' = 'true'
      AND effect_json->>'battle_model_scope' = 'target_or_overload_graveyard_instant_sorcery_copy_cast_runtime_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key NOT IN (
        'battle_rule_v1:c8621a807cc65adc820a8b8189979f70',
        'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
      )
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:c8621a807cc65adc820a8b8189979f70',
        'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg077_deck6_l4_battle_support_20260623_061411
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name IN ('jeska''s will', 'mizzix''s mastery');

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
WHERE normalized_name IN ('jeska''s will', 'mizzix''s mastery')
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
