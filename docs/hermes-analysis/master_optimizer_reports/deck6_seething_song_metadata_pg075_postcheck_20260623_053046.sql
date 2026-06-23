\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash = md5(coalesce(c.oracle_text, ''))
      AND cbr.effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1'
      AND cbr.effect_json->>'produces' = 'R'
      AND cbr.effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime'
  ) AS expected_metadata_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg075_deck6_seething_song_metadata_20260623_053046
  ) AS backup_rows
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  c.name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.effect_json,
  cbr.notes
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
