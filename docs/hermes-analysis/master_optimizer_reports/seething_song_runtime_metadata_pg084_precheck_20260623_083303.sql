\pset pager off

SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json->>'mana_color_status' AS mana_color_status,
  cbr.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  cbr.effect_json->>'pg058_l3b_simple_red_ritual_family' AS pg058_family,
  cbr.review_status,
  cbr.execution_status,
  cbr.effect_json
FROM cards c
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE c.name = 'Seething Song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE cbr.oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32') AS hash_match_rows,
  count(*) FILTER (WHERE cbr.effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime') AS missing_mana_color_status_rows,
  count(*) FILTER (WHERE cbr.effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation') AS missing_runtime_scope_rows,
  count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto') AS trusted_auto_rows
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
