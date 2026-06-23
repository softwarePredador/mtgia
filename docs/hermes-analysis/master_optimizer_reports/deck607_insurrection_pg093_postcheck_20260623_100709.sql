WITH target_rules(normalized_name, card_name, expected_oracle_hash, expected_logical_rule_key, expected_scope) AS (
  VALUES
    (
      'insurrection',
      'Insurrection',
      'a756d0c90be63a18b7eaf97582e75b8e',
      'battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954',
      'steal_all_creatures_until_eot_haste_attack_projection_v1'
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
  (SELECT count(*) FROM target_rows WHERE effect_json->>'runtime_model' = 'compact_damage_projection') AS compact_runtime_rows,
  (SELECT count(*) FROM target_rows WHERE effect_json->>'control_duration' = 'until_end_of_turn' AND (effect_json->>'stolen_creatures_gain_haste')::boolean IS TRUE) AS eot_haste_rows,
  (SELECT count(*) FROM target_rows WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM target_rows WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM non_target_rows WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM non_target_rows WHERE execution_status = 'disabled') AS disabled_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg093_deck607_insurrection_20260623_100709) AS backup_rows;

SELECT normalized_name, card_name, logical_rule_key, oracle_hash, effect_json,
       deck_role_json, review_status, execution_status, source, confidence,
       rule_version
FROM card_battle_rules
WHERE normalized_name = 'insurrection'
ORDER BY normalized_name, execution_status, review_status, logical_rule_key;
