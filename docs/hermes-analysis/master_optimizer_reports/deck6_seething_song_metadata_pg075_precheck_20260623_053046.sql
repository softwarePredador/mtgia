\pset pager off

SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.oracle_hash,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json->>'mana_color_status' AS mana_color_status,
  cbr.effect_json,
  to_regclass('manaloom_deploy_audit.pg075_deck6_seething_song_metadata_20260623_053046') IS NOT NULL AS backup_table_already_exists
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
