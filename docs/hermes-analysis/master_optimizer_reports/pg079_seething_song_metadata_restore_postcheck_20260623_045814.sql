\pset pager off

SELECT
  c.name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json->>'produces' AS produces,
  (cbr.effect_json->>'mana_produced')::integer AS mana_produced,
  cbr.effect_json->>'mana_color_status' AS mana_color_status,
  cbr.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  cbr.effect_json->>'pg058_l3b_simple_red_ritual_family' AS pg058_l3b_simple_red_ritual_family,
  (SELECT count(*) FROM manaloom_deploy_audit.pg079_seething_song_metadata_restore_20260623_045814) AS backup_rows
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
