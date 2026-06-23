\pset pager off

SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
  cbr.oracle_hash,
  cbr.review_status,
  cbr.execution_status,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json->>'mana_color_status' AS mana_color_status
FROM cards c
JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
