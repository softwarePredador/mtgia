\pset pager off

SELECT
  count(*) AS ranger_rule_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash = md5(coalesce(c.oracle_text, ''))
      AND cbr.effect_json->>'battle_model_scope' = 'creature_body_etb_small_creature_tutor_sacrifice_noncreature_silence_annotation_v1'
      AND cbr.effect_json->>'etb_tutor_target' = 'creature_mana_value_1_or_less'
      AND cbr.effect_json->>'etb_tutor_status' = 'runtime_library_to_hand'
      AND cbr.effect_json->>'etb_tutor_runtime_scope' = 'creature_mana_value_1_or_less_to_hand'
      AND cbr.effect_json->>'sacrifice_noncreature_silence_status' = 'annotation_only'
  ) AS expected_ranger_tutor_runtime_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358
  ) AS backup_rows
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE c.name = 'Ranger-Captain of Eos'
  AND cbr.logical_rule_key = 'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495';

SELECT
  c.name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.effect_json,
  cbr.notes
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE c.name = 'Ranger-Captain of Eos'
  AND cbr.logical_rule_key = 'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495';
