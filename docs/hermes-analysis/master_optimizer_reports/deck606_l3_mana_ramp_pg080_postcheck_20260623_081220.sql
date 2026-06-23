\pset pager off

WITH expected(normalized_name, card_name, logical_rule_key, expected_oracle_hash, expected_scope) AS (
  VALUES
    ('monologue tax', 'Monologue Tax', 'battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d', 'ebe3a1480ad7cad5f9de5567b06db92e', 'opponent_second_spell_each_turn_create_treasure_v1'),
    ('mox opal', 'Mox Opal', 'battle_rule_v1:b236b60de8fac9e692f1442119330f34', '24b582b5091c110d1da08fec15ad07a1', 'metalcraft_three_artifacts_any_color_mana_rock_v1'),
    ('simian spirit guide', 'Simian Spirit Guide', 'battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9', 'd48d6662206fd4ed5137e37ec214e46d', 'hand_exile_red_mana_ability_v1')
),
target_rules AS (
  SELECT cbr.*, e.expected_oracle_hash, e.expected_scope
  FROM card_battle_rules cbr
  JOIN expected e
    ON e.normalized_name = cbr.normalized_name
   AND e.logical_rule_key = cbr.logical_rule_key
),
shadow_rules AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN expected e ON e.normalized_name = cbr.normalized_name
  WHERE cbr.source = 'generated'
)
SELECT
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  (SELECT count(*) FROM target_rules WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM target_rules WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM shadow_rules WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM shadow_rules WHERE review_status = 'deprecated' AND execution_status = 'disabled') AS disabled_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg080_deck606_l3_mana_ramp_20260623_081220) AS backup_rows;

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('monologue tax', 'battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d', 'ebe3a1480ad7cad5f9de5567b06db92e'),
    ('mox opal', 'battle_rule_v1:b236b60de8fac9e692f1442119330f34', '24b582b5091c110d1da08fec15ad07a1'),
    ('simian spirit guide', 'battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9', 'd48d6662206fd4ed5137e37ec214e46d')
)
SELECT
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json,
  cbr.deck_role_json
FROM card_battle_rules cbr
JOIN expected e
  ON e.normalized_name = cbr.normalized_name
 AND e.logical_rule_key = cbr.logical_rule_key
ORDER BY cbr.card_name;
