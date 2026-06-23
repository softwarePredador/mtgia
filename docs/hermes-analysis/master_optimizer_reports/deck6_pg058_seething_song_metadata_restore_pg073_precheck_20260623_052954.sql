\pset pager off

SELECT
  count(*) FILTER (
    WHERE c.name = 'Seething Song'
      AND md5(coalesce(c.oracle_text, '')) = 'ccd492289c6f1c14c8fb7a248d7bbf32'
  ) AS target_cards_with_expected_oracle_hash,
  count(*) FILTER (
    WHERE r.normalized_name = 'seething song'
      AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
      AND r.execution_status = 'auto'
      AND r.oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
  ) AS target_runtime_rows,
  count(*) FILTER (
    WHERE r.normalized_name = 'seething song'
      AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
      AND r.execution_status = 'auto'
      AND (
        r.effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime'
        OR r.effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
        OR r.effect_json->>'pg058_l3b_simple_red_ritual_family' IS DISTINCT FROM 'deck6_simple_red_rituals'
      )
  ) AS target_missing_runtime_metadata_rows,
  to_regclass('manaloom_deploy_audit.pg073_pg058_seething_song_metadata_restore_20260623_052954') IS NOT NULL AS backup_table_already_exists
FROM cards c
LEFT JOIN card_battle_rules r ON r.card_id = c.id OR r.normalized_name = lower(c.name)
WHERE c.name = 'Seething Song';

SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS card_oracle_hash,
  r.normalized_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.confidence,
  r.oracle_hash,
  r.effect_json,
  r.notes
FROM cards c
JOIN card_battle_rules r ON r.card_id = c.id OR r.normalized_name = lower(c.name)
WHERE c.name = 'Seething Song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
ORDER BY r.logical_rule_key;
