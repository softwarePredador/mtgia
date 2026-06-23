WITH target_rules(normalized_name, card_name, expected_oracle_hash, expected_logical_rule_key, expected_scope) AS (
  VALUES
    (
      'return the favor',
      'Return the Favor',
      'a24911b7ea2027ebba59bb6792eee776',
      'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2',
      'spree_copy_instant_or_sorcery_stack_spell_change_target_annotation_v1'
    ),
    (
      'untimely malfunction',
      'Untimely Malfunction',
      '877f2d75c90c7886ca9536135829bb90',
      'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8',
      'modal_destroy_artifact_redirect_or_cant_block_annotation_v1'
    )
),
target_rows AS (
  SELECT cbr.*, tr.expected_oracle_hash, tr.expected_scope
  FROM target_rules tr
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.expected_logical_rule_key
),
non_target_rows AS (
  SELECT cbr.*
  FROM target_rules tr
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key <> tr.expected_logical_rule_key
)
SELECT
  (SELECT count(*) FROM target_rows) AS target_rule_rows,
  (SELECT count(*) FROM target_rows WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  (SELECT count(*) FROM target_rows WHERE oracle_hash IS NULL) AS target_missing_hash_rows,
  (SELECT count(*) FROM target_rows WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT count(*) FROM target_rows WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM target_rows WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM target_rows WHERE normalized_name = 'return the favor' AND effect_json->>'change_target_mode_status' = 'annotation_only' AND effect_json->>'copy_activated_triggered_ability_status' = 'annotation_only') AS return_annotation_rows,
  (SELECT count(*) FROM target_rows WHERE normalized_name = 'untimely malfunction' AND effect_json->>'redirect_target_mode_status' = 'annotation_only' AND effect_json->>'cant_block_mode_status' = 'annotation_only') AS untimely_annotation_rows,
  (SELECT count(*) FROM non_target_rows WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM non_target_rows WHERE execution_status = 'disabled') AS disabled_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg092_deck608_l7_modal_interaction_20260623_095405) AS backup_rows;

SELECT normalized_name, card_name, logical_rule_key, oracle_hash, effect_json,
       deck_role_json, review_status, execution_status, source, confidence,
       rule_version
FROM card_battle_rules
WHERE normalized_name IN ('return the favor', 'untimely malfunction')
ORDER BY normalized_name, execution_status, review_status, logical_rule_key;
