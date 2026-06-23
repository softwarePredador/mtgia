\pset pager off

WITH expected(normalized_name, card_name, old_logical_rule_key, new_logical_rule_key, expected_oracle_hash, expected_scope) AS (
  VALUES
    ('monologue tax', 'Monologue Tax', 'battle_rule_v1:f1e0d9cb7e20dbb87296e1fc11566ad5', 'battle_rule_v1:4c6a09e794fd065ea945bb51e8fe045d', 'ebe3a1480ad7cad5f9de5567b06db92e', 'opponent_second_spell_each_turn_create_treasure_v1'),
    ('mox opal', 'Mox Opal', 'battle_rule_v1:a5270b2fac934dee9b6efc9d0e2ea81d', 'battle_rule_v1:b236b60de8fac9e692f1442119330f34', '24b582b5091c110d1da08fec15ad07a1', 'metalcraft_three_artifacts_any_color_mana_rock_v1'),
    ('simian spirit guide', 'Simian Spirit Guide', 'battle_rule_v1:4e1327303383797ace516af3151eed77', 'battle_rule_v1:5ceeb0717088fe3c67faab83de1a48c9', 'd48d6662206fd4ed5137e37ec214e46d', 'hand_exile_red_mana_ability_v1')
),
target_rules AS (
  SELECT cbr.*, e.expected_oracle_hash, e.expected_scope, e.new_logical_rule_key
  FROM card_battle_rules cbr
  JOIN expected e
    ON e.normalized_name = cbr.normalized_name
   AND e.old_logical_rule_key = cbr.logical_rule_key
),
shadow_rules AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN expected e ON e.normalized_name = cbr.normalized_name
  WHERE cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
)
SELECT
  (SELECT count(*) FROM expected) AS expected_target_rules,
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  (SELECT count(*) FROM target_rules WHERE COALESCE(effect_json->>'battle_model_scope', '') = '') AS target_missing_scope_rows,
  (SELECT count(*) FROM shadow_rules) AS review_shadow_rows,
  to_regclass('manaloom_deploy_audit.pg080_deck606_l3_mana_ramp_20260623_081220') IS NOT NULL AS backup_table_already_exists;

WITH expected(normalized_name, card_name, old_logical_rule_key, expected_oracle_hash, expected_scope) AS (
  VALUES
    ('monologue tax', 'Monologue Tax', 'battle_rule_v1:f1e0d9cb7e20dbb87296e1fc11566ad5', 'ebe3a1480ad7cad5f9de5567b06db92e', 'opponent_second_spell_each_turn_create_treasure_v1'),
    ('mox opal', 'Mox Opal', 'battle_rule_v1:a5270b2fac934dee9b6efc9d0e2ea81d', '24b582b5091c110d1da08fec15ad07a1', 'metalcraft_three_artifacts_any_color_mana_rock_v1'),
    ('simian spirit guide', 'Simian Spirit Guide', 'battle_rule_v1:4e1327303383797ace516af3151eed77', 'd48d6662206fd4ed5137e37ec214e46d', 'hand_exile_red_mana_ability_v1')
)
SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash,
  e.expected_oracle_hash,
  c.oracle_text
FROM expected e
JOIN cards c ON lower(c.name) = e.normalized_name
ORDER BY e.normalized_name;
